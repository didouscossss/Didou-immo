import 'dart:convert';
import 'dart:typed_data';

import '../utils/calculations.dart';
import 'file_saver/save_bytes.dart';

/// Export des échéances fiscales récurrentes (voir `Deadline`,
/// `calculations.dart`) au format iCalendar (.ics) — pour que l'utilisateur
/// les ajoute une fois pour toutes à son agenda personnel (Google Calendar,
/// Apple Calendar...), plutôt que de devoir y penser lui-même chaque année.
///
/// Seules les échéances dont le champ `periode` contient un nom de mois
/// reconnaissable (ex. "Mai", "Avril – juin") sont exportées — celles sans
/// date calendaire fixe ("Date anniversaire du bail", "Chaque année",
/// "Trimestriel / selon commune"...) n'ont pas de jour sensé à leur donner
/// et sont silencieusement ignorées plutôt que de leur inventer une date.
/// Pour une plage ("Avril – juin"), le 1er jour du PREMIER mois cité est
/// utilisé comme rappel — ça laisse toute la fenêtre pour agir ensuite.
///
/// Chaque événement est marqué `RRULE:FREQ=YEARLY` (se répète tout seul
/// dans l'agenda, pas besoin de réexporter chaque année) et sa description
/// précise explicitement qu'il s'agit d'une date INDICATIVE à vérifier —
/// on ne connaît pas la date exacte propre à chaque situation/commune.
class CalendarExportService {
  static const _mois = {
    'janvier': 1,
    'fevrier': 2,
    'mars': 3,
    'avril': 4,
    'mai': 5,
    'juin': 6,
    'juillet': 7,
    'aout': 8,
    'septembre': 9,
    'octobre': 10,
    'novembre': 11,
    'decembre': 12,
  };

  static Future<bool> exportEcheances(List<Deadline> deadlines) async {
    final now = DateTime.now().toUtc();
    final dtstamp = _formatDateTimeUtc(now);
    final buffer = StringBuffer();
    void line(String s) => buffer.write('$s\r\n');

    line('BEGIN:VCALENDAR');
    line('VERSION:2.0');
    line('PRODID:-//Didou Immo//Echeances fiscales//FR');
    line('CALSCALE:GREGORIAN');

    var nbExportees = 0;
    for (final d in deadlines) {
      final mois = _moisDepuisPeriode(d.periode);
      if (mois == null) continue; // pas de date calendaire fixe, voir doc de la classe
      nbExportees++;
      final date = _prochaineDate(mois);
      line('BEGIN:VEVENT');
      line('UID:${_uidFor(d.label)}');
      line('DTSTAMP:$dtstamp');
      line('DTSTART;VALUE=DATE:${_formatDate(date)}');
      line('RRULE:FREQ=YEARLY');
      line('SUMMARY:${_escape(d.label)}');
      line('DESCRIPTION:${_escape("Échéance indicative (Didou Immo) — vérifie la date exacte applicable à ta situation, ta commune ou ton régime fiscal avant l'échéance réelle.")}');
      line('END:VEVENT');
    }
    line('END:VCALENDAR');

    if (nbExportees == 0) return false;

    final bytes = Uint8List.fromList(utf8.encode(buffer.toString()));
    return saveBytes(bytes: bytes, filename: 'didou-immo-echeances-fiscales.ics', mimeType: 'text/calendar;charset=utf-8');
  }

  /// Cherche un nom de mois reconnaissable n'importe où dans la chaîne (ex.
  /// "Avril – juin" -> avril, premier mois trouvé dans le texte, pas dans
  /// une liste arbitraire) — insensible à la casse et aux accents.
  static int? _moisDepuisPeriode(String periode) {
    final normalise = _sansAccents(periode.toLowerCase());
    for (final mot in normalise.split(RegExp(r'[^a-z]+'))) {
      final mois = _mois[mot];
      if (mois != null) return mois;
    }
    return null;
  }

  static String _sansAccents(String s) {
    const accents = 'àâäéèêëïîôöùûüÿçñ';
    const sansAccents = 'aaaeeeeiioouuuycn';
    var out = s;
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], sansAccents[i]);
    }
    return out;
  }

  /// Le 1er jour du [mois] donné, dans le futur (cette année si le mois
  /// n'est pas encore passé, sinon l'année prochaine) — `RRULE:FREQ=YEARLY`
  /// prend ensuite le relais pour les occurrences suivantes.
  static DateTime _prochaineDate(int mois) {
    final now = DateTime.now();
    var date = DateTime(now.year, mois, 1);
    if (!date.isAfter(now)) date = DateTime(now.year + 1, mois, 1);
    return date;
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

  static String _formatDateTimeUtc(DateTime d) =>
      '${_formatDate(d)}T${d.hour.toString().padLeft(2, '0')}${d.minute.toString().padLeft(2, '0')}${d.second.toString().padLeft(2, '0')}Z';

  /// UID stable (basé sur le libellé, pas une valeur aléatoire) : réexporter
  /// remplace le même événement dans l'agenda au lieu d'en créer un doublon
  /// à chaque fois.
  static String _uidFor(String label) {
    final slug = _sansAccents(label.toLowerCase()).replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return '$slug@didou-immo.app';
  }

  /// Échappement minimal requis par la RFC 5545 pour les valeurs texte.
  static String _escape(String s) =>
      s.replaceAll('\\', '\\\\').replaceAll(',', '\\,').replaceAll(';', '\\;').replaceAll('\n', '\\n');
}
