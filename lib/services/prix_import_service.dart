import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';

import 'prix_reference_service.dart';

class PrixImportException implements Exception {
  final String message;
  const PrixImportException(this.message);
  @override
  String toString() => message;
}

class PrixImportResult {
  final int nbCommunes;
  const PrixImportResult({required this.nbCommunes});
}

/// [data] : voir [PrixImportService.parseCsv]. [sample] : quelques lignes
/// lisibles (commune → code retenu, prix, ventes) tirées du fichier, pour
/// vérifier à l'œil dans l'admin que les codes ressemblent bien à des codes
/// INSEE — utile pour diagnostiquer un souci de correspondance (le fichier
/// "Statistiques totales DVF" peut utiliser une colonne "code_geo" qui n'est
/// pas forcément un code INSEE brut selon l'échelle) sans avoir à inspecter
/// le fichier de 30 Mo à la main.
class PrixParseResult {
  final Map<String, dynamic> data;
  final List<String> sample;
  const PrixParseResult({required this.data, required this.sample});
}

/// Traitement du CSV "Statistiques totales DVF" (data.gouv.fr — prix médian
/// au m² par commune, calculé par la DGFiP à partir des ventes réellement
/// constatées) et republication sur Firebase Storage, sur le même principe
/// que [LoyerImportService] pour les loyers : un admin réimporte ce fichier
/// à chaque nouvelle édition (deux fois par an, avril/octobre), sans passer
/// par une nouvelle version d'app.
///
/// Format réel du fichier (une seule ligne par entité géographique, colonnes
/// confirmées sur un fichier téléchargé — pas une supposition) :
/// `code_geo;libelle_geo;code_parent;echelle_geo;nb_ventes_whole_appartement;
/// moy_prix_m2_whole_appartement;med_prix_m2_whole_appartement;
/// nb_ventes_whole_maison;...;nb_ventes_whole_apt_maison;
/// moy_prix_m2_whole_apt_maison;med_prix_m2_whole_apt_maison;
/// nb_ventes_whole_local;...`. Pas de colonne année : chaque ligne agrège
/// déjà les 5 dernières années en un seul chiffre — donc pas d'évolution
/// sur 1 an calculable à partir de ce fichier (voir `PrixCommuneRef`).
/// On retient la colonne "apt_maison" (appartements + maisons confondus,
/// déjà fusionnée dans le fichier) plutôt que de recombiner nous-mêmes
/// "appartement" et "maison" séparément : c'est l'équivalent direct du
/// repère de prix générique (non typé) utilisé partout ailleurs dans l'app.
class PrixImportService {
  /// Nombre minimal de communes reconnues pour accepter le fichier — sous
  /// ce seuil, il ne ressemble probablement pas au bon fichier (même logique
  /// que pour les loyers).
  static const _minCommunes = 1000;

  static const _codeInseeCandidates = ['codegeo', 'codecommune', 'inseecom', 'codeinsee', 'insee'];
  static const _libelleCandidates = ['libellegeo', 'nomcommune', 'libellecommune', 'nom'];
  static const _echelleCandidates = ['echellegeo', 'echelle', 'niveaugeo'];
  static const _nbVentesCandidates = ['nbventeswholeaptmaison', 'nbventes', 'nombreventes'];
  static const _prixMedianCandidates = ['medprixm2wholeaptmaison', 'prixm2median', 'prixmedianm2'];
  static const _prixMoyenCandidates = ['moyprixm2wholeaptmaison', 'prixm2moyen', 'prixmoyenm2'];

  /// Parse le CSV brut. Détecte automatiquement le séparateur (`;` ou `,`)
  /// et l'encodage (UTF-8, repli Latin-1). [PrixParseResult.data] est le
  /// JSON compact `{codeInsee: {"p": prixMedian, "n": nbVentes}}`, identique
  /// au format lu par [PrixReferenceService].
  static PrixParseResult parseCsv(List<int> bytes) {
    // `LineSplitter.split(...)` (contrairement à `.convert(...)` ou à un
    // `text.split(RegExp(...)).toList()`) parcourt le texte ligne par ligne
    // à la demande, sans jamais matérialiser la liste complète des ~35 000
    // lignes du fichier en mémoire d'un coup. Appelé via `compute()` (voir
    // `AdminScreen`) pour ne pas geler l'interface pendant le traitement.
    final lines = LineSplitter.split(_decode(bytes)).where((l) => l.trim().isNotEmpty);
    if (lines.isEmpty) throw const PrixImportException('Fichier vide.');

    final delimiter = lines.first.split(';').length >= lines.first.split(',').length ? ';' : ',';
    final rawHeader = _splitRow(lines.first, delimiter);
    final header = rawHeader.map(_normalize).toList();

    int idxOf(List<String> candidates) => header.indexWhere((h) => candidates.contains(h));

    final idxInsee = idxOf(_codeInseeCandidates);
    final idxLibelle = idxOf(_libelleCandidates);
    final idxNbVentes = idxOf(_nbVentesCandidates);
    var idxPrix = idxOf(_prixMedianCandidates);
    if (idxPrix == -1) idxPrix = idxOf(_prixMoyenCandidates);
    final idxEchelle = idxOf(_echelleCandidates);

    if (idxInsee == -1 || idxNbVentes == -1 || idxPrix == -1) {
      throw PrixImportException(
          "Colonnes attendues introuvables — ce n'est probablement pas le bon fichier, ou sa "
          "structure a changé. En-têtes trouvées dans ce fichier : ${rawHeader.join(', ')}");
    }

    final result = <String, dynamic>{};
    final sample = <String>[];
    for (final line in lines.skip(1)) {
      final fields = _splitRow(line, delimiter);
      final maxIdx = [idxInsee, idxNbVentes, idxPrix].reduce((a, b) => a > b ? a : b);
      if (fields.length <= maxIdx) continue;
      if (idxEchelle != -1 && idxEchelle < fields.length && !_normalize(fields[idxEchelle]).contains('commune')) {
        continue;
      }
      final insee = fields[idxInsee].trim();
      if (insee.isEmpty) continue;
      final nbVentes = int.tryParse(fields[idxNbVentes].trim());
      final prix = double.tryParse(fields[idxPrix].trim().replaceAll(',', '.'));
      if (nbVentes == null || nbVentes <= 0 || prix == null || prix <= 0) continue;
      result[insee] = {'p': double.parse(prix.toStringAsFixed(0)), 'n': nbVentes};
      if (sample.length < 8) {
        final nom = idxLibelle != -1 && idxLibelle < fields.length ? fields[idxLibelle].trim() : null;
        sample.add('${nom != null && nom.isNotEmpty ? '$nom : ' : ''}code "$insee" — ${prix.toStringAsFixed(0)} €/m², $nbVentes ventes');
      }
    }

    if (result.length < _minCommunes) {
      throw PrixImportException(
          'Seulement ${result.length} commune(s) reconnue(s) dans ce fichier — il semble '
          'incomplet ou mal formé, rien n\'a été publié.');
    }

    return PrixParseResult(data: result, sample: sample);
  }

  static String _decode(List<int> bytes) {
    try {
      return const Utf8Decoder(allowMalformed: false).convert(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  static List<String> _splitRow(String line, String delimiter) =>
      line.split(delimiter).map((f) => f.trim().replaceAll('"', '')).toList();

  /// Normalise un en-tête pour la comparaison : minuscules, accents et
  /// caractères non alphanumériques retirés (`Code Geo` / `code_geo` /
  /// `CODE-GEO` matchent tous `codegeo`).
  static String _normalize(String s) {
    const accents = 'àâäéèêëïîôöùûüÿçñ';
    const sansAccents = 'aaaeeeeiioouuuycn';
    var out = s.trim().toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], sansAccents[i]);
    }
    return out.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static PrixImportResult summarize(Map<String, dynamic> data) => PrixImportResult(nbCommunes: data.length);

  /// Publie le nouveau fichier sur Firebase Storage, en écrasant l'ancien —
  /// réservé aux comptes admin (voir `storage.rules`). Invalide aussi le
  /// cache local de [PrixReferenceService].
  static Future<void> publish(Map<String, dynamic> data) async {
    final bytes = utf8.encode(jsonEncode(data));
    final ref = FirebaseStorage.instance.ref(prixCommunesStoragePath);
    await ref.putData(bytes, SettableMetadata(contentType: 'application/json'));
    PrixReferenceService.invalidateCache();
  }
}
