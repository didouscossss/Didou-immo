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
        scenario: "Tu reçois un héritage de 180 000 € et tu peux payer un bien comptant, sans emprunter. Un "
            "proche te dit que ça « élimine le risque du crédit ». Du strict point de vue de l'effet de "
            "levier, que perds-tu en achetant comptant plutôt qu'à crédit ?",
        options: [
          FormationQuizOption(
            text: "Rien : l'effet de levier décrit le rendement locatif, pas le mode de financement.",
            correct: false,
            explanation: "L'effet de levier décrit précisément le fait de faire travailler l'argent emprunté "
                "en plus du tien — il n'existe que parce qu'il y a un crédit. Payer comptant l'annule "
                "totalement, même si le rendement locatif du bien reste identique.",
          ),
          FormationQuizOption(
            text: "La possibilité de faire travailler l'argent de la banque en plus du tien, et donc "
                "d'acquérir potentiellement plusieurs biens avec la même somme plutôt qu'un seul.",
            correct: true,
            explanation: "Exactement : avec 180 000 € d'apport répartis sur plusieurs crédits plutôt qu'un "
                "seul achat comptant, le même capital peut financer plusieurs biens — c'est tout l'intérêt de "
                "l'effet de levier, au prix d'un risque de crédit à assumer en échange.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Deux studios identiques dans le même immeuble : loué en meublé longue durée, l'un "
            "rapporte 480 €/mois ; en courte durée, l'autre pourrait rapporter environ 650 €/mois net de "
            "charges, mais la gestion (messages, ménage, clés) demande une disponibilité quasi quotidienne. "
            "Tu as un poste à temps plein très prenant. Quel critère doit peser le plus dans ton choix ?",
        options: [
          FormationQuizOption(
            text: "Le montant brut le plus élevé : 650 € restera toujours plus intéressant que 480 €.",
            correct: false,
            explanation: "Ce chiffre ignore le coût d'une délégation de gestion si tu n'as pas le temps "
                "(souvent 20 à 30 % des revenus en courte durée) — une fois ce coût intégré, l'écart avec la "
                "longue durée peut largement se réduire, voire s'inverser.",
          ),
          FormationQuizOption(
            text: "Ta disponibilité réelle, en recalculant le revenu net d'une éventuelle délégation de "
                "gestion plutôt qu'en comparant les loyers bruts affichés.",
            correct: true,
            explanation: "C'est la bonne démarche : le chiffre à comparer n'est pas 480 € contre 650 €, mais "
                "480 € contre 650 € moins le coût réel de la solution de gestion compatible avec ton emploi "
                "du temps.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Le vendeur d'un bien a déjà « son » notaire. On te dit que, pour aller plus vite, mieux "
            "vaut utiliser directement celui-ci plutôt que d'en choisir un toi-même. Est-ce vrai ?",
        options: [
          FormationQuizOption(
            text: "Oui, prendre un second notaire double les frais de notaire à payer.",
            correct: false,
            explanation: "Les frais de notaire ne doublent pas : quand acheteur et vendeur ont chacun leur "
                "notaire, les deux se partagent simplement les mêmes honoraires, sans surcoût pour toi.",
          ),
          FormationQuizOption(
            text: "Non : tu peux choisir ton propre notaire sans surcoût, les deux études se partageant "
                "alors les honoraires entre elles.",
            correct: true,
            explanation: "Exactement — rien n'oblige à utiliser le notaire du vendeur, et choisir le tien "
                "n'augmente pas le prix. C'est même recommandé pour avoir un interlocuteur qui ne défend que "
                "tes intérêts.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Cela fait 6 semaines que tu cherches sérieusement : 3 visites, aucune n'a encore "
            "correspondu à tes critères. Un proche te dit que tu es « clairement trop long à te décider ». "
            "Que penses-tu de ce jugement, au regard du rythme habituel d'un premier achat ?",
        options: [
          FormationQuizOption(
            text: "Il a raison : 6 semaines sans offre signée est un signal d'indécision à corriger vite.",
            correct: false,
            explanation: "6 semaines et 3 visites reste en-deçà du rythme moyen d'un premier achat, qui "
                "s'étale plutôt sur plusieurs mois et une dizaine de visites. Rien dans ce rythme ne signale "
                "une indécision anormale.",
          ),
          FormationQuizOption(
            text: "C'est un rythme tout à fait normal pour un premier achat, qui demande généralement "
                "plusieurs mois et de nombreuses visites avant de trouver le bon bien.",
            correct: true,
            explanation: "Exactement. Le vrai risque serait plutôt d'assouplir ses critères trop vite par "
                "impatience, pas de prendre le temps nécessaire à ce stade.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Bien A : cash-flow de -25 €/mois, situé dans une métropole en forte croissance "
            "démographique. Bien B : cash-flow de +180 €/mois, dans une ville moyenne stable mais sans "
            "dynamique particulière. Tu as de hauts revenus, aucun besoin de complément immédiat, et tu "
            "prépares ta retraite dans 20 ans. Lequel correspond le mieux à CET objectif précis ?",
        options: [
          FormationQuizOption(
            text: "Le Bien B : un cash-flow positif reste toujours préférable, quel que soit l'objectif.",
            correct: false,
            explanation: "Un cash-flow positif n'est un critère prioritaire que pour un objectif de revenu "
                "immédiat. Pour une stratégie patrimoniale sur 20 ans avec des revenus qui permettent "
                "d'absorber un léger effort mensuel, ce n'est pas le critère décisif.",
          ),
          FormationQuizOption(
            text: "Le Bien A : l'objectif patrimonial à 20 ans valorise la dynamique démographique de la "
                "zone bien plus que le cash-flow immédiat, que tes revenus actuels permettent d'absorber.",
            correct: true,
            explanation: "C'est la bonne lecture : objectif et capacité financière alignés sur le Bien A. Le "
                "Bien B conviendrait mieux à quelqu'un qui recherche un complément de revenu dès maintenant.",
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
        scenario: "Tes mensualités de crédit existantes (voiture) s'élèvent à 220 €/mois, pour des revenus "
            "nets de 2 600 €/mois. Une banque te propose un crédit locatif dont la mensualité serait de "
            "650 €/mois. Ton taux d'endettement total dépasserait-il la limite généralement admise de 35 % ?",
        options: [
          FormationQuizOption(
            text: "Oui : 650 € seuls représentent déjà largement plus d'un tiers de mes revenus.",
            correct: false,
            explanation: "650 € seuls représentent 25 % de 2 600 €, pas plus d'un tiers — et c'est le total "
                "des mensualités qu'il faut rapporter aux revenus, pas une mensualité isolée.",
          ),
          FormationQuizOption(
            text: "Non : le total (220 € + 650 €, soit 870 €) représente environ 33,5 % des revenus, sous la "
                "limite généralement admise.",
            correct: true,
            explanation: "Exact : (220 + 650) / 2 600 ≈ 33,5 %, sous le seuil des 35 %. Le dossier reste "
                "dans les clous, à condition que le reste à vivre soit aussi jugé suffisant par la banque.",
          ),
          FormationQuizOption(
            text: "Impossible à dire sans connaître le taux d'intérêt du nouveau crédit.",
            correct: false,
            explanation: "Le taux d'endettement se calcule sur les mensualités rapportées aux revenus, pas "
                "sur le taux d'intérêt du prêt — celui-ci influence le montant de la mensualité, mais n'entre "
                "pas séparément dans le calcul une fois la mensualité connue.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu as 40 000 € d'épargne disponible pour un projet à 150 000 € qui nécessite environ "
            "12 000 € d'apport minimum. Un conseiller te suggère de mettre 35 000 € d'apport « pour limiter "
            "le risque ». Quel est le principal inconvénient de suivre ce conseil ?",
        options: [
          FormationQuizOption(
            text: "Aucun : mettre plus d'apport que le minimum est toujours strictement préférable.",
            correct: false,
            explanation: "Plus d'apport réduit la mensualité, mais immobilise aussi un capital qui ne "
                "travaille plus pour un futur projet — ce n'est pas un choix neutre, c'est un vrai arbitrage.",
          ),
          FormationQuizOption(
            text: "Cela immobilise un capital qui ne pourra plus servir d'apport pour un futur achat, "
                "réduisant l'effet de levier global de ta stratégie.",
            correct: true,
            explanation: "C'est l'inconvénient réel : chaque euro apporté en plus du minimum est un euro qui "
                "ne pourra pas financer un second projet via un second crédit.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un bien ancien est affiché à 210 000 €. En additionnant uniquement le prix d'achat et un "
            "apport de 10 %, combien manque-t-il au minimum dans ce budget pour être réaliste ?",
        options: [
          FormationQuizOption(
            text: "Rien : le prix affiché et l'apport suffisent à cadrer le budget d'un achat dans l'ancien.",
            correct: false,
            explanation: "Il manque au minimum les frais de notaire, qui ne sont jamais inclus dans le prix "
                "affiché d'une annonce — un oubli très fréquent chez un premier acheteur.",
          ),
          FormationQuizOption(
            text: "Au minimum les frais de notaire (environ 7 à 8 % dans l'ancien, soit 15 000 à 17 000 € "
                "ici), avant même de compter d'éventuels travaux ou frais de dossier.",
            correct: true,
            explanation: "Exactement — et ce n'est qu'un minimum : travaux, frais de dossier bancaire et "
                "ameublement éventuel viennent encore s'ajouter selon le bien.",
          ),
          FormationQuizOption(
            text: "Uniquement la TVA à 20 % sur le prix d'achat.",
            correct: false,
            explanation: "La TVA s'applique principalement au neuf vendu par un promoteur, pas à un achat "
                "dans l'ancien entre particuliers — ce ne sont pas les frais à anticiper ici.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Ta banque mentionne que tu pourrais être éligible au Prêt Accession Sociale (PAS) pour "
            "réduire tes frais sur ton achat locatif. Qu'en est-il réellement, la plupart du temps ?",
        options: [
          FormationQuizOption(
            text: "Bonne nouvelle à saisir immédiatement : ces prêts aidés réduisent toujours les frais, "
                "quel que soit le projet.",
            correct: false,
            explanation: "Comme le PTZ, le PAS est en pratique réservé à l'achat d'une résidence principale "
                "— à vérifier systématiquement avant d'y consacrer du temps pour un projet locatif.",
          ),
          FormationQuizOption(
            text: "Comme le PTZ, le PAS est en pratique réservé à l'achat d'une résidence principale, à "
                "vérifier donc avant de compter dessus pour un projet locatif.",
            correct: true,
            explanation: "Exact. Confondre les dispositifs réservés à la résidence principale avec ceux "
                "disponibles en locatif fait perdre un temps précieux à monter un dossier inéligible.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Ton enveloppe maximale est fixée à 150 000 € tout compris. Un bien à 145 000 € te plaît, "
            "mais une fois les travaux réellement chiffrés (12 000 €, absents de ton enveloppe initiale), le "
            "total dépasse légèrement ta limite. Que fais-tu ?",
        options: [
          FormationQuizOption(
            text: "Je signe quand même : le dépassement est minime et le bien me plaît vraiment.",
            correct: false,
            explanation: "C'est précisément ce que la discipline budgétaire doit éviter : un dépassement "
                "« minime » à chaque projet est le chemin le plus direct vers un cash-flow trop tendu.",
          ),
          FormationQuizOption(
            text: "Je retire du budget les travaux les moins visibles pour faire rentrer le total dans "
                "l'enveloppe sur le papier.",
            correct: false,
            explanation: "Retirer des travaux réels du budget ne les fait pas disparaître — ça ne fait que "
                "reporter la dépense, en pire, une fois le bien acheté et les travaux redevenus nécessaires.",
          ),
          FormationQuizOption(
            text: "Je renégocie le prix d'achat à la baisse pour faire rentrer le coût total (travaux "
                "compris) dans mon enveloppe, ou je renonce si ce n'est pas possible.",
            correct: true,
            explanation: "La bonne réaction : l'enveloppe doit couvrir le coût total réel, pas seulement le "
                "prix d'achat — la négocier à la baisse est le bon levier, pas les travaux eux-mêmes.",
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
        scenario: "Tu cherches un bien exclusivement sur un seul portail d'annonces en ligne depuis un mois, "
            "sans résultat convaincant. Qu'est-ce qui limite le plus cette approche ?",
        options: [
          FormationQuizOption(
            text: "Rien de particulier : un bon portail suffit à voir l'essentiel des annonces du marché.",
            correct: false,
            explanation: "Un portail, aussi complet soit-il, ne couvre ni les annonces notariales, ni le "
                "réseau local, ni les biens off-market — une part réelle du marché lui échappe.",
          ),
          FormationQuizOption(
            text: "Tu es en concurrence avec tous les autres acheteurs du même portail, et tu passes à côté "
                "des biens trouvés via les notaires ou le réseau local avant publication.",
            correct: true,
            explanation: "Exactement : combiner plusieurs canaux élargit le nombre d'opportunités vues ET "
                "réduit la concurrence directe sur chacune d'elles.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Une annonce ne mentionne ni le montant des charges de copropriété ni le DPE du logement. "
            "Que dois-tu en conclure avant la visite ?",
        options: [
          FormationQuizOption(
            text: "Que le bien n'a probablement pas de charges de copropriété.",
            correct: false,
            explanation: "L'absence de mention ne signifie jamais l'absence de charges — presque tout "
                "logement en copropriété en a. C'est une information manquante, pas une absence réelle.",
          ),
          FormationQuizOption(
            text: "Que c'est un point à vérifier explicitement avant la visite, sans présumer que l'absence "
                "de mention soit bonne ou mauvaise en soi.",
            correct: true,
            explanation: "La bonne attitude : ni paniquer, ni ignorer — demander l'information manquante "
                "directement, plutôt que de se faire une opinion sans elle.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "En visite, le vendeur te dit que les PV d'assemblée générale « ne sont disponibles "
            "qu'après signature du compromis, c'est la procédure normale ». Qu'en penses-tu ?",
        options: [
          FormationQuizOption(
            text: "C'est effectivement la procédure standard, rien d'anormal à attendre la signature.",
            correct: false,
            explanation: "Rien n'empêche de les demander avant une offre — les obtenir plus tôt permet "
                "justement d'intégrer d'éventuels travaux votés dans ta négociation, pas seulement de "
                "découvrir un problème après coup.",
          ),
          FormationQuizOption(
            text: "Tu peux et dois les demander avant de faire une offre, pour intégrer d'éventuels travaux "
                "votés dans ta négociation plutôt que de les découvrir après.",
            correct: true,
            explanation: "Exactement. Attendre le compromis pour les lire, c'est se priver du principal "
                "levier de négociation qu'ils peuvent offrir.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu veux négocier le prix d'un bien en disant uniquement « c'est cher pour le quartier », "
            "sans autre argument. Pourquoi cette approche a-t-elle peu de chances de fonctionner ?",
        options: [
          FormationQuizOption(
            text: "Parce qu'en pratique, les vendeurs n'acceptent quasiment jamais de négocier en France.",
            correct: false,
            explanation: "Un prix affiché n'est presque jamais un prix plancher — la négociation fonctionne "
                "couramment, mais seulement avec de vrais arguments à l'appui.",
          ),
          FormationQuizOption(
            text: "Parce qu'un argument sans chiffre ni fait vérifiable (travaux à prévoir, délai de vente, "
                "DPE pénalisant) est facile à ignorer par le vendeur.",
            correct: true,
            explanation: "C'est exactement ça : les leviers efficaces s'appuient toujours sur des faits "
                "précis et justifiés, jamais sur une impression générale.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un bien semble impeccable à l'intérieur, mais les parties communes de l'immeuble sont "
            "visiblement négligées (peinture écaillée, ascenseur en panne depuis des mois). Quel est le bon "
            "réflexe ?",
        options: [
          FormationQuizOption(
            text: "Ignorer ce détail, puisque c'est l'état du logement lui-même qui compte le plus.",
            correct: false,
            explanation: "L'état des parties communes est justement l'un des indicateurs les plus fiables de "
                "la santé financière d'une copropriété — un logement impeccable n'empêche pas des charges "
                "qui s'envolent ou des travaux de structure non votés.",
          ),
          FormationQuizOption(
            text: "Y voir un signal d'alerte sur la santé financière de la copropriété, à vérifier via les "
                "PV d'AG avant de t'engager, même si le logement lui-même est en parfait état.",
            correct: true,
            explanation: "Exactement le bon réflexe — un logement impeccable dans une copropriété en "
                "difficulté reste un risque réel, à vérifier avant, pas après l'achat.",
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
        scenario: "Tu veux connaître l'évolution démographique d'une commune sur les 10 dernières années "
            "avant de t'engager. Vers quelle source te tourner en priorité ?",
        options: [
          FormationQuizOption(
            text: "Les avis Google laissés par les habitants du quartier sur les commerces locaux.",
            correct: false,
            explanation: "Ces avis reflètent des expériences ponctuelles et subjectives, pas une évolution "
                "démographique mesurable — ce n'est pas la bonne source pour ce type de donnée.",
          ),
          FormationQuizOption(
            text: "Les données publiques de l'INSEE, qui publient librement ces statistiques commune par "
                "commune.",
            correct: true,
            explanation: "Exactement la bonne source : gratuite, officielle, et actualisée régulièrement — "
                "le point de départ pour toute analyse objective d'une zone.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Une nouvelle ligne de tramway est officiellement annoncée pour desservir un quartier dans "
            "3 ans, mais les prix immobiliers locaux n'ont pas encore bougé. Comment interpréter ce "
            "décalage ?",
        options: [
          FormationQuizOption(
            text: "C'est le signe que l'information est probablement fausse, sinon les prix auraient déjà "
                "réagi immédiatement.",
            correct: false,
            explanation: "Les prix intègrent souvent ce type d'annonce avec retard, pas instantanément — "
                "l'absence de réaction immédiate ne remet pas en cause la fiabilité de l'annonce elle-même.",
          ),
          FormationQuizOption(
            text: "C'est souvent une fenêtre d'opportunité : les prix réagissent à ce type d'amélioration "
                "progressivement, parfois bien après l'annonce officielle.",
            correct: true,
            explanation: "C'est exactement l'intérêt de repérer les projets d'aménagement à l'avance — "
                "acheter avant que le marché n'ait intégré l'information dans les prix.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Une ville affiche un faible taux de chômage, mais 60 % des emplois locaux dépendent d'une "
            "seule grande entreprise. Ce taux de chômage bas est-il, à lui seul, un signal pleinement "
            "rassurant ?",
        options: [
          FormationQuizOption(
            text: "Oui, un faible taux de chômage reste toujours rassurant, quelle que soit sa composition.",
            correct: false,
            explanation: "Un chômage bas aujourd'hui ne dit rien du risque futur : une forte dépendance à un "
                "seul employeur expose le bassin d'emploi à un choc brutal en cas de fermeture ou de "
                "restructuration.",
          ),
          FormationQuizOption(
            text: "Pas entièrement : cette forte dépendance à un seul employeur expose à un risque brutal en "
                "cas de fermeture ou de restructuration, malgré un chômage bas aujourd'hui.",
            correct: true,
            explanation: "Exactement — un bassin d'emploi diversifié est structurellement plus sûr qu'un "
                "bassin dépendant d'un seul acteur, même quand ses chiffres actuels sont bons.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "À budget identique, tu hésites entre un studio dans une métropole (forte liquidité de "
            "revente, rendement plus faible) et un T2 dans une ville moyenne dynamique (rendement plus "
            "élevé, revente plus incertaine). Tu sais que tu auras besoin de récupérer ton capital dans 4 "
            "ans pour un autre projet personnel. Quel bien ce critère favorise-t-il ?",
        options: [
          FormationQuizOption(
            text: "Le T2 en ville moyenne : un rendement plus élevé compense toujours un horizon de revente "
                "court.",
            correct: false,
            explanation: "Le rendement locatif ne compense pas une revente difficile ou lente si tu as "
                "besoin de récupérer ton capital à une date précise et rapprochée.",
          ),
          FormationQuizOption(
            text: "Le studio en métropole : un horizon de revente court valorise la liquidité (facilité et "
                "rapidité de revente) plus que le rendement locatif.",
            correct: true,
            explanation: "C'est la bonne lecture : plus l'horizon de revente est court et certain, plus la "
                "liquidité du marché pèse lourd dans le choix, parfois davantage que le rendement affiché.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Une ville affiche, en moyenne, une croissance démographique positive. Dans le quartier "
            "précis que tu vises, tu observes pourtant des immeubles mal entretenus et une population qui "
            "semble vieillir sans renouvellement visible. Que privilégier dans ton analyse ?",
        options: [
          FormationQuizOption(
            text: "La moyenne communale, statistiquement plus fiable qu'une simple impression de terrain.",
            correct: false,
            explanation: "Une moyenne communale peut masquer de fortes disparités internes — un quartier "
                "précis peut très bien décliner pendant que le reste de la ville tire la moyenne vers le "
                "haut.",
          ),
          FormationQuizOption(
            text: "L'observation de terrain à l'échelle du quartier, qui peut diverger fortement de la "
                "moyenne communale et révéler une réalité différente.",
            correct: true,
            explanation: "Exactement — les statistiques à l'échelle de la ville ne remplacent jamais "
                "l'observation du quartier précis où se trouve le bien, seule capable de révéler ce type "
                "d'écart.",
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
      FormationQuizQuestion(
        scenario: "Un bien à 120 000 € est loué 680 €/mois. Après charges annuelles de copropriété (720 €), "
            "taxe foncière (950 €) et assurance (180 €), quel est l'ordre de grandeur de sa rentabilité "
            "nette (pas brute) ?",
        options: [
          FormationQuizOption(
            text: "Environ 6,8 %, quasiment identique à la rentabilité brute puisque ces charges restent "
                "limitées.",
            correct: false,
            explanation: "6,8 % correspond à la rentabilité BRUTE (8 160 € de loyers / 120 000 €) — les "
                "charges annuelles, même limitées, font sensiblement baisser le chiffre une fois déduites.",
          ),
          FormationQuizOption(
            text: "Environ 5,3 %, nettement inférieure aux 6,8 % de rentabilité brute une fois les charges "
                "déduites.",
            correct: true,
            explanation: "Exact : 8 160 € de loyers moins 1 850 € de charges annuelles donne environ 6 310 € "
                "nets, soit environ 5,3 % de 120 000 € — un écart significatif avec la brute.",
          ),
          FormationQuizOption(
            text: "Environ 4 %, car la mensualité du crédit immobilier doit aussi être déduite pour calculer "
                "la rentabilité nette.",
            correct: false,
            explanation: "Le crédit n'entre pas dans le calcul de la rentabilité nette, qui ne déduit que les "
                "charges récurrentes du bien — c'est le cash-flow, un indicateur différent, qui intègre la "
                "mensualité de crédit.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un bien affiche une excellente rentabilité nette de 7 %, mais une fois la mensualité de "
            "crédit déduite, le cash-flow ressort à -180 €/mois. Peux-tu conclure que ce projet est "
            "financièrement confortable au quotidien ?",
        options: [
          FormationQuizOption(
            text: "Oui : une rentabilité nette de 7 % est un très bon chiffre, le reste est secondaire.",
            correct: false,
            explanation: "La rentabilité nette ne tient pas compte du crédit — un excellent chiffre de "
                "rentabilité peut très bien coexister avec un cash-flow négatif, qui est ce qui pèse "
                "réellement sur ton compte chaque mois.",
          ),
          FormationQuizOption(
            text: "Pas nécessairement : un cash-flow négatif signifie qu'il faut sortir 180 € de ta poche "
                "chaque mois, indépendamment de la qualité de la rentabilité nette affichée.",
            correct: true,
            explanation: "Exactement — rentabilité nette et cash-flow répondent à deux questions "
                "différentes : l'une mesure la performance du bien, l'autre ce qu'il te reste (ou te coûte) "
                "concrètement chaque mois.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Dans ta simulation, tu as supposé une vacance locative de 0 % « car le quartier est très "
            "demandé ». Quel est le principal risque de cette hypothèse ?",
        options: [
          FormationQuizOption(
            text: "Aucun risque réel si le quartier est effectivement très demandé.",
            correct: false,
            explanation: "Même dans un marché très tendu, un délai entre deux locataires (recherche, état "
                "des lieux, petits travaux) reste quasi systématique — une vacance strictement nulle reste "
                "rare, même dans les meilleurs secteurs.",
          ),
          FormationQuizOption(
            text: "Une vacance de sécurité de 4 à 8 % reste la norme à intégrer, même en zone tendue — une "
                "hypothèse à 0 % rend le prévisionnel artificiellement optimiste.",
            correct: true,
            explanation: "Exact. Une hypothèse trop optimiste sur la vacance peut masquer un cash-flow "
                "réellement plus fragile que ce que montre la simulation de départ.",
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
        scenario: "Deux dossiers affichent exactement le même taux d'endettement de 32 % une fois le "
            "nouveau crédit ajouté. Pourtant, la banque accepte le premier et refuse le second. Quel "
            "facteur, souvent décisif au-delà du taux d'endettement lui-même, peut expliquer cette "
            "différence ?",
        options: [
          FormationQuizOption(
            text: "Rien ne peut l'expliquer : à taux d'endettement égal, une banque décide toujours de la "
                "même façon.",
            correct: false,
            explanation: "Le taux d'endettement n'est qu'un critère parmi d'autres — deux dossiers peuvent "
                "l'avoir identique et pourtant diverger sur un autre facteur tout aussi déterminant.",
          ),
          FormationQuizOption(
            text: "Le reste à vivre réel une fois toutes les charges payées — un même taux d'endettement "
                "laisse un reste à vivre très différent selon le niveau de revenus.",
            correct: true,
            explanation: "Exactement : 32 % d'endettement laisse un reste à vivre confortable pour de hauts "
                "revenus, mais peut devenir très serré pour des revenus plus modestes — c'est ce reste à "
                "vivre que la banque regarde aussi de près.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Sur un même montant emprunté, allonger la durée du prêt de 15 à 25 ans réduit la "
            "mensualité d'environ un tiers. Quel est le vrai prix de cette réduction ?",
        options: [
          FormationQuizOption(
            text: "Aucun : allonger la durée est toujours gagnant, puisque le cash-flow s'améliore "
                "immédiatement.",
            correct: false,
            explanation: "Le cash-flow immédiat s'améliore effectivement, mais ce n'est pas sans contrepartie "
                "— le prêt coûte alors plus cher au total, même si chaque mensualité pèse moins lourd.",
          ),
          FormationQuizOption(
            text: "Un coût total des intérêts nettement plus élevé sur la durée totale du prêt, même si la "
                "mensualité devient plus confortable.",
            correct: true,
            explanation: "Exactement — un arbitrage à faire consciemment entre confort du cash-flow immédiat "
                "et coût total du crédit, pas un choix neutre ou automatiquement avantageux.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un courtier te dit que ses services sont « gratuits » pour toi. Est-ce systématiquement "
            "le cas ?",
        options: [
          FormationQuizOption(
            text: "Oui, un courtier n'est jamais rémunéré directement par l'emprunteur.",
            correct: false,
            explanation: "Ce n'est pas systématique : si la commission est le plus souvent prise en charge "
                "par la banque, certaines offres prévoient une partie à la charge de l'emprunteur.",
          ),
          FormationQuizOption(
            text: "Pas toujours : sa commission est souvent prise en charge par la banque, mais certaines "
                "offres prévoient une partie à ta charge — à clarifier avant de signer un mandat.",
            correct: true,
            explanation: "Exact. Ce point se vérifie simplement en lisant le mandat avant de le signer, "
                "plutôt qu'en se fiant à une affirmation orale.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un prêt in fine (intérêts remboursés chaque mois, capital remboursé en une fois à "
            "l'échéance) coûte, au total, plus cher en intérêts qu'un prêt amortissable classique pour le "
            "même montant et la même durée. Pourquoi ce montage reste-t-il parfois utilisé malgré ce "
            "surcoût ?",
        options: [
          FormationQuizOption(
            text: "En réalité il n'est pas plus cher : c'est une idée reçue répandue mais fausse.",
            correct: false,
            explanation: "Le surcoût en intérêts est réel : le capital ne diminuant jamais avant l'échéance, "
                "les intérêts se calculent sur le montant total emprunté pendant toute la durée, contrairement "
                "à un prêt amortissable classique.",
          ),
          FormationQuizOption(
            text: "Parce qu'il peut optimiser la fiscalité dans certains régimes (intérêts déductibles sur "
                "un capital qui ne diminue jamais) — un calcul réservé à des profils avertis, conscients du "
                "surcoût total.",
            correct: true,
            explanation: "C'est la bonne lecture : l'avantage fiscal potentiel peut, pour un profil "
                "spécifique, compenser le surcoût d'intérêts — mais ce n'est jamais un montage à choisir par "
                "défaut sans ce calcul précis.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu envisages d'acheter avec un ami, chacun à parts égales, sans rédiger de convention "
            "particulière, « parce que vous vous faites confiance ». Quel est le principal risque de cette "
            "approche ?",
        options: [
          FormationQuizOption(
            text: "Aucun risque réel tant que la confiance entre les deux parties reste bonne.",
            correct: false,
            explanation: "La confiance au moment de l'achat ne garantit rien des années plus tard — "
                "circonstances personnelles, désaccords, besoin de liquidités différent peuvent apparaître "
                "sans qu'aucun cadre n'ait prévu comment les gérer.",
          ),
          FormationQuizOption(
            text: "En cas de désaccord ou si l'un des deux veut sortir du projet plus tôt que prévu, "
                "l'absence de cadre juridique clair peut transformer un désaccord simple en conflit "
                "compliqué.",
            correct: true,
            explanation: "Exactement — répartition, modalités de sortie, prise de décision à deux : autant "
                "de points qu'une convention (ou une SCI) permet de clarifier avant qu'un désaccord ne "
                "survienne, pas après.",
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
        scenario: "Un diagnostic signale une non-conformité électrique dans un logement que tu viens "
            "d'acheter, mais le bien se loue déjà très facilement en l'état sur le marché local. Peux-tu "
            "reporter ces travaux de quelques années, le temps d'autres priorités ?",
        options: [
          FormationQuizOption(
            text: "Oui, puisque la demande locative reste forte malgré la non-conformité.",
            correct: false,
            explanation: "Le succès locatif actuel du bien ne change rien à l'obligation de sécurité — une "
                "non-conformité électrique reste un risque réel (sinistre, assurance) indépendamment de la "
                "facilité à trouver un locataire.",
          ),
          FormationQuizOption(
            text: "Non : une non-conformité électrique relève de la sécurité, pas d'un choix de "
                "valorisation — elle doit être traitée indépendamment du succès locatif actuel du bien.",
            correct: true,
            explanation: "Exactement la distinction du module : travaux obligatoires et travaux de "
                "valorisation ne répondent pas à la même logique de priorité, et la demande locative ne "
                "rend jamais une non-conformité négociable.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un artisan te propose un devis 40 % moins cher que les deux autres pour les mêmes "
            "travaux, sans être venu visiter le chantier au préalable. Que dois-tu en penser ?",
        options: [
          FormationQuizOption(
            text: "C'est une bonne opportunité à saisir rapidement, avant qu'il ne change d'avis sur le "
                "prix.",
            correct: false,
            explanation: "Un devis sans visite préalable du chantier repose sur des hypothèses, pas sur une "
                "évaluation réelle — l'écart se traduit souvent en suppléments imprévus une fois le chantier "
                "commencé.",
          ),
          FormationQuizOption(
            text: "Un écart aussi important sans visite préalable est un signal à vérifier sérieusement, "
                "plutôt qu'une simple bonne affaire.",
            correct: true,
            explanation: "C'est le bon réflexe : soit le devis sous-estime le chantier réel (suppléments à "
                "venir), soit la prestation diffère sensiblement — dans les deux cas, ça mérite d'être "
                "clarifié avant de signer.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu fais réaliser des travaux d'isolation par un artisan qui n'est pas certifié RGE, en te "
            "disant que tu demanderas MaPrimeRénov' une fois les travaux terminés. Qu'arrive-t-il "
            "généralement dans ce cas ?",
        options: [
          FormationQuizOption(
            text: "Aucun problème : l'aide s'obtient simplement sur présentation de la facture, une fois les "
                "travaux achevés.",
            correct: false,
            explanation: "L'aide est conditionnée à des critères précis vérifiés en amont, pas simplement à "
                "la présentation d'une facture après coup.",
          ),
          FormationQuizOption(
            text: "L'aide est généralement conditionnée à un artisan certifié RGE ET à un dossier monté "
                "avant le démarrage des travaux — les deux conditions non respectées ici compromettent "
                "l'éligibilité.",
            correct: true,
            explanation: "Exact. Ces deux conditions, souvent découvertes trop tard par les primo-acheteurs, "
                "doivent être vérifiées avant même de choisir l'artisan, pas après la fin du chantier.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Ton budget travaux est limité. Tu dois choisir entre refaire la cuisine (valorisation, "
            "pas obligatoire) et mettre aux normes l'installation électrique (obligatoire, conditionne la "
            "location) — un seul des deux chantiers est finançable pour l'instant. Lequel prioriser ?",
        options: [
          FormationQuizOption(
            text: "La cuisine, car elle a davantage d'impact visuel pour attirer un locataire rapidement.",
            correct: false,
            explanation: "L'impact visuel ne sert à rien si le bien ne peut légalement pas être loué faute "
                "de mise aux normes — la priorité va toujours à ce qui conditionne la location elle-même.",
          ),
          FormationQuizOption(
            text: "La mise aux normes électrique, car elle conditionne la possibilité même de louer "
                "légalement — la valorisation peut attendre un second temps.",
            correct: true,
            explanation: "Exactement la bonne priorisation : un chantier obligatoire passe toujours avant un "
                "chantier de valorisation quand le budget ne permet pas de faire les deux à la fois.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un bien est actuellement classé E au DPE. Sans aucun travaux, à partir de quand son "
            "propriétaire risque-t-il de ne plus pouvoir le louer légalement ?",
        options: [
          FormationQuizOption(
            text: "Dès maintenant : le classement E est d'ores et déjà interdit à la location.",
            correct: false,
            explanation: "Le classement E n'est pas encore concerné par une interdiction — seul le G l'est "
                "déjà aujourd'hui, le F le sera en 2028.",
          ),
          FormationQuizOption(
            text: "À partir de 2034, selon le calendrier légal d'interdiction progressive (G déjà, F en "
                "2028, E en 2034).",
            correct: true,
            explanation: "Exact — un calendrier à connaître précisément : un bien classé E aujourd'hui reste "
                "louable, mais son propriétaire a tout intérêt à anticiper les travaux bien avant l'échéance "
                "de 2034.",
          ),
          FormationQuizOption(
            text: "Jamais : seuls les classements F et G sont concernés par une interdiction de location.",
            correct: false,
            explanation: "Le calendrier légal prévoit aussi l'interdiction du classement E à partir de 2034 "
                "— ce n'est pas un classement épargné, seulement un peu plus de temps avant l'échéance.",
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
        scenario: "Tu loues un studio nu, acheté comptant (aucun crédit en cours), avec très peu de charges "
            "annuelles. Dans ce cas précis, lequel du micro-foncier ou du régime réel est probablement le "
            "plus avantageux ?",
        options: [
          FormationQuizOption(
            text: "Le régime réel, systématiquement plus avantageux dès qu'on loue un bien.",
            correct: false,
            explanation: "Sans crédit à déduire et avec peu de charges réelles, le principal levier du régime "
                "réel (déduire les intérêts d'emprunt) disparaît — ce n'est donc pas automatique.",
          ),
          FormationQuizOption(
            text: "Le micro-foncier : sans crédit en cours, les charges réelles déductibles sont souvent "
                "inférieures à l'abattement forfaitaire de 30 %, ce qui rend le réel moins intéressant que "
                "d'habitude.",
            correct: true,
            explanation: "Exactement — le régime réel devient surtout avantageux quand il y a un crédit en "
                "cours ou des charges significatives à déduire. Sans ces deux leviers, l'abattement "
                "forfaitaire peut rester le plus simple ET le plus favorable.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Une SCI à l'impôt sur le revenu (IR) a-t-elle pour but principal de réduire l'impôt payé "
            "sur les loyers, comme une SCI à l'impôt sur les sociétés (IS) ?",
        options: [
          FormationQuizOption(
            text: "Oui, c'est sa fonction principale, au même titre qu'une SCI à l'IS.",
            correct: false,
            explanation: "Une SCI à l'IR est fiscalement transparente : chaque associé est imposé exactement "
                "comme s'il détenait le bien en direct — elle ne procure aucun avantage fiscal particulier "
                "sur les loyers.",
          ),
          FormationQuizOption(
            text: "Non : une SCI à l'IR est fiscalement transparente — elle sert surtout à organiser la "
                "détention à plusieurs ou la transmission, pas à optimiser l'impôt.",
            correct: true,
            explanation: "Exact — c'est la SCI à l'IS, pas celle à l'IR, qui permet d'amortir le bien comme "
                "en LMNP. Confondre les deux structures mène à un mauvais choix dès le départ.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu revends un bien détenu depuis 25 ans, en nom propre. Concernant l'impôt sur le revenu "
            "(19 %) et les prélèvements sociaux (17,2 %) qui s'appliquent normalement à la plus-value, où "
            "en es-tu exactement ?",
        options: [
          FormationQuizOption(
            text: "Totalement exonéré des deux : l'abattement devient complet dès 22 ans de détention, pour "
                "l'impôt comme pour les prélèvements sociaux.",
            correct: false,
            explanation: "Les deux taxes suivent des calendriers différents : l'exonération d'impôt sur le "
                "revenu arrive bien à 22 ans, mais celle des prélèvements sociaux n'arrive qu'à 30 ans.",
          ),
          FormationQuizOption(
            text: "Exonéré de l'impôt sur le revenu (seuil de 22 ans atteint), mais pas encore totalement "
                "des prélèvements sociaux (seuil de 30 ans).",
            correct: true,
            explanation: "Exactement — à 25 ans de détention, seule l'exonération d'impôt sur le revenu est "
                "acquise ; il reste encore 5 ans avant l'exonération complète des prélèvements sociaux.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu loues en LMNP au régime réel depuis cette année. Ton résultat fiscal ressort à 0 € "
            "grâce à l'amortissement. Dois-tu quand même remplir une liasse fiscale complète ?",
        options: [
          FormationQuizOption(
            text: "Non, un résultat à 0 € dispense de toute déclaration pour cette activité.",
            correct: false,
            explanation: "Un résultat nul ne dispense de rien : la liasse fiscale documente justement COMMENT "
                "ce résultat a été obtenu (amortissements, charges) — elle reste due même sans impôt à "
                "payer.",
          ),
          FormationQuizOption(
            text: "Oui : la liasse fiscale dédiée reste obligatoire chaque année, que le résultat fiscal "
                "soit positif, nul ou négatif.",
            correct: true,
            explanation: "Exact — l'obligation déclarative est indépendante du montant d'impôt dû, et "
                "l'oublier expose à des pénalités même quand aucun impôt n'était finalement à payer.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu restes au régime micro-foncier pour un unique bien loué nu, sans projet d'évolution. "
            "Un comptable te propose ses services pour 350 €/an. Est-ce généralement un bon calcul dans "
            "cette situation précise ?",
        options: [
          FormationQuizOption(
            text: "Oui, un comptable est toujours rentable, quel que soit le régime fiscal choisi.",
            correct: false,
            explanation: "Au micro-foncier, l'abattement est automatique et forfaitaire — il n'y a "
                "structurellement rien à optimiser, contrairement au régime réel ou au LMNP.",
          ),
          FormationQuizOption(
            text: "Rarement : au micro-foncier, il n'y a rien à optimiser, donc un comptable n'apporte "
                "généralement aucune valeur ajoutée dans ce cas précis.",
            correct: true,
            explanation: "Exactement — l'utilité d'un comptable dépend directement du régime : indispensable "
                "ou presque dès le réel ou le LMNP réel, superflu au micro-foncier ou micro-BIC.",
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
        scenario: "Tu vis à 600 km de ton bien locatif et tu as très peu de temps libre. Un ami te dit que "
            "gérer soi-même permet toujours d'économiser de l'argent par rapport à une agence. Est-ce vrai "
            "dans TA situation ?",
        options: [
          FormationQuizOption(
            text: "Oui, gérer soi-même est toujours plus rentable, quelle que soit la situation.",
            correct: false,
            explanation: "Les frais de gestion économisés peuvent être annulés par les coûts indirects d'une "
                "gestion mal adaptée à distance : délais de réaction sur un incident, vacance locative plus "
                "longue, voire dégradations non traitées à temps.",
          ),
          FormationQuizOption(
            text: "Pas nécessairement : l'éloignement et le manque de disponibilité augmentent le risque de "
                "délais de réaction coûteux, qui peuvent annuler l'économie des frais de gestion.",
            correct: true,
            explanation: "Exactement — le bon calcul compare le coût de l'agence au coût RÉEL (pas seulement "
                "théorique) d'une gestion directe mal adaptée à ta situation, pas aux seuls frais de gestion "
                "économisés sur le papier.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un candidat locataire te propose de te fournir son relevé bancaire complet des 6 derniers "
            "mois pour « prouver sa solvabilité ». Dois-tu accepter ce document ?",
        options: [
          FormationQuizOption(
            text: "Oui, plus de documents vaut toujours mieux pour sécuriser mon choix de locataire.",
            correct: false,
            explanation: "La loi encadre strictement la liste des pièces qu'un propriétaire peut demander à "
                "un candidat locataire — accumuler des documents hors de cette liste n'est pas une précaution "
                "supplémentaire sans conséquence.",
          ),
          FormationQuizOption(
            text: "Non : la loi encadre strictement la liste des pièces qu'un propriétaire peut demander, et "
                "un relevé bancaire complet n'en fait généralement pas partie.",
            correct: true,
            explanation: "Exact — se renseigner sur cette liste légale avant de sélectionner un locataire "
                "évite à la fois un dossier insuffisant et une demande non conforme.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "À la sortie d'un locataire, tu constates une tache sur la moquette. L'état des lieux "
            "d'entrée, réalisé 3 ans plus tôt, mentionnait seulement « moquette bon état », sans aucune "
            "photo. Peux-tu facilement retenir une partie du dépôt de garantie pour cette tache ?",
        options: [
          FormationQuizOption(
            text: "Oui, la mention écrite « bon état » suffit largement à justifier une retenue.",
            correct: false,
            explanation: "Une mention écrite générale, sans photo datée, laisse une marge d'interprétation "
                "importante — elle ne prouve pas que cette tache précise n'existait pas déjà à l'entrée.",
          ),
          FormationQuizOption(
            text: "Difficilement : sans photo datée à l'entrée, il est difficile de prouver que cette tache "
                "précise n'existait pas déjà — un état des lieux non photographié affaiblit ta position.",
            correct: true,
            explanation: "Exactement pourquoi un état des lieux d'entrée précis et photographié, pièce par "
                "pièce, est la seule vraie protection en cas de litige à la sortie.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Le chauffe-eau tombe en panne chez ton locataire après 8 ans d'usage normal. Qui doit "
            "financer son remplacement ?",
        options: [
          FormationQuizOption(
            text: "Le locataire, puisque c'est lui qui utilise l'équipement au quotidien.",
            correct: false,
            explanation: "L'usage quotidien ne transfère pas la responsabilité d'un équipement qui s'use "
                "normalement — seule une dégradation causée par un mauvais usage relèverait du locataire.",
          ),
          FormationQuizOption(
            text: "Le propriétaire : une panne liée à l'usure normale relève de l'entretien du logement, à "
                "distinguer d'une dégradation causée par un mauvais usage du locataire.",
            correct: true,
            explanation: "Exact — cette distinction entre usure normale (propriétaire) et dégradation par "
                "mauvais usage (locataire) évite la plupart des conflits sur les réparations.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Un candidat locataire est jeune actif en CDI depuis seulement 2 mois, avec peu de recul "
            "pour valider une assurance loyers impayés (GLI) classique. Existe-t-il une alternative de "
            "garantie adaptée à ce profil précis ?",
        options: [
          FormationQuizOption(
            text: "Non, sans GLI classique validée, il n'existe aucune solution de garantie pour ce profil.",
            correct: false,
            explanation: "Il existe justement une alternative pensée pour ce type de profil, pas seulement "
                "la GLI classique qui exclut souvent les dossiers trop récents.",
          ),
          FormationQuizOption(
            text: "Oui : la caution Visale, qui cible notamment les jeunes actifs, peut se substituer à une "
                "GLI classique pour ce type de profil.",
            correct: true,
            explanation: "Exact — la caution Visale existe précisément pour sécuriser des profils que la GLI "
                "classique accepte difficilement, sans exclure ces candidats de ta recherche.",
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
        scenario: "Un bien acheté 130 000 € est aujourd'hui estimé à 175 000 €, avec un capital restant dû "
            "de 80 000 €. Tu veux financer un second projet mais tu n'as pas d'épargne liquide disponible. "
            "Que permet potentiellement cette situation, sans vendre le premier bien ?",
        options: [
          FormationQuizOption(
            text: "Rien : sans épargne liquide disponible, il est impossible de financer un second projet.",
            correct: false,
            explanation: "L'épargne liquide n'est pas le seul levier possible — la valeur du bien lui-même, "
                "une fois revalorisée, peut aussi servir de base à un financement.",
          ),
          FormationQuizOption(
            text: "Solliciter un refinancement auprès de ta banque pour dégager une capacité financière "
                "basée sur la revalorisation du bien, utilisable comme apport pour un second achat.",
            correct: true,
            explanation: "Exactement le mécanisme du refinancement : la revalorisation (175 000 € contre "
                "80 000 € restant dû) représente une capacité réelle, mobilisable sans attendre d'avoir "
                "épargné ailleurs.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu envisages de revendre un bien après seulement 12 ans de détention en nom propre, "
            "principalement pour profiter d'une belle plus-value immédiate. Qu'as-tu intérêt à vérifier "
            "avant de te décider ?",
        options: [
          FormationQuizOption(
            text: "Rien de particulier : une plus-value est toujours intéressante à encaisser dès qu'elle se "
                "présente.",
            correct: false,
            explanation: "La plus-value brute n'est pas le seul chiffre à regarder — la fiscalité qui "
                "s'applique encore à 12 ans de détention peut représenter une part significative de ce "
                "montant.",
          ),
          FormationQuizOption(
            text: "Le montant de l'abattement fiscal auquel tu renonces en vendant avant 22 ans "
                "(exonération d'impôt) et 30 ans (exonération des prélèvements sociaux).",
            correct: true,
            explanation: "Exactement : à 12 ans, l'imposition sur la plus-value reste significative — "
                "attendre plus longtemps pourrait augmenter sensiblement la plus-value NETTE perçue à la "
                "revente.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu as un crédit immobilier à 4,2 % souscrit il y a 4 ans. Les taux du marché sont depuis "
            "descendus à 3,1 % pour un profil similaire au tien, et tu n'as jamais réétudié ton crédit "
            "depuis la souscription. Quel est le risque concret de cette inaction ?",
        options: [
          FormationQuizOption(
            text: "Aucun risque : un taux fixe signé reste automatiquement optimisé par la banque au fil du "
                "temps.",
            correct: false,
            explanation: "Un taux fixe ne s'ajuste jamais automatiquement à la baisse — c'est à l'emprunteur "
                "de solliciter activement un rachat ou une renégociation s'il veut en profiter.",
          ),
          FormationQuizOption(
            text: "Payer des intérêts significativement plus élevés que nécessaire pendant toute la durée "
                "restante, alors qu'un rachat ou une renégociation pourrait réduire ce coût.",
            correct: true,
            explanation: "Exactement le risque d'un crédit jamais réétudié — l'écart de taux, cumulé sur les "
                "années restantes, représente souvent une somme loin d'être négligeable.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Après un seul premier achat réussi, un proche te pousse à diversifier immédiatement vers "
            "une stratégie totalement différente (courte durée, ville inconnue) « pour ne pas mettre tous "
            "ses œufs dans le même panier ». Ce conseil est-il bien appliqué à ce stade précis ?",
        options: [
          FormationQuizOption(
            text: "Oui, diversifier le plus tôt possible reste toujours la meilleure stratégie patrimoniale.",
            correct: false,
            explanation: "La diversification prend surtout son sens une fois plusieurs biens déjà acquis, "
                "pour répartir un risque déjà concentré — après un seul achat, il n'y a pas encore de "
                "concentration réelle à corriger.",
          ),
          FormationQuizOption(
            text: "Pas nécessairement : après un seul achat, approfondir la maîtrise d'une stratégie reste "
                "souvent plus prudent que diversifier immédiatement vers l'inconnu.",
            correct: true,
            explanation: "Exact — la diversification se construit progressivement, projet après projet, pas "
                "dès le premier achat où l'expérience reste encore limitée.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Tu détiens un bien en nom propre que tu comptes transmettre un jour à tes deux enfants. "
            "Pourquoi une donation-partage anticipée est-elle souvent recommandée plutôt que d'attendre la "
            "succession classique ?",
        options: [
          FormationQuizOption(
            text: "Parce qu'elle permet d'éviter totalement les droits de succession, contrairement à une "
                "succession classique.",
            correct: false,
            explanation: "La donation-partage ne supprime pas les droits à payer — elle s'appuie sur les "
                "mêmes abattements fiscaux, mais renouvelables dans le temps si elle est anticipée tôt.",
          ),
          FormationQuizOption(
            text: "Parce qu'elle permet de répartir le bien progressivement, dans la limite des abattements "
                "fiscaux, et d'éviter des conflits ultérieurs entre héritiers sur un bien difficile à "
                "diviser.",
            correct: true,
            explanation: "Exactement les deux avantages : lisser la fiscalité dans le temps, et clarifier la "
                "répartition avant qu'un désaccord entre héritiers ne survienne sur un bien physique.",
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
      FormationQuizQuestion(
        scenario: "Dans le cas n°3, quel élément aurait pu être détecté AVANT même la visite, simplement en "
            "consultant des statistiques publiques, sans avoir besoin d'un chiffrage complet ?",
        options: [
          FormationQuizOption(
            text: "Le montant exact des charges de copropriété de l'immeuble.",
            correct: false,
            explanation: "Ce montant précis ne figure dans aucune statistique publique — il faut le demander "
                "directement via les procès-verbaux d'assemblée générale, pas avant la prise de contact avec "
                "le bien.",
          ),
          FormationQuizOption(
            text: "La tendance démographique en déclin de la commune, disponible librement via l'INSEE.",
            correct: true,
            explanation: "Exactement — ce signal-là, contrairement au DPE ou aux charges, était accessible "
                "avant même de contacter l'agence, en reprenant simplement la méthode du module « Bien "
                "choisir sa zone ».",
          ),
          FormationQuizOption(
            text: "Le classement DPE précis du logement.",
            correct: false,
            explanation: "Le DPE est propre à chaque logement, pas à la commune — il ne peut être connu "
                "qu'une fois le bien identifié, via son diagnostic réel, pas via une statistique publique "
                "générale.",
          ),
        ],
      ),
      FormationQuizQuestion(
        scenario: "Le stress-test « Et si...? » (taux qui monte, occupation qui baisse, travaux imprévus) "
            "a-t-il été appliqué, dans ce module, à chacun des 4 cas présentés ?",
        options: [
          FormationQuizOption(
            text: "Oui, chaque cas intègre déjà un stress-test complet dans son chiffrage.",
            correct: false,
            explanation: "Les 4 cas présentent des simulations de base, pas des scénarios dégradés — le "
                "stress-test n'a été appliqué à aucun d'entre eux dans ce module.",
          ),
          FormationQuizOption(
            text: "Non : ce sont des simulations de base sans stress-test explicite — un exercice à "
                "reproduire toi-même dans Didou-Immo avant de te fier à l'un de ces profils.",
            correct: true,
            explanation: "Exact — et c'est volontaire : ces cas illustrent la méthode de chiffrage de base, "
                "le stress-test restant une étape supplémentaire à appliquer toi-même avant de t'engager sur "
                "un projet réel.",
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
