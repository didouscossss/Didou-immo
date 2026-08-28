import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Gère la création de compte, la connexion et la déconnexion.
/// Deux méthodes : email/mot de passe (rapide à intégrer) et Google
/// Sign-In (zéro friction pour l'utilisateur, recommandé en priorité).
class AuthService {
  // `late` : ne touche Firebase qu'au premier usage réel, pas à la
  // construction — indispensable pour que l'app démarre en mode local tant
  // que Firebase n'est pas initialisé (voir `main.dart`).
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null; // annulé par l'utilisateur
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Fournisseur du compte connecté ('password', 'google.com'...), pour
  /// savoir quel flux de réauthentification proposer avant suppression.
  String? get currentProviderId =>
      _auth.currentUser?.providerData.isNotEmpty == true ? _auth.currentUser!.providerData.first.providerId : null;

  /// Requis par Firebase avant une opération sensible (suppression de
  /// compte) si la dernière connexion date de trop longtemps.
  Future<void> reauthenticateWithEmail(String email, String password) {
    final credential = EmailAuthProvider.credential(email: email, password: password);
    return _auth.currentUser!.reauthenticateWithCredential(credential);
  }

  /// Équivalent pour un compte connecté via Google — redemande le
  /// consentement Google plutôt qu'un mot de passe (il n'y en a pas).
  Future<void> reauthenticateWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(code: 'reauth-cancelled', message: 'Reconnexion annulée.');
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _auth.currentUser!.reauthenticateWithCredential(credential);
  }

  /// Supprime le compte Firebase Auth. À appeler seulement après avoir
  /// effacé les données Firestore associées (voir
  /// `FirestoreService.deleteAllUserData`) : une fois le compte supprimé,
  /// le client perd son jeton d'authentification et les règles Firestore
  /// (`isOwner`) refuseraient toute suppression ultérieure.
  Future<void> deleteAccount() {
    return _auth.currentUser!.delete();
  }
}
