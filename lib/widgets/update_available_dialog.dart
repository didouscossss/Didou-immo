import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/app_update_service.dart';
import '../theme/app_theme.dart';

/// Pop-up affichée au lancement si une version plus récente que celle
/// installée est disponible — voir `AppUpdateService.checkForUpdate`.
/// Jamais bloquante : toujours "Plus tard" en plus de "Mettre à jour", et
/// le fond reste cliquable (`barrierDismissible`).
Future<void> showUpdateAvailableDialog(BuildContext context, {required UpdateInfo info}) {
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(Icons.system_update_alt, color: AppColors.accent, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nouvelle version disponible',
                style: AppTextStyles.serif(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          Text(
            (info.message?.isNotEmpty ?? false)
                ? info.message!
                : 'Une nouvelle version de Didou Immo est disponible, avec des corrections et des améliorations.',
            style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.7)).copyWith(height: 1.45),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await launchUrl(Uri.parse(info.storeUrl), mode: LaunchMode.externalApplication);
              } catch (_) {
                // Rien de plus à faire si l'ouverture échoue — l'utilisateur
                // peut toujours aller sur le Play Store lui-même, comme
                // avant cette pop-up.
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Mettre à jour'),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Plus tard', style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6))),
          ),
        ]),
      ),
    ),
  );
}
