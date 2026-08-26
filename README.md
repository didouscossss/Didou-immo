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

### 1. Créer le projet Firebase
1. Aller sur https://console.firebase.google.com → Créer un projet
2. Activer **Authentication** (méthodes Email/mot de passe + Google)
3. Activer **Firestore Database** (mode production)
4. **Coller le contenu de `firestore.rules`** dans Firestore Database →
   Règles, puis publier — sans ça, Firestore refuse tout accès par défaut
   et rien ne fonctionnera (comptes, biens, parrainage)
5. Ajouter une app Android, package name `com.didouimmo.didou_immo`
   (voir `android/app/build.gradle.kts`), télécharger `google-services.json`
   → le placer dans `android/app/`
6. Ajouter une app Web (pour la version déployée sur GitHub Pages)
7. `flutterfire configure` à la racine du projet pour relier automatiquement
   les deux — ça génère `lib/firebase_options.dart` et met à jour
   `lib/main.dart` pour lui passer les vraies options. **Dès que ce fichier
   existe avec de vraies clés, les comptes s'activent automatiquement** —
   aucun autre changement de code n'est nécessaire (voir le mode local
   défensif dans `main.dart`)
8. Pour Google Sign-In **sur le web** spécifiquement : Firebase Console →
   Authentication → Google → récupérer le "Web client ID", puis l'ajouter
   dans `web/index.html` (`<meta name="google-signin-client_id" content="...">`)

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
Le contournement implémenté (`lib/services/referral_service.dart`) :

- Chaque compte a un code de parrainage unique (`DIDOU-XXXX`)
- Un nouveau compte qui saisit un code reçoit `pendingBonusDays` (+3 jours
  pour un mensuel, ou ajuster à +36 jours si tu factures l'annuel — voir
  constantes `bonusDaysMonthly` / `bonusDaysYearly`) ; le parrain reçoit le
  même bonus
- **Ces jours bonus doivent être appliqués par ta Cloud Function** au
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
- Firebase gratuit jusqu'à un volume confortable pour démarrer (plan Spark),
  passage au plan Blaze (payant à l'usage) seulement si le volume grossit
- Commission Google Play sur l'abonnement : 15 % (jusqu'à 1M$/an de revenus
  par app, sinon 30 % au-delà) — donc ~4,24€ net sur 4,99€/mois

## Développement

```bash
flutter pub get
flutter test       # analyse + tests des 5 écrans (novice/avancé, sauvegarde, comparatif)
flutter run
```
