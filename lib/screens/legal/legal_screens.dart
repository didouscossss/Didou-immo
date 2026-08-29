import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Écrans d'informations légales — mentions légales, politique de
/// confidentialité, CGU/CGV. Contenu figé dans le code (pas de back-office
/// éditorial) : la seule source de vérité est ce fichier, à mettre à jour
/// ici si les conditions changent.
///
/// ⚠️ Rédigé à partir des informations fournies par l'éditeur, pas relu par
/// un professionnel du droit — à faire vérifier par un avocat/expert-
/// comptable avant une activation réelle de la facturation, en particulier
/// le numéro SIRET (à compléter dès immatriculation, voir [MentionsLegalesScreen]).
const _lastUpdated = '28 août 2026';

class LegalHubScreen extends StatelessWidget {
  const LegalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Informations légales')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HubTile(
            icon: Icons.gavel_outlined,
            title: 'Mentions légales',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MentionsLegalesScreen())),
          ),
          const SizedBox(height: 12),
          _HubTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ConfidentialiteScreen())),
          ),
          const SizedBox(height: 12),
          _HubTile(
            icon: Icons.description_outlined,
            title: "Conditions générales d'utilisation et de vente",
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CgvScreen())),
          ),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  const _HubTile({required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: AppTextStyles.sans(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink))),
            Icon(Icons.chevron_right, size: 20, color: AppColors.ink.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String heading;
  final String body;
  const _Section(this.heading, this.body);
}

class _LegalPage extends StatelessWidget {
  final String title;
  final List<_Section> sections;
  const _LegalPage({required this.title, required this.sections});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Dernière mise à jour : $_lastUpdated',
              style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.5))),
          const SizedBox(height: 20),
          for (final s in sections) ...[
            Text(s.heading, style: AppTextStyles.serif(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(s.body,
                style: AppTextStyles.sans(fontSize: 13.5, color: AppColors.ink.withValues(alpha: 0.85)).copyWith(height: 1.5)),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class MentionsLegalesScreen extends StatelessWidget {
  const MentionsLegalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Mentions légales',
      sections: [
        _Section(
          'Éditeur',
          "Didou Immo est édité par Valentin Champion, entrepreneur individuel, domicilié à Iteuil (86340), France.\n"
              "Contact : valentin.champion31@gmail.com\n"
              "Numéro SIRET : en cours d'immatriculation — sera complété ici dès attribution.",
        ),
        _Section('Directeur de la publication', 'Valentin Champion.'),
        _Section(
          'Hébergement',
          "Le site est hébergé par GitHub, Inc. (GitHub Pages), 88 Colin P Kelly Jr St, San Francisco, CA 94107, États-Unis.\n"
              "Les comptes utilisateurs et les biens enregistrés sont hébergés par Google Ireland Limited / Google LLC "
              "(Firebase, Google Cloud Platform).",
        ),
        _Section(
          'Propriété intellectuelle',
          "L'ensemble des éléments de l'application (textes, mise en page, code, méthodologie de calcul) est la propriété "
              "de l'éditeur, sauf mention contraire. Toute reproduction non autorisée est interdite.",
        ),
        _Section(
          'Contact',
          'Pour toute question, réclamation ou exercice de tes droits : valentin.champion31@gmail.com.',
        ),
      ],
    );
  }
}

class ConfidentialiteScreen extends StatelessWidget {
  const ConfidentialiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: 'Politique de confidentialité',
      sections: [
        _Section(
          'Responsable du traitement',
          'Valentin Champion — valentin.champion31@gmail.com.',
        ),
        _Section(
          'Données collectées',
          "Ton adresse email et ton mot de passe si tu crées un compte par email (ton mot de passe n'est jamais stocké "
              "en clair : son authentification est gérée par Firebase Authentication, Google).\n"
              "Les données des biens immobiliers que tu saisis toi-même (prix, loyers, charges, simulations...).\n"
              "Ton statut d'abonnement et le nombre d'essais gratuits utilisés.",
        ),
        _Section(
          'Pourquoi ces données',
          "Fournir le service (sauvegarder tes biens et y accéder depuis n'importe quel appareil connecté à ton "
              "compte), gérer ton abonnement, et éviter les abus sur les essais gratuits.",
        ),
        _Section(
          'Base légale',
          "L'exécution du contrat qui te lie à nous quand tu utilises l'application (voir nos CGU/CGV), et notre "
              "intérêt légitime à prévenir la fraude sur les essais gratuits.",
        ),
        _Section(
          'Sous-traitants et hébergement',
          "Google Firebase (authentification, base de données Firestore, fonctions serveur) — Google Ireland Limited "
              "/ Google LLC. Sur Android, le paiement de l'abonnement passe par Google Play Billing : nous ne "
              "recevons et ne stockons jamais tes données bancaires, elles sont gérées entièrement par Google.",
        ),
        _Section(
          'Durée de conservation',
          "Tes données sont conservées tant que ton compte existe. Tu peux les supprimer définitivement à tout "
              "moment depuis Mon compte > Supprimer mon compte : la suppression est immédiate et irréversible.",
        ),
        _Section(
          'Tes droits',
          "Conformément au RGPD, tu disposes d'un droit d'accès, de rectification, d'effacement, d'opposition et de "
              "portabilité sur tes données. Pour les exercer : valentin.champion31@gmail.com. Tu peux aussi "
              "introduire une réclamation auprès de la CNIL (www.cnil.fr).",
        ),
        _Section(
          'Cookies et traceurs',
          "Didou Immo n'utilise aucun cookie publicitaire ni outil de mesure d'audience tiers.",
        ),
      ],
    );
  }
}

class CgvScreen extends StatelessWidget {
  const CgvScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _LegalPage(
      title: "Conditions générales d'utilisation et de vente",
      sections: [
        _Section(
          'Objet',
          "Les présentes conditions régissent l'utilisation de l'application Didou Immo, calculateur de rentabilité "
              "immobilière destiné à t'aider dans tes décisions d'investissement.",
        ),
        _Section(
          "Description de l'offre",
          "Version gratuite : jusqu'à 3 biens enregistrés.\n"
              "Abonnement « Illimité » : 4,99 €/mois ou 50 €/an, sans limite de biens enregistrés. Paiement géré par "
              "Google Play Billing (application Android), avec renouvellement automatique à chaque échéance sauf "
              "résiliation.",
        ),
        _Section(
          'Résiliation',
          "Tu peux résilier ton abonnement à tout moment depuis le Google Play Store (Menu > Abonnements). La "
              "résiliation prend effet à la fin de la période déjà payée ; aucun remboursement au prorata n'est "
              "effectué pour la période en cours.",
        ),
        _Section(
          'Droit de rétractation',
          "Conformément à l'article L221-28 du Code de la consommation, en souscrivant à un abonnement dont "
              "l'exécution commence immédiatement (accès débloqué dès le paiement confirmé), tu renonces "
              "expressément à ton droit de rétractation de 14 jours en validant ce choix au moment du paiement.",
        ),
        _Section(
          'Nature du service et responsabilité',
          "Les calculs, projections et scores fournis par Didou Immo sont des estimations à titre indicatif, basées "
              "sur les données que tu saisis et des hypothèses simplifiées. Ils ne constituent ni un conseil "
              "financier, ni fiscal, ni juridique, et ne remplacent pas l'avis d'un professionnel (notaire, "
              "expert-comptable, conseiller en gestion de patrimoine). Tu restes seul responsable de tes décisions "
              "d'investissement.",
        ),
        _Section(
          'Compte utilisateur',
          "Tu es responsable de la confidentialité de tes identifiants. Ton compte et tes données peuvent être "
              "supprimés à tout moment depuis Mon compte.",
        ),
        _Section(
          'Modification des CGU/CGV',
          "Ces conditions peuvent évoluer ; la version en vigueur est toujours consultable dans l'application depuis "
              "Mon compte > Informations légales.",
        ),
        _Section(
          'Droit applicable',
          "Les présentes conditions sont soumises au droit français. En cas de litige, une solution amiable sera "
              "recherchée en priorité.",
        ),
      ],
    );
  }
}
