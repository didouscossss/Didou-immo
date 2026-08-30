const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {defineSecret} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
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
