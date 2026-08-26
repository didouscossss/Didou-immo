import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Jetons de design — portés depuis le prototype React (rendement-app.jsx).
/// bg #F4F0E6 · ink #16211C · accent #2F5D50 · gold #B8935A · alert #B3452C
/// Display: Fraunces · Body: Inter · Chiffres: Space Mono
class AppColors {
  static const ink = Color(0xFF16211C);
  static const accent = Color(0xFF2F5D50);
  static const gold = Color(0xFFB8935A);
  static const alert = Color(0xFFB3452C);
  static const border = Color(0xFFE4DDC9);
  static const paper = Color(0xFFF4F0E6);
  static const good = Color(0xFF4A7C59);
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

ThemeData buildAppTheme() {
  final base = ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.paper);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: AppColors.accent,
      secondary: AppColors.gold,
      error: AppColors.alert,
      surface: AppColors.paper,
    ),
    textTheme: GoogleFonts.interTextTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.ink,
      elevation: 0,
      titleTextStyle: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
    ),
    dividerColor: AppColors.border,
  );
}
