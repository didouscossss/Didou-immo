import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jetons de design — refonte visuelle complète (voir la maquette/charte
/// détaillée fournie par l'utilisateur : 4 variantes Novice/Avancé ×
/// Jour/Nuit, avec codes hex précis pour chacune).
///
/// Champs calculés (pas `const`) plutôt que fixes, pour pouvoir s'adapter au
/// mode nuit (voir [setDark], piloté par `RendementState.darkMode`) et au
/// niveau (voir [setNovice], piloté par `RendementState.niveau`) sans avoir
/// à passer le thème explicitement à chaque écran — tout le reste de l'app
/// lit ces jetons directement (`AppColors.ink`, etc.), l'équivalent Dart des
/// variables CSS `--color-*` d'un design system web.
class AppColors {
  static bool _dark = false;
  static void setDark(bool value) => _dark = value;
  static bool get isDark => _dark;

  static bool _novice = false;
  static void setNovice(bool value) => _novice = value;
  static bool get isNovice => _novice;

  /// Texte principal.
  static Color get ink {
    if (_novice) return _dark ? const Color(0xFFF1F9F5) : const Color(0xFF10251A);
    return _dark ? const Color(0xFFF8FAFC) : const Color(0xFF1E1B4B);
  }

  /// Texte secondaire (légendes, labels discrets) — jeton à part entière
  /// plutôt qu'un simple alpha sur [ink] : la charte donne une teinte propre
  /// pour ce rôle. Les écrans pas encore retouchés continuent d'utiliser
  /// `ink.withValues(alpha: ...)`, remplacé progressivement page par page.
  static Color get textMuted {
    if (_novice) return _dark ? const Color(0xFF9EB7AB) : const Color(0xFF66756C);
    return _dark ? const Color(0xFF94A3B8) : const Color(0xFF687280);
  }

  /// Couleur d'accent principale (CTA, éléments actifs, chiffres clés
  /// positifs) — vert en mode novice, violet en mode avancé ; plus clair en
  /// mode nuit pour rester lisible sur fond sombre.
  static Color get accent {
    if (_novice) return _dark ? const Color(0xFF34D399) : const Color(0xFF1F8A5B);
    return _dark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  }

  /// Accent secondaire — un cran plus doux que [accent], pour varier sans
  /// sortir de la famille de teinte (ex. icônes secondaires, dégradés).
  static Color get accentSecondary {
    if (_novice) return _dark ? const Color(0xFF10B981) : const Color(0xFF49B97A);
    return _dark ? const Color(0xFF8B5CF6) : const Color(0xFF8B5CF6);
  }

  /// Fond teinté très doux (badges, chips, zones de conseil) — pas assez
  /// contrasté pour du texte, seulement pour un aplat derrière une icône ou
  /// un petit texte déjà coloré par ailleurs.
  static Color get accentSoft {
    if (_novice) return _dark ? const Color(0xFF8CF0C3) : const Color(0xFFDDF4E7);
    return _dark ? const Color(0xFF7C3AED) : const Color(0xFFEDE9FE);
  }

  /// Couleur "attention" (avertissement) — commune aux deux modes, pilotée
  /// par le mode nuit.
  static Color get gold => _dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);

  /// Couleur "erreur" — commune aux deux modes, pilotée par le mode nuit et
  /// (légèrement) par le niveau, comme spécifié par la charte.
  static Color get alert {
    if (_dark) return _novice ? const Color(0xFFF87171) : const Color(0xFFFB7185);
    return const Color(0xFFEF4444);
  }

  /// Vert "succès" — jeton à part entière, commun aux deux modes (distinct
  /// de [accent] en novice : la charte traite les accents sémantiques
  /// succès/attention/erreur comme une palette partagée, séparée de la
  /// couleur de marque de chaque mode).
  static Color get good {
    if (_dark) return const Color(0xFF34D399);
    return _novice ? const Color(0xFF109B81) : const Color(0xFF10B981);
  }

  static Color get border {
    if (_novice) return _dark ? const Color(0xFF2D5C49) : const Color(0xFFDCE8E0);
    return _dark ? const Color(0xFF3F3A78) : const Color(0xFFE2E0F0);
  }

  /// Fond principal de l'app (Scaffold).
  static Color get paper {
    if (_novice) return _dark ? const Color(0xFF0B1F18) : const Color(0xFFF7FBF8);
    return _dark ? const Color(0xFF0F172A) : const Color(0xFFF8F7FC);
  }

  /// Fond secondaire — pour distinguer une section du fond principal sans
  /// passer par une carte à part entière (ex. bandeau, zone groupée).
  static Color get paperSecondary {
    if (_novice) return _dark ? const Color(0xFF10271F) : const Color(0xFFEEF8F1);
    return _dark ? const Color(0xFF15162E) : const Color(0xFFF1EEFB);
  }

  /// Fond des cartes/encadrés.
  static Color get surface {
    if (_novice) return _dark ? const Color(0xFF143429) : const Color(0xFFFFFFFF);
    return _dark ? const Color(0xFF1E1B4B) : const Color(0xFFFFFFFF);
  }

  /// Fond de carte "surélevée" — un cran plus clair que [surface] en
  /// sombre, pour empiler des niveaux de profondeur (carte dans une carte,
  /// zone mise en avant) sans jamais toucher au noir pur.
  static Color get surfaceElevated {
    if (_novice) return _dark ? const Color(0xFF1B4033) : const Color(0xFFEEF9F3);
    return _dark ? const Color(0xFF26205A) : const Color(0xFFF5F1FF);
  }

  /// Dégradé des cartes "chiffres clés" (patrimoine, cash-flow...) — vert
  /// doux en novice (identique jour/nuit), violet clair→principal en avancé
  /// de jour, violet profond→principal en avancé de nuit. Volontairement
  /// resserré sur une seule famille de teinte (pas de rose/orange mêlés)
  /// pour que les courbes tracées par-dessus (ex. cash-flow du portefeuille)
  /// restent lisibles.
  static List<Color> get heroGradient {
    if (_novice) return const [Color(0xFF6FA97F), Color(0xFF3D6B4A)];
    return _dark
        ? const [Color(0xFF312E81), Color(0xFF7C3AED), Color(0xFFA78BFA)]
        : const [Color(0xFFA78BFA), Color(0xFF7C3AED)];
  }

  /// Bande dégradée derrière le titre de chaque section (voir
  /// `SectionTitle`) — terre cuite en mode novice, violet en mode avancé.
  static List<Color> get sectionBandGradient {
    if (_novice) {
      return _dark
          ? const [Color(0xFF8B4226), Color(0xFFC97B4E)]
          : const [Color(0xFFE8956B), Color(0xFFF6D9BE)];
    }
    return _dark
        ? const [Color(0xFF312E81), Color(0xFF7C3AED)]
        : const [Color(0xFFA78BFA), Color(0xFFEDE9FE)];
  }

  /// Dégradé de fond de l'app (écran principal à onglets) — un voile doux,
  /// haut→bas, dans la même famille de teinte que [paper].
  static List<Color> get backgroundGradient {
    if (_novice) {
      return _dark
          ? const [Color(0xFF123B27), Color(0xFF07160F)]
          : const [Color(0xFFF7FBF8), Color(0xFFEEF8F1)];
    }
    return _dark
        ? const [Color(0xFF0F172A), Color(0xFF1E1B4B)]
        : const [Color(0xFFF8F7FC), Color(0xFFEDE9FE)];
  }
}

/// Rayons d'arrondi communs — cartes plus arrondies que les boutons, pour
/// une hiérarchie visuelle cohérente sur tout l'écran plutôt que des valeurs
/// choisies au cas par cas dans chaque widget.
class AppRadius {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double button = 14;
  static const double card = 20;
}

/// Ombres légères — jamais appuyées, juste de quoi détacher une carte ou une
/// barre fixe du fond derrière elle. Plus marquées en mode nuit (un fond
/// sombre a besoin de plus de contraste d'ombre pour rester perceptible).
class AppShadows {
  static List<BoxShadow> get sm => [
        BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark ? 0.28 : 0.04), blurRadius: 8, offset: const Offset(0, 2)),
      ];
  static List<BoxShadow> get md => [
        BoxShadow(color: Colors.black.withValues(alpha: AppColors.isDark ? 0.38 : 0.07), blurRadius: 18, offset: const Offset(0, 6)),
      ];
}

/// Convertit un hex `#RRGGBB` (tel que renvoyé par `calculations.dart`,
/// ex. `colorHex` de [ScoreResult]) en [Color] Flutter.
Color colorFromHex(String hex) {
  final clean = hex.replaceFirst('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

/// Échelle typographique — Fraunces (serif) pour les titres, Inter (sans)
/// pour le texte courant, Space Mono pour les chiffres. Les méthodes `h1`
/// à `label` donnent l'échelle standard (voir la charte : H1 30/700, H2
/// 24/700, H3 20/600, texte 16, texte secondaire 14, label 15/600) ; les
/// méthodes `serif`/`sans`/`mono` restent disponibles pour les cas où une
/// taille hors échelle est nécessaire.
class AppTextStyles {
  static TextStyle serif({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, TextDecoration? decoration}) =>
      GoogleFonts.fraunces(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing, decoration: decoration);
  static TextStyle sans({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, TextDecoration? decoration}) =>
      GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing, decoration: decoration);
  static TextStyle mono({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, TextDecoration? decoration}) =>
      GoogleFonts.spaceMono(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing, decoration: decoration);

  static TextStyle h1({Color? color}) => serif(fontSize: 30, fontWeight: FontWeight.w700, color: color ?? AppColors.ink);
  static TextStyle h2({Color? color}) => serif(fontSize: 24, fontWeight: FontWeight.w700, color: color ?? AppColors.ink);
  static TextStyle h3({Color? color}) => serif(fontSize: 20, fontWeight: FontWeight.w600, color: color ?? AppColors.ink);
  static TextStyle body({Color? color}) => sans(fontSize: 16, color: color ?? AppColors.ink);
  static TextStyle bodySecondary({Color? color}) => sans(fontSize: 14, color: color ?? AppColors.textMuted);
  static TextStyle label({Color? color}) => sans(fontSize: 15, fontWeight: FontWeight.w600, color: color ?? AppColors.ink);
}

/// [dark] doit refléter `RendementState.darkMode`, [novice]
/// `RendementState.niveau` — appelés à chaque changement (voir `main.dart`),
/// pour que le thème Material lui-même (fond de Scaffold, AppBar...) suive
/// le mode nuit et le niveau, pas seulement les widgets qui lisent
/// `AppColors.xxx` directement à chaque rebuild.
ThemeData buildAppTheme({required bool dark, required bool novice}) {
  AppColors.setDark(dark);
  AppColors.setNovice(novice);
  final base = ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: AppColors.paper,
  );
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.gold,
      error: AppColors.alert,
      surface: AppColors.paper,
      onSurface: AppColors.ink,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    dividerColor: AppColors.border,
  );
}
