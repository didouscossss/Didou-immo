import 'package:cloud_firestore/cloud_firestore.dart';

/// Toutes les lectures/écritures Firestore passent par ce service.
///
/// Structure de données recommandée :
///   users/{uid}                     -> { freeTrialsUsed: int, isSubscribed: bool, subscriptionExpiry: Timestamp }
///   users/{uid}/properties/{propId} -> le bien (form + résultats calculés)
///   suggestions/{suggestionId}      -> { uid, title, body, createdAt, status }
///
/// Important : le compteur d'essais gratuits vit sur le compte (Firestore),
/// pas sur l'appareil — sinon désinstaller/réinstaller contournerait la
/// limite des 3 essais gratuits.
class FirestoreService {
  // `late` : ne touche Firebase qu'au premier usage réel, pas à la
  // construction — indispensable pour que l'app démarre en mode local tant
  // que Firebase n'est pas initialisé (voir `main.dart`).
  late final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const int freeTrialsLimit = 3;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _propertiesCol(String uid) =>
      _userDoc(uid).collection('properties');

  /// À appeler à la première connexion pour initialiser le document utilisateur.
  Future<void> ensureUserDoc(String uid) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await _userDoc(uid).set({
        'freeTrialsUsed': 0,
        'isSubscribed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, dynamic>?> getUserStatus(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.data();
  }

  /// Vérifie si l'utilisateur peut encore sauvegarder un bien gratuitement.
  /// Prend en compte : abonnement payant actif, code cadeau (accès gratuit
  /// à vie), ou les 3 essais gratuits classiques.
  Future<bool> canSaveForFree(String uid) async {
    final status = await getUserStatus(uid);
    if (status == null) return true;
    if (status['isSubscribed'] == true) return true;
    if (status['grantedFree'] == true) return true;
    final used = (status['freeTrialsUsed'] ?? 0) as int;
    return used < freeTrialsLimit;
  }

  Future<void> incrementFreeTrialsUsed(String uid) {
    return _userDoc(uid).update({'freeTrialsUsed': FieldValue.increment(1)});
  }

  /// Marque le compte comme abonné suite à un achat côté client.
  ///
  /// ATTENTION : ceci fait confiance à l'app pour débloquer le contenu
  /// payant, ce que le README déconseille explicitement pour la version
  /// publiée — un utilisateur pourrait forger cet état sans payer. À
  /// remplacer par une Cloud Function qui valide le reçu d'achat via les
  /// Real-time Developer Notifications avant de mettre `isSubscribed` à
  /// jour côté serveur.
  Future<void> setSubscribed(String uid, bool value) {
    return _userDoc(uid).update({'isSubscribed': value});
  }

  Future<void> saveProperty(String uid, String propertyId, Map<String, dynamic> data) {
    return _propertiesCol(uid).doc(propertyId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchProperties(String uid) {
    return _propertiesCol(uid).orderBy('updatedAt', descending: true).snapshots();
  }

  Future<void> deleteProperty(String uid, String propertyId) {
    return _propertiesCol(uid).doc(propertyId).delete();
  }

  /// Efface toutes les données du compte (biens + document utilisateur) —
  /// droit à l'effacement RGPD. À appeler AVANT `AuthService.deleteAccount`
  /// tant que les règles Firestore (`isOwner`) autorisent encore l'écriture
  /// avec ce compte.
  Future<void> deleteAllUserData(String uid) async {
    final properties = await _propertiesCol(uid).get();
    final batch = _db.batch();
    for (final doc in properties.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_userDoc(uid));
    await batch.commit();
  }

  /// Suggestions d'amélioration envoyées par les utilisateurs.
  /// Consultables directement depuis la console Firebase, sans back-office
  /// à construire pour démarrer.
  Future<void> submitSuggestion(String uid, String title, String body) {
    return _db.collection('suggestions').add({
      'uid': uid,
      'title': title,
      'body': body,
      'status': 'new', // new | reviewing | planned | done
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
