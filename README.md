# Didou Immo — Rendement

Calculateur de rentabilité immobilière, aide à l'achat.

## Ce qui est déjà fait
- Projet Flutter initialisé (Android + Web), dépendances installées
- Logique de calcul complète en Dart (`lib/utils/calculations.dart`) — portée
  fidèlement depuis le prototype React (`rendement-app.jsx`) : rentabilité,
  régimes fiscaux, score d'investissement, projection patrimoniale, plus-value
  à la revente, comparateur d'offres de prêt, comparatif longue/courte durée
- Les 5 écrans du prototype portés en widgets Flutter (`lib/screens/rendement/`) :
  Bien, Marché (recherche de commune via geo.api.gouv.fr), Fiscalité,
  Projection (graphique `fl_chart`), Comparer — plus l'onboarding et le
  panneau méthodologie (Didou en guide, avec un peu d'animation)
- **Comptes** (`lib/screens/auth/`, `lib/state/user_account_state.dart`) :
  inscription/connexion email + Google, écran "Compte" (abonnement,
  parrainage, déconnexion), paywall après 3 biens gratuits (variable
  `FirestoreService.freeTrialsLimit`), écran admin pour générer des codes
  cadeaux (`lib/screens/admin/`)
- Biens enregistrés synchronisés sur Firestore une fois connecté
  (`RendementState.attachAccount`) ; en mode invité (pas de compte, ou
  Firebase pas encore configuré), tout reste local sur l'appareil comme
  avant — l'app ne casse jamais faute de Firebase, voir plus bas
- Règles de sécurité Firestore prêtes (`firestore.rules`)
- Projet Firebase "didou-immo" relié : `lib/firebase_options.dart` écrit à
  la main à partir des valeurs copiées depuis la Console (la CLI
  `flutterfire configure` n'a pas pu s'authentifier depuis cet
  environnement — réseau restreint), `google-services.json` en place, et
  le client OAuth web ajouté dans `web/index.html` pour Google Sign-In
- Cloud Function `applyReferralCode` écrite (`functions/index.js`) pour
  créditer le parrain en toute sécurité — **pas encore déployée**, voir
  "Ce qu'il reste à faire" → étape 1bis. Le parrainage ("J'ai un code de
  parrainage") ne fonctionnera qu'une fois déployée ; les codes cadeaux
  (`redeemAccessCode`), eux, marchent déjà via les règles Firestore

## Mode local vs mode connecté
`lib/main.dart` essaie d'initialiser Firebase au démarrage ; si ça échoue
(projet pas encore créé/configuré), l'app bascule silencieusement en mode
local : biens enregistrés en illimité sur l'appareil, pas d'écran de
compte, exactement le comportement d'avant l'ajout des comptes — la version
déployée sur GitHub Pages continue donc de fonctionner pendant que tu
configures Firebase. Une fois `flutterfire configure` exécuté avec un vrai
projet, les comptes s'activent automatiquement au prochain démarrage.

L'abonnement (Google Play Billing) n'a pas d'implémentation web : sur la
version GitHub Pages, l'écran "Passer en illimité" l'indique clairement
plutôt que de planter — l'achat réel ne sera possible que depuis l'app
Android.

## Ce qu'il reste à faire (dans l'ordre)

### 1. Finaliser le projet Firebase "didou-immo"
Le projet est créé et relié (`lib/firebase_options.dart`, `google-services.json`).
Il reste, dans https://console.firebase.google.com/project/didou-immo :
1. Activer **Authentication** → méthodes Email/mot de passe + Google, si ce
   n'est pas déjà fait
2. Activer **Firestore Database** (mode production) si ce n'est pas déjà fait
3. **Coller le contenu de `firestore.rules`** dans Firestore Database →
   Règles, puis publier — sans ça, Firestore refuse tout accès par défaut
   et rien ne fonctionnera (comptes, biens, parrainage), même avec la
   configuration ci-dessus en place
4. Activer **Storage** (mode production) si ce n'est pas déjà fait, puis
   **coller le contenu de `storage.rules`** dans Storage → Règles, publier —
   nécessaire pour le loyer/m² par commune (voir `LoyerReferenceService` et
   la section "Mettre à jour le loyer/m² par commune" plus bas)
5. Si tu ajoutes un jour une app iOS/macOS : relancer `flutterfire configure`
   depuis une machine avec un accès réseau normal (ça régénérera
   `lib/firebase_options.dart` en gardant Android + Web)

### 1bis. Déployer les Cloud Functions
Le parrainage écrit sur le compte d'un AUTRE utilisateur (le parrain) — les
règles Firestore ne peuvent pas autoriser ça de façon sûre pour un client,
donc cette opération passe par une Cloud Function (`functions/`), qui
tourne avec des privilèges admin côté serveur. **Tant qu'elles ne sont pas
déployées** : "J'ai un code de parrainage" renverra une erreur
(comportement voulu, pas de faille de sécurité en attendant).

Les fonctions se déploient automatiquement (`.github/workflows/deploy-functions.yml`)
à chaque `push` sur `main` qui touche `functions/` — même principe que le
déploiement de l'app web, sans avoir besoin d'un ordinateur ni de la CLI
Firebase. Une seule chose à faire une fois pour l'activer :

1. **Passer le projet Firebase en plan Blaze** (Firebase Console → ⚙️ →
   Utilisation et facturation) — obligatoire pour déployer *toute* Cloud
   Function, même si le volume reste dans le quota gratuit. Il faut une
   carte bancaire enregistrée, mais l'usage prévu ici ne coûtera rien en
   pratique — voir "Repères de coûts"
2. Génère une clé de compte de service : Console Firebase → ⚙️ → Paramètres
   du projet → Comptes de service → "Générer une nouvelle clé privée" →
   télécharge le fichier JSON
3. Colle le contenu de ce fichier JSON dans un secret GitHub : sur la page
   du dépôt GitHub → Settings → Secrets and variables → Actions → "New
   repository secret" → nom `FIREBASE_SERVICE_ACCOUNT`, valeur = tout le
   contenu du fichier JSON
4. Le prochain `push` sur `main` touchant `functions/` déploiera
   automatiquement — ou déclenche-le à la main depuis l'onglet Actions de
   GitHub → "Déployer les Cloud Functions" → "Run workflow"
5. Teste "J'ai un code de parrainage" dans l'app — l'erreur doit disparaître

### 1ter. Notification de mise à jour du loyer/m²
Une Cloud Function (`checkLoyerDatasetUpdate`, dans le même `functions/index.js`
que le parrainage — se déploie donc en même temps, étape 1bis ci-dessus)
vérifie chaque lundi si data.gouv.fr propose une version plus récente du
fichier "Carte des loyers", et t'envoie un email à
`valentin.champion31@gmail.com` si oui — pour penser à le retélécharger et
le republier depuis Mon compte → Administration (voir étape 3ter plus bas).
Elle ne republie rien elle-même, elle prévient juste.

L'envoi passe par ton compte Gmail (SMTP), via un **mot de passe
d'application** (jamais ton vrai mot de passe Gmail, et jamais stocké en
clair dans le dépôt — c'est un secret Firebase, distinct du secret GitHub
de l'étape 1bis) :

1. Active la validation en deux étapes sur ton compte Google si ce n'est pas
   déjà fait (obligatoire pour créer un mot de passe d'application) :
   https://myaccount.google.com/security
2. Crée un mot de passe d'application : https://myaccount.google.com/apppasswords
   → nom libre (ex. "Didou Immo") → copie le mot de passe généré (16
   caractères)
3. Enregistre-le comme secret, **sans CLI** : Google Cloud Console (le
   même compte que Firebase) → menu ☰ → Sécurité → Secret Manager →
   "Créer un secret" → nom exactement `GMAIL_APP_PASSWORD` → colle le mot
   de passe d'application comme valeur du secret → Créer
4. Le déploiement automatique (étape 1bis) prend le relais dès le prochain
   `push` — pas besoin de rejouer quoi que ce soit de spécial pour cette
   fonction

Le tout premier passage (juste après le déploiement) enregistre uniquement
la version actuelle du fichier comme référence, sans envoyer de mail — le
premier vrai mail n'arrivera qu'à la prochaine vraie mise à jour publiée par
data.gouv.fr (environ une fois par an).

⚠️ Si le secret `GMAIL_APP_PASSWORD` n'existe pas encore au moment d'un
déploiement, seul `checkLoyerDatasetUpdate` échouera (visible dans l'onglet
Actions de GitHub) — les autres fonctions (parrainage, etc.) se déploient
normalement malgré tout.

Une seconde Cloud Function du même genre, `checkDvfRecentDatasetUpdate`,
vérifie chaque lundi si data.gouv.fr propose une version plus récente du
fichier "Statistiques mensuelles DVF" (celui utilisé par la fonction
`refreshRecentPrix`, déclenchée depuis l'écran Administration), et envoie un
email au même compte si oui — pour penser à relancer le traitement complet
depuis Mon compte → Administration → "Prix récents (12 derniers mois
glissants)". Elle réutilise le même secret `GMAIL_APP_PASSWORD` (rien à
créer en plus).

### 2. Premier compte admin
Pas de compte admin par défaut. Une fois que tu t'es inscrit dans l'app :
Firestore Console → collection `users` → ton document (par ton `uid`) →
ajouter manuellement le champ `isAdmin: true` (booléen). L'écran
"Administration" (génération de codes cadeaux) apparaît alors dans
"Mon compte".

### 3. Configurer Google Play Console
1. Créer un compte développeur (25$, paiement unique) : https://play.google.com/console
2. Créer l'application, remplir la fiche store (description, captures d'écran, icône)
3. **Monétisation → Produits → Abonnements** :
   - Créer un abonnement `rendement_abonnement`
   - Ajouter une offre de base mensuelle à 4,99€
   - Ajouter une offre de base annuelle à 50€
4. Configurer les **Real-time Developer Notifications** (RTDN) pour que
   Google prévienne ton backend des renouvellements/annulations
5. Écrire une **Cloud Function** qui reçoit ces notifications et met à jour
   `isSubscribed` / `subscriptionExpiry` dans Firestore — ne jamais faire
   confiance uniquement à l'app pour débloquer le contenu payant

### 3bis. Parrainage (palier → accès gratuit à vie) et codes cadeaux

**Pourquoi ce n'est pas une vraie remise Play Store** : Google Play Billing
fixe les prix au niveau du produit, pas par utilisateur — impossible
d'appliquer -10 % à un code généré par un utilisateur au moment du paiement.
Un bonus en jours d'accès offerts a été essayé puis retiré (voir
l'historique du dépôt) : sans valeur réelle pour un abonné qui reste
abonné en continu — soit il a déjà l'accès, soit il se désabonne parce
qu'il ne veut de toute façon plus utiliser l'app.

Le mécanisme actuel (`lib/services/referral_service.dart` côté app,
`functions/index.js` → `applyReferralCode` + `activateSubscription` +
`checkReferralMilestones` côté serveur, toutes déployées automatiquement —
voir étape 1bis) : un **palier de parrainages qualifiés**, qui bascule le
parrain en accès gratuit à vie une fois atteint — un vrai avantage même
pour quelqu'un qui reste abonné en continu.

- Chaque compte a un code de parrainage unique (`DIDOU-XXXX`)
- Un nouveau compte qui saisit un code est simplement rattaché à son
  parrain (`applyReferralCode` pose `referredBy`/`referredByUid`) — aucun
  bonus immédiat
- Quand un compte active un abonnement, `activateSubscription` pose
  `subscriptionStartedAt` (une seule fois, jamais réécrit ensuite) —
  départ du décompte des 6 mois
- Chaque jour à 06h00, `checkReferralMilestones` marque "qualifié" tout
  filleul resté abonné en continu depuis au moins 6 mois
  (`REFERRAL_QUALIFY_DAYS`), recompte le total de filleuls qualifiés de
  chaque parrain concerné, et bascule son compte en accès gratuit à vie
  (`grantedFree`) une fois le seuil atteint : **10 filleuls qualifiés**, ou
  **8** si le parrain a lui-même été parrainé (`REFERRAL_MILESTONE_STANDARD`
  / `REFERRAL_MILESTONE_HEADSTART`, `functions/index.js`). Un email est
  envoyé à l'admin (même secret `GMAIL_APP_PASSWORD`) à chaque fois que
  quelqu'un atteint le palier — c'est un vrai coût (perte d'un abonné
  payant), utile à savoir.
- L'écran de parrainage (`ReferralScreen.referralEnabled = true`) affiche
  la progression ("X / 10 parrainages qualifiés") et est activé par défaut
  maintenant que les fonctions sont déployées ; repasser ce flag à `false`
  le masque sans rien perdre côté données.
- ⚠️ Ni `applyReferralCode` ni `activateSubscription` ne valident un vrai
  reçu d'achat (pas de vérification Real-time Developer Notifications) —
  elles font confiance à l'app pour les appeler à bon escient, exactement
  comme le faisait l'ancienne écriture cliente `setSubscribed` qu'elles
  remplacent. Un utilisateur qui forgerait l'appel `activateSubscription`
  pourrait donc encore se déclarer abonné sans payer ; seule une vraie
  validation de reçu côté serveur fermerait ce trou.

⚠️ **Limite assumée** : sans vérification Google Play, on ne peut pas
garantir "6 mois de paiement réel" — seulement "6 mois depuis la première
activation, toujours marqué `isSubscribed` en base". `isSubscribed` n'étant
jamais remis à `false` automatiquement (pas de détection d'annulation), un
compte qui paie une fois puis annule immédiatement resterait vu comme
abonné en continu par ce mécanisme. Le vrai frein anti-abus ici est
économique (il faut payer réellement au moins une fois par faux compte
pour espérer faire progresser un palier), pas une garantie stricte contre
une chaîne de comptes créés pour l'occasion. Une vraie garantie
demanderait l'intégration Google Play Developer API (vérification de reçu
+ suivi d'annulation), pas faite ici par choix explicite (discuté avec
l'utilisateur).

**Codes cadeaux (accès gratuit)** — deux options complémentaires :
- **Recommandé pour du volume** : les *codes promotionnels* natifs de Play
  Console (Monétisation → Codes promotionnels). Tu génères un lot de codes,
  Google gère la redemption et l'accès gratuit automatiquement — zéro code
  à écrire.
- **Pour un contrôle fin** (codes distribués toi-même, hors Play Store) :
  `redeemAccessCode()` dans `referral_service.dart`, déjà branché à l'écran
  `lib/screens/referral/referral_screen.dart`. Pour créer un code, utilise
  `createAccessCode()` depuis un script admin ou directement dans la
  console Firebase (collection `accessCodes`).

### 3ter. Mettre à jour le loyer/m² par commune
Le loyer/m² (jeu "Carte des loyers", Ministère chargé du Logement / ANIL)
est stocké sur Firebase Storage (`reference-data/loyers_communes.json`), PAS
compilé dans l'app — le mettre à jour ne demande donc AUCUNE nouvelle
version Play Store, juste republier le fichier. Une nouvelle édition sort
environ une fois par an.

1. Télécharger le fichier "Appartements" (nom se terminant par
   `appmefdhup.csv`) depuis la page data.gouv.fr "Carte des loyers" —
   l'écran Administration de l'app a un bouton qui copie ce lien
2. Dans l'app, aller dans **Mon compte → Administration** (compte admin
   requis, voir étape 2 ci-dessous) → section "Loyer/m² par commune" →
   sélectionner ce CSV
3. Vérifier l'aperçu (nombre de communes reconnues), puis "Publier cette
   mise à jour" — effectif immédiatement pour la session en cours, et pour
   tout le monde au prochain démarrage de leur app (cache local de 7 jours)

Le fichier `assets/data/loyers_communes.json` compilé dans l'app reste un
filet de sécurité (repli si Storage/le réseau sont indisponibles au premier
lancement) — pas la peine de le mettre à jour manuellement à chaque édition,
sauf si tu veux aussi rafraîchir ce filet de sécurité pour les nouvelles
installations. Voir `lib/services/loyer_import_service.dart` et
`loyer_reference_service.dart` pour le détail du format.

### 4. Test interne avant publication
- Ajouter ton compte Google en testeur interne dans Play Console
- Tester tout le parcours : inscription, 3 biens gratuits, paywall, achat
  (les achats en test ne débitent pas réellement)

### 5. Publication
- Générer le bundle : `flutter build appbundle --release`
- Uploader dans Play Console → suivi de version → production (ou d'abord
  test fermé/ouvert pour valider avant le grand public)
- Premier examen Google : compter 1 à 7 jours

### 6. Mises à jour futures
- Incrémenter `version` dans `pubspec.yaml` (ex. `1.0.1+2`)
- `flutter build appbundle --release` → nouvel upload dans Play Console
- Possibilité de déploiement progressif (ex. 10 % des utilisateurs d'abord)
  directement depuis Play Console

## Repères de coûts
- 25$ compte développeur Google (une fois)
- Firebase gratuit jusqu'à un volume confortable pour démarrer, mais le
  plan **Blaze** (facturation à l'usage) est obligatoire dès qu'une seule
  Cloud Function est déployée (`applyReferralCode`, étape 1bis) — le quota
  gratuit du plan Blaze (2 millions d'appels/mois) couvre largement un
  usage normal, donc en pratique ~0€ tant que le volume reste raisonnable
- Commission Google Play sur l'abonnement : 15 % (jusqu'à 1M$/an de revenus
  par app, sinon 30 % au-delà) — donc ~4,24€ net sur 4,99€/mois

## Développement

```bash
flutter pub get
flutter test       # analyse + tests des 5 écrans (novice/avancé, sauvegarde, comparatif)
flutter run
```
