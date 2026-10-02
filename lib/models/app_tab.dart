/// Identifiant stable de chaque onglet principal de l'app — utilisé par
/// [RendementState] (ordre/visibilité personnalisés, persistés) et par
/// l'écran "Personnaliser mon affichage". Le nom de l'enum (`.name`) sert de
/// clé de sérialisation : ne pas renommer une valeur existante sans migrer
/// les préférences déjà enregistrées sur l'appareil des utilisateurs.
enum AppTab { guide, calc, marche, carte, fisc, proj, biens, patrimoine, formation }

/// Ordre par défaut (celui d'origine, avant toute personnalisation) — sert
/// aussi de filet de sécurité : toute valeur absente d'un ordre personnalisé
/// invalide (ex. après une mise à jour qui ajouterait un onglet) est
/// rajoutée à la fin dans cet ordre-là.
///
/// `guide` en première position (plutôt qu'à la fin, où atterrirait un
/// onglet ajouté pour un utilisateur ayant déjà personnalisé son
/// affichage) : pour un nouvel utilisateur, c'est le point d'entrée avant
/// même de remplir "Bien".
const List<AppTab> kDefaultTabOrder = [
  AppTab.guide,
  AppTab.calc,
  AppTab.marche,
  AppTab.carte,
  AppTab.fisc,
  AppTab.proj,
  AppTab.biens,
  AppTab.patrimoine,
  // En dernier (voir la doc du filet de sécurité ci-dessus) : pour un compte
  // ayant déjà personnalisé l'ordre de ses onglets avant l'ajout de la
  // formation, ce nouvel onglet est rajouté en fin de liste plutôt
  // qu'inséré arbitrairement quelque part au milieu.
  AppTab.formation,
];
