/// Identifiant stable de chaque onglet principal de l'app — utilisé par
/// [RendementState] (ordre/visibilité personnalisés, persistés) et par
/// l'écran "Personnaliser mon affichage". Le nom de l'enum (`.name`) sert de
/// clé de sérialisation : ne pas renommer une valeur existante sans migrer
/// les préférences déjà enregistrées sur l'appareil des utilisateurs.
enum AppTab { calc, marche, carte, fisc, proj, biens, patrimoine }

/// Ordre par défaut (celui d'origine, avant toute personnalisation) — sert
/// aussi de filet de sécurité : toute valeur absente d'un ordre personnalisé
/// invalide (ex. après une mise à jour qui ajouterait un onglet) est
/// rajoutée à la fin dans cet ordre-là.
const List<AppTab> kDefaultTabOrder = [
  AppTab.calc,
  AppTab.marche,
  AppTab.carte,
  AppTab.fisc,
  AppTab.proj,
  AppTab.biens,
  AppTab.patrimoine,
];
