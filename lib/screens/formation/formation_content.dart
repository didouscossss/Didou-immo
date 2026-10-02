import 'package:flutter/material.dart';

/// Une leçon — un titre et un contenu réel (pas un résumé d'une ligne comme
/// le Guide gratuit) : c'est le contenu payant, il doit tenir la promesse
/// "59 € et j'ai plein de choses derrière".
class FormationLesson {
  final String title;
  final String body;
  const FormationLesson(this.title, this.body);
}

class FormationModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<FormationLesson> lessons;
  /// "L'essentiel à retenir" — un court récapitulatif à puces affiché à la
  /// fin du module, dans la lecture leçon par leçon (voir
  /// `FormationModuleScreen`). Sert de synthèse mémorisable plutôt que de
  /// laisser le module se terminer sur une dernière leçon comme les autres
  /// — plus agréable à boucler, et ça donne un repère clair de ce qu'il
  /// faut retenir avant de passer au module suivant.
  final List<String> takeaways;
  const FormationModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.lessons,
    required this.takeaways,
  });
}

/// Contenu complet de la formation "Réussir son premier investissement
/// locatif" — 13 modules, du tout premier réflexe jusqu'à la revente, avec
/// 3 études de cas chiffrées pour voir la méthode appliquée de bout en
/// bout. Rédigé pour un débutant complet : chaque module renvoie, quand
/// c'est pertinent, vers l'onglet de l'app qui permet de mettre la notion
/// en pratique immédiatement (Didou-Immo n'est pas juste évoqué en intro,
/// il est le fil rouge de toute la formation).
const List<FormationModule> formationModules = [
  FormationModule(
    title: 'Avant de commencer',
    subtitle: "Ce que cette formation couvre, et comment t'en servir",
    icon: Icons.flag_outlined,
    color: Color(0xFF7C6FE0),
    takeaways: [
      "Suis les modules dans l'ordre pour ton premier projet.",
      "Garde Didou-Immo ouvert à côté pour chiffrer en même temps que tu apprends.",
      "Reviens sur un module précis plus tard, au moment où tu en as vraiment besoin.",
    ],
    lessons: [
      FormationLesson(
        'Ce que tu vas trouver ici',
        "Cette formation part du principe que tu n'as jamais acheté le moindre bien locatif. Elle couvre tout le "
            "chemin : définir ton projet et ton budget, trouver un bien, choisir la bonne zone, chiffrer sa "
            "rentabilité, le financer, gérer les travaux, comprendre la fiscalité, gérer le bien au quotidien, et "
            "penser le temps long jusqu'à une éventuelle revente. Ce n'est pas un recueil de théorie générale : "
            "chaque module donne des critères concrets et des pièges réels, pas des généralités qu'on retrouve "
            "partout sur internet.",
      ),
      FormationLesson(
        "Comment t'en servir",
        "Suis les modules dans l'ordre pour ton premier projet — chacun s'appuie sur le précédent. Garde "
            "Didou-Immo ouvert à côté : dès qu'un module te demande de chiffrer quelque chose (rentabilité, "
            "cash-flow, capacité d'emprunt...), fais-le en même temps dans l'app plutôt qu'en théorie — c'est "
            "exactement pour ça qu'elle existe. Reviens sur un module précis plus tard, au moment où tu en as "
            "réellement besoin (par exemple relire la fiscalité juste avant de signer) plutôt que de tout retenir "
            "d'un coup.",
      ),
    ],
  ),
  FormationModule(
    title: 'Les fondamentaux',
    subtitle: "Pourquoi investir, et dans quoi exactement",
    icon: Icons.foundation_outlined,
    color: Color(0xFF7C6FE0),
    takeaways: [
      "L'effet de levier du crédit est le vrai moteur de l'investissement locatif.",
      "Choisis ta stratégie (nue, LMNP, colocation, courte durée) selon le temps que tu peux y consacrer, pas "
          "seulement le rendement affiché.",
      "Décide cash-flow immédiat ou patrimoine long terme AVANT de chercher un bien, pas après.",
    ],
    lessons: [
      FormationLesson(
        "Pourquoi l'immobilier locatif plutôt qu'autre chose",
        "Trois mécanismes expliquent pourquoi l'immobilier reste un placement de choix pour se constituer un "
            "patrimoine : l'effet de levier du crédit (tu investis avec l'argent de la banque, pas seulement le "
            "tien), le remboursement du prêt par le loyer du locataire (ce n'est pas toi qui rembourses, c'est le "
            "marché locatif), et la revalorisation du bien dans le temps. En échange, c'est un placement peu "
            "liquide (on ne revend pas un appartement en un clic) et qui demande un minimum de temps de gestion — "
            "deux contreparties à accepter en connaissance de cause, pas des surprises à découvrir après coup.",
      ),
      FormationLesson(
        "Les grandes stratégies, et laquelle te correspond",
        "Location nue longue durée : la plus simple à démarrer, fiscalité basique (micro-foncier), mais "
            "rentabilité souvent plus faible et fiscalité qui devient vite pénalisante dès que les revenus "
            "montent.\n\n"
            "Location meublée (LMNP) : mêmes biens, mais la fiscalité au réel permet d'amortir le bien et le "
            "mobilier — souvent 0 € d'impôt sur les loyers pendant de nombreuses années. Un peu plus de gestion "
            "(mobilier à fournir, turnover de locataires parfois plus fréquent).\n\n"
            "Colocation : loyer total souvent supérieur à une location classique sur le même bien, mais gestion "
            "plus lourde (plusieurs baux ou un bail unique à gérer, turnover plus fréquent).\n\n"
            "Courte durée (type Airbnb) : rentabilité potentiellement la plus élevée dans les bonnes zones, mais "
            "gestion quasi quotidienne (ménage, clés, messages) et réglementation locale à vérifier avant tout "
            "achat (certaines villes limitent fortement la location saisonnière).\n\n"
            "Pour un premier projet, la location nue ou le LMNP restent les points d'entrée les plus raisonnables "
            "— le temps d'apprendre, avant d'envisager une stratégie plus exigeante en gestion.",
      ),
      FormationLesson(
        "Définir ton objectif avant de chercher un bien",
        "Deux objectifs très différents demandent des biens très différents. Viser le cash-flow (gagner de "
            "l'argent chaque mois dès maintenant) pousse vers des villes moyennes, des petites surfaces, un bon "
            "rendement locatif. Viser la plus-value et la constitution de patrimoine sur le long terme pousse "
            "plutôt vers des grandes villes dynamiques, quitte à accepter un cash-flow neutre ou légèrement "
            "négatif au départ. Il n'y a pas de bonne réponse universelle — il y a la tienne, en fonction de tes "
            "revenus actuels, ta capacité à encaisser un effort d'épargne mensuel, et ton horizon de temps. "
            "Tranche cette question avant de regarder la moindre annonce : elle détermine tout le reste.",
      ),
    ],
  ),
  FormationModule(
    title: 'Construire son projet et son budget',
    subtitle: "Combien emprunter, combien apporter, quels frais anticiper",
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF2FA39B),
    takeaways: [
      "La règle des 35 % d'endettement : vérifie ta capacité d'emprunt avant de chercher, pas après le coup de "
          "cœur.",
      "Un apport d'environ 10 % est souvent le minimum demandé pour un investissement locatif.",
      "Budgète TOUJOURS les frais annexes (notaire, dossier, travaux, ameublement) — jamais seulement le prix "
          "d'achat affiché.",
    ],
    lessons: [
      FormationLesson(
        "Combien peux-tu réellement emprunter",
        "Les banques appliquent en pratique la règle des 35 % d'endettement : tes mensualités de crédit (tous "
            "crédits compris, le nouveau comme les existants) ne doivent pas dépasser 35 % de tes revenus nets. "
            "Certains dossiers solides (hauts revenus, reste à vivre confortable) peuvent dépasser ce seuil, mais "
            "ne compte pas dessus par défaut. Utilise l'onglet « Capacité d'emprunt » de Didou-Immo pour estimer "
            "ce seuil avant même de chercher un bien — ça évite de tomber amoureux d'une annonce hors budget.",
      ),
      FormationLesson(
        "Apport personnel : combien, et faut-il tout miser",
        "Un apport de 10 % environ (pour couvrir les frais de notaire et de dossier) est souvent le minimum "
            "demandé par les banques pour un investissement locatif — contrairement à la résidence principale, "
            "où un financement à 110 % reste parfois possible. Mettre plus d'apport réduit la mensualité et donc "
            "le risque, mais réduit aussi l'effet de levier : chaque euro apporté est un euro qui ne travaille "
            "plus pour un futur projet. Il n'y a pas de règle absolue ; la bonne question est « combien puis-je "
            "apporter sans vider mon épargne de précaution (3 à 6 mois de charges) ? ».",
      ),
      FormationLesson(
        "Les frais qu'on oublie systématiquement",
        "Au-delà du prix affiché, un projet immobilier inclut toujours : les frais de notaire (7 à 8 % dans "
            "l'ancien, 2 à 3 % dans le neuf), les frais de dossier bancaire et de garantie (caution ou hypothèque), "
            "les frais de courtier si tu en utilises un, l'assurance emprunteur, les travaux (même « juste » un "
            "rafraîchissement), l'ameublement si tu loues meublé, et les premiers mois de charges de copropriété "
            "avant le premier loyer encaissé. Un budget qui ne prévoit que le prix d'achat est un budget faux — "
            "l'onglet « Bien » de Didou-Immo inclut ces frais par défaut (ajustables) pour cette raison précise.",
      ),
    ],
  ),
  FormationModule(
    title: 'Trouver le bon bien',
    subtitle: "Chercher, visiter, négocier — sans tomber dans les pièges classiques",
    icon: Icons.search,
    color: Color(0xFF3B82C4),
    takeaways: [
      "Combine plusieurs canaux de recherche, ne te limite jamais à un seul portail.",
      "Une annonce ne ment pas, mais elle ne dit jamais ce qui dessert la vente — pose les questions qui "
          "manquent.",
      "Demande toujours les 3 derniers procès-verbaux d'assemblée générale avant de t'engager.",
      "Négocie avec un chiffre et sa justification, jamais juste « je propose moins ».",
    ],
    lessons: [
      FormationLesson(
        "Où chercher",
        "Les portails d'annonces classiques (Leboncoin, SeLoger, Bien'ici...) restent le point de départ le plus "
            "simple, mais tu y es en concurrence avec tout le monde. Les notaires publient aussi des annonces, "
            "parfois moins disputées. Le réseau local (agents immobiliers que tu rappelles régulièrement, artisans, "
            "syndics de copropriété) fait souvent remonter des biens avant même leur publication — le fameux "
            "« off-market ». Les ventes aux enchères (notariales ou judiciaires) permettent des décotes réelles, "
            "mais demandent de l'expérience et un financement déjà bouclé avant l'enchère. Pour un premier achat, "
            "combine plusieurs canaux plutôt que de te limiter à un seul.",
      ),
      FormationLesson(
        "Lire une annonce entre les lignes",
        "Certaines formules reviennent souvent et méritent d'être creusées plutôt qu'ignorées : « à rafraîchir » "
            "ou « à personnaliser » signale des travaux au-delà d'une couche de peinture ; « idéal investisseur » "
            "peut signifier que le bien a un défaut qui rebute les acheteurs occupants (DPE, bruit, vis-à-vis) ; "
            "l'absence de mention du montant des charges de copropriété ou du DPE est un signal à vérifier avant "
            "la visite, pas après. Une annonce ne ment pas forcément, mais elle ne dit jamais ce qui dessert la "
            "vente — c'est à toi de poser les questions qui manquent.",
      ),
      FormationLesson(
        "Réussir sa visite",
        "Une visite ne sert pas qu'à se faire une impression générale — c'est le moment de vérifier "
            "concrètement : l'état de la toiture et des façades (vu depuis la rue si tu ne peux pas monter), des "
            "traces d'humidité ou de fissures, l'état des parties communes (un indicateur fiable de la santé de "
            "la copropriété), le bruit à différents moments de la journée si possible, la réception réseau/fibre, "
            "et le DPE réel du logement (pas celui d'un logement similaire de l'immeuble). Demande les 3 derniers "
            "procès-verbaux d'assemblée générale de copropriété avant de t'engager : c'est là que se cachent les "
            "travaux votés mais pas encore facturés, ou les procédures en cours.",
      ),
      FormationLesson(
        "Négocier le prix",
        "Un prix affiché n'est quasiment jamais un prix plancher. Les leviers de négociation les plus efficaces "
            "sont factuels, pas émotionnels : des travaux à prévoir (chiffrés par un devis, pas une estimation "
            "à la louche), un DPE pénalisant qui va limiter la location dans les prochaines années (voir le "
            "module Travaux), un délai de vente déjà long (vérifiable sur les portails, qui affichent parfois "
            "la date de première publication), ou une vente dans un contexte pressé (succession, divorce, "
            "mutation professionnelle). Arrive à la négociation avec un chiffre et sa justification, jamais avec "
            "un simple « je propose moins ».",
      ),
      FormationLesson(
        "Les pièges classiques du premier achat",
        "Le coup de cœur qui fait oublier de chiffrer — toujours passer par une vraie simulation de rentabilité "
            "avant de faire une offre, jamais après. Acheter dans une zone qu'on connaît mal simplement parce "
            "qu'elle est proche de chez soi, sans vérifier objectivement sa tension locative (module suivant). "
            "Sous-estimer systématiquement le montant des travaux (une règle simple : ajoute toujours une marge "
            "de sécurité de 15 à 20 % à n'importe quel devis). Négliger une copropriété en difficulté (charges "
            "qui s'envolent, procédures en cours) parce que le bien lui-même semblait en bon état. Vouloir aller "
            "trop vite sur un premier achat, alors que c'est justement celui où il faut prendre le plus de temps "
            "pour apprendre.",
      ),
    ],
  ),
  FormationModule(
    title: 'Bien choisir sa zone',
    subtitle: "Les critères objectifs, au-delà du coup de cœur",
    icon: Icons.location_on_outlined,
    color: Color(0xFF3B82C4),
    takeaways: [
      "Démographie, emploi, projets d'aménagement : des critères objectifs, pas un ressenti.",
      "Le meilleur choix n'est ni le rendement affiché le plus haut, ni la ville la plus connue — c'est le "
          "meilleur compromis entre les deux.",
      "Vérifie la tension locative réelle du secteur, pas seulement le prix au m².",
    ],
    lessons: [
      FormationLesson(
        "Les critères qui comptent vraiment",
        "Au-delà de l'impression générale, quelques indicateurs objectifs prédisent mieux la demande locative "
            "future : l'évolution démographique de la commune (une population qui croît signale une demande de "
            "logement qui croît aussi), le dynamisme de l'emploi local (bassin d'emploi diversifié, pas "
            "dépendant d'un seul employeur), la présence d'une université ou de grandes écoles (demande "
            "étudiante récurrente), les projets d'aménagement à venir (nouvelle ligne de transport, nouveau "
            "quartier d'affaires) qui annoncent une revalorisation avant qu'elle soit visible dans les prix, et "
            "la proximité immédiate des transports et commerces.",
      ),
      FormationLesson(
        "Où trouver ces données, gratuitement",
        "L'INSEE publie librement l'évolution démographique et les indicateurs socio-économiques par commune. "
            "Les sites des mairies et des intercommunalités détaillent souvent leurs projets d'aménagement en "
            "cours. Les notaires et observatoires locaux de l'immobilier publient des données de prix au m² "
            "fiables, complémentaires de celles déjà intégrées dans Didou-Immo. Et la carte des prix de l'app "
            "(onglet « Carte ») te permet de comparer plusieurs secteurs d'un coup d'œil, sans avoir à chercher "
            "commune par commune.",
      ),
      FormationLesson(
        "Tension locative vs prix d'achat : trouver l'équilibre",
        "Les villes les plus demandées (fort emploi, fort attrait) ont presque toujours les prix d'achat les "
            "plus élevés — ce qui écrase mécaniquement la rentabilité locative. À l'inverse, des villes moins "
            "prisées affichent des rendements affichés très attractifs, mais souvent parce que la demande "
            "locative y est faible (vacance locative plus longue entre deux locataires, loyers qui stagnent). Le "
            "bon raisonnement n'est pas « rendement le plus haut » ni « ville la plus connue », mais le meilleur "
            "compromis entre un rendement correct et une demande locative réelle et durable — vérifiable "
            "concrètement en comparant ton bien au marché local dans l'onglet « Marché ».",
      ),
      FormationLesson(
        "Grande ville ou ville moyenne ?",
        "Les grandes métropoles offrent une liquidité à la revente plus forte et une demande locative quasi "
            "garantie, au prix d'un ticket d'entrée élevé et d'un rendement souvent plus faible. Les villes "
            "moyennes dynamiques (bien desservies, avec un bassin d'emploi solide) permettent souvent un meilleur "
            "rendement et un ticket d'entrée plus accessible pour un premier projet, au prix d'une liquidité "
            "moindre à la revente et d'une demande locative à vérifier plus finement, quartier par quartier. "
            "Aucune des deux options n'est « la bonne » dans l'absolu — c'est un arbitrage à faire selon ton "
            "objectif défini au module 1 (cash-flow immédiat ou patrimoine long terme).",
      ),
    ],
  ),
  FormationModule(
    title: 'Évaluer la rentabilité',
    subtitle: "Les bons chiffres, et les hypothèses à ne pas survendre",
    icon: Icons.calculate_outlined,
    color: Color(0xFF4A9B6E),
    takeaways: [
      "La rentabilité brute sert à comparer vite entre biens — jamais à décider seule.",
      "Le cash-flow est le chiffre qui compte réellement, chaque mois, dans ton compte en banque.",
      "Teste toujours un scénario dégradé (stress-test) avant de signer quoi que ce soit.",
    ],
    lessons: [
      FormationLesson(
        "Rentabilité brute, nette, nette-nette : trois chiffres, trois usages",
        "La rentabilité brute (loyers annuels / prix d'achat) sert à comparer rapidement des biens entre eux, "
            "mais elle ignore toutes les charges — ne jamais décider sur ce seul chiffre. La rentabilité nette "
            "déduit les charges récurrentes (copropriété, gestion, assurance, taxe foncière) et donne une image "
            "bien plus réaliste. La rentabilité nette-nette (ou nette d'impôt) déduit en plus la fiscalité "
            "réellement payée selon ton régime — c'est elle qui détermine ce qu'il te reste vraiment en poche. "
            "Trois biens avec la même rentabilité brute peuvent avoir des rentabilités nette-nette très "
            "différentes selon leur fiscalité.",
      ),
      FormationLesson(
        "Le cash-flow : l'indicateur qui compte au quotidien",
        "La rentabilité est une mesure de performance sur le papier ; le cash-flow est ce qui tombe (ou sort) de "
            "ton compte en banque chaque mois, une fois le crédit et toutes les charges payés par le loyer. Un "
            "cash-flow positif signifie que le bien s'autofinance, voire te rapporte, dès le premier mois. Un "
            "cash-flow négatif signifie que tu dois compléter de ta poche chaque mois — ce qui peut rester un "
            "choix assumé pour un projet patrimonial long terme, mais ne doit jamais être une découverte après "
            "signature. C'est exactement le chiffre mis en avant en haut de l'onglet « Bien » de Didou-Immo.",
      ),
      FormationLesson(
        "Les hypothèses qu'on a tendance à survendre",
        "Un loyer basé sur l'annonce la plus optimiste du quartier plutôt que sur la moyenne réelle. Une vacance "
            "locative à 0 % (alors que compter 4 à 8 % par sécurité est la norme, même dans un marché tendu). Des "
            "charges de copropriété d'aujourd'hui, sans anticiper qu'elles augmentent presque toujours avec le "
            "temps. Aucun budget travaux imprévus sur la durée de détention. Un prix de revente qui suppose une "
            "hausse continue du marché. Un prévisionnel honnête teste systématiquement un scénario dégradé avant "
            "de signer — c'est le rôle du stress-test « Et si...? » de l'app : si le projet encaisse encore un "
            "taux plus élevé, une occupation plus faible et des travaux imprévus, c'est un bon signal.",
      ),
    ],
  ),
  FormationModule(
    title: 'Financer son projet',
    subtitle: "Dossier bancaire, taux, assurance, courtier",
    icon: Icons.account_balance_outlined,
    color: Color(0xFF5B6FD8),
    takeaways: [
      "Un dossier chiffré (vraie simulation de rentabilité) rassure plus qu'un projet présenté à l'oral.",
      "Compare toujours l'assurance emprunteur externe à celle de la banque — l'écart de prix est souvent "
          "significatif.",
      "Un courtier fait gagner du temps, surtout pour un premier projet où tu ne connais pas encore les usages.",
    ],
    lessons: [
      FormationLesson(
        "Ce qui rassure vraiment une banque",
        "Une banque prête à un dossier, pas seulement à un projet immobilier : des revenus stables (CDI, "
            "profession libérale installée), un taux d'endettement qui reste sous les 35 % une fois le nouveau "
            "crédit ajouté, une épargne de précaution qui subsiste après l'apport, et une gestion de comptes "
            "sans incident (découverts à répétition, par exemple) sur les derniers relevés. Un projet "
            "d'investissement locatif bien chiffré (avec une vraie simulation de rentabilité à présenter) "
            "rassure davantage qu'un projet présenté uniquement à l'oral.",
      ),
      FormationLesson(
        "Taux fixe, durée, assurance emprunteur",
        "En France, le taux fixe reste la norme et le choix le plus sûr pour un particulier : la mensualité ne "
            "bouge plus pendant toute la durée du prêt. Une durée plus longue réduit la mensualité (donc facilite "
            "l'octroi et améliore le cash-flow immédiat) mais augmente le coût total des intérêts — un arbitrage "
            "à faire les yeux ouverts, pas par défaut. L'assurance emprunteur peut être souscrite auprès d'un "
            "assureur externe plutôt que celui proposé par la banque (délégation d'assurance) : l'écart de prix "
            "est souvent significatif pour une couverture équivalente, à vérifier systématiquement.",
      ),
      FormationLesson(
        "Courtier : utile ou pas ?",
        "Un courtier démarche plusieurs banques à ta place, négocie le taux et les conditions (frais de dossier, "
            "assurance, indemnités de remboursement anticipé), et connaît les critères internes de chaque "
            "établissement — un gain de temps réel, en particulier pour un premier projet où tu ne connais pas "
            "encore les usages du secteur. Il est rémunéré par une commission (souvent prise en charge par la "
            "banque, parfois en partie par l'emprunteur selon les offres) : à clarifier avant de signer un mandat. "
            "Pour un dossier déjà solide et un emprunteur à l'aise avec la négociation, passer directement par sa "
            "propre banque et une ou deux concurrentes reste tout à fait possible.",
      ),
      FormationLesson(
        "Alternatives de montage à connaître",
        "Le prêt in fine (où seuls les intérêts sont remboursés chaque mois, le capital en une fois à "
            "l'échéance) peut optimiser la fiscalité dans certains régimes, au prix d'un coût total plus élevé — "
            "réservé à des profils avertis. L'achat à plusieurs (indivision ou SCI) permet de mutualiser l'apport "
            "et la capacité d'emprunt, mais demande un cadre juridique clair dès le départ (répartition, sortie "
            "d'un associé, désaccords) pour éviter les conflits plus tard. Pour un premier achat, un prêt "
            "amortissable classique, seul ou en couple, reste le montage le plus simple à maîtriser.",
      ),
    ],
  ),
  FormationModule(
    title: 'Travaux et rénovation',
    subtitle: "DPE, devis, phasage — ce qu'il faut vraiment anticiper",
    icon: Icons.construction_outlined,
    color: Color(0xFFE0705C),
    takeaways: [
      "Distingue toujours travaux obligatoires et travaux de valorisation dans ton budget.",
      "Le DPE est un enjeu réglementaire (interdictions progressives de location) autant que commercial.",
      "Au moins 2 à 3 devis avant de lancer un chantier significatif.",
      "Priorise les travaux qui conditionnent la mise en location pour limiter la vacance locative.",
    ],
    lessons: [
      FormationLesson(
        "Travaux obligatoires vs travaux de valorisation",
        "Certains travaux sont imposés par la réglementation ou la sécurité (mise aux normes électriques, "
            "présence de matériaux dangereux, DPE en dessous du seuil légal de location) et ne sont pas "
            "négociables avec le temps. D'autres sont des choix de valorisation (cuisine, salle de bain, "
            "peintures) qui augmentent le loyer potentiel et l'attractivité, mais restent un arbitrage "
            "coût/bénéfice à chiffrer précisément plutôt qu'une évidence. Distinguer les deux catégories dès le "
            "devis évite de tout mélanger dans un seul budget flou.",
      ),
      FormationLesson(
        "Le DPE : enjeu réglementaire autant que commercial",
        "Le Diagnostic de Performance Énergétique ne sert pas qu'à informer un futur locataire : la loi interdit "
            "déjà la location des logements classés G (depuis 2025 pour les logements neufs à la location), et "
            "interdira progressivement les F (2028) puis les E (2034). Un bien mal classé aujourd'hui peut donc "
            "devenir invendable en l'état, ou nécessiter des travaux de rénovation énergétique obligatoires avant "
            "de pouvoir être reloué. C'est à la fois un risque à anticiper et un levier de négociation à l'achat "
            "— un bien F ou G se négocie en intégrant le coût réel des travaux de mise aux normes à venir, pas "
            "seulement son prix affiché.",
      ),
      FormationLesson(
        "Obtenir des devis fiables",
        "Demande toujours au moins deux ou trois devis pour un chantier significatif — les écarts de prix entre "
            "artisans pour le même travail sont fréquemment importants. Un devis sérieux détaille les matériaux "
            "et la main d'œuvre séparément, précise un délai de réalisation, et porte les mentions légales de "
            "l'entreprise (SIRET, assurance décennale pour le gros œuvre). Méfie-toi d'un devis anormalement bas "
            "sans visite préalable du chantier, ou d'un artisan qui demande un acompte très élevé avant tout "
            "début de travaux.",
      ),
      FormationLesson(
        "Phaser les travaux pour limiter la vacance locative",
        "Chaque mois sans locataire pendant des travaux est un mois de crédit remboursé sans aucun loyer en face "
            "— un coût réel, souvent sous-estimé dans les plannings optimistes. Prioriser les travaux qui "
            "conditionnent la mise en location (sécurité, DPE, salle de bain/cuisine fonctionnelles) avant les "
            "finitions esthétiques permet de relouer plus vite et de financer les finitions restantes avec les "
            "premiers loyers encaissés, plutôt que d'immobiliser le bien plusieurs mois pour un chantier complet "
            "d'un coup.",
      ),
      FormationLesson(
        "Les aides disponibles, à vérifier avant de démarrer",
        "MaPrimeRénov' et l'éco-prêt à taux zéro (éco-PTZ) peuvent financer une partie significative de travaux "
            "de rénovation énergétique, sous conditions de ressources et de type de travaux — à vérifier sur le "
            "site officiel avant tout devis, les critères et montants évoluant régulièrement. Certaines "
            "collectivités locales proposent des aides complémentaires, propres à leur territoire. Ces aides "
            "demandent presque toujours de passer par un artisan certifié RGE (Reconnu Garant de "
            "l'Environnement) et de monter le dossier avant le démarrage des travaux, jamais après.",
      ),
    ],
  ),
  FormationModule(
    title: 'La fiscalité sans prise de tête',
    subtitle: "Les régimes expliqués simplement, pour choisir en connaissance de cause",
    icon: Icons.description_outlined,
    color: Color(0xFFD4A72C),
    takeaways: [
      "Le régime réel devient presque toujours plus avantageux que le micro dès qu'il y a un crédit en cours.",
      "Le LMNP au réel permet d'amortir — souvent 0 € d'impôt sur les loyers pendant plusieurs années.",
      "Le choix de la structure (nom propre, SCI à l'IR ou à l'IS) se décide AVANT l'achat, pas après.",
      "Garder un bien longtemps réduit aussi la fiscalité à la revente, jusqu'à l'exonération totale.",
    ],
    lessons: [
      FormationLesson(
        "Location nue : micro-foncier ou régime réel ?",
        "Le micro-foncier applique un abattement forfaitaire de 30 % sur les loyers perçus, sans aucune "
            "justification à fournir — simple, mais pénalisant dès que les charges réelles (intérêts d'emprunt, "
            "travaux, taxe foncière, assurance) dépassent ce forfait. Le régime réel déduit les charges réellement "
            "payées, souvent plus avantageux dès qu'il y a un crédit en cours (les intérêts sont déductibles) ou "
            "des travaux significatifs. Le régime réel peut même générer un déficit foncier imputable sur le "
            "revenu global, dans une certaine limite — un vrai levier fiscal, mais qui demande une vraie tenue de "
            "comptabilité, même simplifiée.",
      ),
      FormationLesson(
        "Location meublée (LMNP) : l'arme fiscale du débutant",
        "En LMNP au régime réel, le bien et le mobilier peuvent être amortis comptablement chaque année — une "
            "charge qui réduit le revenu imposable sans sortir d'argent de ta poche. Résultat fréquent : plusieurs "
            "années, parfois une décennie ou plus, sans aucun impôt sur les loyers perçus, alors que le cash-flow "
            "réel, lui, reste positif. Le régime micro-BIC (abattement forfaitaire de 50 %) reste plus simple "
            "mais, comme pour le micro-foncier, moins avantageux dès que les charges réelles et l'amortissement "
            "dépassent ce forfait — ce qui est très souvent le cas en LMNP.",
      ),
      FormationLesson(
        "SCI à l'IR ou à l'IS : à ne pas choisir à la légère",
        "Une SCI (Société Civile Immobilière) à l'impôt sur le revenu (IR) est fiscalement transparente : "
            "chaque associé est imposé comme s'il détenait le bien en direct, au prorata de ses parts — elle "
            "sert surtout à organiser la détention à plusieurs ou la transmission, pas à réduire l'impôt. Une SCI "
            "à l'impôt sur les sociétés (IS) permet d'amortir le bien comme en LMNP et d'appliquer un taux "
            "d'imposition sur les bénéfices souvent plus bas que la tranche marginale d'un particulier, mais la "
            "plus-value à la revente y est calculée très différemment (et souvent plus lourdement taxée) qu'en "
            "nom propre. Ce choix se décide avant l'achat, avec un professionnel — en changer après coup est "
            "complexe et coûteux.",
      ),
      FormationLesson(
        "La fiscalité à la revente",
        "La plus-value immobilière (prix de vente moins prix d'achat et frais, pour un bien détenu en nom "
            "propre) est taxée à 19 % au titre de l'impôt sur le revenu et 17,2 % au titre des prélèvements "
            "sociaux, mais un abattement pour durée de détention réduit progressivement cette taxation : "
            "l'exonération devient totale au bout de 22 ans pour l'impôt sur le revenu, et de 30 ans pour les "
            "prélèvements sociaux. Un bien gardé longtemps n'est donc pas seulement plus rentable en loyers "
            "cumulés, il l'est aussi fiscalement à la sortie. Ce calcul est fait automatiquement par l'onglet "
            "« Projection » de Didou-Immo pour n'importe quelle durée de détention simulée.",
      ),
    ],
  ),
  FormationModule(
    title: 'Gérer son bien au quotidien',
    subtitle: "De la mise en location à la relation avec le locataire",
    icon: Icons.vpn_key_outlined,
    color: Color(0xFF2FA39B),
    takeaways: [
      "Un dossier de locataire solide se vérifie sur des critères factuels, pas une impression.",
      "Un état des lieux précis et photographié est ta seule protection en cas de litige à la sortie.",
      "Un loyer impayé se traite tout de suite — relance, mise en demeure, garantie — jamais en espérant que ça "
          "s'arrange.",
    ],
    lessons: [
      FormationLesson(
        "Gestion directe ou agence ?",
        "Gérer soi-même économise les frais de gestion (généralement 5 à 10 % des loyers), mais demande du temps "
            "réel : rédiger et diffuser l'annonce, sélectionner un locataire, rédiger le bail, faire l'état des "
            "lieux, être disponible en cas d'incident. Passer par une agence coûte ces frais en continu, mais "
            "délègue tout ce processus et peut rassurer un propriétaire éloigné géographiquement du bien ou peu "
            "disponible. Un compromis existe : confier uniquement la mise en location initiale (recherche de "
            "locataire) à une agence, puis gérer soi-même le quotidien une fois le bail signé.",
      ),
      FormationLesson(
        "Trouver et choisir un bon locataire",
        "Un dossier solide se vérifie sur des critères factuels : revenus représentant généralement 3 fois le "
            "loyer charges comprises, stabilité professionnelle, et pièces justificatives cohérentes entre elles "
            "(ne jamais se contenter d'une seule pièce, et rester attentif à des documents qui semblent modifiés). "
            "La loi encadre strictement les pièces qu'un propriétaire peut demander — se renseigner sur cette "
            "liste évite à la fois un refus illégal et un dossier insuffisant. Une assurance loyers impayés (GLI) "
            "ou la caution Visale pour les profils éligibles (notamment les jeunes actifs) sécurisent le loyer "
            "même en cas d'incident, moyennant un coût ou des critères d'éligibilité à vérifier en amont.",
      ),
      FormationLesson(
        "Bail, état des lieux, dépôt de garantie : les bases",
        "Le bail (contrat de location) encadre les droits et obligations des deux parties — utiliser un modèle "
            "conforme à la réglementation en vigueur plutôt qu'un document trouvé au hasard évite des clauses "
            "invalides. L'état des lieux d'entrée, précis et si possible photographié pièce par pièce, est la "
            "seule preuve opposable en cas de litige sur les dégradations à la sortie — un état des lieux bâclé "
            "coûte cher au moment de restituer (ou non) le dépôt de garantie. Celui-ci (un mois de loyer hors "
            "charges en location nue, jusqu'à deux en meublé) doit être restitué dans des délais légaux précis, "
            "déductions faites des réparations justifiées par l'état des lieux de sortie.",
      ),
      FormationLesson(
        "Gérer les imprévus",
        "Un loyer impayé se traite vite : relance amiable immédiate, puis mise en demeure, et activation de la "
            "garantie (GLI ou Visale) si le retard persiste — attendre « que ça se arrange tout seul » est "
            "l'erreur la plus coûteuse. Une panne ou une dégradation urgente (chauffage, dégât des eaux) engage "
            "la responsabilité du propriétaire pour les réparations qui relèvent de la structure du logement, "
            "pas de l'usage courant par le locataire — distinguer les deux évite des conflits inutiles. Garder "
            "une petite réserve de trésorerie dédiée à chaque bien (quelques centaines d'euros) absorbe ces "
            "imprévus sans déséquilibrer ton budget personnel.",
      ),
    ],
  ),
  FormationModule(
    title: 'Penser sur le long terme',
    subtitle: "Faire grossir son patrimoine, et savoir quand revendre",
    icon: Icons.trending_up,
    color: Color(0xFF4A9B6E),
    takeaways: [
      "Chaque bien remboursé augmente ta capacité à en financer un nouveau — c'est l'effet boule de neige.",
      "Simule la revente à plusieurs horizons (5, 10, 15 ans), jamais à une seule date arbitraire.",
      "Continue à te former après le premier achat : la réglementation (fiscale, énergétique) change en "
          "continu.",
    ],
    lessons: [
      FormationLesson(
        "Faire grossir son patrimoine : l'effet boule de neige",
        "Chaque bien remboursé (en totalité ou en grande partie) par ses propres loyers augmente ta capacité à "
            "en financer un second : la banque regarde le patrimoine déjà constitué et les revenus locatifs "
            "existants, pas seulement tes revenus du travail. Le refinancement (renégocier ou racheter un crédit "
            "une fois le bien revalorisé) permet parfois de dégager un nouvel apport sans vendre le bien "
            "d'origine. C'est ce mécanisme, répété, qui transforme un premier investissement modeste en un vrai "
            "patrimoine au fil des années — rarement un seul « coup » spectaculaire.",
      ),
      FormationLesson(
        "Quand et comment revendre",
        "Revendre a du sens quand la plus-value nette (après fiscalité, voir le module précédent) dépasse "
            "clairement ce que le bien continuerait de rapporter en le gardant, ou quand il ne correspond plus à "
            "ta stratégie (zone qui se dégrade, gestion devenue trop lourde, besoin de liquidités pour un autre "
            "projet). À l'inverse, revendre trop tôt (avant 22 ans de détention) sacrifie une partie de "
            "l'abattement fiscal pour rien si aucune raison concrète ne pousse à la vente. Simule toujours la "
            "revente à plusieurs horizons (5, 10, 15 ans) plutôt qu'à une seule date arbitraire — c'est "
            "exactement ce que permet l'onglet « Projection » de l'app.",
      ),
      FormationLesson(
        "Les erreurs qui coûtent cher sur 10 à 20 ans",
        "Ne jamais réévaluer un bien après l'achat (ni son loyer, ni son régime fiscal, ni son état) alors que "
            "le marché et la réglementation évoluent en continu. Garder un crédit à un taux largement supérieur "
            "au marché sans jamais étudier un rachat ou une renégociation. Négliger l'entretien courant jusqu'à "
            "ce qu'il faille des travaux lourds et urgents, plus coûteux que des travaux anticipés. Concentrer "
            "tout son patrimoine sur une seule ville ou un seul type de bien, sans aucune diversification "
            "géographique une fois plusieurs projets réalisés. Et surtout : arrêter de se former une fois le "
            "premier bien acheté, alors que la réglementation (fiscale, énergétique, locative) continue de "
            "changer après.",
      ),
    ],
  ),
  FormationModule(
    title: 'Études de cas chiffrées',
    subtitle: "La méthode appliquée de bout en bout, sur 3 profils différents",
    icon: Icons.insights_outlined,
    color: Color(0xFFD4A72C),
    takeaways: [
      "Le même raisonnement s'applique à chaque bien : décrire, chiffrer, vérifier le marché, stress-tester, "
          "lire le verdict.",
      "Un rendement affiché élevé ne garantit rien si le cash-flow réel est négatif ou le DPE bloquant.",
      "Reproduis ces simulations toi-même dans Didou-Immo avant de les croire sur parole — c'est un exemple "
          "pédagogique, pas une offre réelle.",
    ],
    lessons: [
      FormationLesson(
        "Cas n°1 — Le T2 pensé pour le cash-flow (ville moyenne)",
        "Exemple fictif, construit pour illustrer la méthode. T2 de 60 m² dans une ville moyenne dynamique, "
            "acheté 98 000 €, 6 000 € de travaux de rafraîchissement, environ 7 800 € de frais de notaire (8 % "
            "dans l'ancien). Coût total du projet : environ 112 000 €.\n\n"
            "Financement : 12 000 € d'apport, le reste emprunté sur 20 ans à un taux illustratif de 3,9 %, soit "
            "une mensualité (assurance comprise) d'environ 580 €/mois.\n\n"
            "Revenus : loyer attendu 540 €/mois, vacance locative comptée à 5 % par sécurité, charges de "
            "copropriété 600 €/an, taxe foncière 700 €/an, assurance PNO 150 €/an.\n\n"
            "Une fois toutes les charges et le crédit déduits, le cash-flow ressort proche de l'équilibre, "
            "légèrement négatif avant impôt. En LMNP au régime réel, l'amortissement du bien et du mobilier "
            "ramène l'impôt sur les loyers à 0 € les premières années — le cash-flow réel redevient positif. "
            "Rentabilité brute : environ 6,6 %, dans la moyenne haute pour ce type de ville.\n\n"
            "Verdict : un projet solide pour du cash-flow raisonnable, à condition de bien suivre la fiscalité "
            "LMNP dès le départ (voir module Fiscalité) plutôt que de la découvrir après coup.",
      ),
      FormationLesson(
        "Cas n°2 — Le studio meublé en grande ville (stratégie patrimoniale)",
        "Exemple fictif. Studio de 20 m² à proximité immédiate d'une université dans une grande ville, acheté "
            "140 000 € frais compris, aucun travaux nécessaire. Loyer meublé attendu : 520 €/mois, tension "
            "locative très forte (quasiment aucune vacance attendue grâce à la demande étudiante).\n\n"
            "Financement à 90 % sur 25 ans : la mensualité absorbe la quasi-totalité du loyer, laissant un "
            "cash-flow neutre à légèrement négatif chaque mois. Rentabilité brute modeste, autour de 4,5 % — "
            "nettement moins attractive que le cas n°1 sur ce seul critère.\n\n"
            "Pourtant, ce projet peut avoir du sens : en LMNP réel, l'amortissement annule l'impôt sur des "
            "loyers déjà quasi intégralement absorbés par le crédit, et la zone, très demandée, limite "
            "fortement le risque de vacance et soutient la revalorisation du bien dans le temps.\n\n"
            "Verdict : un projet cohérent pour quelqu'un qui vise la plus-value et la constitution de "
            "patrimoine sur 15-20 ans (objectif défini au module 1), pas pour quelqu'un qui cherche un "
            "complément de revenu immédiat. Le même bien serait un mauvais choix pour l'objectif inverse — ce "
            "n'est pas le bien qui est bon ou mauvais dans l'absolu, c'est son adéquation avec ton objectif.",
      ),
      FormationLesson(
        "Cas n°3 — Le bien à éviter, malgré un rendement affiché très attractif",
        "Exemple fictif. T3 dans une ville en déclin démographique, affiché à 60 000 €, loyer annoncé 550 "
            "€/mois — soit une rentabilité brute affichée de 11 %, largement au-dessus des deux cas précédents. "
            "Sur le seul critère du rendement affiché, ce bien semble imbattable.\n\n"
            "En creusant : le DPE est classé F, ce qui impose des travaux de rénovation énergétique avant de "
            "pouvoir continuer à le louer légalement dans les prochaines années — un budget travaux non prévu "
            "d'environ 15 000 €, absent du calcul initial. La commune perd des habitants depuis plusieurs "
            "années, ce qui se traduit en pratique par une vacance locative réelle bien plus élevée que la "
            "moyenne (observée autour de 15 à 20 % par les investisseurs déjà présents sur place, contre 4 à 8 "
            "% ailleurs). La copropriété, ancienne, vote des charges en hausse régulière.\n\n"
            "Une fois le budget travaux et la vacance réelle intégrés, le cash-flow devient nettement négatif, "
            "et la rentabilité réelle tombe largement sous celle des deux cas précédents.\n\n"
            "Verdict : risqué. C'est exactement le type de biens évoqué au module « Trouver le bon bien » — un "
            "rendement affiché élevé qui cache des problèmes structurels (DPE, démographie, copropriété) "
            "invisibles tant qu'on ne regarde que le loyer et le prix. Un simple chiffrage dans Didou-Immo, DPE "
            "et vacance réaliste inclus, aurait suffi à voir le problème avant de visiter.",
      ),
    ],
  ),
  FormationModule(
    title: 'Checklist finale et glossaire',
    subtitle: "Avant de signer, et les mots qu'il faut connaître",
    icon: Icons.fact_check_outlined,
    color: Color(0xFF2F5D50),
    takeaways: [
      "Si une seule case de la checklist n'est pas cochée, ce n'est pas encore le moment de signer.",
      "Garde le glossaire sous la main pour tes premiers rendez-vous (banque, notaire, agence).",
      "Relis le module qui te concerne juste avant d'en avoir besoin, plutôt que de tout retenir d'un coup.",
    ],
    lessons: [
      FormationLesson(
        "Checklist avant de signer",
        "As-tu simulé la rentabilité ET le cash-flow, pas seulement la rentabilité brute ? As-tu testé un "
            "scénario dégradé (stress-test) et le projet reste-t-il tenable ? As-tu vérifié le DPE et son impact "
            "réglementaire sur les prochaines années ? As-tu lu les 3 derniers procès-verbaux d'assemblée "
            "générale de copropriété ? As-tu un financement déjà accepté ou au moins une simulation bancaire "
            "sérieuse ? As-tu chiffré TOUS les frais annexes, pas seulement le prix d'achat ? As-tu choisi ton "
            "régime fiscal en connaissance de cause plutôt que par défaut ? Si une seule réponse est non, ce "
            "n'est pas encore le moment de signer.",
      ),
      FormationLesson(
        "Glossaire des termes essentiels",
        "Rentabilité brute / nette / nette-nette : voir module 5.\n\n"
            "Cash-flow : ce qu'il reste (ou manque) chaque mois après crédit et charges.\n\n"
            "LMNP : Loueur en Meublé Non Professionnel — régime fiscal de la location meublée.\n\n"
            "DPE : Diagnostic de Performance Énergétique, obligatoire et de plus en plus déterminant pour le "
            "droit de louer.\n\n"
            "TMI : Tranche Marginale d'Imposition, le taux qui s'applique à la dernière tranche de tes revenus.\n\n"
            "PNO : assurance Propriétaire Non Occupant, qui couvre le logement loué ou vacant.\n\n"
            "GLI : Garantie Loyers Impayés, une assurance qui couvre le propriétaire en cas d'impayé.\n\n"
            "TAEG : Taux Annuel Effectif Global, le coût réel total du crédit (taux + assurance + frais).\n\n"
            "Taux d'usure : le plafond légal que le TAEG ne peut pas dépasser, publié chaque trimestre par la "
            "Banque de France.",
      ),
    ],
  ),
];
