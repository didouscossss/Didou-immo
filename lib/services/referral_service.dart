import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Gère deux mécanismes distincts :
///
/// 1. PARRAINAGE (+10 % de temps d'utilisation) : Google Play Billing ne
///    permet pas d'appliquer une remise en % arbitraire par code
///    utilisateur (les prix sont fixés au niveau du produit, pas
///    dynamiquement par personne). Le contournement implémenté : au lieu de
///    baisser le prix payé sur le Play Store, on offre l'équivalent en
///    JOURS D'ACCÈS ILLIMITÉ EN PLUS — [bonusDays] jours, à peu près 10 %
///    d'un mois d'abonnement. Le filleul ET le parrain reçoivent chacun ce
///    bonus. Concrètement : `applyReferralCode` (Cloud Function) crédite
///    [bonusDays] en `pendingBonusDays` sur les deux comptes dès que le
///    code est saisi ; `activateSubscription` (Cloud Function, appelée
///    juste après un achat Play Billing — voir `paywall_screen.dart`) les
///    transforme alors en accès garanti jusqu'à `bonusAccessUntil`, qui
///    prolonge l'accès illimité même si l'abonnement Play Billing
///    s'arrêtait entre-temps.
///
/// 2. CODES CADEAUX (accès gratuit) : deux options complémentaires —
///    a) Les "codes promotionnels" natifs de Google Play Console
///       (Monétisation > Codes promotionnels) : la solution la plus fiable
///       pour offrir l'app gratuitement en masse (presse, influenceurs),
///       gérée entièrement par Google, sans code custom nécessaire.
///    b) Ce service, pour des codes gérés depuis Firestore et utilisables
///       directement dans l'app (plus de contrôle, ex. codes à usage limité
///       distribués toi-même) — bascule `grantedFree` sur le compte.
class ReferralService {
  // `late` : ne touche Firebase qu'au premier usage réel, pas à la
  // construction — indispensable pour que l'app démarre en mode local tant
  // que Firebase n'est pas initialisé (voir `main.dart`).
  late final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static const int bonusDays = 3; // ~10% de 30 jours — voir BONUS_DAYS_MONTHLY côté Cloud Function

  /// Génère un code de parrainage unique et lisible (ex. "DIDOU-7F3K").
  String generateReferralCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // sans caractères ambigus
    final rand = Random.secure();
    final suffix =
        List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'DIDOU-$suffix';
  }

  /// À appeler à la création de compte : attribue un code de parrainage
  /// unique à l'utilisateur et l'enregistre pour qu'il soit recherchable.
  Future<String> assignReferralCode(String uid) async {
    // Vérifie l'unicité par lecture directe du document (le code EST l'ID
    // du document, voir plus bas) plutôt que par une requête filtrée : les
    // règles Firestore n'autorisent plus que `get` sur `referralCodes`, pas
    // `list`, pour empêcher un compte connecté d'énumérer tous les codes.
    String code;
    DocumentSnapshot existing;
    do {
      code = generateReferralCode();
      existing = await _db.collection('referralCodes').doc(code).get();
    } while (existing.exists);

    await _db.collection('referralCodes').doc(code).set({
      'code': code,
      'ownerUid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'timesUsed': 0,
    });
    await _db.collection('users').doc(uid).update({'referralCode': code});
    return code;
  }

  /// Applique un code de parrainage saisi par un nouvel utilisateur.
  /// Un code ne peut être appliqué qu'une seule fois par compte.
  /// Retourne un message d'erreur (String) ou null si succès.
  ///
  /// Passe par la Cloud Function `applyReferralCode` (voir `functions/index.js`)
  /// plutôt que d'écrire directement dans Firestore : l'opération crédite
  /// aussi le compte du PARRAIN (un autre utilisateur), ce que les règles
  /// Firestore ne peuvent pas autoriser de façon sûre pour un client — voir
  /// la discussion dans `firestore.rules`. La fonction tourne avec les
  /// privilèges admin et applique exactement la même logique.
  Future<String?> applyReferralCode(String enteredCode) async {
    final code = enteredCode.trim().toUpperCase();
    try {
      await _functions.httpsCallable('applyReferralCode').call({'code': code});
      return null; // succès
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Une erreur est survenue.';
    } catch (_) {
      return 'Une erreur est survenue.';
    }
  }

  /// Confirme l'abonnement côté serveur juste après un achat Play Billing
  /// (voir `paywall_screen.dart`) et applique au passage tout bonus de
  /// parrainage en attente — voir la Cloud Function `activateSubscription`
  /// (`functions/index.js`) pour le détail, et la doc de cette classe pour
  /// le mécanisme d'ensemble.
  Future<void> activateSubscription() async {
    await _functions.httpsCallable('activateSubscription').call();
  }

  /// Codes cadeaux gérés depuis Firestore (option b, voir doc de la classe).
  /// Rend l'app gratuite à vie pour le compte qui l'utilise.
  Future<String?> redeemAccessCode(String uid, String enteredCode) async {
    final code = enteredCode.trim().toUpperCase();
    final codeRef = _db.collection('accessCodes').doc(code);

    return _db.runTransaction<String?>((tx) async {
      final snap = await tx.get(codeRef);
      if (!snap.exists) return 'Code invalide.';
      final data = snap.data()!;
      final usesRemaining = (data['usesRemaining'] ?? 0) as int;
      final active = (data['active'] ?? false) as bool;
      if (!active || usesRemaining <= 0) {
        return 'Ce code n\'est plus valide.';
      }
      tx.update(codeRef, {'usesRemaining': usesRemaining - 1});
      tx.update(_db.collection('users').doc(uid), {
        'grantedFree': true,
        'grantedFreeVia': code,
      });
      return null; // succès
    });
  }

  /// Crée un nouveau code cadeau (à utiliser depuis un outil admin, pas
  /// depuis l'app grand public — ex. un script Node.js ou la console
  /// Firebase directement).
  Future<void> createAccessCode(String code, {int uses = 1}) {
    return _db.collection('accessCodes').doc(code.toUpperCase()).set({
      'code': code.toUpperCase(),
      'usesRemaining': uses,
      'active': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
