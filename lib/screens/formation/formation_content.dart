import 'package:flutter/material.dart';

/// Une leçon — un titre et un contenu réel (pas un résumé d'une ligne comme
/// le Guide gratuit) : c'est le contenu payant, il doit tenir la promesse
/// "59 € et j'ai plein de choses derrière".
class FormationLesson {
  final String title;
  final String body;
  const FormationLesson(this.title, this.body);
}

/// Une des réponses proposées à une question de quiz — qu'elle soit la
/// bonne ou non, elle porte toujours sa propre explication : demandé par
/// l'utilisateur pour qu'une mauvaise réponse explique pourquoi ce n'est
/// pas la bonne, pas seulement "faux, réessaie".
class FormationQuizOption {
  final String text;
  final bool correct;
  final String explanation;
  const FormationQuizOption({required this.text, required this.correct, required this.explanation});
}

/// Une question de quiz — toujours une mise en situation concrète plutôt
/// qu'une question de cours ("Qu'est-ce que le LMNP ?"), pour vérifier que
/// la notion est comprise au-delà de la définition.
class FormationQuizQuestion {
  final String scenario;
  final List<FormationQuizOption> options;
  const FormationQuizQuestion({required this.scenario, required this.options});
}

class FormationModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<FormationLesson> lessons;
  /// Quiz de fin de module — mises en situation avec explications
  /// (voir [FormationQuizQuestion]). Vide (par défaut) pour les modules qui
  /// n'en ont pas besoin (l'intro, et le récapitulatif final).
  final List<FormationQuizQuestion> quiz;
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
    this.quiz = const [],
    required this.takeaways,
  });
}

/// Contenu complet de la formation "Réussir son premier investissement
/// locatif" — 13 modules, du tout premier réflexe jusqu'à la revente, avec
/// 4 études de cas chiffrées pour voir la méthode appliquée de bout en
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
      FormationLesson(
        "Exemples concrets — deux bons choix, et une erreur à ne pas reproduire",
        "✅ Claire, 32 ans, 2 500 €/mois de revenus, achète un T2 à 85 000 € dans une ville moyenne. Loyer 480 "
            "€/mois, cash-flow positif dès le premier mois (+60 €/mois environ). Bon choix : cohérent avec son "
            "objectif assumé de compléter son revenu tout de suite.\n\n"
            "✅ Marc, 45 ans, revenus confortables, achète un deux-pièces à 210 000 € dans une grande ville "
            "dynamique. Cash-flow légèrement négatif (-40 €/mois) mais plus-value attendue forte sur 15 ans. Bon "
            "choix aussi — cohérent avec SON objectif à lui, préparer sa retraite, pas avec celui de Claire.\n\n"
            "❌ Julien copie à l'identique le projet de son collègue — un immeuble de rapport en zone rurale, "
            "rendement affiché à 9 % — sans avoir ni le temps de le gérer à 3 heures de route de chez lui, ni "
            "le même objectif patrimonial. Deux ans plus tard, usé par la gestion à distance et des loyers "
            "irréguliers, il revend à perte. L'erreur n'était pas le bien en lui-même : c'était de copier un "
            "projet qui ne correspondait ni à son temps disponible, ni à son objectif.",
      ),
      FormationLesson(
        "Qui fait quoi autour de toi",
        "Le notaire authentifie la vente et perçoit les frais de mutation (reversés en grande partie à l'État "
            "et aux collectivités, pas à lui) — tu peux en choisir un différent de celui du vendeur, sans "
            "surcoût, les deux se partageant alors les honoraires. L'agent immobilier représente généralement "
            "le vendeur (c'est lui qui le rémunère, même quand les frais d'agence sont affichés « à la charge "
            "de l'acquéreur ») : utile pour trouver un bien, mais garde à l'esprit que son intérêt n'est pas "
            "automatiquement aligné avec le tien lors de la négociation. Le courtier en financement travaille, "
            "lui, pour toi : il démarche les banques à ta place. L'expert-comptable n'est pas obligatoire mais "
            "devient vite rentable dès le régime réel ou le LMNP (voir le module Fiscalité). Savoir qui "
            "défend tes intérêts, et qui défend ceux de quelqu'un d'autre, évite bien des malentendus.",
      ),
      FormationLesson(
        "Combien de temps ça prend, réellement",
        "Compte en moyenne 3 à 6 mois entre le début de la recherche sérieuse et la signature définitive pour "
            "un premier achat — parfois plus dans un marché tendu où les bons biens partent vite, parfois "
            "moins si tu es très réactif et déjà prêt financièrement. La gestion ensuite, une fois le bien "
            "loué et stabilisé, représente en réalité peu de temps au quotidien (quelques heures par mois en "
            "gestion directe, pour les messages, le suivi des paiements et l'administratif courant), avec des "
            "pics ponctuels lors d'un changement de locataire ou d'un imprévu. C'est un projet qui demande de "
            "la disponibilité en amont (recherche, visites, montage du dossier) bien plus qu'au quotidien une "
            "fois en place — prévoir ce rythme dès le départ évite l'épuisement ou l'abandon en cours de route.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Un ami te propose de racheter avec lui l'immeuble de rapport qu'il vient de visiter : "
            "rendement affiché 9 %, mais à 2h30 de route de chez toi et avec de la gestion quotidienne "
            "(colocation, turnover fréquent). Tu n'as ni le temps libre ni l'envie de gérer ça à distance. "
            "Que fais-tu ?",
        options: [
          FormationQuizOption(
            text: "Je fonce, un rendement à 9 % ne se refuse pas.",
            correct: false,
            explanation: "Le rendement affiché ne dit rien de ta capacité réelle à gérer ce bien. Un bon "
                "projet sur le papier devient un mauvais projet pour toi s'il ne correspond pas à ton temps "
                "disponible — c'est exactement l'erreur de Julien dans l'exemple du module.",
          ),
          FormationQuizOption(
            text: "Je regarde si une agence de gestion locale peut tout prendre en charge, et je recalcule "
                "la rentabilité nette avec ses frais inclus avant de décider.",
            correct: true,
            explanation: "Exactement la bonne démarche : le rendement affiché n'est qu'un point de départ. "
                "En intégrant le vrai coût de la solution qui correspond à TA situation (ici, la gestion "
                "déléguée), tu obtiens un chiffre comparable à ta réalité, pas à celle de ton ami.",
          ),
          FormationQuizOption(
            text: "Je refuse par principe, un rendement aussi élevé cache forcément un problème.",
            correct: false,
            explanation: "Un rendement élevé n'est pas automatiquement suspect (voir le module Choisir sa "
                "zone) — le vrai problème ici est l'inadéquation avec ton temps disponible, pas le chiffre "
                "lui-même. Refuser sans même évaluer la solution de gestion déléguée, c'est écarter une "
                "option potentiellement viable trop vite.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu négocies l'achat d'un bien. L'agent immobilier te dit : « Faites-moi confiance, c'est "
            "une super affaire, il faut signer vite. » Quelle est la bonne lecture de la situation ?",
        options: [
          FormationQuizOption(
            text: "L'agent travaille pour moi, je peux suivre son conseil sans vérifier.",
            correct: false,
            explanation: "Dans l'immense majorité des cas, l'agent est rémunéré par le vendeur et représente "
                "donc en priorité ses intérêts, même quand les frais sont facturés à l'acheteur. Ce n'est pas "
                "malhonnête de sa part — c'est juste sa position dans la transaction, à prendre en compte.",
          ),
          FormationQuizOption(
            text: "Je garde en tête que son rôle n'est pas de défendre mon intérêt à moi, et je fais ma "
                "propre vérification (chiffrage, PV d'AG, délai de vente) avant de me décider.",
            correct: true,
            explanation: "C'est la bonne posture : ni méfiance excessive, ni confiance aveugle. L'agent peut "
                "être un bon professionnel et, en même temps, ne pas être celui qui vérifie que CE projet est "
                "bon pour TOI — ce rôle-là te revient.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — le même bien à 180 000 €, deux budgets très différents",
        "✅ Sarah budgète large dès le départ : prix 180 000 € + notaire 14 400 € (8 %) + travaux 8 000 € + "
            "environ 3 mois de charges de copropriété avant le premier loyer (750 €) + frais de dossier "
            "bancaire (900 €) + ameublement pour louer meublé (3 500 €). Budget total réel : 207 550 €. Elle "
            "calibre son prêt sur ce vrai montant dès la simulation — tout se passe ensuite sans accroc.\n\n"
            "❌ Thomas budgète seulement le prix affiché (180 000 €), plus une petite marge « au cas où » de "
            "5 000 €. Une fois le compromis signé, il découvre les 14 400 € de notaire, les 8 000 € de travaux "
            "qui se révèlent indispensables (pas optionnels), et les frais de dossier. Il lui manque plus de "
            "17 000 € qu'il doit emprunter dans l'urgence, via un crédit à la consommation bien plus cher que "
            "son crédit immobilier.",
      ),
      FormationLesson(
        "Ce qui ne s'applique PAS à l'investissement locatif",
        "Plusieurs aides et dispositifs connus concernent uniquement la résidence principale, pas un bien "
            "locatif : le Prêt à Taux Zéro (PTZ) est réservé aux primo-accédants qui achètent pour y habiter "
            "eux-mêmes, pas pour louer. Le Prêt Accession Sociale (PAS) et le Prêt Action Logement suivent la "
            "même logique. Confondre les deux catégories fait perdre un temps précieux à monter un dossier "
            "d'aide pour lequel le projet n'est, en réalité, jamais éligible. À l'inverse, certains dispositifs "
            "fiscaux (amortissement LMNP, déficit foncier au régime réel) n'existent QUE pour le locatif, pas "
            "pour une résidence principale — vérifie toujours de quel côté se trouve le dispositif avant de "
            "bâtir ton budget dessus.",
      ),
      FormationLesson(
        "Fixer une enveloppe maximale, et s'y tenir",
        "Avant même la première visite, fixe un prix maximum tout compris (pas seulement un prix d'achat "
            "maximum) à partir de ta capacité d'emprunt et de ton apport disponible — puis ne le dépasse pas, "
            "même pour « le bien parfait qui ne repassera jamais ». En pratique, le marché produit en continu "
            "de nouvelles opportunités : le bien manqué aujourd'hui a presque toujours un équivalent qui "
            "réapparaît dans les semaines ou mois suivants. Dépasser son enveloppe pour un coup de cœur est la "
            "porte d'entrée la plus fréquente vers un cash-flow trop tendu dès la première année — garder "
            "cette limite écrite quelque part (et pas seulement « dans sa tête ») aide à résister à la "
            "pression du moment lors d'une négociation ou d'une visite groupée.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "En préparant ton financement, un conseiller bancaire te parle d'un « prêt à taux "
            "avantageux pour les primo-accédants » pour ton projet locatif. Que fais-tu ?",
        options: [
          FormationQuizOption(
            text: "Je fonce, un taux avantageux est toujours bon à prendre.",
            correct: false,
            explanation: "Les dispositifs primo-accédants (PTZ, PAS...) sont quasi systématiquement réservés "
                "à une résidence principale. Avant de t'enthousiasmer, vérifie que ton projet locatif y est "
                "bien éligible — ce n'est presque jamais le cas.",
          ),
          FormationQuizOption(
            text: "Je demande explicitement si ce dispositif s'applique à un achat locatif, et pas "
                "seulement à une résidence principale.",
            correct: true,
            explanation: "La bonne question, systématiquement. Beaucoup de dispositifs « avantageux » sont "
                "fléchés résidence principale — le vérifier avant d'y consacrer du temps évite une mauvaise "
                "surprise au moment du dossier.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu as fixé ton enveloppe maximale à 160 000 € tout compris. Une agence te présente un "
            "bien « rare » à 172 000 € en te pressant de te décider avant la fin de la semaine. Que fais-tu ?",
        options: [
          FormationQuizOption(
            text: "Je dépasse mon enveloppe pour cette fois, le bien a l'air exceptionnel.",
            correct: false,
            explanation: "C'est exactement le scénario qui mène à un cash-flow trop tendu dès la première "
                "année. Un bien « rare » aujourd'hui a presque toujours un équivalent qui réapparaît — la "
                "pression du délai est un signal à prendre avec recul, pas une raison de dépasser son budget.",
          ),
          FormationQuizOption(
            text: "Je garde mon enveloppe fixée à l'avance et je laisse passer ce bien si je ne peux pas "
                "négocier le prix à l'intérieur de ma limite.",
            correct: true,
            explanation: "La discipline budgétaire protège justement contre ce genre de pression. Si le prix "
                "ne rentre pas dans l'enveloppe calculée à partir de ta vraie capacité, ce n'est pas le bon "
                "bien pour toi, quelle que soit sa rareté affichée.",
          ),
          FormationQuizOption(
            text: "Je demande un délai supplémentaire à l'agence, sans rien changer à mon enveloppe.",
            correct: false,
            explanation: "Demander un délai ne résout rien si l'intention sous-jacente est quand même de "
                "dépasser l'enveloppe une fois le délai obtenu. La bonne réponse n'est pas de gagner du temps, "
                "c'est de ne pas dépasser la limite fixée à l'avance.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — bien lire une annonce (et le prix d'une négligence)",
        "✅ Une annonce mentionne « charges de copropriété : 1 800 €/an, PV d'AG disponibles sur demande ». "
            "Inès les demande avant même la visite et découvre un ravalement de façade déjà voté mais pas "
            "encore facturé, environ 4 000 € à sa charge en tant que futur copropriétaire. Elle intègre ce "
            "montant dans sa négociation et obtient 5 000 € de rabais sur le prix affiché — la découverte "
            "devient un argument plutôt qu'une mauvaise surprise après-vente.\n\n"
            "❌ Yanis visite un bien « à fort potentiel, idéal investisseur » sans creuser cette formule un "
            "peu trop enthousiaste. Séduit par un prix 15 % sous le marché du secteur et pressé par l'agent "
            "(« un autre investisseur est intéressé »), il signe vite. Après l'achat, il découvre un sinistre "
            "dégât des eaux non déclaré par le vendeur précédent : 12 000 € de travaux imprévus, largement "
            "au-dessus de la décote initiale qui l'avait attiré.",
      ),
      FormationLesson(
        "Se faire connaître des professionnels locaux",
        "Les meilleures opportunités ne passent pas toujours par une annonce publique — un agent qui te "
            "connaît comme acheteur sérieux (dossier prêt, réactif, pas chronophage) te rappelle en priorité "
            "quand un bien correspondant à tes critères rentre en mandat, parfois avant même sa mise en ligne. "
            "Même logique avec les artisans de confiance : celui qui a fait tes premiers travaux connaît "
            "parfois un propriétaire qui vend, ou un bien qui va se libérer. Se construire ce réseau prend du "
            "temps et de la régularité (rappeler, donner des nouvelles de ta recherche, être précis sur tes "
            "critères) — un investissement qui paie souvent sur le deuxième ou troisième achat, rarement sur "
            "le tout premier.",
      ),
      FormationLesson(
        "Combien de biens faut-il visiter avant d'acheter",
        "Il n'y a pas de chiffre magique, mais la plupart des premiers achats réussis suivent un schéma "
            "similaire : une dizaine d'annonces étudiées en détail pour chaque bien réellement visité, et "
            "plusieurs visites (souvent entre 5 et 15) avant de trouver celui qui coche vraiment les critères "
            "fixés en amont. Visiter peu de biens n'est pas un gage de rapidité si ça mène à un mauvais choix "
            "— c'est au contraire souvent un chemin plus long au global (temps perdu en travaux imprévus, "
            "vacance locative non anticipée). À l'inverse, visiter sans fin sans jamais se décider cache "
            "parfois une peur de se tromper plus qu'un vrai manque de bon bien — fixer des critères clairs dès "
            "le départ (module précédent) aide à reconnaître le bon moment pour arrêter de chercher.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Tu cherches activement depuis 3 semaines et tu n'as toujours pas visité de bien "
            "correspondant vraiment à tes critères. Un ami te dit que « ça fait long, il faut peut-être "
            "revoir tes critères à la baisse ». Que penses-tu de ce conseil ?",
        options: [
          FormationQuizOption(
            text: "Il a raison, 3 semaines c'est long, je dois être trop exigeant.",
            correct: false,
            explanation: "Rien ne dit que 3 semaines soit long — la plupart des premiers achats demandent "
                "plusieurs mois et de nombreuses visites avant de trouver le bon bien. Revoir ses critères à "
                "la baisse trop vite est souvent ce qui mène ensuite aux pièges classiques du premier achat.",
          ),
          FormationQuizOption(
            text: "Je relativise : quelques semaines de recherche, ce n'est pas long pour un premier achat, "
                "et je continue avec mes critères tant qu'ils restent cohérents avec mon objectif.",
            correct: true,
            explanation: "Exactement. Le rythme normal d'une recherche sérieuse se compte en mois, pas en "
                "semaines. Tant que les critères restent justifiés par l'objectif fixé au départ, il n'y a pas "
                "de raison de les assouplir simplement par impatience.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un agent immobilier te présente un bien hors marché, pas encore publié, « parce qu'il te "
            "fait confiance ». C'est la première fois que tu travailles avec lui. Comment réagis-tu ?",
        options: [
          FormationQuizOption(
            text: "Je me méfie, un bien qui n'est pas publié cache forcément un défaut.",
            correct: false,
            explanation: "Ce n'est pas automatique : une partie des bonnes affaires passent justement par le "
                "réseau avant publication. Le vrai réflexe n'est pas la méfiance de principe, c'est de "
                "vérifier le bien lui-même avec la même rigueur qu'une annonce classique (PV d'AG, visite, "
                "chiffrage).",
          ),
          FormationQuizOption(
            text: "Je visite et j'applique exactement la même grille de vérification que pour n'importe "
                "quelle autre annonce, sans me précipiter sous prétexte que c'est « en avant-première ».",
            correct: true,
            explanation: "La bonne attitude : un bien hors marché peut être une vraie opportunité, mais il "
                "mérite exactement la même rigueur (PV d'AG, chiffrage, visite complète) qu'une annonce "
                "publique — le canal par lequel on trouve un bien ne change rien à la méthode pour l'évaluer.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — deux villes, deux dynamiques opposées",
        "✅ Léa compare deux villes à prix d'achat presque identique (95 000 € contre 98 000 € pour un bien "
            "équivalent). Ville A perd 0,8 % d'habitants par an et voit son chômage augmenter ; Ville B gagne "
            "1,2 % d'habitants par an, avec une nouvelle ligne de tram annoncée et une université qui "
            "s'agrandit. Elle choisit Ville B malgré un rendement affiché légèrement inférieur (5,8 % contre "
            "6,3 %) — en pariant sur une vacance locative plus faible et une revente bien plus facile le "
            "moment venu.\n\n"
            "❌ Bastien choisit sa ville natale « parce qu'il la connaît », sans vérifier le moindre "
            "indicateur objectif. Il découvre après coup que la commune perd des habitants depuis dix ans : il "
            "met sept mois à trouver son premier locataire, loin des 4 à 8 % de vacance locative habituels "
            "qu'il avait budgétés.",
      ),
      FormationLesson(
        "Analyser un quartier à l'échelle de la rue",
        "Les statistiques à l'échelle de la ville ne disent pas tout : un quartier peut se dégrader ou se "
            "revaloriser bien plus vite que la moyenne communale. En visite, regarde la vacance commerciale "
            "en pied d'immeuble (plusieurs locaux fermés durablement est un signal faible mais réel), "
            "l'entretien général des façades et trottoirs alentour, et la mixité des âges dans le quartier "
            "(un quartier qui vieillit sans aucun renouvellement de population locative est un risque pour la "
            "demande future). À l'inverse, des travaux de voirie en cours, de nouveaux commerces qui "
            "ouvrent, ou un projet de rénovation urbaine annoncé sont des signaux positifs qui précèdent "
            "souvent une hausse de la demande — et donc des prix — avant qu'elle soit visible dans les "
            "statistiques globales de la ville.",
      ),
      FormationLesson(
        "Les signaux d'alerte à ne pas ignorer",
        "Une vacance locative anormalement élevée chez les investisseurs déjà installés dans le secteur (à "
            "demander directement en visite ou via un agent local) est le signal le plus fiable, bien plus "
            "que n'importe quelle statistique nationale. Une population qui vieillit sans renouvellement "
            "(peu de jeunes actifs ou de familles qui s'installent) annonce une demande locative qui va "
            "continuer de se contracter. Une dépendance très forte à un seul employeur local (une usine, une "
            "administration) expose à un risque brutal en cas de fermeture ou de restructuration. Aucun de "
            "ces signaux, pris isolément, n'est forcément rédhibitoire — mais leur accumulation sur une même "
            "zone doit alerter, même quand le prix d'achat semble très attractif.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Tu visites un bien dans un quartier où tu remarques trois locaux commerciaux fermés "
            "depuis plusieurs mois au rez-de-chaussée des immeubles voisins. Le reste du quartier semble "
            "correct. Que fais-tu de cette observation ?",
        options: [
          FormationQuizOption(
            text: "Je l'ignore, ce n'est qu'un détail visuel, le prix du bien reste l'essentiel.",
            correct: false,
            explanation: "Une vacance commerciale durable est un signal faible mais réel de la santé "
                "économique du quartier — pas un détail à ignorer, même si le bien lui-même semble correct.",
          ),
          FormationQuizOption(
            text: "Je m'en sers comme signal d'alerte à creuser : je vérifie la vacance locative réelle "
                "auprès d'investisseurs déjà installés dans le secteur avant de me décider.",
            correct: true,
            explanation: "La bonne réaction : ce signal seul ne suffit pas à rejeter le bien, mais il mérite "
                "d'être vérifié par un indicateur plus direct — la vacance locative réellement observée dans "
                "le secteur, bien plus fiable qu'une impression visuelle.",
          ),
          FormationQuizOption(
            text: "Je renonce immédiatement à ce bien, des commerces fermés annoncent toujours un quartier "
                "en déclin.",
            correct: false,
            explanation: "C'est une réaction trop radicale pour un seul signal faible. Plusieurs raisons "
                "ponctuelles (travaux de voirie temporaires, renouvellement de bail en cours) peuvent "
                "expliquer des locaux fermés sans refléter un vrai déclin — il faut creuser avant de "
                "trancher.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Deux biens au même prix : l'un dans une ville dont la population augmente, avec un "
            "rendement affiché de 5,5 %, l'autre dans une ville qui perd des habitants, avec un rendement "
            "affiché de 8 %. Lequel choisir, et pourquoi ?",
        options: [
          FormationQuizOption(
            text: "Le second, le rendement affiché plus élevé est toujours à privilégier.",
            correct: false,
            explanation: "Le rendement affiché ne dit rien de la vacance locative réelle ni de la facilité de "
                "revente — une ville qui perd des habitants compense souvent un loyer attractif par une "
                "vacance locative plus longue et une revente plus difficile, ce qui réduit la rentabilité "
                "réelle au final.",
          ),
          FormationQuizOption(
            text: "Ça dépend de mon objectif (module 1) : pour du cash-flow pur avec une gestion attentive, "
                "le second peut se défendre ; pour sécuriser mon premier achat, je privilégie plutôt le "
                "premier.",
            correct: true,
            explanation: "La bonne réponse reconnaît qu'il n'y a pas de choix universellement meilleur — tout "
                "dépend de l'objectif fixé au module 1 et de ta tolérance au risque de vacance locative.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — le même bien, trois façons de le regarder",
        "Un bien à 150 000 €, loué 750 €/mois (9 000 €/an).\n\n"
            "✅ Rentabilité brute : 9 000 / 150 000 = 6 %. Rentabilité nette, après charges de copropriété "
            "(900 €), taxe foncière (1 100 €), assurance (200 €) et frais de gestion (540 €) : loyers nets "
            "d'environ 6 260 € sur un coût total voisin de 150 000 €, soit 4,2 %. Rentabilité nette-nette, "
            "après impôt au micro-foncier (TMI 30 % + 17,2 % de prélèvements sociaux) : environ 3,2 %. Une "
            "bonne pratique consiste à toujours présenter ces trois chiffres ensemble, jamais la brute "
            "seule.\n\n"
            "❌ Une annonce met en avant « rentabilité de 6 % » (c'est la brute, sans le dire). Un acheteur "
            "pressé la compare à un autre bien dont il a, lui, calculé la nette-nette (3,2 %) et croit à tort "
            "que le premier bien est deux fois plus rentable que le second — alors que les deux chiffres ne "
            "sont tout simplement pas calculés sur la même base.",
      ),
      FormationLesson(
        "Le TRI, pour comparer deux projets qui ne se ressemblent pas",
        "La rentabilité nette-nette décrit une photo à l'instant T, mais ne dit rien de l'évolution dans le "
            "temps ni de l'argent récupéré à la revente. Le Taux de Rendement Interne (TRI) résout ce "
            "problème : il résume en un seul pourcentage la performance globale d'un projet — tous les loyers "
            "encaissés année après année, PLUS la plus-value nette à la revente — en tenant compte du moment "
            "où chaque euro entre et sort. Deux projets très différents (l'un avec un cash-flow confortable "
            "mais peu de plus-value attendue, l'autre avec un cash-flow serré mais une forte revalorisation "
            "espérée) deviennent alors directement comparables sur un seul chiffre, calculé automatiquement "
            "par l'onglet « Projection » de l'app pour n'importe quelle durée simulée.",
      ),
      FormationLesson(
        "La rentabilité évolue dans le temps, pas seulement à l'achat",
        "Le chiffre calculé le jour de l'achat n'est qu'un point de départ : le loyer évolue (révision "
            "annuelle via l'indice IRL, voir le module Gestion), les charges de copropriété aussi (souvent à "
            "la hausse avec le temps), et la valeur du bien varie avec le marché local. Un bien acheté avec "
            "une rentabilité nette-nette de 3,5 % peut très bien afficher 4,5 % cinq ans plus tard si les "
            "loyers du secteur ont bien progressé — ou au contraire se dégrader si le quartier décroche. "
            "Réévaluer sa rentabilité réelle une fois par an (pas seulement au moment de l'achat) permet de "
            "détecter tôt un problème — ou une opportunité de refinancement (voir le module Penser sur le "
            "long terme) — plutôt que de le découvrir des années plus tard.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Tu compares deux projets : le Projet A a un excellent cash-flow mensuel mais une "
            "revalorisation attendue quasi nulle ; le Projet B a un cash-flow neutre mais une forte "
            "plus-value attendue à la revente dans 10 ans. Comment les comparer objectivement ?",
        options: [
          FormationQuizOption(
            text: "Je compare leur rentabilité nette-nette actuelle, c'est le chiffre le plus complet.",
            correct: false,
            explanation: "La rentabilité nette-nette ne regarde que les loyers à l'instant T — elle ignore "
                "complètement la plus-value attendue à la revente, qui est pourtant l'essentiel de l'avantage "
                "du Projet B. Comparer sur ce seul chiffre désavantage injustement les projets patrimoniaux.",
          ),
          FormationQuizOption(
            text: "Je simule le TRI de chaque projet sur le même horizon (10 ans), loyers et revente "
                "compris, pour les comparer sur une base équivalente.",
            correct: true,
            explanation: "Exactement l'usage du TRI : il intègre à la fois les loyers encaissés dans le temps "
                "ET la revente, ce qui permet de comparer deux stratégies très différentes sur un même pied "
                "d'égalité.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Cinq ans après l'achat d'un bien, tu n'as jamais recalculé sa rentabilité réelle. Les "
            "loyers du quartier ont bien augmenté depuis. Que risques-tu en ne vérifiant jamais ?",
        options: [
          FormationQuizOption(
            text: "Rien de particulier, la rentabilité calculée à l'achat reste valable tant que je ne "
                "revends pas.",
            correct: false,
            explanation: "La rentabilité réelle évolue avec le loyer, les charges et la valeur du bien — ne "
                "jamais la recalculer, c'est risquer de sous-exploiter un bien qui vaut maintenant plus que "
                "prévu (occasion de refinancement manquée) ou de ne pas détecter une dégradation progressive.",
          ),
          FormationQuizOption(
            text: "Je risque de passer à côté d'une opportunité de refinancement si le bien s'est "
                "revalorisé, ou de ne pas détecter à temps une dégradation si la situation s'inverse.",
            correct: true,
            explanation: "C'est exactement le risque : sans réévaluation régulière, ni les bonnes surprises "
                "(refinancement possible) ni les mauvaises (dégradation progressive) ne sont détectées à "
                "temps pour agir.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — déléguer son assurance emprunteur",
        "✅ Sur un prêt de 160 000 € sur 20 ans, l'assurance groupe proposée par la banque coûte 0,34 %/an, "
            "soit environ 544 €/an — 10 880 € sur toute la durée du prêt. En délégation d'assurance (profil "
            "non-fumeur, en bonne santé), un assureur externe propose 0,12 %/an pour une couverture "
            "équivalente, soit environ 192 €/an — 3 840 € sur 20 ans. Écart : plus de 7 000 € d'économie, pour "
            "la même protection, juste en comparant avant de signer.\n\n"
            "❌ Paul accepte l'assurance groupe « pour aller plus vite », pensant que l'écart serait minime. "
            "Trois ans plus tard, en comparant pour un second achat, il réalise qu'il paie depuis le début près "
            "de trois fois le prix nécessaire pour la même couverture — sans jamais avoir pris dix minutes "
            "pour comparer au moment de son premier crédit.",
      ),
      FormationLesson(
        "Le dossier à préparer avant le premier rendez-vous",
        "Arriver avec un dossier complet accélère considérablement l'étude de ta demande : tes 3 derniers "
            "bulletins de salaire (ou bilans si indépendant), ton dernier avis d'imposition, tes 3 derniers "
            "relevés de compte de tous tes comptes, un justificatif de l'apport disponible (relevé "
            "d'épargne), le compromis de vente ou l'annonce du bien visé, et surtout une simulation de "
            "rentabilité chiffrée du projet (loyer attendu, charges, cash-flow prévisionnel) — c'est ce "
            "dernier document, souvent absent des dossiers de primo-investisseurs, qui différencie un projet "
            "pris au sérieux par la banque d'un projet présenté uniquement à l'oral.",
      ),
      FormationLesson(
        "Les leviers qui marchent vraiment pour négocier son prêt",
        "Mettre plusieurs banques en concurrence reste le levier le plus efficace — une offre écrite d'un "
            "établissement concurrent pèse plus lourd dans une négociation que n'importe quel argument "
            "verbal. Domicilier tes revenus dans la banque prêteuse se négocie encore souvent contre une "
            "baisse de taux ou une réduction des frais de dossier, même si cette pratique est désormais "
            "encadrée dans le temps (plafonnée à quelques années). Un apport plus confortable que le minimum "
            "demandé, ou une épargne résiduelle visible après l'achat, rassure et peut aussi se négocier. En "
            "revanche, négocier uniquement sur le taux nominal sans regarder l'assurance emprunteur (souvent "
            "le vrai poste d'économie, voir l'exemple de ce module) laisse de l'argent sur la table.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Tu as rendez-vous avec ta banque dans une semaine pour présenter ton projet locatif. Tu "
            "as rassemblé tes bulletins de salaire et ton avis d'imposition. Que te manque-t-il probablement "
            "le plus pour convaincre ?",
        options: [
          FormationQuizOption(
            text: "Rien, les documents de revenus suffisent à étudier n'importe quel dossier.",
            correct: false,
            explanation: "Les documents de revenus prouvent ta solvabilité personnelle, mais ne disent rien "
                "du projet lui-même. Sans simulation de rentabilité chiffrée, la banque n'a aucun moyen "
                "d'évaluer si CE projet précis est viable.",
          ),
          FormationQuizOption(
            text: "Une simulation de rentabilité chiffrée du bien visé (loyer, charges, cash-flow "
                "prévisionnel), qui manque souvent dans les dossiers de primo-investisseurs.",
            correct: true,
            explanation: "C'est exactement le document qui différencie un dossier pris au sérieux — il "
                "montre que le projet a été pensé au-delà de l'envie d'investir, avec des chiffres réels à "
                "l'appui.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Une banque te propose un taux de 3,6 % avec son assurance groupe. Une autre banque te "
            "propose 3,8 % mais tu sais que tu peux y déléguer ton assurance à un tarif très inférieur. "
            "Laquelle choisir, et comment le vérifier ?",
        options: [
          FormationQuizOption(
            text: "La première automatiquement, le taux nominal le plus bas est toujours le meilleur choix.",
            correct: false,
            explanation: "Le taux nominal seul ne dit pas le coût total du crédit — l'assurance emprunteur "
                "peut représenter plusieurs milliers d'euros d'écart, parfois plus que la différence de taux "
                "elle-même (voir l'exemple chiffré de ce module).",
          ),
          FormationQuizOption(
            text: "Je calcule le coût total (taux + assurance réelle, groupe ou déléguée) sur toute la "
                "durée pour chaque offre avant de comparer.",
            correct: true,
            explanation: "La seule comparaison qui a du sens : le TAEG et le coût total sur la durée, "
                "assurance comprise — pas le taux nominal affiché isolément.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — anticiper un DPE pénalisant plutôt que le subir",
        "✅ Un bien classé F est affiché à 110 000 €, contre 125 000 € pour un équivalent classé D dans le "
            "même immeuble. Noémie fait chiffrer les travaux de rénovation énergétique nécessaires (isolation, "
            "changement du système de chauffage) avant de faire une offre : environ 13 000 €. Elle intègre ce "
            "montant dans sa négociation et dans son budget global — projet final à 123 000 € tout compris, "
            "cohérent, avec un DPE qui remontera en D une fois les travaux faits.\n\n"
            "❌ Hugo achète un bien classé G « pas cher » sans se poser la question du DPE, pensant le "
            "relouer tel quel à son locataire sortant. Après l'achat, il découvre que la location de ce "
            "logement est déjà interdite légalement pour ce classement — il se retrouve propriétaire d'un bien "
            "qu'il ne peut pas louer tant que 18 000 € de travaux, totalement absents de son budget initial, "
            "n'auront pas été réalisés.",
      ),
      FormationLesson(
        "Travaux soi-même ou par des professionnels ?",
        "Le bricolage personnel peut faire sens pour des finitions simples (peinture, petite déco) si tu as "
            "vraiment le temps et la compétence — mais il devient un piège dès qu'il touche à l'électricité, "
            "la plomberie ou la structure : une non-conformité découverte plus tard coûte souvent bien plus "
            "cher à reprendre qu'un chantier confié directement à un professionnel, sans compter le risque "
            "sur l'assurance en cas de sinistre lié à des travaux non réalisés dans les règles. Le vrai coût "
            "à comparer n'est pas seulement le prix du devis contre le prix des matériaux seuls, c'est aussi "
            "le temps que tu immobilises (et donc le loyer non perçu pendant que le chantier traîne) et le "
            "risque si le résultat n'est pas à la hauteur.",
      ),
      FormationLesson(
        "Le calendrier réaliste d'un chantier de rénovation",
        "Pour un chantier de rafraîchissement standard (peinture, sols, petite salle de bain), compte "
            "généralement 3 à 6 semaines une fois les artisans mobilisés — mais prévoir 2 à 4 semaines "
            "supplémentaires avant le démarrage effectif, le temps d'obtenir les devis et de caler les "
            "plannings des différents corps de métier. Pour des travaux plus lourds touchant à "
            "l'électricité, au chauffage ou à l'isolation (comme dans l'exemple de ce module), compte "
            "plutôt 2 à 4 mois, avec un risque de délai supplémentaire si des aides type MaPrimeRénov' "
            "rallongent l'instruction du dossier. Intégrer ce délai réaliste dans ton calendrier (et ton "
            "budget de mensualité pendant la vacance) évite la mauvaise surprise d'un bien qui reste vide "
            "plus longtemps que prévu avant son premier loyer.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Tu viens d'acheter un studio et tu envisages de refaire toi-même l'installation "
            "électrique pour économiser sur le devis d'un artisan. Qu'en penses-tu ?",
        options: [
          FormationQuizOption(
            text: "Bonne idée, ça permet d'économiser le coût de la main d'œuvre.",
            correct: false,
            explanation: "L'électricité touche directement à la sécurité et à la conformité du logement — "
                "une non-conformité découverte plus tard coûte souvent plus cher à reprendre que le devis "
                "initial, sans compter le risque sur ton assurance en cas de sinistre.",
          ),
          FormationQuizOption(
            text: "Je confie ce chantier à un professionnel certifié, et je réserve le bricolage personnel "
                "aux finitions simples (peinture, petite déco) si j'en ai le temps.",
            correct: true,
            explanation: "La bonne répartition : le bricolage personnel se justifie sur des finitions "
                "simples, jamais sur ce qui touche à la sécurité ou à la conformité du logement.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu prévois de relouer ton bien 3 semaines après l'achat, le temps de « juste rafraîchir "
            "un peu ». Les travaux incluent en réalité la réfection complète de la salle de bain. Ton "
            "planning est-il réaliste ?",
        options: [
          FormationQuizOption(
            text: "Oui, 3 semaines suffisent largement pour un rafraîchissement.",
            correct: false,
            explanation: "Une réfection de salle de bain n'est pas un simple rafraîchissement — ce type de "
                "chantier demande plutôt 3 à 6 semaines une fois les artisans mobilisés, sans compter le "
                "délai d'obtention des devis en amont. Un planning trop serré mène presque toujours à un "
                "dépassement.",
          ),
          FormationQuizOption(
            text: "Non, je prévois un délai plus réaliste (6 à 10 semaines au total) et j'intègre cette "
                "vacance locative supplémentaire dans mon budget prévisionnel.",
            correct: true,
            explanation: "C'est la bonne estimation. Sous-estimer systématiquement les délais de travaux est "
                "l'un des pièges les plus fréquents d'un premier projet — mieux vaut un délai large anticipé "
                "qu'une vacance locative imprévue qui grignote le cash-flow.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — LMNP au réel contre micro-BIC, l'écart réel en euros",
        "Loyers meublés perçus : 8 400 €/an.\n\n"
            "✅ Au régime réel : amortissement comptable du bien et du mobilier (environ 4 500 €/an) plus "
            "charges réelles déductibles (intérêts d'emprunt, copropriété, assurance — environ 3 200 €/an). "
            "Résultat fiscal ramené proche de zéro : 0 € d'impôt sur ces loyers, alors que le cash-flow réel, "
            "lui, reste positif.\n\n"
            "❌ Camille reste au régime micro-BIC « par simplicité », sans jamais comparer. Avec l'abattement "
            "forfaitaire de 50 %, sa base imposable est de 4 200 €, taxée à sa tranche (30 % + 17,2 % de "
            "prélèvements sociaux) : environ 1 980 € d'impôt chaque année. Sans l'avoir jamais calculé, elle "
            "paie chaque année l'équivalent d'un mois de loyer en impôt qu'un simple changement de régime "
            "(avec un comptable, souvent facturé 300 à 500 €/an en LMNP réel) lui aurait évité.",
      ),
      FormationLesson(
        "Les obligations déclaratives, concrètement",
        "Au micro-foncier ou micro-BIC, une seule ligne à reporter sur ta déclaration de revenus classique "
            "(formulaire 2042), l'abattement forfaitaire étant appliqué automatiquement. Au régime réel "
            "(foncier ou LMNP), une liasse fiscale dédiée est à produire chaque année (formulaire 2044 pour "
            "le foncier réel, liasse 2031 et annexes pour le LMNP réel), détaillant charges et amortissements "
            "— en pratique, quasiment jamais rempli sans l'aide d'un comptable une fois en LMNP réel, tant le "
            "calcul des amortissements est technique. Au-delà de l'impôt sur le revenu, ne pas oublier la "
            "Cotisation Foncière des Entreprises (CFE), due chaque année en LMNP même si l'activité reste "
            "modeste, avec une exonération possible la première année selon les communes.",
      ),
      FormationLesson(
        "Faut-il un expert-comptable, et pour quel coût",
        "Au micro-foncier ou micro-BIC, un expert-comptable n'apporte généralement aucune valeur : il n'y a "
            "rien à optimiser, l'abattement est automatique. Dès le régime réel, et plus encore en LMNP réel, "
            "un comptable spécialisé devient rapidement rentable : son forfait annuel (souvent entre 300 et "
            "600 € pour un ou deux biens) est en général largement couvert par l'économie d'impôt qu'il "
            "permet de sécuriser (voir l'exemple chiffré de ce module), sans compter le temps que tu "
            "économises et la tranquillité d'un dossier fiscal conforme en cas de contrôle. Un bon réflexe : "
            "comparer le coût du comptable à l'économie d'impôt estimée AVANT de choisir un régime, pas après "
            "— c'est souvent ce calcul qui tranche entre micro et réel pour un investisseur hésitant.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Tu loues un studio meublé, 7 200 €/an de loyers. Tu hésites entre rester au micro-BIC "
            "(simple, sans comptable) et passer au réel (plus complexe, avec un comptable à environ 400 "
            "€/an). Comment trancher ?",
        options: [
          FormationQuizOption(
            text: "Je reste au micro-BIC, pas besoin de payer un comptable pour un seul petit bien.",
            correct: false,
            explanation: "La taille du bien ne dit rien de l'écart fiscal potentiel — c'est le calcul "
                "(amortissement + charges réelles comparé à l'abattement forfaitaire de 50 %) qui tranche, "
                "pas une impression de simplicité.",
          ),
          FormationQuizOption(
            text: "Je fais estimer par un comptable l'économie d'impôt réelle du régime réel pour mon cas "
                "précis, et je compare ce montant à son forfait annuel avant de décider.",
            correct: true,
            explanation: "La bonne méthode : comparer le coût du comptable à l'économie réelle qu'il permet. "
                "Dans la majorité des cas en LMNP avec un crédit en cours, l'écart dépasse largement le "
                "forfait annuel, comme dans l'exemple chiffré de ce module.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu passes au LMNP au régime réel pour ta première année de location meublée. Que dois-tu "
            "absolument prévoir, au-delà du calcul de l'impôt sur les loyers ?",
        options: [
          FormationQuizOption(
            text: "Rien de plus, une fois le régime réel choisi, il n'y a qu'une seule déclaration à faire.",
            correct: false,
            explanation: "Le régime réel implique une liasse fiscale dédiée, bien plus technique qu'une "
                "simple ligne sur la déclaration de revenus — et la Cotisation Foncière des Entreprises (CFE) "
                "reste due chaque année, indépendamment de l'impôt sur les loyers eux-mêmes.",
          ),
          FormationQuizOption(
            text: "La liasse fiscale dédiée du régime réel, et la Cotisation Foncière des Entreprises (CFE), "
                "due chaque année même si le résultat fiscal est à zéro.",
            correct: true,
            explanation: "Exactement les deux obligations à anticiper — la CFE en particulier est souvent "
                "découverte tardivement par les nouveaux loueurs en meublé, alors qu'elle est due "
                "indépendamment du montant d'impôt sur les loyers.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — un impayé bien géré contre un impayé ignoré",
        "✅ Dès le 5ᵉ jour de retard, Inès envoie une relance écrite datée (preuve à l'appui) et active son "
            "assurance loyers impayés dès le premier mois complet non payé — elle avait vérifié le délai de "
            "carence et de déclaration de son contrat avant même de souscrire. Elle est indemnisée dès le 3ᵉ "
            "mois d'impayé, limitant sa perte réelle à environ un mois de loyer.\n\n"
            "❌ David attend « que ça s'arrange », sans relancer par écrit — donc sans aucune preuve "
            "exploitable. Quatre mois plus tard, il découvre que son assurance refuse de l'indemniser : le "
            "délai contractuel de déclaration d'un impayé (souvent 2 à 3 mois) est dépassé. Il perd "
            "l'intégralité des loyers impayés, plus les frais de procédure pour récupérer son logement.",
      ),
      FormationLesson(
        "Fixer le bon loyer, ni trop haut ni trop bas",
        "Un loyer trop élevé par rapport au marché local rallonge la recherche de locataire — chaque mois de "
            "vacance supplémentaire coûte souvent plus cher que la différence de loyer espérée sur l'année. "
            "Un loyer trop bas trouve preneur plus vite, mais rogne directement la rentabilité, parfois pour "
            "des années si le locataire reste en place longtemps. Dans les zones dites « tendues », un "
            "encadrement des loyers peut en plus fixer un plafond légal à ne pas dépasser, consultable "
            "commune par commune. La bonne méthode reste de comparer ton bien à plusieurs annonces "
            "comparables récentes du même secteur (surface, standing, année de rénovation) plutôt que de se "
            "fier à une seule référence ou à une estimation approximative — l'onglet « Marché » de l'app "
            "donne un premier repère de loyer moyen au m² du secteur pour cadrer cette comparaison.",
      ),
      FormationLesson(
        "Faire évoluer le loyer dans le temps",
        "En cours de bail, le loyer d'un logement loué nu ou meublé peut être révisé une fois par an si une "
            "clause de révision est prévue au contrat, en suivant l'évolution de l'Indice de Référence des "
            "Loyers (IRL) publié chaque trimestre par l'INSEE — pas à ta propre appréciation du marché. Entre "
            "deux locataires, en revanche, tu retrouves ta liberté de fixer un nouveau loyer plus proche du "
            "marché actuel (sous réserve, en zone tendue, du plafond légal applicable au relogement). "
            "Beaucoup de propriétaires oublient d'appliquer la révision annuelle IRL par simple oubli "
            "administratif — sur plusieurs années, ce sont plusieurs centaines d'euros de loyer cumulés "
            "jamais perçus, pour une démarche qui ne prend que quelques minutes.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Tu fixes le loyer de ton nouveau bien 15 % au-dessus de la moyenne des annonces "
            "comparables du quartier, pensant « tenter le coup, je baisserai si besoin ». Quel est le risque "
            "principal de cette stratégie ?",
        options: [
          FormationQuizOption(
            text: "Aucun risque réel, je peux toujours baisser le loyer plus tard si ça ne se loue pas.",
            correct: false,
            explanation: "Le risque n'est pas l'impossibilité de baisser, c'est le coût du temps perdu : "
                "chaque mois de vacance locative pendant que le bien reste trop cher coûte souvent plus que "
                "toute la différence de loyer espérée sur l'année entière.",
          ),
          FormationQuizOption(
            text: "Chaque mois de vacance locative pendant la recherche coûte potentiellement plus cher que "
                "le surplus de loyer visé sur l'année — mieux vaut partir d'un loyer cohérent avec le marché "
                "local.",
            correct: true,
            explanation: "Exactement le bon calcul : un loyer surévalué qui rallonge la vacance locative "
                "coûte presque toujours plus cher que le gain espéré — comparer à plusieurs annonces "
                "comparables avant de fixer le prix évite ce piège.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Ton bail prévoit une clause de révision annuelle du loyer, mais tu n'y as plus pensé "
            "depuis 3 ans. Qu'as-tu probablement perdu, et que fais-tu maintenant ?",
        options: [
          FormationQuizOption(
            text: "Rien d'important, l'IRL varie peu d'une année sur l'autre.",
            correct: false,
            explanation: "Même une variation modeste de l'IRL, cumulée sur 3 ans et sur 12 mois de loyer "
                "chaque année, représente souvent plusieurs centaines d'euros jamais perçus — un montant loin "
                "d'être négligeable pour une simple formalité administrative.",
          ),
          FormationQuizOption(
            text: "J'ai probablement perdu plusieurs centaines d'euros cumulés ; j'applique la révision pour "
                "l'avenir et je vérifie si un rattrapage reste possible selon les règles en vigueur.",
            correct: true,
            explanation: "La bonne réaction : reconnaître la perte cumulée, corriger pour la suite, et "
                "vérifier les règles de rattrapage applicables plutôt que de considérer l'oubli comme "
                "définitivement perdu sans vérification.",
          ),
        ],
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
      FormationLesson(
        "Exemple concret — refinancer plutôt que stagner",
        "✅ Après 8 ans, le bien de Farid (acheté 150 000 €) est désormais estimé à 195 000 € et le capital "
            "restant dû n'est plus que de 95 000 €. En faisant réévaluer son bien et en sollicitant sa banque, "
            "il dégage environ 100 000 € de capacité via un refinancement — qui lui sert d'apport pour un "
            "second bien, sans avoir eu à revendre le premier ni à épargner pendant des années de plus.\n\n"
            "❌ Amandine, exactement dans la même situation patrimoniale, ne fait jamais réévaluer son bien "
            "ni ne regarde sa situation globale. Huit ans plus tard, elle n'a toujours qu'un seul bien et "
            "pense « ne pas avoir les moyens » de se relancer — alors que son premier bien, sans qu'elle le "
            "sache, lui permettrait de le faire dès aujourd'hui.",
      ),
      FormationLesson(
        "Diversifier : villes, types de biens, stratégies",
        "Une fois les deux ou trois premiers biens acquis, concentrer tout son patrimoine sur une seule ville "
            "ou un seul type de bien expose à un risque collectif : si cette ville ou ce segment de marché se "
            "retourne, c'est l'ensemble du patrimoine qui encaisse le choc en même temps. Diversifier "
            "progressivement — une autre ville, un autre type de bien (passer du studio au T3 familial, ou "
            "de la longue durée à la courte durée), voire une autre stratégie (ajouter du LMNP à côté d'un "
            "foncier nu) — répartit ce risque sans nécessairement complexifier la gestion si chaque bien "
            "reste individuellement simple à suivre. Cette diversification n'a pas besoin d'être planifiée "
            "dès le premier achat — elle se construit naturellement, projet après projet, à mesure que "
            "l'expérience et la capacité d'emprunt augmentent.",
      ),
      FormationLesson(
        "Les bases de la transmission de patrimoine",
        "Un bien détenu en nom propre se transmet par succession classique, avec les droits de succession "
            "applicables selon le lien de parenté et un abattement renouvelable tous les 15 ans par enfant. "
            "Une SCI familiale facilite souvent la transmission progressive : les parts peuvent être données "
            "petit à petit, dans la limite des abattements fiscaux, plutôt que de transmettre le bien entier "
            "d'un coup — une donation-partage anticipée évite aussi des conflits ultérieurs entre héritiers "
            "sur un bien physique difficile à diviser équitablement. Ce sujet, souvent repoussé « à plus "
            "tard » par de jeunes investisseurs, mérite d'être anticipé dès que le patrimoine commence à "
            "prendre de la valeur — un notaire ou un conseiller en gestion de patrimoine reste le bon "
            "interlocuteur pour structurer cette réflexion, bien avant qu'elle devienne urgente.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "Après 3 achats réussis, tous des studios dans la même ville, on te propose un T3 "
            "familial dans une autre ville, avec un profil de locataire différent. Ta première réaction est "
            "de refuser « pour rester sur ce que je maîtrise ». Qu'en penses-tu ?",
        options: [
          FormationQuizOption(
            text: "C'est prudent, mieux vaut rester sur une stratégie qu'on maîtrise déjà.",
            correct: false,
            explanation: "Rester concentré sur un seul type de bien et une seule ville, une fois plusieurs "
                "projets déjà réalisés, expose au contraire à un risque collectif si ce segment précis se "
                "retourne — la diversification progressive sert justement à répartir ce risque.",
          ),
          FormationQuizOption(
            text: "Je l'étudie sérieusement comme une occasion de diversifier mon patrimoine, en appliquant "
                "la même méthode rigoureuse que pour mes précédents achats, sans la écarter par habitude.",
            correct: true,
            explanation: "La bonne attitude : la diversification n'est pas une prise de risque en soi si "
                "elle suit la même rigueur méthodologique que les achats précédents — c'est justement le fait "
                "de rester sur un seul segment qui, à terme, concentre le risque.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu as 35 ans, deux biens locatifs, et tu te dis que la transmission de patrimoine est « "
            "un sujet pour dans 30 ans ». Est-ce le bon raisonnement ?",
        options: [
          FormationQuizOption(
            text: "Oui, c'est bien trop tôt pour s'en préoccuper à cet âge.",
            correct: false,
            explanation: "Les mécanismes de transmission (comme les abattements renouvelables tous les 15 "
                "ans, ou la structuration en SCI familiale) sont justement plus efficaces quand ils sont "
                "anticipés tôt — attendre réduit les options disponibles plutôt que de simplement reporter "
                "une décision neutre dans le temps.",
          ),
          FormationQuizOption(
            text: "Non, certains mécanismes (abattements renouvelables, SCI familiale) sont plus efficaces "
                "anticipés tôt — une première réflexion avec un professionnel peut se faire sans urgence, "
                "mais pas trop tard.",
            correct: true,
            explanation: "Exactement : ce n'est pas un sujet à traiter dans l'urgence à 35 ans, mais ce n'est "
                "pas non plus un sujet à repousser indéfiniment — une première structuration réfléchie tôt "
                "garde plus d'options ouvertes qu'une réflexion tardive.",
          ),
        ],
      ),
    ],
  ),
  FormationModule(
    title: 'Études de cas chiffrées',
    subtitle: "La méthode appliquée de bout en bout, sur 4 profils différents",
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
      FormationLesson(
        "Cas n°4 — La colocation, rentable mais chronophage",
        "Exemple fictif. Maison de 110 m² (4 chambres) en périphérie d'une ville étudiante, achetée 175 000 "
            "€, 15 000 € de travaux pour cloisonner et équiper chaque chambre. Louée en colocation, 4 "
            "chambres à 420 €/mois charges comprises chacune, soit un loyer total potentiel de 1 680 €/mois "
            "— bien au-dessus du loyer qu'obtiendrait la même maison louée à une seule famille (environ 950 "
            "€/mois dans ce secteur).\n\n"
            "Financement : 20 000 € d'apport, le reste sur 20 ans à 3,8 %, mensualité d'environ 870 €/mois. "
            "Même en comptant une vacance locative plus élevée que la moyenne (chambre individuelle vacante "
            "plus souvent qu'un bail familial unique, environ 10 % retenu par sécurité), le cash-flow ressort "
            "nettement positif, autour de +380 €/mois. Rentabilité brute proche de 10 %, sans aucun problème "
            "structurel caché cette fois — contrairement au cas n°3.\n\n"
            "Le vrai coût de ce projet n'est pas financier : la gestion d'une colocation (turnover plus "
            "fréquent qu'un bail classique, répartition des charges entre colocataires, usure plus rapide des "
            "parties communes) demande largement plus de temps qu'un bien loué à un seul locataire. Beaucoup "
            "de propriétaires en colocation finissent par déléguer cette gestion à une agence spécialisée, ce "
            "qui réduit d'autant le cash-flow net réel.\n\n"
            "Verdict : un excellent projet sur le papier ET dans les faits, mais seulement pour quelqu'un prêt "
            "à y consacrer du temps (ou à en payer la délégation) — exactement le type d'arbitrage évoqué dès "
            "le module 1 : le bon bien n'est pas seulement celui qui a les meilleurs chiffres, c'est celui "
            "qui correspond aussi à ta disponibilité réelle.",
      ),
    ],
    quiz: [
      FormationQuizQuestion(
        scenario: "En comparant uniquement les rentabilités brutes affichées des 4 cas de ce module (6,6 %, "
            "4,5 %, 11 %, 10 %), lequel semble le plus attractif sur le papier — et pourquoi cette lecture "
            "seule est-elle incomplète ?",
        options: [
          FormationQuizOption(
            text: "Le cas n°3 (11 %) est objectivement le meilleur choix, c'est le chiffre le plus élevé.",
            correct: false,
            explanation: "C'est exactement le piège du cas n°3 : le rendement affiché le plus haut cachait "
                "un DPE bloquant et une vacance locative réelle très supérieure à la moyenne — une fois ces "
                "éléments intégrés, c'était en réalité le cas le plus risqué des quatre.",
          ),
          FormationQuizOption(
            text: "Aucun des quatre n'est « le meilleur » dans l'absolu — chacun convient à un objectif et "
                "une disponibilité différents, et le rendement brut seul ne permet jamais de trancher.",
            correct: true,
            explanation: "Exactement la leçon de ce module : le cas n°1 convient au cash-flow immédiat, le "
                "n°2 à la stratégie patrimoniale, le n°4 à qui a du temps à y consacrer, et le n°3 démontre "
                "qu'un rendement affiché élevé peut cacher un vrai risque. Le bon choix dépend toujours du "
                "profil de l'investisseur, pas d'un seul chiffre.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu as peu de temps libre en semaine et tu détestes gérer des conflits entre locataires. "
            "Lequel des 4 cas de ce module te correspondrait le moins bien, même si ses chiffres sont bons ?",
        options: [
          FormationQuizOption(
            text: "Le cas n°4 (la colocation), à cause du temps de gestion qu'il demande malgré d'excellents "
                "chiffres.",
            correct: true,
            explanation: "Correct — c'est précisément le point du cas n°4 : d'excellents chiffres ne "
                "suffisent pas si le temps de gestion réel ne correspond pas à ta situation. Une délégation à "
                "une agence reste possible, mais réduit alors le cash-flow net réel.",
          ),
          FormationQuizOption(
            text: "Le cas n°1 (le T2 cash-flow), parce que son rendement est plus faible que le n°4.",
            correct: false,
            explanation: "Le rendement du cas n°1 est effectivement plus modeste, mais sa gestion est bien "
                "plus simple (un seul locataire, pas de colocation) — ce n'est donc pas le cas qui "
                "correspondrait le moins bien à un profil cherchant à minimiser le temps de gestion.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Dans le cas n°2 (le studio étudiant), le cash-flow mensuel est neutre à légèrement "
            "négatif. Pourquoi ce projet peut-il malgré tout être un bon choix pour certains profils ?",
        options: [
          FormationQuizOption(
            text: "Un cash-flow négatif n'est jamais acceptable, ce projet est donc à éviter dans tous les "
                "cas.",
            correct: false,
            explanation: "Un cash-flow neutre ou légèrement négatif n'est pas rédhibitoire en soi — tout "
                "dépend de l'objectif de l'investisseur. Pour une stratégie patrimoniale assumée (module 1), "
                "ce type de profil est cohérent, à condition de pouvoir encaisser l'effort mensuel.",
          ),
          FormationQuizOption(
            text: "Parce qu'il correspond à une stratégie patrimoniale assumée : forte tension locative, "
                "amortissement LMNP qui annule l'impôt, et revalorisation attendue qui compense le cash-flow "
                "serré sur le long terme.",
            correct: true,
            explanation: "Exactement — ce projet n'a de sens que pour quelqu'un qui vise la plus-value et "
                "peut absorber un effort d'épargne mensuel modéré, pas pour quelqu'un qui cherche un "
                "complément de revenu immédiat.",
          ),
        ],
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
