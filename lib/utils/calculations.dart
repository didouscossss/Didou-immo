// Logique de calcul financière — portée fidèlement depuis le prototype
// React (rendement-app.jsx). Toutes les formules sont volontairement pures
// (pas d'état, pas d'I/O) pour rester faciles à tester unitairement.
import 'dart:math';

const double social = 0.172; // prélèvements sociaux (17,2 %)

// ---------------------------------------------------------------------------
// Helpers financiers
// ---------------------------------------------------------------------------

/// Mensualité d'un prêt (formule d'annuité standard).
double monthlyPayment(double principal, double annualRatePct, int years) {
  final r = annualRatePct / 100 / 12;
  final n = years * 12;
  if (principal <= 0 || n <= 0) return 0;
  if (r == 0) return principal / n;
  return (principal * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
}

/// Capital restant dû après [yearsElapsed] années.
double remainingBalance(
    double principal, double annualRatePct, int years, double yearsElapsed) {
  final r = annualRatePct / 100 / 12;
  final n = years * 12;
  final m = min(max(yearsElapsed, 0) * 12, n.toDouble());
  if (principal <= 0 || n <= 0) return 0;
  if (m <= 0) return principal;
  if (m >= n) return 0;
  final M = monthlyPayment(principal, annualRatePct, years);
  if (r == 0) return max(0, principal - M * m);
  final bal = principal * pow(1 + r, m) - M * ((pow(1 + r, m) - 1) / r);
  return max(0, bal.toDouble());
}

/// Inverse de [monthlyPayment] : montant empruntable pour une mensualité donnée.
double loanPrincipalFromPayment(
    double payment, double annualRatePct, int years) {
  final r = annualRatePct / 100 / 12;
  final n = years * 12;
  if (payment <= 0 || n <= 0) return 0;
  if (r == 0) return payment * n;
  return payment * (1 - pow(1 + r, -n)) / r;
}

double interestPaidYear1(double principal, double annualRatePct, int years) {
  final r = annualRatePct / 100 / 12;
  final M = monthlyPayment(principal, annualRatePct, years);
  double bal = principal, interest = 0;
  final monthsToRun = min(12, years * 12);
  for (var i = 0; i < monthsToRun; i++) {
    final interestThisMonth = bal * r;
    interest += interestThisMonth;
    bal -= (M - interestThisMonth);
  }
  return interest;
}

// ---------------------------------------------------------------------------
// Modèle du bien (équivalent de l'objet `form` du prototype)
// ---------------------------------------------------------------------------

enum RentalMode { longue, courte }

class CommuneRef {
  final String nom;
  final String codePostal;
  final String departement;
  final int population;

  const CommuneRef({
    required this.nom,
    this.codePostal = '',
    this.departement = '',
    this.population = 0,
  });
}

class LoanOffer {
  final int id;
  final String nom;
  final double tauxPct;
  final int dureePretAns;
  final double assurancePct;

  const LoanOffer({
    required this.id,
    required this.nom,
    required this.tauxPct,
    required this.dureePretAns,
    required this.assurancePct,
  });

  LoanOffer copyWith({
    String? nom,
    double? tauxPct,
    int? dureePretAns,
    double? assurancePct,
  }) {
    return LoanOffer(
      id: id,
      nom: nom ?? this.nom,
      tauxPct: tauxPct ?? this.tauxPct,
      dureePretAns: dureePretAns ?? this.dureePretAns,
      assurancePct: assurancePct ?? this.assurancePct,
    );
  }
}

/// Le bien à l'étude — équivalent de l'objet `form`/`DEFAULT_FORM` du JSX.
/// Immuable : on le modifie via [copyWith], comme `setForm(f => ({...f, x}))`.
class PropertyInput {
  final String nom;
  final RentalMode mode;
  final CommuneRef? commune;
  final double surface;
  final String typeBien;
  final double capacite;

  final double prix, notaire, travaux;

  // longue durée
  final double loyer, vacancePct, chargesCopro, gestion;

  // courte durée
  final double prixNuitBasse, prixNuitHaute;
  final int nuitsBasseSaison, nuitsHauteSaison;
  final double dureeSejourMoyenne,
      commissionPct,
      menagePartReservation,
      abonnements,
      ameublementAnnuel,
      taxeSejour;

  // commun
  final double taxeFonciere, assurance;
  final String dpe;

  // financement
  final double apport, tauxPct;
  final int dureePretAns;
  final List<LoanOffer> offres;

  // capacité d'emprunt
  final double revenuMensuelNet, chargesCreditExistantes;

  // fiscalité
  final double tmi;

  // projection & revente
  final int dureeProjection;
  final double croissanceLoyer, croissanceValeur, fraisAgenceRevente;

  const PropertyInput({
    this.nom = '',
    required this.mode,
    this.commune,
    required this.surface,
    this.typeBien = 't2',
    this.capacite = 3,
    required this.prix,
    required this.notaire,
    required this.travaux,
    this.loyer = 0,
    this.vacancePct = 0,
    this.chargesCopro = 0,
    this.gestion = 0,
    this.prixNuitBasse = 0,
    this.prixNuitHaute = 0,
    this.nuitsBasseSaison = 0,
    this.nuitsHauteSaison = 0,
    this.dureeSejourMoyenne = 1,
    this.commissionPct = 0,
    this.menagePartReservation = 0,
    this.abonnements = 0,
    this.ameublementAnnuel = 0,
    this.taxeSejour = 0,
    required this.taxeFonciere,
    required this.assurance,
    this.dpe = 'D',
    required this.apport,
    required this.tauxPct,
    required this.dureePretAns,
    this.offres = const [],
    this.revenuMensuelNet = 0,
    this.chargesCreditExistantes = 0,
    this.tmi = 30,
    this.dureeProjection = 15,
    this.croissanceLoyer = 1.5,
    this.croissanceValeur = 2,
    this.fraisAgenceRevente = 5,
  });

  /// Équivalent de `DEFAULT_FORM` dans le prototype.
  factory PropertyInput.defaultForm() => const PropertyInput(
        mode: RentalMode.longue,
        commune: CommuneRef(
          nom: 'Nantes',
          codePostal: '44000',
          departement: 'Loire-Atlantique',
          population: 320000,
        ),
        surface: 45,
        typeBien: 't2',
        capacite: 3,
        prix: 180000,
        notaire: 14000,
        travaux: 6000,
        loyer: 850,
        vacancePct: 4,
        chargesCopro: 900,
        gestion: 0,
        prixNuitBasse: 55,
        prixNuitHaute: 110,
        nuitsBasseSaison: 90,
        nuitsHauteSaison: 70,
        dureeSejourMoyenne: 3,
        commissionPct: 15,
        menagePartReservation: 45,
        abonnements: 600,
        ameublementAnnuel: 400,
        taxeSejour: 1.5,
        taxeFonciere: 1100,
        assurance: 250,
        dpe: 'D',
        apport: 20000,
        tauxPct: 3.7,
        dureePretAns: 20,
        offres: [
          LoanOffer(id: 1, nom: 'Banque A', tauxPct: 3.7, dureePretAns: 20, assurancePct: 0.34),
          LoanOffer(id: 2, nom: 'Banque B', tauxPct: 3.9, dureePretAns: 20, assurancePct: 0.12),
        ],
        revenuMensuelNet: 2800,
        chargesCreditExistantes: 0,
        tmi: 30,
        dureeProjection: 15,
        croissanceLoyer: 1.5,
        croissanceValeur: 2,
        fraisAgenceRevente: 5,
      );

  PropertyInput copyWith({
    String? nom,
    RentalMode? mode,
    CommuneRef? commune,
    double? surface,
    String? typeBien,
    double? capacite,
    double? prix,
    double? notaire,
    double? travaux,
    double? loyer,
    double? vacancePct,
    double? chargesCopro,
    double? gestion,
    double? prixNuitBasse,
    double? prixNuitHaute,
    int? nuitsBasseSaison,
    int? nuitsHauteSaison,
    double? dureeSejourMoyenne,
    double? commissionPct,
    double? menagePartReservation,
    double? abonnements,
    double? ameublementAnnuel,
    double? taxeSejour,
    double? taxeFonciere,
    double? assurance,
    String? dpe,
    double? apport,
    double? tauxPct,
    int? dureePretAns,
    List<LoanOffer>? offres,
    double? revenuMensuelNet,
    double? chargesCreditExistantes,
    double? tmi,
    int? dureeProjection,
    double? croissanceLoyer,
    double? croissanceValeur,
    double? fraisAgenceRevente,
  }) {
    return PropertyInput(
      nom: nom ?? this.nom,
      mode: mode ?? this.mode,
      commune: commune ?? this.commune,
      surface: surface ?? this.surface,
      typeBien: typeBien ?? this.typeBien,
      capacite: capacite ?? this.capacite,
      prix: prix ?? this.prix,
      notaire: notaire ?? this.notaire,
      travaux: travaux ?? this.travaux,
      loyer: loyer ?? this.loyer,
      vacancePct: vacancePct ?? this.vacancePct,
      chargesCopro: chargesCopro ?? this.chargesCopro,
      gestion: gestion ?? this.gestion,
      prixNuitBasse: prixNuitBasse ?? this.prixNuitBasse,
      prixNuitHaute: prixNuitHaute ?? this.prixNuitHaute,
      nuitsBasseSaison: nuitsBasseSaison ?? this.nuitsBasseSaison,
      nuitsHauteSaison: nuitsHauteSaison ?? this.nuitsHauteSaison,
      dureeSejourMoyenne: dureeSejourMoyenne ?? this.dureeSejourMoyenne,
      commissionPct: commissionPct ?? this.commissionPct,
      menagePartReservation: menagePartReservation ?? this.menagePartReservation,
      abonnements: abonnements ?? this.abonnements,
      ameublementAnnuel: ameublementAnnuel ?? this.ameublementAnnuel,
      taxeSejour: taxeSejour ?? this.taxeSejour,
      taxeFonciere: taxeFonciere ?? this.taxeFonciere,
      assurance: assurance ?? this.assurance,
      dpe: dpe ?? this.dpe,
      apport: apport ?? this.apport,
      tauxPct: tauxPct ?? this.tauxPct,
      dureePretAns: dureePretAns ?? this.dureePretAns,
      offres: offres ?? this.offres,
      revenuMensuelNet: revenuMensuelNet ?? this.revenuMensuelNet,
      chargesCreditExistantes: chargesCreditExistantes ?? this.chargesCreditExistantes,
      tmi: tmi ?? this.tmi,
      dureeProjection: dureeProjection ?? this.dureeProjection,
      croissanceLoyer: croissanceLoyer ?? this.croissanceLoyer,
      croissanceValeur: croissanceValeur ?? this.croissanceValeur,
      fraisAgenceRevente: fraisAgenceRevente ?? this.fraisAgenceRevente,
    );
  }
}

// ---------------------------------------------------------------------------
// Calcul central — reproduit exactement `computeCore` du prototype.
// ---------------------------------------------------------------------------

class CoreResult {
  final double prixTotal,
      apport,
      montantEmprunte,
      mensualite,
      interetsAn1,
      loyerAnnuelBrut,
      chargesAnnuelles,
      revenuNet,
      brut,
      net,
      cashflowMensuel,
      prixM2,
      loyerM2,
      mensualiteMax,
      tauxOccupation;
  final bool capaciteOk;
  final double? nuitsTotal, nombreReservations, prixNuitMoyen;

  const CoreResult({
    required this.prixTotal,
    required this.apport,
    required this.montantEmprunte,
    required this.mensualite,
    required this.interetsAn1,
    required this.loyerAnnuelBrut,
    required this.chargesAnnuelles,
    required this.revenuNet,
    required this.brut,
    required this.net,
    required this.cashflowMensuel,
    required this.prixM2,
    required this.loyerM2,
    required this.mensualiteMax,
    required this.capaciteOk,
    required this.tauxOccupation,
    this.nuitsTotal,
    this.nombreReservations,
    this.prixNuitMoyen,
  });
}

CoreResult computeCore(PropertyInput f) {
  final prixTotal = f.prix + f.notaire + f.travaux;
  final apport = min(f.apport, prixTotal);
  final montantEmprunte = max(0, prixTotal - apport).toDouble();
  final mensualite = monthlyPayment(montantEmprunte, f.tauxPct, f.dureePretAns);
  final interetsAn1 = interestPaidYear1(montantEmprunte, f.tauxPct, f.dureePretAns);

  double loyerAnnuelBrut, chargesSpecifiques, tauxOccupation;
  double? nuitsTotal, nombreReservations, prixNuitMoyen;
  if (f.mode == RentalMode.longue) {
    loyerAnnuelBrut = f.loyer * 12 * (1 - f.vacancePct / 100);
    chargesSpecifiques = f.chargesCopro + f.gestion;
    tauxOccupation = 100 - f.vacancePct;
  } else {
    final nuitsTotalV = (f.nuitsBasseSaison + f.nuitsHauteSaison).toDouble();
    final loyerAvantCommission =
        f.prixNuitBasse * f.nuitsBasseSaison + f.prixNuitHaute * f.nuitsHauteSaison;
    loyerAnnuelBrut = loyerAvantCommission * (1 - f.commissionPct / 100);
    final nombreReservationsV =
        f.dureeSejourMoyenne > 0 ? nuitsTotalV / f.dureeSejourMoyenne : 0.0;
    final menageAnnuel = nombreReservationsV * f.menagePartReservation;
    chargesSpecifiques = menageAnnuel + f.abonnements + f.ameublementAnnuel;
    tauxOccupation = (nuitsTotalV / 365) * 100;
    prixNuitMoyen = nuitsTotalV > 0 ? loyerAvantCommission / nuitsTotalV : 0.0;
    nuitsTotal = nuitsTotalV;
    nombreReservations = nombreReservationsV;
  }
  final chargesAnnuelles = chargesSpecifiques + f.taxeFonciere + f.assurance;
  final revenuNet = loyerAnnuelBrut - chargesAnnuelles;
  final brut = prixTotal > 0 ? (loyerAnnuelBrut / prixTotal) * 100 : 0.0;
  final net = prixTotal > 0 ? (revenuNet / prixTotal) * 100 : 0.0;
  final cashflowMensuel = (loyerAnnuelBrut - chargesAnnuelles) / 12 - mensualite;

  final prixM2 = f.surface > 0 ? prixTotal / f.surface : 0.0;
  final loyerM2 = f.surface > 0
      ? (f.mode == RentalMode.longue ? f.loyer / f.surface : (loyerAnnuelBrut / 12) / f.surface)
      : 0.0;
  final mensualiteMax = f.revenuMensuelNet * 0.35 - f.chargesCreditExistantes;
  final capaciteOk = mensualite <= mensualiteMax;

  return CoreResult(
    prixTotal: prixTotal,
    apport: apport,
    montantEmprunte: montantEmprunte,
    mensualite: mensualite,
    interetsAn1: interetsAn1,
    loyerAnnuelBrut: loyerAnnuelBrut,
    chargesAnnuelles: chargesAnnuelles,
    revenuNet: revenuNet,
    brut: brut,
    net: net,
    cashflowMensuel: cashflowMensuel,
    prixM2: prixM2,
    loyerM2: loyerM2,
    mensualiteMax: mensualiteMax,
    capaciteOk: capaciteOk,
    tauxOccupation: tauxOccupation,
    nuitsTotal: nuitsTotal,
    nombreReservations: nombreReservations,
    prixNuitMoyen: prixNuitMoyen,
  );
}

// ---------------------------------------------------------------------------
// Régimes fiscaux
// ---------------------------------------------------------------------------

class RegimeResult {
  final String id, label, note;
  final bool eligible;
  final double base, impot, revenuNetNet, netNetPct;

  const RegimeResult({
    required this.id,
    required this.label,
    required this.note,
    required this.eligible,
    required this.base,
    required this.impot,
    required this.revenuNetNet,
    required this.netNetPct,
  });
}

List<RegimeResult> computeRegimes(PropertyInput f, CoreResult core) {
  final loyerAnnuelBrut = core.loyerAnnuelBrut;
  final chargesAnnuelles = core.chargesAnnuelles;
  final interetsAn1 = core.interetsAn1;
  final prixTotal = core.prixTotal;
  final tmi = f.tmi / 100;
  final eligibleMicroFoncier = f.mode == RentalMode.longue && loyerAnnuelBrut <= 15000;
  final amortAnnuel = (prixTotal * 0.85) / 25;

  final defs = <({String id, String label, bool eligible, String note, double Function() base})>[
    (
      id: 'microFoncier',
      label: 'Micro-foncier',
      eligible: eligibleMicroFoncier,
      note: 'Location nue, loyers < 15 000 €/an. Abattement forfaitaire 30 %.',
      base: () => max(0, loyerAnnuelBrut * 0.7),
    ),
    (
      id: 'reel',
      label: 'Réel foncier',
      eligible: f.mode == RentalMode.longue,
      note: "Location nue. Déduction des charges réelles + intérêts d'emprunt.",
      base: () => max(0, loyerAnnuelBrut - chargesAnnuelles - interetsAn1),
    ),
    (
      id: 'lmnpMicro',
      label: 'LMNP micro-BIC',
      eligible: true,
      note: 'Location meublée. Abattement forfaitaire 50 % (71 % si tourisme classé).',
      base: () => max(0, loyerAnnuelBrut * 0.5),
    ),
    (
      id: 'lmnpReel',
      label: 'LMNP réel',
      eligible: true,
      note: 'Location meublée. Amortissement du bien + charges réelles déduits.',
      base: () => max(0, loyerAnnuelBrut - chargesAnnuelles - interetsAn1 - amortAnnuel),
    ),
  ];

  return defs.map((r) {
    final base = r.base();
    final impot = base * (tmi + social);
    final revenuNetNet = loyerAnnuelBrut - chargesAnnuelles - impot;
    final netNetPct = prixTotal > 0 ? (revenuNetNet / prixTotal) * 100 : 0.0;
    return RegimeResult(
      id: r.id,
      label: r.label,
      note: r.note,
      eligible: r.eligible,
      base: base,
      impot: impot,
      revenuNetNet: revenuNetNet,
      netNetPct: netNetPct,
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// Projection patrimoniale
// ---------------------------------------------------------------------------

class ProjectionPoint {
  final int year;
  final double valeurBien, capitalRestant, equity;
  const ProjectionPoint({
    required this.year,
    required this.valeurBien,
    required this.capitalRestant,
    required this.equity,
  });
}

List<ProjectionPoint> buildProjection(
  PropertyInput f,
  CoreResult core,
  int years,
  double croissanceLoyer,
  double croissanceValeur,
) {
  final points = <ProjectionPoint>[];
  for (var y = 0; y <= years; y++) {
    final valeurBien = core.prixTotal * pow(1 + croissanceValeur / 100, y);
    final capitalRestant =
        remainingBalance(core.montantEmprunte, f.tauxPct, f.dureePretAns, y.toDouble());
    final equity = valeurBien - capitalRestant;
    points.add(ProjectionPoint(
      year: y,
      valeurBien: valeurBien.roundToDouble(),
      capitalRestant: capitalRestant.roundToDouble(),
      equity: equity.roundToDouble(),
    ));
  }
  return points;
}

// ---------------------------------------------------------------------------
// Score d'investissement
// ---------------------------------------------------------------------------

class ScoreParts {
  final double rendement, cashflow, marche, occupation;
  const ScoreParts({
    required this.rendement,
    required this.cashflow,
    required this.marche,
    required this.occupation,
  });
}

class ScoreResult {
  final int score;
  final String label;
  final String colorHex;
  final ScoreParts parts;
  const ScoreResult({
    required this.score,
    required this.label,
    required this.colorHex,
    required this.parts,
  });
}

const String _accentHex = '#2F5D50';
const String _goldHex = '#B8935A';
const String _alertHex = '#B3452C';
const String _goodHex = '#4A7C59';

ScoreResult computeScore(PropertyInput f, CoreResult core, RefInfo? refInfo) {
  final rendement = min(40.0, max(0.0, (core.net / 8) * 40));
  final cashflow =
      core.cashflowMensuel >= 0 ? 25.0 : max(0.0, 25 + core.cashflowMensuel / 8);
  double marche;
  if (refInfo != null && f.surface > 0 && core.prixM2 > 0) {
    final ratio = refInfo.ref.prixM2 / core.prixM2;
    marche = min(20.0, max(0.0, ratio * 15));
  } else {
    marche = 10;
  }
  final occupation = min(15.0, (max(0.0, min(100.0, core.tauxOccupation)) / 100) * 15);

  final total = rendement + cashflow + marche + occupation;
  final score = min(100, max(0, total)).round();
  String label = 'Risqué';
  String color = _alertHex;
  if (score >= 80) {
    label = 'Excellent';
    color = _accentHex;
  } else if (score >= 60) {
    label = 'Bon';
    color = _goodHex;
  } else if (score >= 40) {
    label = 'Moyen';
    color = _goldHex;
  }

  return ScoreResult(
    score: score,
    label: label,
    colorHex: color,
    parts: ScoreParts(rendement: rendement, cashflow: cashflow, marche: marche, occupation: occupation),
  );
}

// ---------------------------------------------------------------------------
// Checklists & échéances
// ---------------------------------------------------------------------------

const List<String> checklistLongue = [
  'Diagnostics obligatoires avant location (DPE, électricité, gaz, plomb si besoin)',
  'Rédaction du bail conforme (loi de 1989) + état des lieux d\'entrée',
  "Attestation d'assurance propriétaire non-occupant (PNO)",
  'Notice d\'information annexée au bail',
  'Dossier de diagnostic technique remis au locataire',
  'Déclaration des revenus fonciers (formulaire 2044 ou 2072)',
];

class Deadline {
  final String periode, label;
  const Deadline(this.periode, this.label);
}

const List<Deadline> deadlinesLongue = [
  Deadline('Avril – juin', 'Déclaration annuelle des revenus fonciers'),
  Deadline('Date anniversaire du bail', "Révision du loyer selon l'indice IRL (si prévue au bail)"),
  Deadline('Septembre – novembre', 'Réception et paiement de la taxe foncière'),
  Deadline("3 ans avant l'échéance", 'Vérifier la validité du DPE et des diagnostics'),
];

const List<String> checklistCourte = [
  "Déclaration en mairie (numéro d'enregistrement, obligatoire dans de nombreuses villes)",
  'Vérifier le plafond de jours autorisés si résidence principale (120 jours/an)',
  "Attestation d'assurance adaptée à la location saisonnière",
  'Mise en conformité sécurité (détecteur de fumée, extincteur selon commune)',
  'Collecte et reversement de la taxe de séjour',
  'Déclaration des revenus en BIC (régime LMNP)',
];

const List<Deadline> deadlinesCourte = [
  Deadline('Avant la 1ère mise en location', 'Déclaration en mairie + numéro d\'enregistrement'),
  Deadline('Trimestriel / selon commune', 'Reversement de la taxe de séjour collectée'),
  Deadline('Mai', 'Déclaration des revenus BIC (formulaire 2042-C-PRO)'),
  Deadline('Chaque année', 'Vérifier le quota de jours si résidence principale'),
];

const List<String> checklistVisite = [
  'État de la toiture, des façades et des menuiseries extérieures',
  'Traces d\'humidité (murs, plafonds, sous-sol, cave)',
  'Pression d\'eau et évacuation (éviers, douche, WC)',
  'Fonctionnement du chauffage, de la VMC et de l\'électricité',
  'Niveau sonore aux différentes heures (rue, voisins, activité commerciale)',
  'Exposition et luminosité réelle (matin, après-midi, soir)',
  'Réception réseau mobile et disponibilité fibre/box',
  'État des parties communes et de la cage d\'escalier',
  "3 derniers PV d'assemblée générale de copropriété",
  'Montant des charges de copropriété des 2 dernières années',
  'Travaux votés ou à prévoir (ravalement, toiture, ascenseur)',
];

// ---------------------------------------------------------------------------
// DPE : impact sur la location
// ---------------------------------------------------------------------------

class DpeInfo {
  final String colorHex;
  final String? banIssue;
  const DpeInfo(this.colorHex, this.banIssue);
}

const Map<String, DpeInfo> dpeInfo = {
  'A': DpeInfo('#1D7A4A', null),
  'B': DpeInfo('#3F9142', null),
  'C': DpeInfo('#8CB93C', null),
  'D': DpeInfo(_goldHex, null),
  'E': DpeInfo('#C97A3A', 'Location interdite à partir de 2034'),
  'F': DpeInfo('#C4562F', 'Location interdite depuis 2028'),
  'G': DpeInfo(_alertHex, 'Location déjà interdite (logements neufs à la location depuis 2025)'),
};

// ---------------------------------------------------------------------------
// Plus-value à la revente (régime des particuliers, simplifié)
// ---------------------------------------------------------------------------

/// Abattement IR pour la plus-value (régime des particuliers).
double abattementIR(int years) {
  if (years <= 5) return 0;
  if (years >= 22) return 1;
  double ab = 0;
  for (var i = 6; i <= years; i++) {
    ab += i == 22 ? 0.04 : 0.06;
  }
  return min(1, ab);
}

/// Abattement prélèvements sociaux pour la plus-value.
double abattementPS(int years) {
  if (years <= 5) return 0;
  if (years >= 30) return 1;
  double ab = 0;
  for (var i = 6; i <= years; i++) {
    ab += i <= 21 ? 0.0165 : (i == 22 ? 0.016 : 0.09);
  }
  return min(1, ab);
}

class PlusValueResult {
  final double prixVenteNet, plusValueBrute, impotIR, impotPS, plusValueNette, abIR, abPS;
  const PlusValueResult({
    required this.prixVenteNet,
    required this.plusValueBrute,
    required this.impotIR,
    required this.impotPS,
    required this.plusValueNette,
    required this.abIR,
    required this.abPS,
  });
}

PlusValueResult computePlusValue(
    PropertyInput f, CoreResult core, double valeurRevente, int years) {
  final prixVenteNet = valeurRevente * (1 - f.fraisAgenceRevente / 100);
  final prixAcquisition = core.prixTotal;
  final plusValueBrute = max(0.0, prixVenteNet - prixAcquisition);
  final abIR = abattementIR(years);
  final abPS = abattementPS(years);
  final impotIR = plusValueBrute * (1 - abIR) * 0.19;
  final impotPS = plusValueBrute * (1 - abPS) * social;
  final plusValueNette = plusValueBrute - impotIR - impotPS;
  return PlusValueResult(
    prixVenteNet: prixVenteNet,
    plusValueBrute: plusValueBrute,
    impotIR: impotIR,
    impotPS: impotPS,
    plusValueNette: plusValueNette,
    abIR: abIR,
    abPS: abPS,
  );
}

// ---------------------------------------------------------------------------
// Comparateur d'offres de prêt
// ---------------------------------------------------------------------------

class OffreResult {
  final LoanOffer offre;
  final double mensualiteCredit,
      assuranceMensuelle,
      mensualiteTotale,
      coutTotalCredit,
      coutTotalAssurance,
      coutTotal;
  const OffreResult({
    required this.offre,
    required this.mensualiteCredit,
    required this.assuranceMensuelle,
    required this.mensualiteTotale,
    required this.coutTotalCredit,
    required this.coutTotalAssurance,
    required this.coutTotal,
  });
}

OffreResult computeOffre(LoanOffer offre, double montantEmprunte) {
  final mensualiteCredit = monthlyPayment(montantEmprunte, offre.tauxPct, offre.dureePretAns);
  final assuranceMensuelle = (montantEmprunte * (offre.assurancePct / 100)) / 12;
  final mensualiteTotale = mensualiteCredit + assuranceMensuelle;
  final coutTotalCredit = mensualiteCredit * offre.dureePretAns * 12 - montantEmprunte;
  final coutTotalAssurance = assuranceMensuelle * offre.dureePretAns * 12;
  final coutTotal = coutTotalCredit + coutTotalAssurance;
  return OffreResult(
    offre: offre,
    mensualiteCredit: mensualiteCredit,
    assuranceMensuelle: assuranceMensuelle,
    mensualiteTotale: mensualiteTotale,
    coutTotalCredit: coutTotalCredit,
    coutTotalAssurance: coutTotalAssurance,
    coutTotal: coutTotal,
  );
}

// ---------------------------------------------------------------------------
// Mode de détention
// ---------------------------------------------------------------------------

class Structure {
  final String id, label, subtitle;
  final List<String> points;
  const Structure(this.id, this.label, this.subtitle, this.points);
}

const List<Structure> structures = [
  Structure(
    'propre',
    'Nom propre',
    'Achat en direct, sans société',
    [
      'Simple et rapide à mettre en place',
      'Revenus fonciers ou BIC imposés directement à ton nom',
      'Plus-value : régime des particuliers, abattements pour durée de détention',
      'Transmission moins souple (pas de parts à répartir)',
    ],
  ),
  Structure(
    'sciIR',
    "SCI à l'IR",
    'Société civile, transparente fiscalement',
    [
      'Facilite l\'achat à plusieurs et la transmission (donation de parts)',
      'Les revenus sont imposés comme en nom propre, au prorata des parts',
      'Plus-value : régime des particuliers, mêmes abattements',
      'Formalités de constitution et comptabilité simplifiée à prévoir',
    ],
  ),
  Structure(
    'sciIS',
    "SCI à l'IS",
    "Société soumise à l'impôt sur les sociétés",
    [
      'Amortissement du bien déductible — fiscalité souvent allégée pendant la détention',
      'Plus-value à la revente calculée différemment, souvent plus taxée qu\'en nom propre',
      'Pertinent surtout pour un projet de réinvestissement long terme sans besoin de revenus immédiats',
      'Comptabilité commerciale obligatoire, plus complexe et coûteuse',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Typologie du logement
// ---------------------------------------------------------------------------

class Typology {
  final String id, label, pieces;
  final int capaciteDefaut;
  final double coefPrixM2, coefLoyerM2;
  const Typology(this.id, this.label, this.pieces, this.capaciteDefaut, this.coefPrixM2, this.coefLoyerM2);
}

const List<Typology> typologies = [
  Typology('studio', 'Studio', '1 pièce', 2, 1.15, 1.28),
  Typology('t1', 'T1', '1 pièce + coin nuit', 2, 1.10, 1.18),
  Typology('t2', 'T2', '2 pièces', 3, 1.00, 1.00),
  Typology('t3', 'T3', '3 pièces', 5, 0.93, 0.90),
  Typology('t4', 'T4', '4 pièces', 6, 0.88, 0.85),
  Typology('t5', 'T5+', '5 pièces ou +', 8, 0.82, 0.80),
];

/// Un logement loué à la nuitée, bien rempli, génère en général un équivalent
/// mensuel supérieur à un bail classique — coefficient indicatif.
const double primeCourteDuree = 1.8;

class ReferenceResult {
  final double prixM2, loyerM2, loyerMensuelRef, nuiteeRef;
  const ReferenceResult({
    required this.prixM2,
    required this.loyerM2,
    required this.loyerMensuelRef,
    required this.nuiteeRef,
  });
}

ReferenceResult? computeReferences(RefInfo? refInfo, Typology typology, double surface) {
  if (refInfo == null) return null;
  final prixM2 = refInfo.ref.prixM2 * typology.coefPrixM2;
  final loyerM2 = refInfo.ref.loyerM2 * typology.coefLoyerM2;
  final loyerMensuelRef = surface > 0 ? loyerM2 * surface : 0.0;
  final nuiteeRef = surface > 0 ? (loyerM2 * surface * primeCourteDuree) / 30 : 0.0;
  return ReferenceResult(
    prixM2: prixM2,
    loyerM2: loyerM2,
    loyerMensuelRef: loyerMensuelRef,
    nuiteeRef: nuiteeRef,
  );
}

// ---------------------------------------------------------------------------
// Localisation — repères de prix
// ---------------------------------------------------------------------------

class CityRef {
  final String name;
  final double prixM2, loyerM2;
  final bool tension;
  final double lat, lon;
  const CityRef(this.name, this.prixM2, this.loyerM2, this.tension, this.lat, this.lon);
}

/// Repère de prix : pas de données fiables gratuites au niveau du village
/// (trop peu de ventes pour une moyenne significative). On rattache la
/// commune choisie à la grande ville de référence la plus proche pour donner
/// un ordre de grandeur, sinon on retombe sur une moyenne nationale.
const CityRef nationalAvg = CityRef('Moyenne nationale', 3000, 14, false, 46.6, 2.2);

/// Un repère par département métropolitain (généralement sa préfecture) —
/// valeurs indicatives et arrondies, pas une donnée officielle temps réel
/// (voir l'avertissement affiché avec, dans l'onglet Marché/Carte). Alimente
/// à la fois le rattachement de commune (onglet Marché) et la carte de
/// France (onglet Carte).
const List<CityRef> frenchCities = [
  CityRef('Paris', 9500, 32, true, 48.8566, 2.3522),
  CityRef('Lyon', 5200, 16, true, 45.7640, 4.8357),
  CityRef('Marseille', 3400, 14, true, 43.2965, 5.3698),
  CityRef('Toulouse', 3600, 13.5, true, 43.6047, 1.4442),
  CityRef('Nice', 5300, 18, true, 43.7102, 7.2620),
  CityRef('Nantes', 3700, 13, true, 47.2184, -1.5536),
  CityRef('Strasbourg', 3300, 12.5, true, 48.5734, 7.7521),
  CityRef('Montpellier', 3600, 14, true, 43.6108, 3.8767),
  CityRef('Bordeaux', 4600, 15, true, 44.8378, -0.5792),
  CityRef('Lille', 3200, 13, true, 50.6292, 3.0573),
  CityRef('Rennes', 3500, 13, true, 48.1173, -1.6778),
  CityRef('Reims', 2400, 11, false, 49.2583, 4.0317),
  CityRef('Le Havre', 2100, 10, false, 49.4944, 0.1079),
  CityRef('Saint-Étienne', 1300, 8.5, false, 45.4397, 4.3872),
  CityRef('Toulon', 3300, 14, false, 43.1242, 5.9280),
  CityRef('Angers', 2900, 11.5, false, 47.4784, -0.5632),
  CityRef('Dijon', 2700, 11, false, 47.3220, 5.0415),
  CityRef('Limoges', 1600, 9, false, 45.8336, 1.2611),
  CityRef('Clermont-Ferrand', 2100, 10.5, false, 45.7772, 3.0870),
  CityRef('Le Mans', 1900, 9.5, false, 48.0061, 0.1996),
  CityRef('Bourg-en-Bresse', 2300, 10.5, false, 46.2058, 5.2255),
  CityRef('Laon', 1500, 8.5, false, 49.5642, 3.6203),
  CityRef('Moulins', 1400, 8, false, 46.5654, 3.3327),
  CityRef('Digne-les-Bains', 2100, 10, false, 44.0917, 6.2358),
  CityRef('Gap', 2400, 10.5, false, 44.5594, 6.0790),
  CityRef('Privas', 1700, 9, false, 44.7350, 4.5985),
  CityRef('Charleville-Mézières', 1400, 8, false, 49.7738, 4.7196),
  CityRef('Foix', 1600, 8.5, false, 42.9647, 1.6053),
  CityRef('Troyes', 1900, 9.5, false, 48.2973, 4.0744),
  CityRef('Carcassonne', 1900, 9.5, false, 43.2130, 2.3491),
  CityRef('Rodez', 1700, 8.5, false, 44.3506, 2.5744),
  CityRef('Caen', 2900, 12, true, 49.1829, -0.3707),
  CityRef('Aurillac', 1400, 8, false, 44.9245, 2.4433),
  CityRef('Angoulême', 1700, 9, false, 45.6484, 0.1560),
  CityRef('La Rochelle', 4600, 15, true, 46.1603, -1.1511),
  CityRef('Bourges', 1500, 8.5, false, 47.0810, 2.3988),
  CityRef('Tulle', 1300, 8, false, 45.2671, 1.7716),
  CityRef('Ajaccio', 3800, 14, true, 41.9192, 8.7386),
  CityRef('Bastia', 3200, 13, true, 42.7028, 9.4508),
  CityRef('Saint-Brieuc', 2100, 9.5, false, 48.5136, -2.7652),
  CityRef('Guéret', 1000, 7, false, 46.1667, 1.8667),
  CityRef('Périgueux', 1700, 9, false, 45.1847, 0.7214),
  CityRef('Besançon', 2400, 11, false, 47.2378, 6.0241),
  CityRef('Valence', 2200, 10.5, false, 44.9334, 4.8924),
  CityRef('Évreux', 1900, 10, false, 49.0270, 1.1510),
  CityRef('Chartres', 2300, 11, false, 48.4439, 1.4890),
  CityRef('Quimper', 2600, 10.5, false, 47.9960, -4.0972),
  CityRef('Nîmes', 2600, 12, true, 43.8367, 4.3601),
  CityRef('Auch', 1600, 8.5, false, 43.6459, 0.5860),
  CityRef('Châteauroux', 1200, 7.5, false, 46.8098, 1.6960),
  CityRef('Tours', 3000, 12, true, 47.3941, 0.6848),
  CityRef('Grenoble', 3100, 13.5, true, 45.1885, 5.7245),
  CityRef('Lons-le-Saunier', 1800, 9, false, 46.6742, 5.5522),
  CityRef('Mont-de-Marsan', 2000, 9.5, false, 43.8898, -0.4989),
  CityRef('Blois', 2000, 9.5, false, 47.5861, 1.3359),
  CityRef('Le Puy-en-Velay', 1500, 8, false, 45.0430, 3.8850),
  CityRef('Orléans', 2700, 11.5, true, 47.9029, 1.9093),
  CityRef('Cahors', 1700, 8.5, false, 44.4477, 1.4372),
  CityRef('Agen', 1700, 9, false, 44.2049, 0.6212),
  CityRef('Mende', 1500, 8, false, 44.5178, 3.5000),
  CityRef('Saint-Lô', 1700, 9, false, 49.1147, -1.0899),
  CityRef('Châlons-en-Champagne', 1700, 9, false, 48.9560, 4.3630),
  CityRef('Chaumont', 1300, 7.5, false, 48.1113, 5.1391),
  CityRef('Laval', 1900, 9.5, false, 48.0698, -0.7700),
  CityRef('Nancy', 2600, 11.5, true, 48.6921, 6.1844),
  CityRef('Bar-le-Duc', 1200, 7.5, false, 48.7714, 5.1608),
  CityRef('Vannes', 3600, 12.5, true, 47.6582, -2.7603),
  CityRef('Metz', 2300, 11, false, 49.1193, 6.1757),
  CityRef('Nevers', 1300, 8, false, 46.9896, 3.1590),
  CityRef('Beauvais', 2000, 10, false, 49.4295, 2.0807),
  CityRef('Alençon', 1500, 8, false, 48.4322, 0.0900),
  CityRef('Arras', 2300, 10.5, false, 50.2910, 2.7807),
  CityRef('Pau', 2600, 11, false, 43.2951, -0.3708),
  CityRef('Tarbes', 1700, 8.5, false, 43.2327, 0.0781),
  CityRef('Perpignan', 2400, 11.5, true, 42.6986, 2.8954),
  CityRef('Colmar', 3200, 12, true, 48.0794, 7.3585),
  CityRef('Vesoul', 1400, 8, false, 47.6167, 6.1546),
  CityRef('Mâcon', 2200, 10.5, false, 46.3067, 4.8283),
  CityRef('Chambéry', 3400, 13.5, true, 45.5646, 5.9178),
  CityRef('Annecy', 5300, 17, true, 45.8992, 6.1294),
  CityRef('Rouen', 2700, 11.5, true, 49.4431, 1.0993),
  CityRef('Melun', 3200, 13.5, true, 48.5389, 2.6600),
  CityRef('Versailles', 6500, 22, true, 48.8049, 2.1204),
  CityRef('Niort', 2100, 10, false, 46.3239, -0.4587),
  CityRef('Amiens', 2400, 11, false, 49.8941, 2.2958),
  CityRef('Albi', 1900, 9.5, false, 43.9298, 2.1480),
  CityRef('Montauban', 2100, 10, false, 44.0175, 1.3547),
  CityRef('Avignon', 2900, 12.5, true, 43.9493, 4.8055),
  CityRef('La Roche-sur-Yon', 2100, 10, false, 46.6705, -1.4266),
  CityRef('Poitiers', 2400, 11, false, 46.5802, 0.3404),
  CityRef('Épinal', 1500, 8, false, 48.1735, 6.4457),
  CityRef('Auxerre', 1800, 9, false, 47.7982, 3.5730),
  CityRef('Belfort', 1900, 9.5, false, 47.6379, 6.8630),
  CityRef('Évry-Courcouronnes', 3500, 15, true, 48.6303, 2.4406),
  CityRef('Nanterre', 6500, 24, true, 48.8924, 2.2065),
  CityRef('Bobigny', 4000, 17, true, 48.9092, 2.4394),
  CityRef('Créteil', 4500, 18, true, 48.7904, 2.4556),
  CityRef('Cergy', 3600, 15, true, 49.0364, 2.0770),
];

class RefInfo {
  final CityRef ref;
  final bool precise;
  const RefInfo({required this.ref, required this.precise});
}

RefInfo? nearestReference(CommuneRef? commune) {
  if (commune == null) return null;
  for (final c in frenchCities) {
    if (c.name.toLowerCase() == commune.nom.toLowerCase()) {
      return RefInfo(ref: c, precise: true);
    }
  }
  for (final c in frenchCities) {
    if (commune.departement.isNotEmpty &&
        c.name.toLowerCase() == commune.departement.toLowerCase()) {
      return RefInfo(ref: c, precise: false);
    }
  }
  return const RefInfo(ref: nationalAvg, precise: false);
}

// ---------------------------------------------------------------------------
// Comparatif longue vs courte durée (même bien)
// ---------------------------------------------------------------------------

class CompareResult {
  final CoreResult longue, courte;
  final RentalMode gagnant;
  final double ecartPct;
  const CompareResult({
    required this.longue,
    required this.courte,
    required this.gagnant,
    required this.ecartPct,
  });
}

CompareResult compareModes(PropertyInput form) {
  final longue = computeCore(form.copyWith(mode: RentalMode.longue));
  final courte = computeCore(form.copyWith(mode: RentalMode.courte));
  final gagnant = courte.net > longue.net ? RentalMode.courte : RentalMode.longue;
  final ecartPct =
      longue.net.abs() > 0.01 ? ((courte.net - longue.net) / longue.net.abs()) * 100 : 0.0;
  return CompareResult(longue: longue, courte: courte, gagnant: gagnant, ecartPct: ecartPct);
}
