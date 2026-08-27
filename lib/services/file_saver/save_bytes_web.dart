import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Déclenche un téléchargement navigateur classique (Blob + lien `download`
/// invisible) — fonctionne dans tous les navigateurs, contrairement à la
/// Web Share API (non universellement supportée pour des fichiers).
Future<bool> saveBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  final blobParts = <JSAny>[bytes.toJS].toJS;
  final blob = web.Blob(blobParts, web.BlobPropertyBag(type: mimeType));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename;
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
