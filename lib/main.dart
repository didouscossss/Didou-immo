import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/rendement/rendement_home.dart';
import 'services/loyer_reference_service.dart';
import 'state/rendement_state.dart';
import 'state/user_account_state.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialisation défensive : si Firebase refuse de démarrer (options
  // invalides, projet supprimé...), l'app bascule en mode local — sans
  // compte, sans limite de biens — au lieu de planter.
  var firebaseReady = false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    firebaseReady = true;
  } catch (_) {
    firebaseReady = false;
  }
  // Démarré ici (après Firebase, pas avant) : `LoyerReferenceService` tente
  // Firebase Storage en premier, avant de retomber sur l'asset embarqué —
  // le tenter avant que Firebase soit prêt échouerait à coup sûr. Non
  // attendu : `RendementState.load` ne bloque plus dessus non plus (voir sa
  // doc), pour ne jamais retarder le premier affichage de l'app dessus.
  unawaited(LoyerReferenceService.preload());
  runApp(DidouImmoApp(firebaseReady: firebaseReady));
}

class DidouImmoApp extends StatelessWidget {
  final bool firebaseReady;
  const DidouImmoApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RendementState()),
        ChangeNotifierProvider(create: (_) => UserAccountState()),
      ],
      // `Consumer` plutôt que `theme: buildAppTheme()` directement : le
      // thème Material (fond de Scaffold, AppBar...) doit se reconstruire
      // quand `darkMode` change, pas seulement les widgets qui lisent
      // `AppColors.xxx` à chaque rebuild.
      child: Consumer<RendementState>(
        builder: (context, state, _) => MaterialApp(
          title: 'Rendement',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(dark: state.darkMode, novice: state.niveau == NiveauMode.novice),
          // Sans ça, les sélecteurs de date natifs (ex. date d'achat d'un
          // bien) s'affichaient avec les noms de mois/jours en anglais.
          locale: const Locale('fr', 'FR'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('fr', 'FR')],
          home: AppRoot(firebaseReady: firebaseReady),
        ),
      ),
    );
  }
}

/// Bascule entre mode local (pas de compte) et mode connecté selon
/// [firebaseReady] et l'état d'authentification, et garde `RendementState`
/// synchronisé avec le compte courant (voir `RendementState.attachAccount`).
class AppRoot extends StatefulWidget {
  final bool firebaseReady;
  const AppRoot({super.key, required this.firebaseReady});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  UserAccountState? _account;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.firebaseReady && _account == null) {
      _account = context.read<UserAccountState>()
        ..start()
        ..addListener(_syncAccount);
    }
  }

  void _syncAccount() {
    context.read<RendementState>().attachAccount(_account?.user?.uid);
  }

  @override
  void dispose() {
    _account?.removeListener(_syncAccount);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseReady) {
      return const RendementHome(firebaseReady: false);
    }
    final account = context.watch<UserAccountState>();
    if (account.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (account.user == null) {
      return const AuthScreen();
    }
    return const RendementHome(firebaseReady: true);
  }
}
