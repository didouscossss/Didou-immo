const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");

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
