import 'dart:math';

import 'calculations.dart';
import 'formatters.dart';

/// Une piste concrète pour améliorer ce bien, avec son effet réellement
/// recalculé via [computeCore] sur une hypothèse modifiée (durée de prêt,
/// taux, vacance, frais de gestion...) — jamais un pourcentage inventé.
/// Affichée dans la pop-up de résultats après enregistrement, voir
/// `property_saved_dialog.dart`.
class ImprovementSuggestion {
  final String title;
  final String description;
  /// Gain de cash-flow mensuel si la piste est suivie — sert à classer les
  /// pistes entre elles par ordre d'impact (voir [computeImprovementSuggestions]).
  final double deltaCashflow;

  const ImprovementSuggestion({
    required this.title,
    required this.description,
    required this.deltaCashflow,
  });
}

/// Sous ce seuil (€/mois), l'effet d'une piste est trop faible pour valoir
/// la peine d'être suggéré.
const double _seuilPertinence = 5.0;

/// Calcule jusqu'à 2 pistes concrètes pour [f], classées par impact sur le
/// cash-flow. Chaque piste teste une hypothèse réaliste (ex. durée de prêt
/// +5 ans, vacance -2 points) en relançant [computeCore] dessus plutôt qu'en
/// affichant un chiffre inventé, et n'est retenue que si son effet dépasse
/// [_seuilPertinence] — pour rester pertinent plutôt que de suggérer un
/// changement négligeable sur un bien déjà optimisé.
List<ImprovementSuggestion> computeImprovementSuggestions(PropertyInput f, CoreResult core) {
  final candidates = <ImprovementSuggestion>[];

  ImprovementSuggestion? essai(
    String title,
    PropertyInput hypothese,
    String Function(CoreResult alt, double delta) decrire,
  ) {
    final alt = computeCore(hypothese);
    final delta = alt.cashflowMensuel - core.cashflowMensuel;
    if (delta <= _seuilPertinence) return null;
    return ImprovementSuggestion(title: title, description: decrire(alt, delta), deltaCashflow: delta);
  }

  // Frais de gestion (agence) en longue durée — se gérer soi-même les
  // ramène à zéro.
  if (f.mode == RentalMode.longue && f.gestion > 0) {
    final s = essai(
      'Gérer le bien soi-même',
      f.copyWith(gestion: 0),
      (alt, delta) => "Sans les ${eur(f.gestion)}/an de frais de gestion, ta rentabilité nette passerait de "
          "${fmt(core.net, 1)} % à ${fmt(alt.net, 1)} %, et ton cash-flow progresserait de +${eur(delta.round())}/mois.",
    );
    if (s != null) candidates.add(s);
  }

  // Vacance locative en longue durée — une meilleure sélection du locataire
  // ou un bail mieux anticipé la réduit.
  if (f.mode == RentalMode.longue && f.vacancePct > 2) {
    final reduite = max(0.0, f.vacancePct - 2);
    final s = essai(
      'Réduire la vacance locative',
      f.copyWith(vacancePct: reduite),
      (alt, delta) => "En ramenant la vacance de ${fmt(f.vacancePct, 0)} % à ${fmt(reduite, 0)} % (meilleure "
          "sélection du locataire, bail mieux anticipé), ta rentabilité nette passerait de ${fmt(core.net, 1)} % "
          "à ${fmt(alt.net, 1)} %, soit +${eur(delta.round())}/mois de cash-flow.",
    );
    if (s != null) candidates.add(s);
  }

  // Commission de plateforme en courte durée — diffusion multi-canal ou
  // réservation directe pour réduire la part prélevée.
  if (f.mode == RentalMode.courte && f.commissionPct > 5) {
    final reduite = max(0.0, f.commissionPct - 3);
    final s = essai(
      'Réduire la commission de plateforme',
      f.copyWith(commissionPct: reduite),
      (alt, delta) => "En ramenant la commission de ${fmt(f.commissionPct, 0)} % à ${fmt(reduite, 0)} % (diffusion "
          "sur plusieurs plateformes, réservation directe), ta rentabilité nette passerait de ${fmt(core.net, 1)} % "
          "à ${fmt(alt.net, 1)} %, soit +${eur(delta.round())}/mois de cash-flow.",
    );
    if (s != null) candidates.add(s);
  }

  // Durée du prêt — l'allonger baisse la mensualité. N'affecte pas la
  // rentabilité (indépendante du financement), seulement le cash-flow — et
  // augmente le coût total du crédit, mentionné pour rester honnête.
  if (core.montantEmprunte > 0 && f.dureePretAns < 25) {
    final allongee = min(25, f.dureePretAns + 5);
    final s = essai(
      'Allonger la durée du prêt',
      f.copyWith(dureePretAns: allongee),
      (alt, delta) => "En passant de ${f.dureePretAns} à $allongee ans (même taux, même capital emprunté), ta "
          "mensualité baisserait de ${eur(core.mensualite.round())} à ${eur(alt.mensualite.round())}, soit "
          "+${eur(delta.round())}/mois de cash-flow. La rentabilité ne change pas, mais le coût total du crédit "
          "augmente.",
    );
    if (s != null) candidates.add(s);
  }

  // Taux du prêt — une renégociation réaliste (marge courante observée)
  // baisse aussi la mensualité, sans toucher à la rentabilité.
  if (core.montantEmprunte > 0 && f.tauxPct > 0.8) {
    final negocie = max(0.5, f.tauxPct - 0.3);
    if (negocie < f.tauxPct) {
      final s = essai(
        'Renégocier le taux du prêt',
        f.copyWith(tauxPct: negocie),
        (alt, delta) => "En renégociant ton taux de ${fmt(f.tauxPct, 1)} % à ${fmt(negocie, 1)} % (une marge "
            "réaliste en négociation), ta mensualité baisserait de ${eur(core.mensualite.round())} à "
            "${eur(alt.mensualite.round())}, soit +${eur(delta.round())}/mois de cash-flow.",
      );
      if (s != null) candidates.add(s);
    }
  }

  candidates.sort((a, b) => b.deltaCashflow.compareTo(a.deltaCashflow));
  return candidates.take(2).toList();
}
