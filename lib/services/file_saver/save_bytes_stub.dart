import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Enregistre le fichier via le sélecteur natif `file_picker` — Android (et
/// toute autre plateforme non-web) n'a pas de dossier "Téléchargements"
/// accessible par un chemin de fichier classique depuis Android 10 (accès
/// au stockage restreint) : passer `bytes` à `saveFile` laisse le système
/// écrire lui-même le fichier à l'endroit choisi par l'utilisateur, sans
/// jamais manipuler de chemin brut (même mécanisme que `FilePicker.pickFiles`
/// déjà utilisé pour l'import, voir `admin_screen.dart`).
///
/// `saveFile` renvoie `null` aussi bien sur une vraie erreur que si
/// l'utilisateur annule simplement la boîte de dialogue — indistinguable
/// sans réécrire le contrat de retour de cette fonction partagée avec le
/// web ; les deux cas sont donc traités pareil (retour `false`), comme une
/// annulation silencieuse plutôt qu'une erreur alarmante.
///
/// [mimeType] n'est pas utilisé ici : la version de `file_picker` installée
/// (11.0.3) n'accepte pas ce paramètre sur `saveFile` (contrairement à des
/// versions plus récentes du package) — gardé dans la signature uniquement
/// pour correspondre au contrat partagé avec `save_bytes_web.dart`.
Future<bool> saveBytes({
  required Uint8List bytes,
  required String filename,
  required String mimeType,
}) async {
  try {
    final path = await FilePicker.saveFile(fileName: filename, bytes: bytes);
    return path != null;
  } catch (_) {
    return false;
  }
}
