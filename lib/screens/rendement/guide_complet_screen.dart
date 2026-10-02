import 'package:flutter/material.dart';

import '../../models/app_tab.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_title.dart';
import 'app_tab_meta.dart';

/// Un onglet vers lequel un pas du parcours renvoie (voir [_JourneyStep.targets])
/// — un libellé propre à l'étape (ex. "Onglets Marché et Carte" plutôt que
/// deux chips séparées "Marché"/"Carte") associé à l'onglet réellement visé
/// au clic.
class _TabTarget {
  final String label;
  final AppTab tab;
  const _TabTarget(this.label, this.tab);
}

/// Une étape du parcours "du projet au résultat" (voir [_journeySteps]) —
/// le cœur de cet écran : une vraie marche à suivre, dans l'ordre où on
/// avance réellement dans l'appli, plutôt qu'une simple liste d'encarts
/// expliqués (voir [_guideTabs] plus bas, qui reste disponible pour qui
/// veut creuser un point précis).
class _JourneyStep {
  final String title;
  final IconData icon;
  final Color color;
  final String body;
  final List<_TabTarget> targets;
  // Puces optionnelles — seule l'étape "verdict" en a besoin, pour détailler
  // les quelques seuils concrets (score, cash-flow, rentabilité...) plutôt
  // que les noyer dans un paragraphe.
  final List<String>? bullets;
  const _JourneyStep({
    required this.title,
    required this.icon,
    required this.color,
    required this.body,
    required this.targets,
    this.bullets,
  });
}

/// Index de l'étape "verdict" dans [_journeySteps] — mise en avant
/// visuellement (carte teintée, bordure colorée) puisque c'est la réponse
/// à "ce projet est-il bon ou pas".
const int _kVerdictStepIndex = 7;

const List<_JourneyStep> _journeySteps = [
  _JourneyStep(
    title: 'Décris le bien',
    icon: Icons.home_outlined,
    color: Color(0xFF7C6FE0),
    body: "Nom, localisation, prix d'achat, travaux, surface. C'est la carte d'identité du projet : tout le reste de "
        "l'appli s'appuie dessus.",
    targets: [_TabTarget('Onglet Bien', AppTab.calc)],
  ),
  _JourneyStep(
    title: 'Renseigne des revenus réalistes',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF2FA39B),
    body: "Loyer attendu, vacance locative, charges de copro, frais de gestion. Mieux vaut rester prudent sur ces "
        "chiffres : la rentabilité se recalcule sous tes yeux à chaque champ rempli, pas besoin de valider quoi "
        "que ce soit.",
    targets: [_TabTarget('Onglet Bien', AppTab.calc)],
  ),
  _JourneyStep(
    title: 'Monte ton financement',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF5B6FD8),
    body: "Apport, taux, durée du prêt — et vérifie ta capacité d'emprunt pendant que tu y es. C'est ce qui "
        "détermine ton cash-flow mensuel, l'un des indicateurs les plus importants à la fin.",
    targets: [_TabTarget('Onglet Bien', AppTab.calc)],
  ),
  _JourneyStep(
    title: 'Vérifie que tu achètes au bon prix',
    icon: Icons.location_on_outlined,
    color: Color(0xFF3B82C4),
    body: "Compare le prix et le loyer de ton bien à ceux du secteur (et visualise-les sur la carte si tu hésites "
        "entre plusieurs villes). Un bien peut sembler rentable sur le papier et pourtant être acheté trop cher.",
    targets: [_TabTarget('Onglet Marché', AppTab.marche), _TabTarget('Onglet Carte', AppTab.carte)],
  ),
  _JourneyStep(
    title: 'Anticipe la fiscalité',
    icon: Icons.description_outlined,
    color: Color(0xFFD4A72C),
    body: "Regarde ce que chaque régime (micro-foncier, réel, LMNP...) te laisserait réellement net d'impôt selon "
        "ta tranche. Un même loyer peut rapporter très différemment selon le choix fait ici.",
    targets: [_TabTarget('Onglet Fiscalité', AppTab.fisc)],
  ),
  _JourneyStep(
    title: 'Projette-toi dans le temps',
    icon: Icons.trending_up,
    color: Color(0xFF4A9B6E),
    body: "Remboursement du prêt, évolution de ton patrimoine, revente simulée dans quelques années. Un bien peut "
        "être tendu les premières années et devenir très rentable sur la durée — ou l'inverse.",
    targets: [_TabTarget('Onglet Projection', AppTab.proj)],
  ),
  _JourneyStep(
    title: 'Stress-teste avant de signer',
    icon: Icons.bolt,
    color: Color(0xFFE0705C),
    body: "L'encart « Et si...? » simule un scénario pessimiste : taux qui monte, occupation qui baisse, travaux "
        "imprévus. Si le projet tient encore debout dans ce scénario, c'est plutôt bon signe.",
    targets: [_TabTarget('Onglet Bien', AppTab.calc)],
  ),
  _JourneyStep(
    title: 'Lis le résultat : bon ou pas bon ?',
    icon: Icons.task_alt,
    color: Color(0xFF2F5D50),
    body: "Trois indicateurs, toujours affichés en haut de l'onglet Bien, résument tout le projet en un coup "
        "d'œil :",
    targets: [_TabTarget('Onglet Bien', AppTab.calc)],
    bullets: [
      "Score d'investissement /100 : 80+ Excellent, 60-79 Bon, 40-59 Moyen, en dessous de 40 Risqué. Il combine "
          "rentabilité, cash-flow, écart au marché et taux d'occupation.",
      "Cash-flow mensuel positif = le loyer couvre le crédit et les charges. Négatif = il faudra compléter de ta "
          "poche chaque mois.",
      "Rentabilité nette : à partir d'environ 4 %, c'est considéré correct pour ce type de bien — en dessous, "
          "compare avec d'autres projets avant de te décider.",
      "Capacité d'emprunt dépassée (plus de 35 % d'endettement) ou DPE pénalisant (F ou G, location bientôt ou "
          "déjà interdite) : deux signaux d'alerte à regarder aussi.",
    ],
  ),
  _JourneyStep(
    title: 'Enregistre et compare',
    icon: Icons.layers_outlined,
    color: Color(0xFFD4A72C),
    body: "Convaincu, ou pas encore ? « Enregistrer ce bien » l'ajoute à Comparer et Patrimoine : tu peux alors le "
        "mettre face à d'autres projets, suivre l'ensemble de ton patrimoine, et exporter tes données en PDF ou "
        "CSV.",
    targets: [_TabTarget('Onglet Comparer', AppTab.biens), _TabTarget('Onglet Patrimoine', AppTab.patrimoine)],
  ),
];

/// Un encart expliqué (un "encart" = une des cartes grises qu'on retrouve
/// dans chaque onglet, reconnaissables à leur [SectionTitle] coloré) — le
/// détail de référence, gardé sous le parcours ci-dessus pour qui veut
/// aller plus loin qu'une étape en particulier.
class _GuideField {
  final String title;
  final String body;
  const _GuideField(this.title, this.body);
}

/// Le contenu expliqué d'un onglet entier — un bloc par onglet de l'appli,
/// dans l'ordre où ils apparaissent dans la barre du bas / le menu latéral.
class _GuideTab {
  final AppTab tab;
  final String intro;
  final List<_GuideField> fields;
  const _GuideTab({required this.tab, required this.intro, required this.fields});
}

const List<_GuideTab> _guideTabs = [
  _GuideTab(
    tab: AppTab.calc,
    intro: "Le point de départ de toute simulation : tu décris le bien, son financement, ses revenus et ses charges — "
        "la rentabilité se recalcule automatiquement à chaque champ rempli.",
    fields: [
      _GuideField(
        'Informations générales',
        "Le nom du bien ne sert qu'à t'y retrouver une fois plusieurs biens enregistrés. Le type de location "
            "(longue ou courte durée) change les champs proposés ensuite.",
      ),
      _GuideField(
        'Caractéristiques du bien',
        "Localisation, surface et capacité d'accueil permettent de comparer ton bien aux repères de prix du secteur "
            "et, en courte durée, d'estimer un potentiel de nuitées réaliste.",
      ),
      _GuideField(
        'Prix et travaux',
        "Prix d'achat, frais de notaire et travaux forment le coût total réel du projet. C'est cette base qui sert "
            "à calculer la rentabilité et le montant à financer.",
      ),
      _GuideField(
        'Revenus & charges',
        "Loyer, vacance locative, charges de copropriété et frais de gestion donnent le revenu net réellement "
            "perçu — c'est ce chiffre-là, pas le loyer affiché, qui détermine si le bien est vraiment rentable.",
      ),
      _GuideField(
        'Financement',
        "Apport, taux d'intérêt et durée du prêt déterminent la mensualité de crédit, donc le cash-flow mensuel.",
      ),
      _GuideField(
        'Comparer des offres de prêt',
        "Saisis plusieurs propositions de banque pour voir laquelle coûte réellement le moins cher sur la durée "
            "totale — pas seulement sur le taux affiché.",
      ),
      _GuideField(
        "Capacité d'emprunt",
        "Estime, à partir de tes revenus et crédits en cours, le montant maximum qu'une banque accepterait "
            "généralement de te prêter.",
      ),
      _GuideField(
        'Et si...? (stress-test)',
        "Simule un scénario pessimiste pour voir si le projet reste viable même si tout ne se passe pas comme "
            "prévu.",
      ),
    ],
  ),
  _GuideTab(
    tab: AppTab.marche,
    intro: "Resitue ton bien par rapport aux prix réels du secteur, pour savoir si tu achètes au bon prix.",
    fields: [
      _GuideField(
        'Localisation & marché',
        "Affiche le prix et le loyer moyen au m² du secteur et calcule l'écart avec ton bien. Un score "
            "d'investissement résume cette comparaison en un coup d'œil.",
      ),
    ],
  ),
  _GuideTab(
    tab: AppTab.carte,
    intro: "La même donnée de prix au m², mais sur une carte — pratique pour comparer plusieurs secteurs ou villes.",
    fields: [
      _GuideField(
        'Carte des prix',
        "Affiche le prix et le loyer au m² zone par zone, pour repérer les secteurs sous-évalués ou déjà tendus.",
      ),
    ],
  ),
  _GuideTab(
    tab: AppTab.fisc,
    intro: "La fiscalité peut faire la différence entre un bon et un mauvais investissement.",
    fields: [
      _GuideField(
        'Régimes fiscaux',
        "Compare, selon ta tranche d'imposition, ce que chaque régime te laisserait réellement net d'impôt.",
      ),
      _GuideField(
        'Documents & démarches',
        "Liste ce qu'il faut réunir et anticiper pour le régime retenu.",
      ),
      _GuideField(
        'Échéances récurrentes',
        "Rappelle les dates et obligations qui reviennent chaque année une fois le bien en exploitation.",
      ),
      _GuideField(
        'Structure de détention',
        "En nom propre ou en SCI : la structure choisie a un impact fiscal et patrimonial fort, en particulier à "
            "la revente.",
      ),
    ],
  ),
  _GuideTab(
    tab: AppTab.proj,
    intro: "Projette le bien dans le temps : remboursement du prêt, évolution de sa valeur, revente simulée.",
    fields: [
      _GuideField(
        'Projection patrimoniale',
        "Simule l'évolution de ton patrimoine année après année à partir d'hypothèses de croissance.",
      ),
      _GuideField(
        "Tableau d'amortissement",
        "Détaille la part d'intérêts et de capital remboursés, utile pour une revente anticipée.",
      ),
      _GuideField(
        'Simulation de revente',
        "Estime la plus-value nette si tu revends après la durée choisie, impôt déjà déduit.",
      ),
      _GuideField(
        'TRI',
        "Résume en un seul pourcentage la performance globale du projet (loyers + revente) — la mesure la plus "
            "complète pour comparer deux projets entre eux.",
      ),
    ],
  ),
  _GuideTab(
    tab: AppTab.biens,
    intro: "Une fois plusieurs biens enregistrés, cet onglet les met côte à côte pour t'aider à choisir.",
    fields: [
      _GuideField('Comparatif', "Tableau récapitulatif — rentabilité, cash-flow et score de tous tes biens."),
      _GuideField('Comparatif graphique', "Les mêmes indicateurs sous forme de graphiques, souvent plus parlants."),
      _GuideField('Historique des ventes', "Garde une trace des biens marqués comme vendus, avec leur date."),
      _GuideField('Exporter en CSV', "Exporte toutes tes données dans un fichier exploitable dans un tableur."),
    ],
  ),
  _GuideTab(
    tab: AppTab.patrimoine,
    intro: "Une vue d'ensemble de tous tes biens enregistrés, comme un portefeuille d'investissement.",
    fields: [
      _GuideField(
        'Patrimoine',
        "Agrège la valeur, les revenus et le cash-flow de l'ensemble de tes biens pour une vision globale.",
      ),
    ],
  ),
];

/// Onglet "Guide" — un vrai parcours pas à pas ("du projet au résultat")
/// suivi d'un détail de référence, onglet par onglet et encart par encart,
/// pour qui veut creuser un point précis.
///
/// Un onglet principal à part entière (comme "Bien" ou "Projection"),
/// plutôt qu'enfoui dans le panneau d'aide : demandé explicitement pour le
/// mettre en avant, vu l'importance du contenu pour un nouvel utilisateur.
/// Ses chips "Onglet X" sont cliquables ([onGoToTab]) — bascule directement
/// vers l'onglet concerné, comme une mini table des matières active plutôt
/// qu'un simple repère visuel.
class GuideCompletScreen extends StatelessWidget {
  final void Function(AppTab tab) onGoToTab;
  const GuideCompletScreen({super.key, required this.onGoToTab});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _buildHero(),
        const SizedBox(height: 24),
        Text(
          'Du projet au résultat, étape par étape',
          style: AppTextStyles.serif(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          "Suis-les dans l'ordre pour ton premier bien — tout reste modifiable à tout moment ensuite.",
          style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < _journeySteps.length; i++)
          _JourneyStepTile(
            step: _journeySteps[i],
            index: i,
            isLast: i == _journeySteps.length - 1,
            highlight: i == _kVerdictStepIndex,
            onGoToTab: onGoToTab,
          ),
        const SizedBox(height: 12),
        Divider(color: AppColors.border, height: 48),
        Text(
          'Le détail de chaque encart',
          style: AppTextStyles.serif(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 4),
        Text(
          "Pour creuser un champ en particulier, sans suivre tout le parcours.",
          style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 20),
        for (final guideTab in _guideTabs) ...[
          InkWell(
            onTap: () => onGoToTab(guideTab.tab),
            borderRadius: BorderRadius.circular(14),
            child: SectionTitle(kTabMeta[guideTab.tab]!.label, icon: kTabMeta[guideTab.tab]!.icon, color: _tabColor(guideTab.tab)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              guideTab.intro,
              style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6)).copyWith(height: 1.45),
            ),
          ),
          for (final field in guideTab.fields) _GuideFieldTile(field, color: _tabColor(guideTab.tab)),
          const SizedBox(height: 20),
        ],
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline, size: 16, color: AppColors.ink.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Pour les hypothèses de calcul elles-mêmes (sources des prix, barèmes fiscaux utilisés...), "
                "retrouve-les dans Méthodologie, depuis l'icône d'aide.",
                style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: AppColors.sectionBandGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipOval(
          child: Image.asset('assets/images/didou_face.png', width: 44, height: 44, fit: BoxFit.cover),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Salut, je suis Didou 👋', style: AppTextStyles.serif(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 6),
            Text(
              "Voici comment aller d'une idée de bien à un vrai résultat chiffré, avec une réponse claire : "
              "bon investissement, ou pas pour toi.",
              style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75)).copyWith(height: 1.5),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Couleur par onglet pour la section de référence — reprend celle déjà
/// utilisée par le premier [SectionTitle] de chaque écran, pour que le code
/// couleur reste cohérent avec l'onglet réel plutôt qu'une teinte inventée
/// ici.
Color _tabColor(AppTab tab) {
  switch (tab) {
    case AppTab.guide:
      return const Color(0xFF2F5D50);
    case AppTab.calc:
      return const Color(0xFF7C6FE0);
    case AppTab.marche:
      return const Color(0xFF7C6FE0);
    case AppTab.carte:
      return const Color(0xFF3B82C4);
    case AppTab.fisc:
      return const Color(0xFF5B6FD8);
    case AppTab.proj:
      return const Color(0xFF4A9B6E);
    case AppTab.biens:
      return const Color(0xFFD4A72C);
    case AppTab.patrimoine:
      return const Color(0xFF2FA39B);
    case AppTab.formation:
      return const Color(0xFFC9A227);
  }
}

class _JourneyStepTile extends StatelessWidget {
  final _JourneyStep step;
  final int index;
  final bool isLast;
  final bool highlight;
  final void Function(AppTab tab) onGoToTab;
  const _JourneyStepTile({
    required this.step,
    required this.index,
    required this.isLast,
    required this.onGoToTab,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: step.color),
                child: Icon(step.icon, size: 16, color: Colors.white),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: AppColors.border,
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: highlight ? step.color.withValues(alpha: AppColors.isDark ? 0.16 : 0.07) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: highlight ? step.color.withValues(alpha: 0.4) : AppColors.border, width: highlight ? 1.5 : 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Étape ${index + 1}', style: AppTextStyles.mono(fontSize: 11, color: step.color)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(step.title, style: AppTextStyles.serif(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      step.body,
                      style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.75)).copyWith(height: 1.55),
                    ),
                    if (step.bullets != null) ...[
                      const SizedBox(height: 10),
                      for (final b in step.bullets!)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.only(top: 7, right: 10),
                                decoration: BoxDecoration(color: step.color, shape: BoxShape.circle),
                              ),
                              Expanded(
                                child: Text(b, style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.8)).copyWith(height: 1.5)),
                              ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final target in step.targets)
                        InkWell(
                          onTap: () => onGoToTab(target.tab),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: step.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.arrow_forward, size: 12, color: step.color),
                              const SizedBox(width: 4),
                              Text(target.label, style: AppTextStyles.sans(fontSize: 11, fontWeight: FontWeight.w600, color: step.color)),
                            ]),
                          ),
                        ),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideFieldTile extends StatelessWidget {
  final _GuideField field;
  final Color color;
  const _GuideFieldTile(this.field, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          iconColor: color,
          collapsedIconColor: AppColors.ink.withValues(alpha: 0.4),
          title: Text(field.title, style: AppTextStyles.sans(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.ink)),
          children: [
            Text(
              field.body,
              style: AppTextStyles.sans(fontSize: 12.5, color: AppColors.ink.withValues(alpha: 0.7)).copyWith(height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
