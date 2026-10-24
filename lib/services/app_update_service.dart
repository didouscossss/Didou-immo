import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

/// URL de la fiche Play Store — même valeur que le lien promotionnel déjà
/// affiché ailleurs dans l'app (voir `rendement_home.dart`).
const String _defaultPlayStoreUrl = 'https://play.google.com/store/apps/details?id=com.didouimmo.didou_immo';

class UpdateInfo {
  final String storeUrl;
  final String? message;
  const UpdateInfo({required this.storeUrl, this.message});
}

/// Vérifie si une version plus récente que celle installée a été publiée —
/// demandé par l'utilisateur : sans ça, personne ne savait qu'une mise à
/// jour existait tant qu'il n'allait pas vérifier lui-même sur le Play
/// Store. Compare le numéro de build local (`package_info_plus`) au champ
/// `latestVersionCode` du document Firestore `appConfig/android` — lisible
/// par tous, y compris en mode local sans compte (voir `firestore.rules`).
///
/// Mis à jour À LA MAIN dans Firebase Console à chaque nouvelle publication
/// Android (volontairement : pas d'API Play Store officielle ici, pour
/// éviter une dépendance native supplémentaire — voir la discussion avec
/// l'utilisateur). Si le document n'existe pas encore, ou que Firestore est
/// injoignable, ne propose simplement rien plutôt que d'échouer bruyamment.
class AppUpdateService {
  Future<UpdateInfo?> checkForUpdate() async {
    // `defaultTargetPlatform` (et non `dart:io Platform`, incompatible web) —
    // ce fichier est importé par `rendement_home.dart`, partagé avec le
    // build web, qui ne compile pas `dart:io`.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    try {
      final doc = await FirebaseFirestore.instance.collection('appConfig').doc('android').get();
      final data = doc.data();
      if (data == null) return null;
      final latest = (data['latestVersionCode'] as num?)?.toInt();
      if (latest == null) return null;

      final info = await PackageInfo.fromPlatform();
      final current = int.tryParse(info.buildNumber) ?? 0;
      if (current <= 0 || latest <= current) return null;

      final storeUrl = (data['storeUrl'] as String?)?.trim();
      return UpdateInfo(
        storeUrl: (storeUrl != null && storeUrl.isNotEmpty) ? storeUrl : _defaultPlayStoreUrl,
        message: data['message'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
