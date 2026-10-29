/// Identifiant stable de chaque onglet principal de l'app — utilisé par
/// [RendementState] (ordre/visibilité personnalisés, persistés) et par
/// l'écran "Personnaliser mon affichage". Le nom de l'enum (`.name`) sert de
/// clé de sérialisation : ne pas renommer une valeur existante sans migrer
/// les préférences déjà enregistrées sur l'appareil des utilisateurs.
enum AppTab { guide, calc, marche, carte, fisc, proj, biens, patrimoine, formation }

/// Ordre par défaut (celui d'origine, avant toute personnalisation) de la
/// barre du bas — sert aussi de filet de sécurité : toute valeur absente
/// d'un ordre personnalisé invalide (ex. après une mise à jour qui
/// ajouterait un onglet) est rajoutée à la fin dans cet ordre-là.
///
/// `guide` et `formation` n'y figurent PAS : demandé par l'utilisateur, ils
/// ont leur propre icône en haut de l'écran (voir `RendementHome`) plutôt
/// qu'une place dans une barre du bas déjà chargée — `RendementState`
/// filtre aussi ces deux valeurs de tout ordre personnalisé restauré d'un
/// ancien enregistrement (voir `_applyTabLayout`), pour qu'elles ne
/// réapparaissent pas dans la barre du bas d'un utilisateur qui les y avait
/// avant ce changement.
const List<AppTab> kDefaultTabOrder = [
  AppTab.calc,
  AppTab.marche,
  AppTab.carte,
  AppTab.fisc,
  AppTab.proj,
  AppTab.biens,
  AppTab.patrimoine,
];
