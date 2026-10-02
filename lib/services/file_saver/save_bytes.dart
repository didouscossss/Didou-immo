/// Déclenche l'enregistrement d'un fichier depuis des octets en mémoire —
/// utilisé pour les exports CSV (biens, suivi patrimoine) et .ics
/// (échéances fiscales). Téléchargement navigateur direct sur le web
/// (`save_bytes_web.dart`) ; sélecteur natif `file_picker` sur Android et
/// les autres plateformes non-web (`save_bytes_stub.dart`), pour une
/// fonctionnalité identique des deux côtés.
library;

export 'save_bytes_stub.dart' if (dart.library.js_interop) 'save_bytes_web.dart';
