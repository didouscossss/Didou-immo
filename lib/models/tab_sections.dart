import 'app_tab.dart';

/// Blocs personnalisables à l'intérieur d'un onglet — même principe que
/// [AppTab] pour les onglets eux-mêmes (voir `RendementState.sectionOrder`/
/// `hiddenSections` et `SectionCustomizationScreen`), mais un cran plus fin.
///
/// Les identifiants de [defaultOrder] servent de clé de sérialisation : ne
/// pas renommer une valeur existante sans migrer les préférences déjà
/// enregistrées sur l'appareil des utilisateurs.
class TabSections {
  final List<String> defaultOrder;
  final Map<String, String> labels;

  /// Bloc qui ne peut jamais être masqué (toujours visible, mais
  /// déplaçable) — `null` si tous les blocs de cet onglet sont masquables.
  final String? lockedId;

  const TabSections({required this.defaultOrder, required this.labels, this.lockedId});
}

/// Un onglet absent de cette table (ex. "Carte") n'a pas de personnalisation
/// par blocs : son contenu forme un seul bloc indissociable, pas la peine
/// d'ajouter un écran de personnalisation qui n'aurait rien à réordonner.
const Map<AppTab, TabSections> kTabSections = {
  AppTab.calc: TabSections(
    defaultOrder: [
      'localisation',
      'bien',
      'revenus',
      'financement',
      'capacite',
      'resultats',
      'comparatif',
      'stress_test',
      'save',
      'export',
    ],
    labels: {
      'localisation': 'Localisation',
      'bien': 'Le bien',
      'revenus': 'Revenus & charges',
      'financement': 'Financement',
      'capacite': "Capacité d'emprunt",
      'resultats': 'Résultats',
      'comparatif': 'Comparatif longue/courte durée',
      'stress_test': 'Stress-test (mode avancé)',
      'save': 'Enregistrer ce bien',
      'export': 'Export PDF',
    },
    // 'save' (le bouton "Enregistrer ce bien") ne peut pas être masqué —
    // sans lui, l'onglet n'aurait plus aucun moyen d'enregistrer le bien
    // en cours.
    lockedId: 'save',
  ),
  AppTab.marche: TabSections(
    defaultOrder: ['reperes', 'score'],
    labels: {
      'reperes': 'Repères de marché',
      'score': "Score d'investissement",
    },
  ),
  AppTab.fisc: TabSections(
    defaultOrder: ['regimes', 'documents', 'echeances', 'structure'],
    labels: {
      'regimes': 'Régimes fiscaux',
      'documents': 'Documents & démarches',
      'echeances': 'Échéances récurrentes',
      'structure': 'Structure de détention',
    },
  ),
  AppTab.proj: TabSections(
    defaultOrder: ['projection', 'amortissement', 'revente', 'tri'],
    labels: {
      'projection': 'Projection patrimoniale',
      'amortissement': "Tableau d'amortissement",
      'revente': 'Simulation de revente',
      'tri': 'TRI (mode avancé)',
    },
  ),
  AppTab.biens: TabSections(
    defaultOrder: ['patrimoine', 'liste', 'comparatif', 'historique', 'export'],
    labels: {
      'patrimoine': 'Patrimoine acquis',
      'liste': 'Liste des biens',
      'comparatif': 'Comparatif graphique (mode avancé)',
      'historique': 'Historique des ventes',
      'export': 'Export CSV',
    },
    // 'liste' est le contenu même de l'onglet "Comparer" — le masquer
    // viderait l'écran de tout intérêt.
    lockedId: 'liste',
  ),
  AppTab.patrimoine: TabSections(
    defaultOrder: ['resume', 'liste'],
    labels: {
      'resume': 'Résumé du portefeuille',
      'liste': 'Liste des biens suivis',
    },
    lockedId: 'liste',
  ),
};
