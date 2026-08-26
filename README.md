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
4. Si tu ajoutes un jour une app iOS/macOS : relancer `flutterfire configure`
   depuis une machine avec un accès réseau normal (ça régénérera
   `lib/firebase_options.dart` en gardant Android + Web)

### 1bis. Déployer la Cloud Function de parrainage
Le parrainage écrit sur le compte d'un AUTRE utilisateur (le parrain) — les
règles Firestore ne peuvent pas autoriser ça de façon sûre pour un client,
donc cette opération passe par une Cloud Function (`functions/`), qui
tourne avec des privilèges admin côté serveur. **Elle n'est pas encore
déployée** : en attendant, "J'ai un code de parrainage" renverra une
erreur (comportement voulu, pas de faille de sécurité en attendant).

Impossible de la déployer depuis la Console Firebase seule (pas d'éditeur
de code pour les Functions dans le navigateur) — il faut une CLI, donc un
ordinateur (le tien ou celui d'une personne qui t'aide) :

1. **Passer le projet Firebase en plan Blaze** (Firebase Console → ⚙️ →
   Utilisation et facturation) — obligatoire pour déployer *toute* Cloud
   Function, même si le volume reste dans le quota gratuit. Il faut une
   carte bancaire enregistrée, mais l'usage prévu ici (quelques appels de
   fonction) ne coûtera rien en pratique — voir "Repères de coûts"
2. Installer les CLI : `npm install -g firebase-tools`, puis
   `dart pub global activate flutterfire_cli` (déjà fait si tu as suivi
   l'étape 1 — sinon uniquement `firebase-tools` est nécessaire ici)
3. `firebase login` (ouvre le navigateur pour se connecter avec le compte
   Google propriétaire du projet)
4. Depuis la racine du projet (là où se trouve `firebase.json`) :
   `firebase deploy --only functions`
5. Teste "J'ai un code de parrainage" dans l'app — l'erreur doit
   disparaître

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

### 3bis. Parrainage (-10 %) et codes cadeaux

**Pourquoi ce n'est pas une vraie remise Play Store** : Google Play Billing
fixe les prix au niveau du produit, pas par utilisateur — impossible
d'appliquer -10 % à un code généré par un utilisateur au moment du paiement.
Le contournement implémenté (`lib/services/referral_service.dart` côté
app, `functions/index.js` → `applyReferralCode` côté serveur, à déployer
— voir étape 1bis) :

- Chaque compte a un code de parrainage unique (`DIDOU-XXXX`)
- Un nouveau compte qui saisit un code reçoit `pendingBonusDays` (+3 jours
  pour un mensuel, ou ajuster à +36 jours si tu factures l'annuel — voir
  constantes `bonusDaysMonthly` / `BONUS_DAYS_MONTHLY`, à garder en phase
  entre le Dart et la Cloud Function) ; le parrain reçoit le même bonus
- **Ces jours bonus doivent en plus être appliqués par ta Cloud Function
  de facturation** au
  moment où l'abonnement réel est confirmé via RTDN : additionner
  `pendingBonusDays` à `subscriptionExpiry`, puis remettre
  `pendingBonusDays` à 0. Pseudo-code :
  ```js
  // dans la Cloud Function qui traite les notifications Play Billing
  const bonus = userDoc.data().pendingBonusDays || 0;
  if (bonus > 0) {
    subscriptionExpiry = subscriptionExpiry.plusDays(bonus);
    await userRef.update({ pendingBonusDays: 0 });
  }
  ```

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
