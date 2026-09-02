const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getStorage} = require("firebase-admin/storage");
const {Readable} = require("node:stream");
const readline = require("node:readline");
const nodemailer = require("nodemailer");

initializeApp();
const db = getFirestore();

// ~10 % d'un mois (~30 jours). Voir lib/services/referral_service.dart —
// garder les deux en phase si cette valeur change.
const BONUS_DAYS_MONTHLY = 3;

/**
 * Applique un code de parrainage : crédite `pendingBonusDays` au filleul
 * (l'appelant) ET au parrain (propriétaire du code), et incrémente le
 * compteur d'utilisation du code.
 *
 * Tourne côté serveur (Admin SDK, contourne les règles Firestore) parce que
 * l'opération écrit sur le document d'un AUTRE utilisateur (le parrain) —
 * ce que les règles Firestore ne peuvent pas autoriser de façon sûre pour
 * un client (voir la discussion dans firestore.rules). Le client appelle
 * cette fonction via `FirebaseFunctions.instance.httpsCallable(...)`
 * (voir referral_service.dart) au lieu d'écrire directement.
 *
 * data: { code: string }
 * Lève une HttpsError (unauthenticated / invalid-argument / not-found /
 * failed-precondition) avec un message adapté à l'affichage utilisateur en
 * cas d'échec ; ne renvoie rien de particulier en cas de succès.
 */
exports.applyReferralCode = onCall(async (request) => {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Connecte-toi pour utiliser un code.");
  }

  const enteredCode = String(request.data && request.data.code || "").trim().toUpperCase();
  if (!enteredCode) {
    throw new HttpsError("invalid-argument", "Code manquant.");
  }

  const userRef = db.collection("users").doc(uid);
  const codeRef = db.collection("referralCodes").doc(enteredCode);

  await db.runTransaction(async (tx) => {
    const [userSnap, codeSnap] = await Promise.all([tx.get(userRef), tx.get(codeRef)]);

    if (userSnap.exists && userSnap.data().referredBy) {
      throw new HttpsError(
          "failed-precondition",
          "Un code de parrainage a déjà été utilisé sur ce compte.",
      );
    }
    if (!codeSnap.exists) {
      throw new HttpsError("not-found", "Code de parrainage introuvable.");
    }
    const ownerUid = codeSnap.data().ownerUid;
    if (ownerUid === uid) {
      throw new HttpsError("failed-precondition", "Tu ne peux pas utiliser ton propre code.");
    }

    // Le filleul reçoit son bonus immédiatement (appliqué au prochain abonnement)
    tx.update(userRef, {
      referredBy: enteredCode,
      pendingBonusDays: FieldValue.increment(BONUS_DAYS_MONTHLY),
    });
    // Le parrain reçoit une récompense équivalente
    tx.update(db.collection("users").doc(ownerUid), {
      pendingBonusDays: FieldValue.increment(BONUS_DAYS_MONTHLY),
    });
    tx.update(codeRef, {
      timesUsed: FieldValue.increment(1),
    });
  });

  return {success: true};
});

// Mot de passe d'application Gmail (PAS le mot de passe du compte) — stocké
// comme secret Firebase, jamais en clair dans le dépôt. Voir README.md
// ("Notification de mise à jour du loyer/m²") pour la procédure de création
// et `firebase functions:secrets:set GMAIL_APP_PASSWORD` pour le déployer.
const gmailAppPassword = defineSecret("GMAIL_APP_PASSWORD");

// Adresse à la fois expéditrice (via Gmail SMTP) et destinataire de la
// notification — c'est le compte admin qui doit penser à republier le
// fichier, donc il s'envoie le mail à lui-même.
const NOTIFY_EMAIL = "valentin.champion31@gmail.com";

// Même jeu de données que celui pointé par le bouton "Copier le lien
// data.gouv.fr" de l'écran Administration (voir admin_screen.dart) — à
// garder en phase si l'éditeur renomme/republie le jeu de données sous un
// autre slug.
const LOYER_DATASET_SLUG =
    "carte-des-loyers-indicateurs-de-loyers-dannonce-par-commune-en-2025";
const LOYER_DATASET_API_URL =
    `https://www.data.gouv.fr/api/1/datasets/${LOYER_DATASET_SLUG}/`;

/**
 * Vérifie chaque semaine si data.gouv.fr propose une version plus récente
 * du fichier "Carte des loyers" (celui dont le nom se termine par
 * `appmefdhup.csv`, voir `loyer_import_service.dart`), et envoie un email à
 * l'admin si oui — pour qu'il pense à le retélécharger et le republier
 * depuis Mon compte > Administration, sans attendre de tomber dessus par
 * hasard (cette donnée n'est republiée qu'environ une fois par an).
 *
 * Ne modifie rien côté app : seulement une alerte, la republication reste
 * un geste manuel (import + vérification de l'aperçu) via l'écran
 * Administration existant.
 */
exports.checkLoyerDatasetUpdate = onSchedule(
    {
      schedule: "0 8 * * 1", // chaque lundi 08h00
      timeZone: "Europe/Paris",
      secrets: [gmailAppPassword],
    },
    async () => {
      const res = await fetch(LOYER_DATASET_API_URL);
      if (!res.ok) {
        console.error(`data.gouv.fr a répondu ${res.status} pour ${LOYER_DATASET_API_URL}`);
        return;
      }
      const dataset = await res.json();

      const resource = (dataset.resources || []).find((r) => {
        const haystack = `${r.url || ""} ${r.title || ""}`.toLowerCase();
        return haystack.includes("appmefdhup");
      });
      if (!resource) {
        console.warn("Ressource 'appmefdhup.csv' introuvable dans le jeu de données data.gouv.fr — " +
            "le format de la page a peut-être changé, à vérifier manuellement.");
        return;
      }

      // Selon la version de l'API udata, le champ peut s'appeler
      // `last_modified` ou (plus rarement) `last_update` — on essaie les
      // deux plutôt que de dépendre d'un seul nom de champ.
      const lastModified = resource.last_modified || resource.last_update || resource.created_at;
      if (!lastModified) {
        console.warn("Aucune date exploitable trouvée sur la ressource — vérification manuelle nécessaire.");
        return;
      }

      const watchRef = db.collection("system").doc("loyerDatasetWatch");
      const watchSnap = await watchRef.get();
      const known = watchSnap.exists ? watchSnap.data().lastModified : null;

      if (known === lastModified) return; // rien de nouveau depuis la dernière vérification

      await watchRef.set(
          {lastModified, resourceUrl: resource.url || null, checkedAt: FieldValue.serverTimestamp()},
          {merge: true},
      );

      // Premier passage (pas de valeur connue en base) : on enregistre juste
      // la référence, sans envoyer de mail — sinon le tout premier
      // déploiement enverrait systématiquement un mail "fantôme" pour une
      // donnée qui n'a en réalité pas changé depuis la dernière mise à jour
      // manuelle.
      if (!known) return;

      const transporter = nodemailer.createTransport({
        service: "gmail",
        auth: {user: NOTIFY_EMAIL, pass: gmailAppPassword.value()},
      });
      await transporter.sendMail({
        from: NOTIFY_EMAIL,
        to: NOTIFY_EMAIL,
        subject: "Didou Immo : nouveau fichier loyer/m² disponible sur data.gouv.fr",
        text:
            "Un fichier plus récent que le dernier connu est disponible sur data.gouv.fr " +
            "(\"Carte des loyers\").\n\n" +
            `Lien : ${resource.url || `https://www.data.gouv.fr/datasets/${LOYER_DATASET_SLUG}`}\n\n` +
            "Pour le mettre à jour : télécharge ce fichier, puis republie-le depuis " +
            "Mon compte > Administration > Loyer/m² par commune.",
      });
    },
);

// Même jeu de données que celui pointé par le bouton "Copier le lien
// data.gouv.fr" pour les prix dans l'écran Administration (voir
// admin_screen.dart, `_dataGouvPrixUrl`) — à garder en phase si l'éditeur
// renomme/republie le jeu de données sous un autre slug.
const DVF_DATASET_SLUG = "statistiques-dvf";
const DVF_DATASET_API_URL = `https://www.data.gouv.fr/api/1/datasets/${DVF_DATASET_SLUG}/`;

const CODE_INSEE_CANDIDATES = ["codegeo", "codecommune", "inseecom", "codeinsee", "insee"];
const LIBELLE_CANDIDATES = ["libellegeo", "nomcommune", "libellecommune", "nom"];
const ECHELLE_CANDIDATES = ["echellegeo", "echelle", "niveaugeo"];
// Format confirmé sur le fichier réel "Statistiques mensuelles DVF" (voir
// dryRun) : colonne "annee_mois", une ligne par commune ET PAR MOIS (ex.
// "2021-01") — contrairement à ce qu'on espérait, ce n'est PAS un agrégat
// glissant déjà calculé par data.gouv.fr : il faut vraiment agréger
// nous-mêmes les 12 derniers mois (voir plus bas).
const PERIODE_CANDIDATES = [
  "anneemois", "periode", "moisannee", "date", "datedebut", "datemutation", "annee",
];
// Confirmé sur le fichier réel : PAS de "whole" dans ces noms de colonnes,
// contrairement au fichier "5 ans" (nb_ventes_whole_apt_maison). Les deux
// jeux de candidats sont gardés (whole ET sans whole) au cas où data.gouv.fr
// change de convention entre les deux fichiers à l'avenir.
const NB_VENTES_CANDIDATES = [
  "nbventesaptmaison", "nbventeswholeaptmaison", "nbventes", "nombreventes",
];
const PRIX_MEDIAN_CANDIDATES = [
  "medprixm2aptmaison", "medprixm2wholeaptmaison", "prixm2median", "prixmedianm2",
];
const PRIX_MOYEN_CANDIDATES = [
  "moyprixm2aptmaison", "moyprixm2wholeaptmaison", "prixm2moyen", "prixmoyenm2",
];

/** Même normalisation que `PrixImportService._normalize` côté Dart : minuscules,
 * accents et caractères non alphanumériques retirés — pour que "Code Geo" /
 * "code_geo" / "CODE-GEO" matchent tous "codegeo". */
function normalizeHeader(s) {
  const accents = "àâäéèêëïîôöùûüÿçñ";
  const sansAccents = "aaaeeeeiioouuuycn";
  let out = s.trim().toLowerCase();
  for (let i = 0; i < accents.length; i++) {
    out = out.split(accents[i]).join(sansAccents[i]);
  }
  return out.replace(/[^a-z0-9]/g, "");
}

function splitRow(line, delimiter) {
  return line.split(delimiter).map((f) => f.trim().replace(/"/g, ""));
}

/** "AAAA-MM" pour le mois courant moins [monthsAgo] mois (UTC), du même
 * format que la colonne "annee_mois" du fichier — pour comparer par simple
 * ordre lexicographique de chaînes, sans parser de vraies dates. */
function periodeMonthsAgo(monthsAgo) {
  const now = new Date();
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - monthsAgo, 1));
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, "0")}`;
}

/** Lit un flux HTTP ligne par ligne sans jamais matérialiser le fichier
 * entier en mémoire — indispensable pour le fichier mensuel (~264 Mo) : voir
 * `LineSplitter.split` côté Dart pour l'équivalent client (fichier "5 ans",
 * ~30 Mo, déjà trop lourd pour être chargé d'un coup sur un téléphone). */
function streamLines(webReadableStream) {
  const nodeStream = Readable.fromWeb(webReadableStream);
  return readline.createInterface({input: nodeStream, crlfDelay: Infinity});
}

/**
 * Republie le prix médian réel au m² par commune sur la fenêtre glissante
 * des 12 derniers mois (voir `PrixReferenceService` côté app, qui lira ce
 * fichier séparément du fichier "5 ans" existant — travail restant, pas
 * encore fait à ce stade). Contrairement à l'import "5 ans" (fait depuis
 * l'app par l'admin, fichier ~30 Mo), celui-ci tourne côté serveur : le
 * fichier "Statistiques mensuelles DVF" pèse ~264 Mo, bien trop pour être
 * téléchargé et traité depuis un téléphone (voir la discussion avec
 * l'utilisateur — risque réel de faire planter l'onglet du navigateur).
 *
 * data: { dryRun?: boolean } — en mode aperçu (dryRun: true), ne lit que
 * l'en-tête et quelques lignes du fichier réel (rapide, ne télécharge pas
 * tout) et les renvoie telles quelles, SANS rien publier — pour confirmer
 * le format exact du fichier avant de lancer un vrai traitement complet,
 * vu que sa structure précise n'a pas pu être vérifiée à l'avance.
 */
exports.refreshRecentPrix = onCall(
    {timeoutSeconds: 1800, memory: "2GiB"},
    async (request) => {
      // Convertit toute exception inattendue (ex. panne réseau au milieu du
      // streaming, dépassement mémoire...) en HttpsError avec le vrai
      // message, plutôt que de laisser Firebase renvoyer un générique
      // "internal" côté client sans aucun détail exploitable (constaté en
      // conditions réelles lors du premier vrai run).
      try {
        return await runRefreshRecentPrix(request);
      } catch (err) {
        if (err instanceof HttpsError) throw err;
        throw new HttpsError("internal", `Erreur inattendue : ${err && err.message ? err.message : err}`);
      }
    },
);

async function runRefreshRecentPrix(request) {
  const uid = request.auth && request.auth.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Connecte-toi pour utiliser cette fonction.");
  }
  const userSnap = await db.collection("users").doc(uid).get();
  if (!userSnap.exists || userSnap.data().isAdmin !== true) {
    throw new HttpsError("permission-denied", "Réservé aux comptes admin.");
  }
  const dryRun = !!(request.data && request.data.dryRun);

  const datasetRes = await fetch(DVF_DATASET_API_URL);
  if (!datasetRes.ok) {
    throw new HttpsError("unavailable",
        `data.gouv.fr a répondu ${datasetRes.status} pour le jeu de données ${DVF_DATASET_SLUG}.`);
  }
  const dataset = await datasetRes.json();
  const resource = (dataset.resources || []).find((r) =>
    (r.title || "").toLowerCase().includes("mensuelle"));
  if (!resource || !resource.url) {
    throw new HttpsError("not-found",
        "Fichier \"Statistiques mensuelles DVF\" introuvable dans le jeu de données data.gouv.fr " +
        `(${DVF_DATASET_SLUG}) — le nom a peut-être changé, à vérifier manuellement.`);
  }

  const csvRes = await fetch(resource.url);
  if (!csvRes.ok) {
    throw new HttpsError("unavailable", `HTTP ${csvRes.status} en téléchargeant le fichier mensuel.`);
  }

  const rl = streamLines(csvRes.body);
  const lineIterator = rl[Symbol.asyncIterator]();

  const first = await lineIterator.next();
  if (first.done || !first.value.trim()) {
    throw new HttpsError("failed-precondition", "Fichier vide.");
  }
  const delimiter = first.value.split(";").length >= first.value.split(",").length ? ";" : ",";
  const rawHeader = splitRow(first.value, delimiter);
  const header = rawHeader.map(normalizeHeader);

  const idxOf = (candidates) => header.findIndex((h) => candidates.includes(h));
  const idxInsee = idxOf(CODE_INSEE_CANDIDATES);
  const idxLibelle = idxOf(LIBELLE_CANDIDATES);
  const idxEchelle = idxOf(ECHELLE_CANDIDATES);
  const idxPeriode = idxOf(PERIODE_CANDIDATES);
  const idxNbVentes = idxOf(NB_VENTES_CANDIDATES);
  let idxPrix = idxOf(PRIX_MEDIAN_CANDIDATES);
  if (idxPrix === -1) idxPrix = idxOf(PRIX_MOYEN_CANDIDATES);

  if (dryRun) {
    const sample = [];
    for (let i = 0; i < 5; i++) {
      const next = await lineIterator.next();
      if (next.done) break;
      sample.push(next.value);
    }
    rl.close();
    return {
      dryRun: true,
      headers: rawHeader,
      colonnesReconnues: {
        codeInsee: idxInsee !== -1 ? rawHeader[idxInsee] : null,
        libelle: idxLibelle !== -1 ? rawHeader[idxLibelle] : null,
        echelle: idxEchelle !== -1 ? rawHeader[idxEchelle] : null,
        periode: idxPeriode !== -1 ? rawHeader[idxPeriode] : null,
        nbVentes: idxNbVentes !== -1 ? rawHeader[idxNbVentes] : null,
        prix: idxPrix !== -1 ? rawHeader[idxPrix] : null,
      },
      sample,
    };
  }

  if (idxInsee === -1 || idxNbVentes === -1 || idxPrix === -1 || idxPeriode === -1) {
    rl.close();
    throw new HttpsError("failed-precondition",
        "Colonnes attendues introuvables — en-têtes réelles du fichier : " + rawHeader.join(", "));
  }

  // Une ligne = une commune ET un seul mois (confirmé via dryRun sur le
  // fichier réel — PAS un agrégat glissant déjà calculé par data.gouv.fr,
  // contrairement à ce qu'on espérait). Un seul mois de ventes par
  // commune est statistiquement trop fragile pour une médiane fiable
  // (voir la discussion avec l'utilisateur — c'est exactement pourquoi
  // ce fichier existe plutôt que d'utiliser juste le dernier mois) :
  // on agrège donc nous-mêmes les 12 derniers mois glissants par
  // commune, plutôt que de garder une seule ligne.
  //
  // Sans les transactions individuelles (seulement la médiane et le
  // nombre de ventes DE CHAQUE MOIS), une vraie médiane sur 12 mois
  // n'est pas calculable exactement : on combine les médianes
  // mensuelles par une moyenne pondérée par le nombre de ventes de
  // chaque mois — une approximation raisonnable, nettement plus
  // représentative qu'un seul mois isolé.
  const cutoffPeriode = periodeMonthsAgo(11); // 11 mois + le mois en cours = fenêtre de 12 mois
  const parCommune = new Map(); // insee -> {sommePonderee, sommeVentes}
  for await (const line of rl) {
    if (!line.trim()) continue;
    const fields = splitRow(line, delimiter);
    const maxIdx = Math.max(idxInsee, idxNbVentes, idxPrix, idxPeriode);
    if (fields.length <= maxIdx) continue;
    if (idxEchelle !== -1 && !normalizeHeader(fields[idxEchelle]).includes("commune")) continue;

    const insee = fields[idxInsee].trim();
    if (!insee) continue;
    const periode = fields[idxPeriode].trim();
    if (periode < cutoffPeriode) continue;
    const nbVentes = parseInt(fields[idxNbVentes].trim(), 10);
    const prix = parseFloat(fields[idxPrix].trim().replace(",", "."));
    if (!Number.isFinite(nbVentes) || nbVentes <= 0 || !Number.isFinite(prix) || prix <= 0) continue;

    const existing = parCommune.get(insee) || {sommePonderee: 0, sommeVentes: 0};
    existing.sommePonderee += prix * nbVentes;
    existing.sommeVentes += nbVentes;
    parCommune.set(insee, existing);
  }

  if (parCommune.size < 1000) {
    throw new HttpsError("failed-precondition",
        `Seulement ${parCommune.size} commune(s) reconnue(s) sur les 12 derniers mois dans ce fichier — ` +
        "il semble incomplet ou mal formé, rien n'a été publié.");
  }

  const result = {};
  for (const [insee, {sommePonderee, sommeVentes}] of parCommune) {
    result[insee] = {p: Math.round(sommePonderee / sommeVentes), n: sommeVentes};
  }

  const bucket = getStorage().bucket();
  await bucket.file("reference-data/prix_recents_12mois.json").save(
      JSON.stringify(result),
      {contentType: "application/json", metadata: {cacheControl: "no-cache"}},
  );

  return {success: true, nbCommunes: parCommune.size};
}
