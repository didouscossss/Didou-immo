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
  static bool get isNovice => _novice;

  /// Novice : texte quasi noir en jour, crème en nuit (inchangé). Avancé :
  /// aligné sur la charte fournie par l'utilisateur — foncé #1E1B4B en jour,
  /// texte #F8FAFC en nuit (au lieu du crème partagé avec le novice avant,
  /// qui ne collait plus à l'identité violette du mode avancé).
  static Color get ink {
    if (_novice) return _dark ? const Color(0xFFEDE6D2) : const Color(0xFF16211C);
    return _dark ? const Color(0xFFF8FAFC) : const Color(0xFF1E1B4B);
  }

  /// Couleur d'accent principale (boutons, montants positifs, graphiques) —
  /// vert forêt en mode novice, violet en mode avancé ; plus clair en mode
  /// nuit pour rester lisible sur un fond sombre. Charte fournie par
  /// l'utilisateur pour l'avancé : violet principal #7C3AED en jour, #A78BFA
  /// en nuit.
  static Color get accent {
    if (_novice) return _dark ? const Color(0xFF6FA97F) : const Color(0xFF1F6B4A);
    return _dark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
  }

  /// Couleur "attention" (accent secondaire/avertissement) — jaune ambre,
  /// désormais pilotée par le mode nuit comme le reste de la charte
  /// (auparavant fixe, elle ne s'éclaircissait pas sur fond sombre).
  static Color get gold => _dark ? const Color(0xFFFBBF24) : const Color(0xFFF59E0B);

  /// Couleur "erreur" — charte fournie par l'utilisateur (#EF4444 jour,
  /// #F87171 nuit), remplace les tons brique précédents.
  static Color get alert => _dark ? const Color(0xFFF87171) : const Color(0xFFEF4444);

  static Color get border {
    if (_novice) return _dark ? const Color(0xFF2C3830) : const Color(0xFFE6E0D0);
    // Avancé : bordures teintées lavande/violet plutôt que gris neutre, en
    // cohérence avec la charte (surfaces/fond de la palette avancée).
    return _dark ? const Color(0xFF3730A3) : const Color(0xFFDDD6FE);
  }

  static Color get paper {
    // Novice : crème doux plutôt que blanc verdâtre, plus proche du fond
    // neutre de la maquette de référence (le vert reste porté par l'accent
    // et les pastilles d'icône, pas par le fond).
    if (_novice) return _dark ? const Color(0xFF0F241A) : const Color(0xFFF3F0E6);
    // Avancé : lavande (#EDE9FE, charte utilisateur) en jour ; #0F172A déjà
    // conforme à la charte en nuit ("Fond").
    return _dark ? const Color(0xFF0F172A) : const Color(0xFFEDE9FE);
  }

  /// Fond des cartes/encadrés — légèrement plus clair que [paper] en
  /// sombre ; teintée en cohérence avec [paper] plutôt que de flotter en
  /// blanc/vert neutre dessus.
  static Color get surface {
    if (_novice) return _dark ? const Color(0xFF193A28) : const Color(0xFFFFFFFF);
    // Avancé : blanc (charte "Fond" jour) / #1E1B4B (charte "Surface" nuit).
    return _dark ? const Color(0xFF1E1B4B) : const Color(0xFFFFFFFF);
  }

  /// Vert "succès" — désormais un jeton à part entière (charte utilisateur
  /// #10B981 jour / #34D399 nuit), distinct de [accent] même en novice : la
  /// maquette de référence traite les accents sémantiques (succès,
  /// attention, erreur) comme une palette commune aux deux modes, séparée
  /// de la couleur de marque de chaque mode.
  static Color get good => _dark ? const Color(0xFF34D399) : const Color(0xFF10B981);

  /// Dégradé des cartes "chiffres clés" (patrimoine, cash-flow...) — vert
  /// doux en novice (identique jour/nuit), violet clair→principal en avancé
  /// de jour (mauve #A768FA → violet principal #7C3AED, charte
  /// utilisateur), violet profond→principal en avancé de nuit — remplace
  /// l'ardoise→cyan→émeraude précédent, qui ne collait plus à l'identité
  /// violette. Toujours volontairement resserré sur une seule famille de
  /// teinte (pas de rose/orange mêlés) pour que les courbes tracées
  /// par-dessus (ex. cash-flow du portefeuille) restent lisibles.
  static List<Color> get heroGradient {
    if (_novice) return const [Color(0xFF6FA97F), Color(0xFF3D6B4A)];
    return _dark
        ? const [Color(0xFF312E81), Color(0xFF7C3AED), Color(0xFFA78BFA)]
        : const [Color(0xFFA768FA), Color(0xFF7C3AED)];
  }

  /// Bande dégradée derrière le titre de chaque section (voir
  /// `SectionTitle`) — terre cuite en mode novice (inchangée), violet en
  /// mode avancé (mauve→lavande en jour, violet profond→principal en nuit,
  /// charte utilisateur) : le cyan/turquoise précédent jurait avec la
  /// nouvelle identité violette de l'avancé.
  static List<Color> get sectionBandGradient {
    if (_novice) {
      return _dark
          ? const [Color(0xFF8B4226), Color(0xFFC97B4E)]
          : const [Color(0xFFE8956B), Color(0xFFF6D9BE)];
    }
    return _dark
        ? const [Color(0xFF312E81), Color(0xFF7C3AED)]
        : const [Color(0xFFA768FA), Color(0xFFEDE9FE)];
  }

  /// Dégradé de fond de l'app (écran principal à onglets) — un voile doux,
  /// haut→bas, dans la même famille de teinte que [paper] plutôt qu'un
  /// simple aplat ; distinct par mode/nuit comme le reste de l'identité
  /// visuelle. Avancé recalé sur la lavande/le fond de la charte utilisateur.
  static List<Color> get backgroundGradient {
    if (_novice) {
      return _dark
          ? const [Color(0xFF123B27), Color(0xFF07160F)]
          : const [Color(0xFFF3F8ED), Color(0xFFE0EBD2)];
    }
    return _dark
        ? const [Color(0xFF0F172A), Color(0xFF1E1B4B)]
        : const [Color(0xFFF8F6FF), Color(0xFFEDE9FE)];
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
