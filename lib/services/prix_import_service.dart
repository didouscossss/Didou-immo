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
  final int anneeMax;
  const PrixImportResult({required this.nbCommunes, required this.anneeMax});
}

/// Traitement du CSV "Statistiques DVF" (data.gouv.fr — prix médian au m²
/// par commune, calculé par la DGFiP à partir des ventes réellement
/// constatées) et republication sur Firebase Storage, sur le même principe
/// que [LoyerImportService] pour les loyers : un admin réimporte ce fichier
/// à chaque nouvelle édition (deux fois par an, avril/octobre), sans passer
/// par une nouvelle version d'app.
///
/// ⚠️ Contrairement au fichier des loyers (dont les 3 colonnes exactes
/// avaient été vérifiées sur le fichier réel), la structure précise de ce
/// fichier n'a pas pu être inspectée directement (accès à data.gouv.fr
/// bloqué depuis l'environnement où ce code a été écrit) : les noms de
/// colonnes ci-dessous sont une reconstitution la plus fidèle possible
/// d'après la documentation publique du jeu de données. [parseCsv] essaie
/// donc plusieurs variantes plausibles pour chaque colonne, et échoue avec
/// un message listant les en-têtes réellement trouvées si aucune ne
/// correspond — pour corriger le mapping en une fois si le premier import
/// réel échoue, plutôt que de publier une donnée mal interprétée.
class PrixImportService {
  /// Nombre minimal de communes reconnues pour accepter le fichier — sous
  /// ce seuil, il ne ressemble probablement pas au bon fichier (même logique
  /// que pour les loyers).
  static const _minCommunes = 1000;

  static const _codeInseeCandidates = [
    'code_geo', 'codegeo', 'code_commune', 'codecommune', 'insee_com', 'code_insee', 'codeinsee', 'insee',
  ];
  static const _echelleCandidates = ['echelle_geo', 'echellegeo', 'echelle', 'niveau_geo', 'niveaugeo'];
  static const _anneeCandidates = ['annee', 'année'];
  static const _nbVentesCandidates = [
    'nb_ventes', 'nombre_ventes', 'nbventes', 'nombre_mutations', 'nb_mutations', 'nombre_de_ventes',
  ];
  static const _prixMedianCandidates = [
    'prix_m2_median', 'prix_median_m2', 'prixm2median', 'prix_metre_carre_median', 'prix_m2_median_vente',
  ];
  static const _prixMoyenCandidates = ['prix_m2_moyen', 'prix_moyen_m2', 'prixm2moyen'];

  /// Parse le CSV brut. Détecte automatiquement le séparateur (`;` ou `,`)
  /// et l'encodage (UTF-8, repli Latin-1). Renvoie le JSON compact
  /// `{codeInsee: {"p": prixMedian, "n": nbVentes, "a": annee, "e": evolution?}}`,
  /// identique au format lu par [PrixReferenceService].
  ///
  /// Une commune peut apparaître sur plusieurs lignes (plusieurs années,
  /// plusieurs types de bien, parfois plusieurs échelles géographiques dans
  /// le même fichier) : on ne garde que les lignes "commune" (si une colonne
  /// d'échelle géographique existe), on choisit l'année la plus récente
  /// disponible pour chaque commune, et s'il reste plusieurs lignes pour
  /// cette année (types de bien non fusionnés dans le fichier), on moyenne
  /// leurs prix médians en les pondérant par le nombre de ventes — une
  /// approximation raisonnable d'un prix "tous types" en l'absence de ligne
  /// déjà agrégée. L'évolution sur 1 an n'est calculée que si l'année
  /// précédente est aussi présente pour la même commune ; sinon elle reste
  /// simplement absente (dégradation déjà gérée partout où elle est lue).
  static Map<String, dynamic> parseCsv(List<int> bytes) {
    final text = _decode(bytes);
    final lines = text.split(RegExp(r'\r\n|\r|\n')).where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) throw const PrixImportException('Fichier vide.');

    final delimiter = lines.first.split(';').length >= lines.first.split(',').length ? ';' : ',';
    final rawHeader = _splitRow(lines.first, delimiter);
    final header = rawHeader.map(_normalize).toList();

    int idxOf(List<String> candidates) => header.indexWhere((h) => candidates.contains(h));

    final idxInsee = idxOf(_codeInseeCandidates);
    final idxAnnee = idxOf(_anneeCandidates);
    final idxNbVentes = idxOf(_nbVentesCandidates);
    var idxPrix = idxOf(_prixMedianCandidates);
    if (idxPrix == -1) idxPrix = idxOf(_prixMoyenCandidates);
    final idxEchelle = idxOf(_echelleCandidates);

    if (idxInsee == -1 || idxAnnee == -1 || idxNbVentes == -1 || idxPrix == -1) {
      throw PrixImportException(
          "Colonnes attendues introuvables — ce n'est probablement pas le bon fichier, ou sa "
          "structure a changé. En-têtes trouvées dans ce fichier : ${rawHeader.join(', ')}");
    }

    // {codeInsee: {annee: [(prix, nbVentes)]}}
    final parByCommune = <String, Map<int, List<(double, int)>>>{};

    for (final line in lines.skip(1)) {
      final fields = _splitRow(line, delimiter);
      final maxIdx = [idxInsee, idxAnnee, idxNbVentes, idxPrix].reduce((a, b) => a > b ? a : b);
      if (fields.length <= maxIdx) continue;
      if (idxEchelle != -1 && idxEchelle < fields.length && !_normalize(fields[idxEchelle]).contains('commune')) {
        continue;
      }
      final insee = fields[idxInsee].trim();
      if (insee.isEmpty) continue;
      final annee = _parseAnnee(fields[idxAnnee]);
      if (annee == null) continue;
      final nbVentes = int.tryParse(fields[idxNbVentes].trim());
      final prix = double.tryParse(fields[idxPrix].trim().replaceAll(',', '.'));
      if (nbVentes == null || nbVentes <= 0 || prix == null || prix <= 0) continue;
      parByCommune.putIfAbsent(insee, () => {}).putIfAbsent(annee, () => []).add((prix, nbVentes));
    }

    if (parByCommune.length < _minCommunes) {
      throw PrixImportException(
          'Seulement ${parByCommune.length} commune(s) reconnue(s) dans ce fichier — il semble '
          'incomplet ou mal formé, rien n\'a été publié.');
    }

    final result = <String, dynamic>{};
    for (final entry in parByCommune.entries) {
      final annees = entry.value.keys.toList()..sort();
      final derniere = annees.last;
      final prixDerniere = _prixPondere(entry.value[derniere]!);
      double? evolution;
      if (annees.length > 1 && annees[annees.length - 2] == derniere - 1) {
        final prixPrecedente = _prixPondere(entry.value[derniere - 1]!);
        if (prixPrecedente > 0) evolution = ((prixDerniere - prixPrecedente) / prixPrecedente) * 100;
      }
      final nbVentesDerniere = entry.value[derniere]!.fold<int>(0, (s, v) => s + v.$2);
      result[entry.key] = {
        'p': double.parse(prixDerniere.toStringAsFixed(0)),
        'n': nbVentesDerniere,
        'a': derniere,
        if (evolution != null) 'e': double.parse(evolution.toStringAsFixed(1)),
      };
    }

    return result;
  }

  static double _prixPondere(List<(double, int)> valeurs) {
    final totalVentes = valeurs.fold<int>(0, (s, v) => s + v.$2);
    if (totalVentes == 0) return 0;
    final somme = valeurs.fold<double>(0, (s, v) => s + v.$1 * v.$2);
    return somme / totalVentes;
  }

  static int? _parseAnnee(String raw) {
    final direct = int.tryParse(raw.trim());
    if (direct != null && direct > 2000 && direct < 2100) return direct;
    final match = RegExp(r'(20\d{2})').firstMatch(raw);
    if (match == null) return null;
    return int.parse(match.group(1)!);
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
  /// caractères non alphanumériques retirés (`Code Commune` /
  /// `code_commune` / `CODE-COMMUNE` matchent tous `codecommune`).
  static String _normalize(String s) {
    const accents = 'àâäéèêëïîôöùûüÿçñ';
    const sansAccents = 'aaaeeeeiioouuuycn';
    var out = s.trim().toLowerCase();
    for (var i = 0; i < accents.length; i++) {
      out = out.replaceAll(accents[i], sansAccents[i]);
    }
    return out.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static PrixImportResult summarize(Map<String, dynamic> data) {
    var anneeMax = 0;
    for (final v in data.values) {
      final a = (v as Map)['a'] as int;
      if (a > anneeMax) anneeMax = a;
    }
    return PrixImportResult(nbCommunes: data.length, anneeMax: anneeMax);
  }

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
