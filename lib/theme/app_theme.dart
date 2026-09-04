import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jetons de design — portés depuis le prototype React (rendement-app.jsx).
/// bg #F4F0E6 · ink #16211C · accent #2F5D50 · gold #B8935A · alert #B3452C
/// Display: Fraunces · Body: Inter · Chiffres: Space Mono
///
/// Champs calculés (pas `const`) plutôt que fixes, pour pouvoir s'adapter au
/// mode nuit (voir [setDark], piloté par `RendementState.darkMode`) sans
/// avoir à passer le thème explicitement à chaque écran — tout le reste de
/// l'app lit ces couleurs directement (`AppColors.ink`, etc.).
class AppColors {
  static bool _dark = false;
  static void setDark(bool value) => _dark = value;
  static bool get isDark => _dark;

  /// Mode novice : identité nettement différente du mode avancé — vert
  /// sauge doux et lumineux (fond ET accent), contre un bleu-nuit/violet
  /// plus analytique et froid en avancé, y compris en mode nuit. Piloté par
  /// [setNovice], reflète `RendementState.niveau`. Étendu à [surface]
  /// (cartes) et [accent] pour que le contraste entre les deux modes se
  /// voie partout, pas seulement en arrière-plan.
  static bool _novice = false;
  static void setNovice(bool value) => _novice = value;

  static Color get ink => _dark ? const Color(0xFFEDE6D2) : const Color(0xFF16211C);

  /// Couleur d'accent principale (boutons, montants positifs, graphiques) —
  /// vert doux (le même que [good], pas un vert flashy) en mode novice,
  /// violet profond mais pas trop sombre en mode avancé ; plus clair en
  /// mode nuit pour rester lisible sur un fond sombre.
  static Color get accent {
    if (_novice) return _dark ? const Color(0xFF6FA97F) : const Color(0xFF4A7C59);
    return _dark ? const Color(0xFF8B5CF6) : const Color(0xFF6D28D9);
  }

  static Color get gold => const Color(0xFFB8935A);
  static Color get alert => _dark ? const Color(0xFFE29385) : const Color(0xFFB3452C);
  static Color get border => _dark ? const Color(0xFF2C3830) : const Color(0xFFE4DDC9);
  static Color get paper {
    // Novice sombre : vert forêt/émeraude profond (plus de bleu que de
    // jaune dans la teinte) — un premier réglage (0xFF1C2617) virait trop
    // vers le kaki/olive terne au goût de l'utilisateur, corrigé ici vers
    // une teinte plus franche et moins brune.
    if (_novice) return _dark ? const Color(0xFF0F241A) : const Color(0xFFE6EFDA);
    // Avancé : bleu-nuit/ardoise (plutôt que le vert neutre précédent) pour
    // appuyer l'identité "analytique" du mode, y compris de jour (nuance
    // froide très légère plutôt que le beige chaud du novice).
    return _dark ? const Color(0xFF0F172A) : const Color(0xFFF3F2F9);
  }

  /// Fond des cartes/encadrés — légèrement plus clair que [paper] en
  /// sombre ; teintée en cohérence avec [paper] plutôt que de flotter en
  /// blanc/vert neutre dessus.
  static Color get surface {
    if (_novice) return _dark ? const Color(0xFF193A28) : const Color(0xFFF6FAF0);
    return _dark ? const Color(0xFF1E293B) : const Color(0xFFFFFFFF);
  }

  static Color get good => _dark ? const Color(0xFF6FA97F) : const Color(0xFF4A7C59);

  /// Dégradé des cartes "chiffres clés" (patrimoine, cash-flow...) — vert
  /// doux en novice (identique jour/nuit), violet (un seul ton, dégradé
  /// clair→foncé) en avancé de jour, ardoise→cyan→émeraude en avancé de
  /// nuit. Volontairement monochrome en avancé de jour (pas de rose/orange
  /// mêlés) : un dégradé multi-teintes devenait criard et rendait les
  /// courbes tracées par-dessus (ex. cash-flow du portefeuille) difficiles
  /// à lire.
  static List<Color> get heroGradient {
    if (_novice) return const [Color(0xFF6FA97F), Color(0xFF3D6B4A)];
    return _dark
        ? const [Color(0xFF1E293B), Color(0xFF06B6D4), Color(0xFF10B981)]
        : const [Color(0xFF8B5CF6), Color(0xFF6D28D9)];
  }

  /// Dégradé de fond de l'app (écran principal à onglets) — un voile doux,
  /// haut→bas, dans la même famille de teinte que [paper] plutôt qu'un
  /// simple aplat ; distinct par mode/nuit comme le reste de l'identité
  /// visuelle.
  static List<Color> get backgroundGradient {
    if (_novice) {
      return _dark
          ? const [Color(0xFF123B27), Color(0xFF07160F)]
          : const [Color(0xFFF3F8ED), Color(0xFFE0EBD2)];
    }
    return _dark
        ? const [Color(0xFF0F172A), Color(0xFF1A1233)]
        : const [Color(0xFFF6F4FB), Color(0xFFE8E3F3)];
  }
}

/// Convertit un hex `#RRGGBB` (tel que renvoyé par `calculations.dart`,
/// ex. `colorHex` de [ScoreResult]) en [Color] Flutter.
Color colorFromHex(String hex) {
  final clean = hex.replaceFirst('#', '');
  return Color(int.parse('FF$clean', radix: 16));
}

class AppTextStyles {
  static TextStyle serif({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, TextDecoration? decoration}) =>
      GoogleFonts.fraunces(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing, decoration: decoration);
  static TextStyle sans({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, TextDecoration? decoration}) =>
      GoogleFonts.inter(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing, decoration: decoration);
  static TextStyle mono({double? fontSize, FontWeight? fontWeight, Color? color, double? letterSpacing, TextDecoration? decoration}) =>
      GoogleFonts.spaceMono(fontSize: fontSize, fontWeight: fontWeight, color: color, letterSpacing: letterSpacing, decoration: decoration);
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
