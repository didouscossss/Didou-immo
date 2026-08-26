import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/referral_service.dart';

/// État du compte utilisateur — enveloppe Firebase Auth et le document
/// Firestore `users/{uid}` (essais gratuits, abonnement, parrainage, admin).
///
/// N'existe et n'est peuplé que si Firebase a pu être initialisé (voir
/// `main.dart`) : tant que le projet Firebase n'est pas configuré, l'app
/// reste utilisable en mode local sans compte, et cet état n'est jamais
/// démarré.
class UserAccountState extends ChangeNotifier {
  final AuthService _auth = AuthService();
  final FirestoreService _firestore = FirestoreService();
  final ReferralService _referral = ReferralService();

  fb.User? user;
  Map<String, dynamic>? userDoc;
  bool loading = false;
  StreamSubscription<fb.User?>? _authSub;

  bool get isSignedIn => user != null;
  int get freeTrialsUsed => (userDoc?['freeTrialsUsed'] as num?)?.toInt() ?? 0;
  bool get isSubscribed => userDoc?['isSubscribed'] == true;
  bool get grantedFree => userDoc?['grantedFree'] == true;
  bool get isAdmin => userDoc?['isAdmin'] == true;
  String? get referralCode => userDoc?['referralCode'] as String?;

  /// Équivalent client de `FirestoreService.canSaveForFree`, pour piloter
  /// l'UI sans aller-retour réseau supplémentaire.
  bool get canSaveForFree =>
      isSubscribed || grantedFree || freeTrialsUsed < FirestoreService.freeTrialsLimit;

  void start() {
    _authSub ??= _auth.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(fb.User? u) async {
    user = u;
    userDoc = null;
    if (u != null) {
      loading = true;
      notifyListeners();
      await _firestore.ensureUserDoc(u.uid);
      var status = await _firestore.getUserStatus(u.uid);
      if (status != null && status['referralCode'] == null) {
        await _referral.assignReferralCode(u.uid);
        status = await _firestore.getUserStatus(u.uid);
      }
      userDoc = status;
      loading = false;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (user == null) return;
    userDoc = await _firestore.getUserStatus(user!.uid);
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) =>
      _guard(() => _auth.signInWithEmail(email, password));

  Future<String?> signUp(String email, String password) =>
      _guard(() => _auth.signUpWithEmail(email, password));

  Future<String?> signInWithGoogle() => _guard(() => _auth.signInWithGoogle());

  Future<String?> _guard(Future<Object?> Function() action) async {
    try {
      await action();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return e.message ?? 'Une erreur est survenue.';
    } catch (_) {
      return 'Une erreur est survenue.';
    }
  }

  Future<void> signOut() => _auth.signOut();

  /// Comptabilise un essai gratuit utilisé (bien sauvegardé sans abonnement
  /// ni code cadeau) — à appeler après une sauvegarde réussie.
  Future<void> recordFreeSave() async {
    if (user == null || isSubscribed || grantedFree) return;
    await _firestore.incrementFreeTrialsUsed(user!.uid);
    await refresh();
  }

  Future<String?> applyReferralCode(String code) async {
    if (user == null) return 'Connecte-toi pour utiliser un code.';
    final err = await _referral.applyReferralCode(code);
    if (err == null) await refresh();
    return err;
  }

  Future<String?> redeemAccessCode(String code) async {
    if (user == null) return 'Connecte-toi pour utiliser un code.';
    final err = await _referral.redeemAccessCode(user!.uid, code);
    if (err == null) await refresh();
    return err;
  }

  /// Réservé aux comptes admin (`isAdmin: true` sur le document Firestore
  /// `users/{uid}`, à activer manuellement depuis la console Firebase — il
  /// n'existe pas de premier compte admin par défaut).
  Future<void> createGiftCode(String code, {int uses = 1}) {
    return _referral.createAccessCode(code, uses: uses);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
