/// Déclenche l'enregistrement/téléchargement d'un fichier depuis des octets
/// en mémoire — utilisé pour l'export CSV. Implémentation web (seule
/// plateforme réellement déployée par cette app, voir `save_bytes_web.dart`) ;
/// `save_bytes_stub.dart` répond `false` ailleurs plutôt que de planter.
library;

export 'save_bytes_stub.dart' if (dart.library.js_interop) 'save_bytes_web.dart';
