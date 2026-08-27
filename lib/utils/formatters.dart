import 'package:intl/intl.dart';

/// Formatage de nombres/euros — portés depuis `fmt`/`eur` du prototype React.
String fmt(num? value, [int decimals = 0]) {
  final v = (value == null || value.isNaN || value.isInfinite) ? 0 : value;
  final formatter = NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}', 'fr_FR');
  return formatter.format(v);
}

String eur(num? value) => '${fmt(value)} €';

/// Date au format français JJ/MM/AAAA — évite de dépendre des données de
/// locale d'`intl` (non initialisées dans l'app) pour un format aussi simple.
String dateFr(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
