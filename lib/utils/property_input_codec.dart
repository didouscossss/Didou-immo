import '../utils/calculations.dart';

/// (Dé)sérialisation JSON de [PropertyInput] — utilisée pour la persistance
/// locale des biens enregistrés (équivalent du `JSON.stringify(biens)` /
/// `window.storage` du prototype).
extension PropertyInputCodec on PropertyInput {
  Map<String, dynamic> toJson() => {
        'nom': nom,
        'mode': mode.name,
        'commune': commune == null
            ? null
            : {
                'nom': commune!.nom,
                'codePostal': commune!.codePostal,
                'departement': commune!.departement,
                'population': commune!.population,
                'codeInsee': commune!.codeInsee,
                'codeDepartement': commune!.codeDepartement,
              },
        'surface': surface,
        'typeBien': typeBien,
        'capacite': capacite,
        'meuble': meuble,
        'prix': prix,
        'notaire': notaire,
        'travaux': travaux,
        'notaireAuto': notaireAuto,
        'travauxAuto': travauxAuto,
        'achete': achete,
        'dateAchat': dateAchat?.toIso8601String(),
        'vendu': vendu,
        'dateVente': dateVente?.toIso8601String(),
        'prixVente': prixVente,
        'suivi': suivi
            .map((s) => {
                  'dateDebut': s.dateDebut.toIso8601String(),
                  'dateFin': s.dateFin?.toIso8601String(),
                  'loyerPercu': s.loyerPercu,
                  'chargesCoproReelles': s.chargesCoproReelles,
                  'taxeFonciereReelle': s.taxeFonciereReelle,
                  'assuranceReelle': s.assuranceReelle,
                  'vacant': s.vacant,
                  'travauxImprevus': s.travauxImprevus,
                  'note': s.note,
                })
            .toList(),
        'residencePrincipale': residencePrincipale,
        'loyer': loyer,
        'vacancePct': vacancePct,
        'chargesCopro': chargesCopro,
        'gestion': gestion,
        'prixNuitBasse': prixNuitBasse,
        'prixNuitHaute': prixNuitHaute,
        'nuitsBasseSaison': nuitsBasseSaison,
        'nuitsHauteSaison': nuitsHauteSaison,
        'dureeSejourMoyenne': dureeSejourMoyenne,
        'commissionPct': commissionPct,
        'menagePartReservation': menagePartReservation,
        'abonnements': abonnements,
        'ameublementAnnuel': ameublementAnnuel,
        'taxeSejour': taxeSejour,
        'taxeFonciere': taxeFonciere,
        'assurance': assurance,
        'dpe': dpe,
        'apport': apport,
        'tauxPct': tauxPct,
        'dureePretAns': dureePretAns,
        'offres': offres
            .map((o) => {
                  'id': o.id,
                  'nom': o.nom,
                  'tauxPct': o.tauxPct,
                  'dureePretAns': o.dureePretAns,
                  'assurancePct': o.assurancePct,
                })
            .toList(),
        'revenuMensuelNet': revenuMensuelNet,
        'chargesCreditExistantes': chargesCreditExistantes,
        'tmi': tmi,
        'dureeProjection': dureeProjection,
        'croissanceLoyer': croissanceLoyer,
        'croissanceValeur': croissanceValeur,
        'fraisAgenceRevente': fraisAgenceRevente,
      };

  static PropertyInput fromJson(Map<String, dynamic> json) {
    final communeJson = json['commune'] as Map<String, dynamic>?;
    return PropertyInput(
      nom: json['nom'] as String? ?? '',
      mode: RentalMode.values.firstWhere(
        (m) => m.name == json['mode'],
        orElse: () => RentalMode.longue,
      ),
      commune: communeJson == null
          ? null
          : CommuneRef(
              nom: communeJson['nom'] as String? ?? '',
              codePostal: communeJson['codePostal'] as String? ?? '',
              departement: communeJson['departement'] as String? ?? '',
              population: (communeJson['population'] as num?)?.toInt() ?? 0,
              codeInsee: communeJson['codeInsee'] as String? ?? '',
              codeDepartement: communeJson['codeDepartement'] as String? ?? '',
            ),
      surface: (json['surface'] as num?)?.toDouble() ?? 0,
      typeBien: json['typeBien'] as String? ?? 't2',
      capacite: (json['capacite'] as num?)?.toDouble() ?? 3,
      meuble: json['meuble'] as bool? ?? false,
      prix: (json['prix'] as num?)?.toDouble() ?? 0,
      notaire: (json['notaire'] as num?)?.toDouble() ?? 0,
      travaux: (json['travaux'] as num?)?.toDouble() ?? 0,
      // `false` par défaut pour les biens déjà enregistrés avant l'ajout de
      // ce calcul auto (champ absent du JSON) : on ne veut pas se mettre à
      // recalculer silencieusement une valeur que l'utilisateur avait
      // saisie lui-même.
      notaireAuto: json['notaireAuto'] as bool? ?? false,
      travauxAuto: json['travauxAuto'] as bool? ?? false,
      achete: json['achete'] as bool? ?? false,
      dateAchat: json['dateAchat'] != null ? DateTime.tryParse(json['dateAchat'] as String) : null,
      vendu: json['vendu'] as bool? ?? false,
      dateVente: json['dateVente'] != null ? DateTime.tryParse(json['dateVente'] as String) : null,
      prixVente: (json['prixVente'] as num?)?.toDouble(),
      suivi: (json['suivi'] as List?)
              ?.map((s) => SuiviEntry(
                    // `date` : ancien format (avant l'introduction des
                    // périodes dateDebut/dateFin) — les relevés déjà
                    // enregistrés deviennent des périodes ponctuelles sans
                    // date de fin connue, plutôt que d'être perdus.
                    dateDebut: DateTime.tryParse((s['dateDebut'] ?? s['date']) as String? ?? '') ?? DateTime.now(),
                    dateFin: s['dateFin'] != null ? DateTime.tryParse(s['dateFin'] as String) : null,
                    loyerPercu: (s['loyerPercu'] as num?)?.toDouble(),
                    chargesCoproReelles: (s['chargesCoproReelles'] as num?)?.toDouble() ?? (s['chargesReelles'] as num?)?.toDouble(),
                    taxeFonciereReelle: (s['taxeFonciereReelle'] as num?)?.toDouble(),
                    assuranceReelle: (s['assuranceReelle'] as num?)?.toDouble(),
                    vacant: s['vacant'] as bool? ?? false,
                    travauxImprevus: (s['travauxImprevus'] as num?)?.toDouble(),
                    note: s['note'] as String?,
                  ))
              .toList() ??
          const [],
      residencePrincipale: json['residencePrincipale'] as bool? ?? false,
      loyer: (json['loyer'] as num?)?.toDouble() ?? 0,
      vacancePct: (json['vacancePct'] as num?)?.toDouble() ?? 0,
      chargesCopro: (json['chargesCopro'] as num?)?.toDouble() ?? 0,
      gestion: (json['gestion'] as num?)?.toDouble() ?? 0,
      prixNuitBasse: (json['prixNuitBasse'] as num?)?.toDouble() ?? 0,
      prixNuitHaute: (json['prixNuitHaute'] as num?)?.toDouble() ?? 0,
      nuitsBasseSaison: (json['nuitsBasseSaison'] as num?)?.toInt() ?? 0,
      nuitsHauteSaison: (json['nuitsHauteSaison'] as num?)?.toInt() ?? 0,
      dureeSejourMoyenne: (json['dureeSejourMoyenne'] as num?)?.toDouble() ?? 1,
      commissionPct: (json['commissionPct'] as num?)?.toDouble() ?? 0,
      menagePartReservation: (json['menagePartReservation'] as num?)?.toDouble() ?? 0,
      abonnements: (json['abonnements'] as num?)?.toDouble() ?? 0,
      ameublementAnnuel: (json['ameublementAnnuel'] as num?)?.toDouble() ?? 0,
      taxeSejour: (json['taxeSejour'] as num?)?.toDouble() ?? 0,
      taxeFonciere: (json['taxeFonciere'] as num?)?.toDouble() ?? 0,
      assurance: (json['assurance'] as num?)?.toDouble() ?? 0,
      dpe: json['dpe'] as String? ?? 'D',
      apport: (json['apport'] as num?)?.toDouble() ?? 0,
      tauxPct: (json['tauxPct'] as num?)?.toDouble() ?? 0,
      dureePretAns: (json['dureePretAns'] as num?)?.toInt() ?? 20,
      offres: (json['offres'] as List?)
              ?.map((o) => LoanOffer(
                    id: (o['id'] as num).toInt(),
                    nom: o['nom'] as String? ?? '',
                    tauxPct: (o['tauxPct'] as num?)?.toDouble() ?? 0,
                    dureePretAns: (o['dureePretAns'] as num?)?.toInt() ?? 20,
                    assurancePct: (o['assurancePct'] as num?)?.toDouble() ?? 0,
                  ))
              .toList() ??
          const [],
      revenuMensuelNet: (json['revenuMensuelNet'] as num?)?.toDouble() ?? 0,
      chargesCreditExistantes: (json['chargesCreditExistantes'] as num?)?.toDouble() ?? 0,
      tmi: (json['tmi'] as num?)?.toDouble() ?? 30,
      dureeProjection: (json['dureeProjection'] as num?)?.toInt() ?? 15,
      croissanceLoyer: (json['croissanceLoyer'] as num?)?.toDouble() ?? 1.5,
      croissanceValeur: (json['croissanceValeur'] as num?)?.toDouble() ?? 2,
      fraisAgenceRevente: (json['fraisAgenceRevente'] as num?)?.toDouble() ?? 5,
    );
  }
}
