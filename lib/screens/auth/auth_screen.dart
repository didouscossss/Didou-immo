import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../legal/legal_screens.dart';

/// Écran de connexion / inscription — équivalent d'un `AuthGate` classique.
/// Un seul écran, bascule entre les deux modes.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  bool _acceptedTerms = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  late final _cguRecognizer = TapGestureRecognizer()
    ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CgvScreen()));
  late final _confidentialiteRecognizer = TapGestureRecognizer()
    ..onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConfidentialiteScreen()));

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _cguRecognizer.dispose();
    _confidentialiteRecognizer.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Renseigne ton email et ton mot de passe.');
      return;
    }
    if (_isSignUp && !_acceptedTerms) {
      setState(() => _error = "Tu dois accepter les CGU et la politique de confidentialité pour créer un compte.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = context.read<UserAccountState>();
    final error = _isSignUp ? await state.signUp(email, password) : await state.signIn(email, password);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  Future<void> _submitGoogle() async {
    if (_isSignUp && !_acceptedTerms) {
      setState(() => _error = "Tu dois accepter les CGU et la politique de confidentialité pour créer un compte.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final error = await context.read<UserAccountState>().signInWithGoogle();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      // `LayoutBuilder` + `ConstrainedBox(minHeight: ...)` plutôt qu'un
      // `Center` autour du `SingleChildScrollView` : ce dernier empêchait le
      // clavier de faire défiler jusqu'au champ actif (l'écran restait
      // "centré" sur son ancienne hauteur), masquant en partie le formulaire
      // à la saisie. Ici, `minHeight` suit la hauteur réellement dispo (donc
      // rétrécie par le clavier), donc le défilement automatique vers le
      // champ actif fonctionne normalement.
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    // Recadré autour du texte (le fichier source d'origine,
                    // carré, laissait une grande marge vide au-dessus et en
                    // dessous qui rendait "Didou-immo" minuscule et illisible
                    // une fois réduit à la taille d'un logo d'écran).
                    child: Image.asset('assets/images/didou_logo.png', width: 220, fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Image.asset('assets/images/didou.png', height: 130, fit: BoxFit.contain),
                ),
                const SizedBox(height: 12),
                Text(
                  _isSignUp ? 'Créer un compte' : 'Content de te revoir',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Text(
                  "Ton compte garde tes biens enregistrés, où que tu te connectes.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6)),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _decoration('Mot de passe'),
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: _loading ? null : (v) => setState(() => _acceptedTerms = v ?? false),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7)),
                              children: [
                                const TextSpan(text: "J'accepte les "),
                                TextSpan(
                                  text: 'CGU',
                                  style: TextStyle(color: AppColors.accent, decoration: TextDecoration.underline),
                                  recognizer: _cguRecognizer,
                                ),
                                const TextSpan(text: ' et la '),
                                TextSpan(
                                  text: 'politique de confidentialité',
                                  style: TextStyle(color: AppColors.accent, decoration: TextDecoration.underline),
                                  recognizer: _confidentialiteRecognizer,
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.alert)),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_isSignUp ? 'Créer mon compte' : 'Se connecter'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _submitGoogle,
                  icon: const Icon(Icons.login, size: 18),
                  label: const Text('Continuer avec Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(
                    _isSignUp ? 'Déjà un compte ? Se connecter' : 'Pas encore de compte ? En créer un',
                    style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.accent),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.border)),
      );
}
