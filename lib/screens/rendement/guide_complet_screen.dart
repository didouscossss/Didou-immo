import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/section_title.dart';

/// Un encart expliqué (un "encart" = une des cartes grises qu'on retrouve
/// dans chaque onglet, reconnaissables à leur [SectionTitle] coloré).
class _GuideField {
  final String title;
  final String body;
  const _GuideField(this.title, this.body);
}

/// Le contenu expliqué d'un onglet entier — un bloc par onglet de l'appli,
/// dans l'ordre où ils apparaissent dans la barre du bas / le menu latéral.
class _GuideTab {
  final String label;
  final IconData icon;
  final Color color;
  final String intro;
  final List<_GuideField> fields;
  const _GuideTab({required this.label, required this.icon, required this.color, required this.intro, required this.fields});
}

/// Contenu du guide — un équivalent détaillé, encart par encart, de ce que
/// [MethodologieSheet] résume en quelques lignes et que le tuto de prise en
/// main ([OnboardingSheet]) ne fait que survoler onglet par onglet. Gardé
/// séparé de ces deux-là (plutôt que de les allonger) : ce sont des points
/// d'entrée courts et rapides à lire, celui-ci est la version longue pour
/// qui veut vraiment comprendre le "pourquoi" de chaque champ.
const List<_GuideTab> _guideTabs = [
  _GuideTab(
    label: 'Bien',
    icon: Icons.home_outlined,
    color: Color(0xFF7C6FE0),
    intro: "Le point de départ de toute simulation : tu décris le bien, son financement, ses revenus et ses charges — "
        "la rentabilité se recalcule automatiquement à chaque champ rempli, pas besoin de valider quoi que ce soit.",
    fields: [
      _GuideField(
        'Informations générales',
        "Le nom du bien ne sert qu'à t'y retrouver une fois plusieurs biens enregistrés. Le type de location "
            "(longue ou courte durée) change les champs proposés ensuite : la courte durée affiche des champs "
            "saisonniers (prix par nuit, nuits occupées en basse/haute saison) à la place du loyer mensuel classique, "
            "parce que les deux façons de louer ne se calculent pas pareil.",
      ),
      _GuideField(
        'Caractéristiques du bien',
        "Localisation, surface et capacité d'accueil permettent de comparer ton bien aux repères de prix du secteur "
            "(onglet Marché) et, en courte durée, d'estimer un potentiel de nuitées réaliste pour la zone.",
      ),
      _GuideField(
        'Prix et travaux',
        "Prix d'achat, frais de notaire et travaux forment le coût total réel du projet, pas seulement le prix "
            "affiché par le vendeur. C'est cette base qui sert à calculer la rentabilité brute et nette, et le "
            "montant à financer.",
      ),
      _GuideField(
        'Revenus & charges',
        "Loyer (ou revenus saisonniers en courte durée), vacance locative, charges de copropriété et frais de "
            "gestion donnent le revenu net réellement perçu une fois les charges déduites. C'est ce chiffre-là, pas "
            "le loyer affiché, qui détermine si le bien est vraiment rentable.",
      ),
      _GuideField(
        'Financement',
        "Apport, taux d'intérêt et durée du prêt déterminent la mensualité de crédit, donc le cash-flow mensuel — "
            "ce qu'il te reste, ou ce qu'il te manque, chaque mois une fois le prêt et les charges payés.",
      ),
      _GuideField(
        'Comparer des offres de prêt',
        "Permet de saisir plusieurs propositions de banque (taux, durée, assurance) et de voir laquelle coûte "
            "réellement le moins cher sur la durée totale du prêt — pas seulement sur le taux affiché, qui ne dit "
            "pas tout une fois l'assurance comptée.",
      ),
      _GuideField(
        "Capacité d'emprunt",
        "À partir de tes revenus et de tes crédits en cours, estime le montant maximum qu'une banque accepterait "
            "généralement de te prêter (taux d'endettement). Utile pour savoir si le projet est finançable avant "
            "même de contacter une banque.",
      ),
      _GuideField(
        'Et si...? (stress-test)',
        "Simule un scénario pessimiste — le taux qui grimpe, l'occupation qui baisse, des travaux imprévus — pour "
            "voir si le projet reste viable même si tout ne se passe pas comme prévu. Un réflexe essentiel avant de "
            "s'engager sur 15 ou 20 ans.",
      ),
    ],
  ),
  _GuideTab(
    label: 'Marché',
    icon: Icons.location_on_outlined,
    color: Color(0xFF7C6FE0),
    intro: "Resitue ton bien par rapport aux prix réels du secteur, pour savoir si tu achètes au bon prix.",
    fields: [
      _GuideField(
        'Localisation & marché',
        "Une fois la commune renseignée, affiche le prix et le loyer moyen au m² du secteur (voir Méthodologie pour "
            "la source) et calcule l'écart avec ton bien. Un score d'investissement résume ensuite cette comparaison "
            "en un coup d'œil, pour ne pas avoir à interpréter plusieurs chiffres séparément.",
      ),
    ],
  ),
  _GuideTab(
    label: 'Carte',
    icon: Icons.map_outlined,
    color: Color(0xFF3B82C4),
    intro: "La même donnée de prix au m², mais sur une carte — pratique pour comparer plusieurs secteurs ou villes "
        "avant même de choisir où investir.",
    fields: [
      _GuideField(
        'Carte des prix',
        "Affiche le prix et le loyer au m² zone par zone. Utile pour repérer rapidement les secteurs sous-évalués "
            "ou, à l'inverse, ceux où les prix sont déjà tendus — sans avoir à chercher commune par commune.",
      ),
    ],
  ),
  _GuideTab(
    label: 'Fiscalité',
    icon: Icons.account_balance_outlined,
    color: Color(0xFF5B6FD8),
    intro: "La fiscalité peut faire la différence entre un bon et un mauvais investissement — cet onglet t'aide à "
        "anticiper, pas à remplir ta déclaration à ta place.",
    fields: [
      _GuideField(
        'Régimes fiscaux',
        "Compare, selon ta tranche d'imposition (TMI), ce que chaque régime (micro-foncier, réel, LMNP...) te "
            "laisserait réellement net d'impôt. Un même loyer peut rapporter très différemment selon le régime "
            "choisi — c'est souvent là que se joue une vraie différence de rentabilité.",
      ),
      _GuideField(
        'Documents & démarches',
        "Liste les documents à réunir et les démarches à anticiper pour le régime retenu, pour ne pas découvrir une "
            "obligation administrative après coup, une fois le bien déjà acheté.",
      ),
      _GuideField(
        'Échéances récurrentes',
        "Rappelle les dates et obligations qui reviennent chaque année (déclarations, taxe foncière...) une fois le "
            "bien en exploitation, pour les anticiper plutôt que les découvrir.",
      ),
      _GuideField(
        'Structure de détention',
        "En nom propre, en SCI à l'IR ou à l'IS... la structure juridique choisie pour détenir le bien a un impact "
            "fiscal et patrimonial fort, en particulier en cas de revente ou de transmission plus tard.",
      ),
    ],
  ),
  _GuideTab(
    label: 'Projection',
    icon: Icons.trending_up,
    color: Color(0xFF4A9B6E),
    intro: "Projette le bien dans le temps : remboursement du prêt, évolution de sa valeur, et ce qu'il te "
        "resterait si tu le revendais.",
    fields: [
      _GuideField(
        'Projection patrimoniale',
        "À partir d'hypothèses de croissance des loyers et de la valeur du bien, simule l'évolution de ton "
            "patrimoine année après année. Le graphique montre si tu t'enrichis réellement avec ce bien, et à quel "
            "rythme.",
      ),
      _GuideField(
        "Tableau d'amortissement",
        "Détaille, échéance par échéance, la part d'intérêts et de capital remboursés. Utile pour savoir combien tu "
            "dois réellement encore à la banque à un instant donné, par exemple en vue d'une revente anticipée.",
      ),
      _GuideField(
        'Simulation de revente',
        "Estime la plus-value nette si tu revends le bien après la durée de projection choisie, impôt sur la "
            "plus-value déjà déduit. Cette imposition diminue avec le temps, jusqu'à disparaître après 22 à 30 ans "
            "de détention.",
      ),
      _GuideField(
        'TRI',
        "Le Taux de Rendement Interne résume en un seul pourcentage la performance globale du projet (loyers + "
            "revente), en tenant compte du moment où chaque euro entre et sort. C'est la mesure la plus complète "
            "pour comparer deux projets très différents entre eux.",
      ),
    ],
  ),
  _GuideTab(
    label: 'Comparer',
    icon: Icons.layers_outlined,
    color: Color(0xFFD4A72C),
    intro: "Une fois plusieurs biens enregistrés, cet onglet les met côte à côte pour t'aider à choisir entre eux.",
    fields: [
      _GuideField(
        'Comparatif',
        "Tableau récapitulatif de tous tes biens enregistrés — rentabilité, cash-flow et score — pour repérer en "
            "un coup d'œil lequel est le plus intéressant.",
      ),
      _GuideField(
        'Comparatif graphique',
        "Les mêmes indicateurs (rentabilité nette, cash-flow, score) présentés sous forme de graphiques en barres — "
            "souvent plus parlant qu'un tableau de chiffres pour trancher entre plusieurs biens.",
      ),
      _GuideField(
        'Historique des ventes',
        "Garde une trace des biens que tu as marqués comme vendus, avec leur date de vente. Utile pour suivre tes "
            "décisions passées et affiner ton jugement au fil du temps.",
      ),
      _GuideField(
        'Exporter en CSV',
        "Exporte toutes tes données dans un fichier exploitable dans un tableur — pratique pour un suivi personnel "
            "plus poussé, ou pour les partager avec un comptable ou un conseiller.",
      ),
    ],
  ),
  _GuideTab(
    label: 'Patrimoine',
    icon: Icons.insights_outlined,
    color: Color(0xFF2FA39B),
    intro: "Une vue d'ensemble de tous tes biens enregistrés, comme un portefeuille d'investissement plutôt que "
        "bien par bien.",
    fields: [
      _GuideField(
        'Patrimoine',
        "Agrège la valeur, les revenus et le cash-flow de l'ensemble de tes biens enregistrés, pour donner une "
            "vision globale de ton patrimoine immobilier — pas bien par bien, mais dans son ensemble.",
      ),
    ],
  ),
];

/// Écran "Guide complet" — explique, onglet par onglet puis encart par
/// encart, à quoi sert chaque section de l'appli et pourquoi elle compte,
/// comme demandé en plus du tuto rapide et de la méthodologie déjà
/// existants. Un vrai écran (pas une feuille) : le contenu est trop long
/// pour une sheet, et ça permet de défiler et de revenir en arrière
/// normalement, identique sur mobile comme sur le site web.
class GuideCompletScreen extends StatelessWidget {
  const GuideCompletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guide complet')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "Comment utiliser l'application",
            style: AppTextStyles.serif(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          Text(
            "Chaque onglet ci-dessous correspond à ceux de la barre de navigation. Dans chacun, les encarts se "
            "remplissent de haut en bas — commence par l'onglet Bien, les autres se nourrissent de ce que tu y "
            "renseignes. Le mode Novice/Avancé (icône en haut), le réordonnancement des onglets et des encarts "
            "(icône Personnaliser) et le thème clair/sombre sont accessibles à tout moment et n'effacent jamais tes "
            "données.",
            style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.65)).copyWith(height: 1.5),
          ),
          const SizedBox(height: 28),
          for (final tab in _guideTabs) ...[
            SectionTitle(tab.label, icon: tab.icon, color: tab.color),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tab.intro,
                style: AppTextStyles.sans(fontSize: 13, color: AppColors.ink.withValues(alpha: 0.6)).copyWith(height: 1.45),
              ),
            ),
            for (final field in tab.fields) _GuideFieldTile(field),
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
                  "retrouve-les dans Méthodologie, juste à côté de ce guide.",
                  style: AppTextStyles.sans(fontSize: 12, color: AppColors.ink.withValues(alpha: 0.6)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _GuideFieldTile extends StatelessWidget {
  final _GuideField field;
  const _GuideFieldTile(this.field);

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
          iconColor: AppColors.accent,
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
