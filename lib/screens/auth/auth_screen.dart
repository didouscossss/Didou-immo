import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/rendement_state.dart';
import '../../state/user_account_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arrival_bounce.dart';
import '../legal/legal_screens.dart';

/// Jetons de couleur figés sur la DA "Novice" (jour/nuit) — cette page doit
/// toujours rendre le vert Novice, quel que soit le réglage Novice/Avancé
/// courant de l'utilisateur (ex. il était en Avancé juste avant de se
/// déconnecter). `AppColors` est un singleton global mutable piloté par ce
/// même réglage (voir `theme/app_theme.dart`) : le forcer temporairement
/// pendant `build()` ne suffirait pas, les widgets descendants se
/// construisent après le retour de cette méthode, avec la valeur globale
/// déjà repartie sur son état réel. Valeurs identiques à celles déjà codées
/// dans `AppColors` (branche novice), pas une palette inventée — seul le
/// jour/nuit reste dynamique (branché sur `RendementState.darkMode`, un
/// vrai réglage global, lui).
class _NoviceColors {
  final bool dark;
  const _NoviceColors(this.dark);

  Color get ink => dark ? const Color(0xFFF1F9F5) : const Color(0xFF10251A);
  Color get textMuted => dark ? const Color(0xFF9EB7AB) : const Color(0xFF66756C);
  Color get accent => dark ? const Color(0xFF34D399) : const Color(0xFF1F8A5B);
  Color get accentSoft => dark ? const Color(0xFF8CF0C3) : const Color(0xFFDDF4E7);
  Color get border => dark ? const Color(0xFF2D5C49) : const Color(0xFFDCE8E0);
  Color get bg => dark ? const Color(0xFF0B1F18) : const Color(0xFFF7FBF8);
  Color get bgSecondary => dark ? const Color(0xFF10271F) : const Color(0xFFEEF8F1);
  Color get surface => dark ? const Color(0xFF143429) : const Color(0xFFFFFFFF);
  Color get alert => dark ? const Color(0xFFF87171) : const Color(0xFFEF4444);
  Color get alertSoft => dark ? const Color(0xFF3A1616) : const Color(0xFFFEF2F2);
  /// Texte/icône lisible par-dessus [accentSoft] (clair sur fond clair en
  /// jour, foncé sur fond clair-mint en nuit — [accentSoft] reste clair
  /// dans les deux modes).
  Color get onAccentSoft => dark ? bg : accent;
  List<BoxShadow> get shadowSm => [BoxShadow(color: Colors.black.withValues(alpha: dark ? 0.28 : 0.04), blurRadius: 8, offset: const Offset(0, 2))];
}

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
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

  Future<void> _forgotPassword() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('On t\'envoie un lien de réinitialisation par email.'),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Adresse e-mail'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    final error = await context.read<UserAccountState>().resetPassword(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Email envoyé — vérifie ta boîte de réception.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<RendementState>().darkMode;
    final c = _NoviceColors(dark);

    return Scaffold(
      backgroundColor: c.bg,
      // `LayoutBuilder` + `ConstrainedBox(minHeight: ...)` plutôt qu'un
      // `Center` autour du `SingleChildScrollView` : ce dernier empêchait le
      // clavier de faire défiler jusqu'au champ actif (l'écran restait
      // "centré" sur son ancienne hauteur), masquant en partie le formulaire
      // à la saisie. Ici, `minHeight` suit la hauteur réellement dispo (donc
      // rétrécie par le clavier), donc le défilement automatique vers le
      // champ actif fonctionne normalement.
      body: Stack(
        children: [
          // Fond décoratif (taches + feuilles douces) — repris de la
          // maquette fournie, recréé en formes plutôt qu'en image : léger à
          // toutes les résolutions, et cohérent avec le reste du design
          // system (tokens de couleur). Jour seulement — sur fond déjà
          // sombre la nuit, des taches vert pâle perdraient leur discrétion.
          if (!dark) Positioned.fill(child: IgnorePointer(child: ClipRect(child: _PageBackground(c: c)))),
          _buildForm(context, c, dark),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, _NoviceColors c, bool dark) {
    return SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.topRight, child: _themeToggle(c, dark)),
                      Center(child: _logo(c, dark)),
                      const SizedBox(height: 2),
                      Center(
                        child: Text('BIEN INVESTIR',
                            style: AppTextStyles.sans(fontSize: 11, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 20),
                      _welcomeCard(c),
                      const SizedBox(height: 24),
                      _fieldLabel('Adresse e-mail', c),
                      const SizedBox(height: 6),
                      _AuthField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        colors: c,
                        hint: 'ex. nom@email.fr',
                        prefixIcon: Icons.mail_outline,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                      ),
                      const SizedBox(height: 16),
                      _fieldLabel('Mot de passe', c),
                      const SizedBox(height: 6),
                      _AuthField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        colors: c,
                        hint: 'Votre mot de passe',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        autofillHints: const [AutofillHints.password],
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _loading ? null : _submit(),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: c.textMuted),
                        ),
                      ),
                      if (!_isSignUp) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _loading ? null : _forgotPassword,
                            child: Text('Mot de passe oublié ?', style: AppTextStyles.sans(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.accent)),
                          ),
                        ),
                      ],
                      if (_isSignUp) ...[
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              activeColor: c.accent,
                              onChanged: _loading ? null : (v) => setState(() => _acceptedTerms = v ?? false),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.sans(fontSize: 12.5, color: c.textMuted),
                                    children: [
                                      const TextSpan(text: "J'accepte les "),
                                      TextSpan(text: 'CGU', style: TextStyle(color: c.accent, decoration: TextDecoration.underline), recognizer: _cguRecognizer),
                                      const TextSpan(text: ' et la '),
                                      TextSpan(
                                        text: 'politique de confidentialité',
                                        style: TextStyle(color: c.accent, decoration: TextDecoration.underline),
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
                        const SizedBox(height: 14),
                        _errorCard(_error!, c),
                      ],
                      const SizedBox(height: 20),
                      ArrivalBounce(
                        active: !_loading,
                        child: SizedBox(
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: c.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: c.accent.withValues(alpha: 0.6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                            ),
                            child: _loading
                                ? Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                                    const SizedBox(width: 10),
                                    Text(_isSignUp ? 'Création...' : 'Connexion...', style: AppTextStyles.sans(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ])
                                : Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                                    Text(_isSignUp ? 'Créer mon compte' : 'Se connecter', style: AppTextStyles.sans(fontSize: 15.5, fontWeight: FontWeight.w600, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                  ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(child: Divider(color: c.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('ou continuer avec', style: AppTextStyles.sans(fontSize: 11.5, color: c.textMuted)),
                        ),
                        Expanded(child: Divider(color: c.border)),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _submitGoogle,
                          icon: const Icon(Icons.login, size: 18),
                          label: const Text('Continuer avec Google'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: c.ink,
                            side: BorderSide(color: c.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: TextButton(
                          onPressed: _loading ? null : () => setState(() => _isSignUp = !_isSignUp),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.sans(fontSize: 13, color: c.textMuted),
                              children: [
                                TextSpan(text: _isSignUp ? 'Déjà un compte ? ' : 'Pas encore de compte ? '),
                                TextSpan(
                                  text: _isSignUp ? 'Se connecter →' : 'Créer un compte →',
                                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _securityCard(c),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
  }

  Widget _themeToggle(_NoviceColors c, bool dark) {
    return InkWell(
      onTap: context.read<RendementState>().toggleDarkMode,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: c.surface, shape: BoxShape.circle, border: Border.all(color: c.border), boxShadow: c.shadowSm),
        child: Icon(dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined, size: 18, color: c.accent),
      ),
    );
  }

  /// Le logo a une partie du texte ("Didou-") et du dessin en blanc — pas de
  /// contraste en mode jour, sur le fond très clair. Un fondu radial discret
  /// juste derrière (visible seulement de jour, le mode nuit n'a pas ce
  /// problème sur son fond déjà sombre) suffit à le rendre lisible sans
  /// ajouter un vrai encadré.
  Widget _logo(_NoviceColors c, bool dark) {
    return Container(
      width: 210,
      height: 130,
      alignment: Alignment.center,
      decoration: dark
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: RadialGradient(radius: 0.75, colors: [c.ink.withValues(alpha: 0.14), c.ink.withValues(alpha: 0)]),
            ),
      child: Image.asset('assets/images/didou_logo.png', width: 150, fit: BoxFit.contain),
    );
  }

  /// Forme "feuille" (rectangle avec deux coins opposés totalement
  /// arrondis, tourné) — même trick réutilisé par [_PageBackground] pour le
  /// fond de l'écran.
  Widget _leaf({required double size, required Color color, double angle = 0}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size * 1.9,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: Radius.circular(size), bottomRight: Radius.circular(size))),
      ),
    );
  }

  Widget _fieldLabel(String text, _NoviceColors c) => Text(text, style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink));

  Widget _welcomeCard(_NoviceColors c) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppRadius.card), border: Border.all(color: c.border), boxShadow: c.shadowSm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Sous ~340px de large, le personnage à côté du texte laisserait
          // trop peu de place aux deux lignes de titre — il passe alors
          // au-dessus, en petit, plutôt que de comprimer le texte.
          final narrow = constraints.maxWidth < 340;
          final texte = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('Bon retour parmi nous !', style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: c.ink)),
            const SizedBox(height: 6),
            Text('Retrouve tes biens, tes analyses et ton patrimoine.', style: AppTextStyles.sans(fontSize: 13.5, color: c.textMuted)),
          ]);
          final mascotteHeight = narrow ? 64.0 : 84.0;
          final mascotte = SizedBox(
            height: mascotteHeight,
            child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
              // Petites feuilles décoratives en second plan derrière la
              // mascotte, comme sur la maquette — jour seulement.
              if (!c.dark) ...[
                Positioned(right: 2, top: -6, child: _leaf(size: 20, color: c.accentSoft, angle: 0.4)),
                Positioned(left: 0, bottom: -6, child: _leaf(size: 16, color: c.accentSoft, angle: -0.3)),
              ],
              Image.asset('assets/images/didou.png', height: mascotteHeight, fit: BoxFit.contain),
            ]),
          );
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            narrow
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [texte, const SizedBox(height: 8), Align(alignment: Alignment.centerRight, child: mascotte)])
                : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: texte), const SizedBox(width: 12), mascotte]),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Row(children: [
                Icon(Icons.eco_outlined, size: 16, color: c.onAccentSoft),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Un meilleur avenir se construit aujourd\'hui.',
                      style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: c.onAccentSoft)),
                ),
              ]),
            ),
          ]);
        },
      ),
    );
  }

  Widget _errorCard(String message, _NoviceColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: c.alertSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.error_outline, size: 16, color: c.alert),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: AppTextStyles.sans(fontSize: 12.5, color: c.alert))),
      ]),
    );
  }

  Widget _securityCard(_NoviceColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: c.bgSecondary, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.verified_user_outlined, size: 16, color: c.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text('Tes données restent privées.', style: AppTextStyles.sans(fontSize: 12, fontWeight: FontWeight.w500, color: c.textMuted)),
        ),
      ]),
    );
  }
}

/// Fond décoratif "taches + feuilles" de la page de connexion, repris de la
/// maquette de référence fournie — recréé en formes plutôt qu'en image
/// bitmap : net à toute résolution/densité d'écran, et les couleurs restent
/// des tokens du design system plutôt qu'une image figée.
class _PageBackground extends StatelessWidget {
  final _NoviceColors c;
  const _PageBackground({required this.c});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned(top: -70, right: -50, child: _blob(200, c.bgSecondary)),
      Positioned(top: 170, right: -90, child: _blob(240, c.accentSoft.withValues(alpha: 0.5))),
      Positioned(bottom: -60, left: -60, child: _blob(220, c.bgSecondary)),
      Positioned(top: 40, left: 6, child: _leafCluster()),
      Positioned(bottom: 40, left: 6, child: _leafCluster()),
    ]);
  }

  Widget _blob(double size, Color color) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));

  Widget _leaf({required double width, required double height, required Color color, double angle = 0}) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.only(topLeft: Radius.circular(width), bottomRight: Radius.circular(width))),
      ),
    );
  }

  Widget _leafCluster() {
    return SizedBox(
      width: 80,
      height: 170,
      child: Stack(children: [
        Positioned(top: 0, left: 20, child: _leaf(width: 26, height: 52, color: c.accent.withValues(alpha: 0.22), angle: -0.6)),
        Positioned(top: 40, left: 0, child: _leaf(width: 30, height: 60, color: c.accent.withValues(alpha: 0.3), angle: -0.5)),
        Positioned(top: 95, left: 26, child: _leaf(width: 24, height: 48, color: c.accent.withValues(alpha: 0.26), angle: -0.65)),
      ]),
    );
  }
}

/// Champ email/mot de passe stylé (label au-dessus fourni par l'appelant,
/// pas de `labelText` flottant) — bordure/ombre discrète qui passe en vert
/// accent au focus. Privé à cet écran : pas d'équivalent générique ailleurs
/// dans le projet (`NumberField` est spécifique aux champs numériques).
class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final _NoviceColors colors;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _AuthField({
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    final focused = widget.focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: focused ? c.accent : c.border, width: focused ? 1.5 : 1),
        boxShadow: focused ? [BoxShadow(color: c.accent.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 0))] : c.shadowSm,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        style: AppTextStyles.sans(fontSize: 16, color: c.ink),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AppTextStyles.sans(fontSize: 15, color: c.textMuted.withValues(alpha: 0.7)),
          prefixIcon: Icon(widget.prefixIcon, size: 20, color: c.textMuted),
          suffixIcon: widget.suffixIcon,
          filled: false,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
