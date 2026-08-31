/// Identifiant stable de chaque bloc réordonnable de l'onglet "Bien" — sert
/// de clé de sérialisation (voir `RendementState.bienSectionOrder`) : ne pas
/// renommer une valeur existante sans migrer les préférences déjà
/// enregistrées sur l'appareil des utilisateurs.
///
/// 'stress_test' n'apparaît que si le niveau est "avancé", et le
/// sous-bloc "Comparer des offres de prêt" à l'intérieur de 'financement'
/// n'apparaît que dans ce même cas — ce filtrage par niveau reste appliqué
/// quel que soit l'ordre/la visibilité choisis par l'utilisateur.
const List<String> kDefaultBienSections = [
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
];

/// 'save' (le bouton "Enregistrer ce bien") ne peut pas être masqué — sans
/// lui, l'onglet n'aurait plus aucun moyen d'enregistrer le bien en cours.
/// Il reste déplaçable comme les autres blocs.
const String kBienSaveSectionId = 'save';

const Map<String, String> kBienSectionLabels = {
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
};
