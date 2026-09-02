import 'package:cloud_functions/cloud_functions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/loyer_import_service.dart';
import '../../services/prix_import_service.dart';
import '../../services/prix_reference_service.dart';
import '../../state/user_account_state.dart';
import 'admin_suggestions_screen.dart';

/// Génération de codes cadeaux (accès gratuit) — réservé aux comptes dont
/// le document Firestore `users/{uid}` porte `isAdmin: true`. Ce flag doit
/// être activé manuellement depuis la console Firebase : il n'existe pas
/// de compte admin par défaut.
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _codeController = TextEditingController();
  final _usesController = TextEditingController(text: '1');
  bool _loading = false;
  String? _message;

  static const _dataGouvUrl =
      'https://www.data.gouv.fr/datasets/carte-des-loyers-indicateurs-de-loyers-dannonce-par-commune-en-2025';
  static const _dataGouvPrixUrl = 'https://www.data.gouv.fr/datasets/statistiques-dvf';

  Map<String, dynamic>? _loyerPending;
  LoyerImportResult? _loyerPreview;
  String? _loyerFileName;
  String? _loyerError;
  bool _loyerParsing = false;
  bool _loyerPublishing = false;
  String? _loyerPublished;

  Map<String, dynamic>? _prixPending;
  PrixImportResult? _prixPreview;
  List<String> _prixSample = [];
  String? _prixFileName;
  String? _prixError;
  bool _prixParsing = false;
  bool _prixPublishing = false;
  String? _prixPublished;
  String? _prixLookupTest;
  String? _prixRawDiag;
  bool _prixRecentRunning = false;
  String? _prixRecentResult;

  @override
  void dispose() {
    _codeController.dispose();
    _usesController.dispose();
    super.dispose();
  }

  Future<void> _pickLoyerCsv() async {
    setState(() {
      _loyerError = null;
      _loyerPublished = null;
      _loyerPending = null;
      _loyerPreview = null;
    });
    FilePickerResult? result;
    try {
      // `FileType.any` plutôt que `FileType.custom` + `allowedExtensions` :
      // sur certains navigateurs/téléphones, le filtre par extension côté
      // sélecteur de fichiers empêche le CSV téléchargé d'apparaître comme
      // sélectionnable (mauvais type MIME détecté...) — sans qu'aucune
      // erreur ne remonte, ça se voit juste comme "rien ne se passe" au tap.
      // On valide plutôt le contenu réel du fichier une fois lu (voir plus
      // bas), pas son extension.
      result = await FilePicker.pickFiles(type: FileType.any, withData: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loyerError =
          "Impossible d'ouvrir le sélecteur de fichiers sur cet appareil/navigateur — réessaie, ou essaie avec un autre navigateur.");
      return;
    }
    final file = (result == null || result.files.isEmpty) ? null : result.files.first;
    if (file?.bytes == null) return; // annulé
    setState(() {
      _loyerFileName = file!.name;
      _loyerParsing = true;
    });
    try {
      // `compute()` : lit et parse le fichier dans un isolate séparé plutôt
      // que sur le thread principal — sans ça, un gros fichier (le fichier
      // des prix DVF peut peser plusieurs dizaines de Mo) gèle l'interface
      // le temps du traitement, au point de sembler planté sur un mobile.
      final data = await compute(LoyerImportService.parseCsv, file!.bytes!);
      final summary = LoyerImportService.summarize(data);
      setState(() {
        _loyerPending = data;
        _loyerPreview = summary;
        _loyerParsing = false;
      });
    } on LoyerImportException catch (e) {
      setState(() {
        _loyerError = e.message;
        _loyerParsing = false;
      });
    } catch (_) {
      setState(() {
        _loyerError = 'Impossible de lire ce fichier.';
        _loyerParsing = false;
      });
    }
  }

  Future<void> _publishLoyerCsv() async {
    final data = _loyerPending;
    if (data == null) return;
    setState(() {
      _loyerPublishing = true;
      _loyerError = null;
    });
    try {
      await LoyerImportService.publish(data);
      if (!mounted) return;
      setState(() {
        _loyerPublishing = false;
        _loyerPublished = 'Publié — pris en compte immédiatement dans cette session, '
            'et pour tout le monde au prochain démarrage de leur app.';
        _loyerPending = null;
        _loyerPreview = null;
        _loyerFileName = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loyerPublishing = false;
        _loyerError = "Échec de la publication — vérifie ta connexion, et que ton compte a "
            'bien les droits admin sur Firebase Storage.';
      });
    }
  }

  Future<void> _pickPrixCsv() async {
    setState(() {
      _prixError = null;
      _prixPublished = null;
      _prixPending = null;
      _prixPreview = null;
      _prixSample = [];
    });
    FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(type: FileType.any, withData: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _prixError =
          "Impossible d'ouvrir le sélecteur de fichiers sur cet appareil/navigateur — réessaie, ou essaie avec un autre navigateur.");
      return;
    }
    final file = (result == null || result.files.isEmpty) ? null : result.files.first;
    if (file?.bytes == null) return; // annulé
    setState(() {
      _prixFileName = file!.name;
      _prixParsing = true;
    });
    try {
      final parsed = await compute(PrixImportService.parseCsv, file!.bytes!);
      final summary = PrixImportService.summarize(parsed.data);
      setState(() {
        _prixPending = parsed.data;
        _prixPreview = summary;
        _prixSample = parsed.sample;
        _prixParsing = false;
      });
    } on PrixImportException catch (e) {
      setState(() {
        _prixError = e.message;
        _prixParsing = false;
      });
    } catch (_) {
      setState(() {
        _prixError = 'Impossible de lire ce fichier.';
        _prixParsing = false;
      });
    }
  }

  Future<void> _publishPrixCsv() async {
    final data = _prixPending;
    if (data == null) return;
    setState(() {
      _prixPublishing = true;
      _prixError = null;
    });
    try {
      await PrixImportService.publish(data);
      if (!mounted) return;
      setState(() {
        _prixPublishing = false;
        _prixPublished = 'Publié — pris en compte immédiatement dans cette session, '
            'et pour tout le monde au prochain démarrage de leur app.';
        _prixPending = null;
        _prixPreview = null;
        _prixSample = [];
        _prixFileName = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _prixPublishing = false;
        _prixError = "Échec de la publication — vérifie ta connexion, et que ton compte a "
            'bien les droits admin sur Firebase Storage.';
      });
    }
  }

  /// Vérifie ce que l'app relit réellement pour Poitiers, en direct — sans
  /// passer par la carte, pour isoler si le souci vient de la publication/
  /// relecture (`PrixReferenceService`) ou de l'écran Carte lui-même.
  Future<void> _testerLecturePoitiers() async {
    setState(() => _prixLookupTest = 'Lecture...');
    // `preload()` ne charge qu'une seule fois (`_loading ??= ...`) : après le
    // premier chargement au démarrage de l'app, un second appel ne fait
    // rien et renvoie l'ancien résultat déjà résolu. Il faut explicitement
    // invalider pour forcer une vraie relecture depuis Firebase Storage.
    PrixReferenceService.invalidateCache();
    await PrixReferenceService.preload();
    final ref = PrixReferenceService.lookup('86194');
    if (!mounted) return;
    setState(() {
      _prixLookupTest = ref != null
          ? "L'app trouve Poitiers : ${ref.prixMedianM2.toStringAsFixed(0)} €/m², ${ref.nbVentes} ventes."
          : "L'app NE trouve PAS Poitiers dans les données rechargées (le fichier publié ne contient "
              'peut-être pas encore cette mise à jour, ou la relecture échoue).';
    });
  }

  /// Lecture BRUTE de Firebase Storage (voir
  /// `PrixReferenceService.diagnosticRawFetch`) : contrairement au test
  /// ci-dessus, celui-ci n'avale aucune exception — s'il y a un souci de
  /// permissions/réseau invisible jusqu'ici (masqué par le repli
  /// silencieux normal de l'app), il apparaît ici en toutes lettres.
  Future<void> _diagnostiquerLectureBrute() async {
    setState(() => _prixRawDiag = 'Lecture...');
    final result = await PrixReferenceService.diagnosticRawFetch();
    if (!mounted) return;
    setState(() => _prixRawDiag = result);
  }

  /// Déclenche la Cloud Function `refreshRecentPrix` (voir `functions/index.js`)
  /// — le fichier "Statistiques mensuelles DVF" (~264 Mo) est traité côté
  /// serveur, jamais téléchargé sur ce téléphone. [dryRun] ne lit que
  /// l'en-tête et quelques lignes du vrai fichier (rapide, ne publie rien) :
  /// à utiliser en premier pour confirmer le format exact avant de lancer
  /// [dryRun]: false, qui traite tout le fichier et republie le résultat.
  Future<void> _refreshRecentPrix({required bool dryRun}) async {
    setState(() {
      _prixRecentRunning = true;
      _prixRecentResult = dryRun ? "Aperçu en cours (lecture de l'en-tête seulement)..." : 'Traitement complet en cours (peut prendre plusieurs minutes)...';
    });
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('refreshRecentPrix', options: HttpsCallableOptions(timeout: const Duration(minutes: 9)))
          .call({'dryRun': dryRun});
      final data = Map<String, dynamic>.from(result.data as Map);
      if (!mounted) return;
      setState(() {
        _prixRecentResult = dryRun
            ? 'En-têtes trouvées : ${(data['headers'] as List).join(', ')}\n\n'
                'Colonnes reconnues : ${data['colonnesReconnues']}\n\n'
                "Échantillon :\n${(data['sample'] as List).join('\n')}"
            : 'Publié : ${data['nbCommunes']} commune(s) sur les 12 derniers mois.';
      });
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      setState(() => _prixRecentResult = 'Échec (${e.code}) : ${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _prixRecentResult = 'Échec : $e');
    } finally {
      if (mounted) setState(() => _prixRecentRunning = false);
    }
  }

  Future<void> _generate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) return;
    final uses = int.tryParse(_usesController.text.trim()) ?? 1;
    setState(() {
      _loading = true;
      _message = null;
    });
    await context.read<UserAccountState>().createGiftCode(code, uses: uses);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = 'Code "$code" créé — utilisable $uses fois.';
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Codes cadeaux', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Un code cadeau rend l'app gratuite à vie pour le compte qui l'utilise "
            "(bascule `grantedFree` sur son document Firestore).",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Code (ex. DIDOU-NOEL)', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Nombre d'utilisations", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _generate,
            child: Text(_loading ? 'Création...' : 'Générer le code'),
          ),
          if (_message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_message!, style: const TextStyle(color: Colors.green)),
            ),
          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 20),
          const Text('Loyer/m² par commune ("Carte des loyers")',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "À refaire une fois par an environ, quand l'ANIL publie une nouvelle édition. "
            '1. Télécharge le fichier "Appartements" (nom se terminant par "appmefdhup.csv") '
            'depuis data.gouv.fr. 2. Sélectionne-le ci-dessous. 3. Vérifie l\'aperçu, publie.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: _dataGouvUrl));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Lien copié.')));
            },
            icon: const Icon(Icons.link, size: 16),
            label: const Text('Copier le lien data.gouv.fr'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Comment reconnaître le bon fichier', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              SizedBox(height: 6),
              Text(
                'Le téléchargement contient 4 fichiers CSV — un seul est le bon, celui '
                'nommé exactement "predappmefdhup.csv" (rien entre "app" et "mefdhup", '
                "c'est le plus court des 4). Les 3 autres ne sont PAS utilisés par l'app :\n"
                '• predapp12mefdhup.csv → appartements 1-2 pièces\n'
                '• predapp3mefdhup.csv → appartements 3 pièces et plus\n'
                '• predmaimefdhup.csv → maisons\n\n'
                "Les 4 fichiers ont la même structure : l'aperçu ci-dessous affichera "
                'toujours "~34 900 communes reconnues" même si tu sélectionnes le mauvais '
                'par erreur — vérifie donc bien le NOM du fichier avant de publier. Pas '
                'grave si tu te trompes, republier le bon fichier écrase simplement le '
                'précédent.',
                style: TextStyle(fontSize: 12.5),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loyerParsing ? null : _pickLoyerCsv,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(_loyerParsing ? 'Lecture...' : 'Sélectionner le fichier CSV'),
          ),
          if (_loyerFileName != null && _loyerPreview != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_loyerFileName!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('${_loyerPreview!.nbCommunes} communes reconnues, dont '
                      '${_loyerPreview!.nbEstimationZone} en estimation de zone élargie.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loyerPublishing ? null : _publishLoyerCsv,
                    child: Text(_loyerPublishing ? 'Publication...' : 'Publier cette mise à jour'),
                  ),
                ]),
              ),
            ),
          ],
          if (_loyerError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_loyerError!, style: const TextStyle(color: Colors.red)),
            ),
          if (_loyerPublished != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_loyerPublished!, style: const TextStyle(color: Colors.green)),
            ),
          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 20),
          const Text('Prix/m² par commune ("Statistiques DVF")',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Remplace l'appel en direct à VALORIS par notre propre republication — à refaire "
            "environ deux fois par an, quand data.gouv.fr publie une nouvelle édition (habituellement "
            'en avril et en octobre) : plus besoin d\'attendre le rythme de VALORIS pour avoir des '
            'chiffres à jour. 1. Télécharge le fichier "Statistiques DVF" (prix médian par commune) '
            'depuis data.gouv.fr. 2. Sélectionne-le ci-dessous. 3. Vérifie l\'aperçu, publie.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: _dataGouvPrixUrl));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Lien copié.')));
            },
            icon: const Icon(Icons.link, size: 16),
            label: const Text('Copier le lien data.gouv.fr'),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quel fichier prendre', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              SizedBox(height: 6),
              Text(
                'Sur la page data.gouv.fr, prends "Statistiques totales DVF" (le fichier agrégé '
                'sur 5 ans, ~30 Mo) — pas "Statistiques mensuelles DVF" (plus de 250 Mo, pas '
                "utilisable ici). Ce fichier agrège déjà les 5 dernières années en une seule "
                "ligne par commune : pas d'année précise ni d'évolution sur 1 an affichées pour "
                "cette donnée, juste le prix médian réel sur la période. La lecture peut prendre "
                "jusqu'à une minute, mais l'app ne se fige plus pendant ce temps — patiente le "
                'temps que "Lecture..." redevienne "Sélectionner le fichier CSV".',
                style: TextStyle(fontSize: 12.5),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _prixParsing ? null : _pickPrixCsv,
            icon: const Icon(Icons.upload_file_outlined, size: 18),
            label: Text(_prixParsing ? 'Lecture...' : 'Sélectionner le fichier CSV'),
          ),
          if (_prixFileName != null && _prixPreview != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_prixFileName!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('${_prixPreview!.nbCommunes} communes reconnues (prix médian agrégé sur les '
                      '5 dernières années).'),
                  if (_prixSample.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text('Exemples lus dans le fichier (vérifie que les codes ressemblent à '
                        'de vrais codes INSEE à 5 chiffres) :',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    ..._prixSample.map((s) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(s, style: const TextStyle(fontSize: 11.5, fontFamily: 'monospace')),
                        )),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _prixPublishing ? null : _publishPrixCsv,
                    child: Text(_prixPublishing ? 'Publication...' : 'Publier cette mise à jour'),
                  ),
                ]),
              ),
            ),
          ],
          if (_prixError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_prixError!, style: const TextStyle(color: Colors.red)),
            ),
          if (_prixPublished != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_prixPublished!, style: const TextStyle(color: Colors.green)),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _testerLecturePoitiers,
            icon: const Icon(Icons.search, size: 16),
            label: const Text('Tester ce que l\'app relit pour Poitiers'),
          ),
          if (_prixLookupTest != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_prixLookupTest!, style: const TextStyle(fontSize: 12.5)),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _diagnostiquerLectureBrute,
            icon: const Icon(Icons.bug_report_outlined, size: 16),
            label: const Text('Diagnostiquer la lecture Storage (brut, sans repli silencieux)'),
          ),
          if (_prixRawDiag != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_prixRawDiag!, style: const TextStyle(fontSize: 12.5)),
            ),
          const SizedBox(height: 28),
          const Text('Prix récents (12 derniers mois glissants)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Traité côté serveur (le fichier mensuel de data.gouv.fr pèse ~264 Mo, bien trop pour ce téléphone) — "
            'commence par "Vérifier le format" pour confirmer que le fichier a bien la structure attendue avant '
            'de lancer le traitement complet.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              onPressed: _prixRecentRunning ? null : () => _refreshRecentPrix(dryRun: true),
              icon: const Icon(Icons.preview_outlined, size: 16),
              label: const Text('Vérifier le format'),
            ),
            ElevatedButton.icon(
              onPressed: _prixRecentRunning ? null : () => _refreshRecentPrix(dryRun: false),
              icon: const Icon(Icons.cloud_sync_outlined, size: 16),
              label: const Text('Lancer le traitement complet'),
            ),
          ]),
          if (_prixRecentResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(_prixRecentResult!, style: const TextStyle(fontSize: 12.5)),
            ),
          const SizedBox(height: 36),
          const Divider(),
          const SizedBox(height: 20),
          const Text('Suggestions des utilisateurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "Idées d'amélioration envoyées depuis l'app (Mon compte → Proposer une amélioration).",
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminSuggestionsScreen())),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Voir les suggestions'),
          ),
        ],
      ),
    );
  }
}
