import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';

import 'loyer_reference_service.dart';

class LoyerImportException implements Exception {
  final String message;
  const LoyerImportException(this.message);
  @override
  String toString() => message;
}

class LoyerImportResult {
  final int nbCommunes;
  final int nbEstimationZone;
  const LoyerImportResult({required this.nbCommunes, required this.nbEstimationZone});
}

/// Traitement du CSV "Carte des loyers" (fichier "Appartements" — celui dont
/// le nom se termine par `appmefdhup.csv` sur data.gouv.fr, voir
/// `LoyerReferenceService`) et republication sur Firebase Storage — pour
/// qu'un compte admin puisse mettre à jour cette donnée depuis l'app à
/// chaque nouvelle édition annuelle, sans passer par une nouvelle version
/// d'app ni redemander à Claude de retraiter le fichier à la main.
///
/// Reproduit exactement le traitement fait manuellement lors de
/// l'intégration initiale (voir l'historique de la PR qui l'a ajoutée) :
/// mêmes colonnes lues (`INSEE_C`, `loypredm2`, `TYPPRED`), même format de
/// sortie compact.
class LoyerImportService {
  /// Parse le CSV brut (tel que renvoyé par le sélecteur de fichier — le
  /// fichier officiel est encodé en Windows-1252/Latin-1, jamais en UTF-8)
  /// et renvoie le JSON compact `{codeInsee: {"m": loyer, "z": 1?}}`,
  /// identique au format de `assets/data/loyers_communes.json`.
  ///
  /// Lève [LoyerImportException] (message adapté à l'affichage direct dans
  /// l'UI) si le fichier ne ressemble pas au bon CSV — colonnes attendues
  /// absentes, ou trop peu de communes reconnues.
  static Map<String, dynamic> parseCsv(List<int> bytes) {
    final text = latin1.decode(bytes, allowInvalid: true);
    final lines = text.split(RegExp(r'\r\n|\r|\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) throw const LoyerImportException('Fichier vide.');

    final header = _splitRow(lines.first);
    final idxInsee = header.indexOf('INSEE_C');
    final idxLoyer = header.indexOf('loypredm2');
    final idxType = header.indexOf('TYPPRED');
    if (idxInsee == -1 || idxLoyer == -1 || idxType == -1) {
      throw const LoyerImportException(
          "Colonnes attendues introuvables (INSEE_C, loypredm2, TYPPRED) — ce n'est "
          'probablement pas le bon fichier. Il faut le fichier "Appartements" du jeu '
          '"Carte des loyers" (nom se terminant par "appmefdhup.csv" sur data.gouv.fr).');
    }
    final maxIdx = [idxInsee, idxLoyer, idxType].reduce((a, b) => a > b ? a : b);

    final result = <String, dynamic>{};
    for (final line in lines.skip(1)) {
      final fields = _splitRow(line);
      if (fields.length <= maxIdx) continue;
      final insee = fields[idxInsee];
      if (insee.isEmpty) continue;
      final loyer = double.tryParse(fields[idxLoyer].replaceAll(',', '.'));
      if (loyer == null) continue;
      final entry = <String, dynamic>{'m': double.parse(loyer.toStringAsFixed(1))};
      if (fields[idxType] == 'maille') entry['z'] = 1;
      result[insee] = entry;
    }

    if (result.length < 1000) {
      throw LoyerImportException(
          'Seulement ${result.length} commune(s) reconnue(s) dans ce fichier — il semble '
          'incomplet ou mal formé, rien n\'a été publié.');
    }
    return result;
  }

  static List<String> _splitRow(String line) =>
      line.split(';').map((f) => f.trim().replaceAll('"', '')).toList();

  static LoyerImportResult summarize(Map<String, dynamic> data) {
    final zone = data.values.where((v) => (v as Map)['z'] == 1).length;
    return LoyerImportResult(nbCommunes: data.length, nbEstimationZone: zone);
  }

  /// Publie le nouveau fichier sur Firebase Storage, en écrasant l'ancien —
  /// réservé aux comptes admin (voir `storage.rules`, qui refuse l'écriture
  /// à quiconque d'autre). Invalide aussi le cache local de
  /// [LoyerReferenceService] pour que la session en cours voie tout de
  /// suite la mise à jour.
  static Future<void> publish(Map<String, dynamic> data) async {
    final bytes = utf8.encode(jsonEncode(data));
    final ref = FirebaseStorage.instance.ref(loyerCommunesStoragePath);
    await ref.putData(bytes, SettableMetadata(contentType: 'application/json'));
    LoyerReferenceService.invalidateCache();
  }
}
