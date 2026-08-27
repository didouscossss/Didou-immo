import 'dart:typed_data';

/// Plateforme sans mécanisme de téléchargement implémenté (voir
/// `save_bytes_web.dart` pour le web, seule plateforme réellement déployée
/// par cette app) — renvoie `false` plutôt que de planter, l'appelant
/// affiche alors un message adapté.
Future<bool> saveBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  return false;
}
