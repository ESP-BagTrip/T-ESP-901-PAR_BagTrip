# Profil voyageur et personnalisation

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip expose un profil utilisateur en trois volets : (1) les **informations personnelles** (nom complet, telephone, email non editable) gerees via les endpoints auth, (2) le **profil voyageur** (preferences de voyage : types, style, budget, compagnons, frequence, contraintes medicales) persiste dans une table dediee `traveler_profiles`, et (3) les **reglages applicatifs mobiles** (langue, theme light/dark/system) stockes localement en `SharedPreferences`. Un onboarding de personnalisation en 6 etapes (welcome + 5 questions) est declenche apres signup ou login si l'utilisateur n'a jamais complete son profil voyageur. Les preferences alimentent l'agent IA de planification (`TripPlannerService`) en biaisant les choix d'activites et d'hebergements selon le style/budget/compagnons declares.

---

## Cote Backend (API FastAPI)

### Endpoints profil voyageur

Prefixe `/v1/profile` (fichier `api/src/api/profile/routes.py`). Authentification JWT obligatoire (`get_current_user`).

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/v1/profile` | Recupere le profil voyageur de l'utilisateur. Cree un profil vide via upsert si aucun n'existe. |
| PUT | `/v1/profile` | Cree ou met a jour (upsert) les preferences voyage. Tous les champs sont optionnels (patch-like). |
| GET | `/v1/profile/completion` | Retourne `is_completed` (bool) et `missing_fields` (list) parmi `travelTypes`, `travelStyle`, `budget`, `companions`. |

Les **informations personnelles** (nom, telephone) sont gerees par l'endpoint auth :

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/v1/auth/me` | Retourne les infos utilisateur, plan, generations IA restantes, et `isProfileCompleted` (delegue a `ProfileService.check_completion`). |
| PATCH | `/v1/auth/me` | Met a jour `fullName` et/ou `phone`. Email non editable. Re-calcule `isProfileCompleted` et renvoie la reponse complete. |

### Schemas Pydantic (`api/src/api/profile/schemas.py`)

| Schema | Champs |
|--------|--------|
| `ProfileCreateUpdateRequest` | `travelTypes` (list[str]?), `travelStyle` (str?), `budget` (str?), `companions` (str?), `travelFrequency` (str?), `medicalConstraints` (str?). Herite de `BagtripRequestModel` (camelCase). |
| `ProfileResponse` | `id` (UUID), `travelTypes`, `travelStyle`, `budget`, `companions`, `travelFrequency`, `medicalConstraints`, `isCompleted` (bool), `createdAt`, `updatedAt`. `populate_by_name=True`. |
| `ProfileCompletionResponse` | `isCompleted` (bool), `missingFields` (list[str]). |
| `UpdateUserRequest` (auth) | `fullName` (str?), `phone` (str?). Defini dans `api/src/api/auth/schemas.py`. |

### Modele TravelerProfile (`api/src/models/traveler_profile.py`)

Table `traveler_profiles`, relation 1:1 avec `users` (FK `user_id` UNIQUE) :

| Colonne | Type | Nullable | Notes |
|---------|------|----------|-------|
| `id` | UUID | non | Primary key, default uuid4 |
| `user_id` | UUID | non | FK `users.id`, unique, index |
| `travel_types` | JSON (postgresql) | oui | Liste de tags (plage, culture, nature, aventure...) |
| `travel_style` | String | oui | Style declare (ex: flexible, planifie) |
| `budget` | String | oui | Tier (economique, modere, confort, luxe) |
| `companions` | String | oui | Compagnons (solo, couple, famille, amis) |
| `travel_frequency` | String | oui | Frequence annuelle declaree |
| `medical_constraints` | String | oui | Texte libre (allergies, mobilite, regime) |
| `is_completed` | Boolean | non | Recalcule sur chaque upsert (cf. service) |
| `created_at` / `updated_at` | DateTime tz | non | server_default + onupdate |

Le modele `User` (`api/src/models/user.py`) porte les champs personnels : `email` (unique), `full_name`, `phone`, `created_at`. Pas de champ `avatar_url`.

### ProfileService (`api/src/services/profile_service.py`)

Service statique, trois methodes :

- **`get_profile(db, user_id)`** : retourne le `TravelerProfile` ou `None`.
- **`create_or_update_profile(db, user_id, travel_types?, travel_style?, budget?, companions?, medical_constraints?, travel_frequency?)`** : upsert. Cree un profil vide si absent, applique uniquement les champs non-`None` (patch semantique), puis recalcule `is_completed = all([travel_types, travel_style, budget, companions])`. `medical_constraints` et `travel_frequency` ne comptent pas pour `is_completed`. Commit + refresh.
- **`check_completion(db, user_id)`** : retourne `(bool, list[str])`. Liste des `missing_fields` parmi `travelTypes/travelStyle/budget/companions`.

Pas de `unit_of_work`, pas de pagination (profil 1:1), pas de dependency `TripAccess` (auth user-scoped uniquement).

### Tests backend

`api/tests/api/profile/test_profile_routes.py` couvre GET/PUT/completion (creation auto profil vide, upsert partiel, recalcul `is_completed`).

---

## Cote Mobile (Flutter)

### Architecture profil

Trois zones distinctes dans l'app, branchees sur trois BLoCs differents :

1. **`ProfileView`** (`bagtrip/lib/profile/view/profile_view.dart`) : tab profil principal. Affiche `ProfileHeaderCard` (avatar avec initiales, nom, "Membre depuis {date}"), 4 lignes de navigation (`PersonalInfoRoute`, `PersonalizationRoute(from: 'profile')`, `SubscriptionSettingsRoute`, `SettingsRoute`), `RecentBookingsSection`, `LogoutButton`, bouton delete account, `ProfileFooter`.
2. **`PersonalInfoPage`** (`bagtrip/lib/profile/view/personal_info_page.dart`) : edition du nom et du telephone via `showAdaptiveEditDialog`. Email lu mais non editable.
3. **`SettingsPage`** (`bagtrip/lib/profile/view/settings_page.dart`) : delegue a `PreferencesSection` (langue + theme).

`ProfilePage` (`bagtrip/lib/pages/profile_page.dart`) declenche `LoadUserProfile` au mount si `state is UserProfileInitial`, reset+reload si `state is UserProfileError`.

### UserProfileBloc (`bagtrip/lib/profile/bloc/user_profile_bloc.dart`)

Bloc app-level inject via `getIt`. Depend de `AuthRepository` (infos perso) et `ProfileRepository` (preferences voyage).

| Event | Description |
|-------|-------------|
| `LoadUserProfile` | Appelle `AuthRepository.getCurrentUser()` puis `ProfileRepository.getProfile()`. Emet `UserProfileLoaded` agrege. Si user null, logout + erreur auth. |
| `ResetUserProfile` | Emet `UserProfileInitial`. |
| `UpdateUserName` | Optimistic via `copyWith(isUpdating: true)`, appelle `AuthRepository.updateUser(fullName:)`, applique le nom retourne ou rollback isUpdating. |
| `UpdateUserPhone` | Idem pour `phone`. |

State `UserProfileLoaded` : `name`, `email`, `phone` (`—` si vide), `memberSince`, `travelTypes`, `travelStyle`, `budget`, `companions`, `isUpdating`. La frequence et les contraintes ne sont **pas** portees par ce state (lus uniquement dans le flux personnalisation).

### ProfileRepository (`bagtrip/lib/repositories/profile_repository.dart`)

Interface abstraite, implementation `ProfileRepositoryImpl` (`bagtrip/lib/service/profile_api_service.dart`) :

| Methode | Description |
|---------|-------------|
| `getProfile()` | `Result<TravelerProfile>` via GET `/profile`. |
| `updateProfile({travelTypes?, travelStyle?, budget?, companions?, travelFrequency?, medicalConstraints?})` | `Result<TravelerProfile>` via PUT `/profile`. Inclut uniquement les champs non-null dans le body. |
| `checkCompletion()` | `Result<ProfileCompletion>` via GET `/profile/completion`. |

### Modele TravelerProfile (`bagtrip/lib/models/traveler_profile.dart`)

Freezed avec `JsonKey` explicite : `id`, `travelTypes` (default `[]`), `travelStyle`, `budget`, `companions`, `travelFrequency`, `medicalConstraints`, `isCompleted` (default `false`), `createdAt`, `updatedAt`. Modele companion `ProfileCompletion` (`isCompleted`, `missingFields`).

### Widgets profil

- **`ProfileHeaderCard`** : avatar genere par initiales (gradient primary->secondary), nom, "Membre depuis {date}". Pas d'upload de photo.
- **`PersonalInfoSection`** : 3 lignes nom/email/telephone. Boutons "Modifier" sur nom et telephone uniquement (email designe non editable, pas de callback `onEditEmail`).
- **`ExperiencePersonalizationSection`** : carte preferences voyage, chips travel types, lignes style/budget/companions, message d'invitation a configurer si vide. Tap navigue vers `PersonalizationRoute(from: 'profile')`.
- **`PreferencesSection`** : `BlocBuilder<SettingsBloc>`. Langue via `showAdaptiveActionSheet` (Francais, English), theme via 3 cards `light` / `dark` / `system`.
- **`LogoutButton`** + bouton destructif delete account (`AuthBloc.DeleteAccountRequested`).
- **`RecentBookingsSection`** : injecte conditionnellement si `BookingBloc` resolvable, masque si pas de bookings.

### SettingsBloc (`bagtrip/lib/settings/bloc/settings_bloc.dart`)

Bloc leger app-level avec `autoLoad` declenche en ctor.

| Event | Description |
|-------|-------------|
| `LoadSettings` | Lit `SettingsStorage.getTheme()` (default `system`) et `getLanguage()` (default `Français`). |
| `ChangeTheme` | Emet le nouveau theme + persiste via `SettingsStorage.setTheme()`. |
| `ChangeLanguage` | Idem pour la langue. |

`SettingsState` : `selectedTheme` (`'light'`/`'dark'`/`'system'`), `selectedLanguage` (`'Français'`/`'English'`). Storage via `SharedPreferences` cles globales (`settings_theme`, `settings_language`), pas user-scoped.

### PersonalizationBloc (`bagtrip/lib/personalization/bloc/personalization_bloc.dart`)

Bloc local a `PersonalizationPage`. Depend de `AuthRepository`, `PersonalizationStorage`, `ProfileRepository`.

| Event | Description |
|-------|-------------|
| `LoadPersonalization` | Appelle `getCurrentUser`, puis tente `getProfile` API. Fallback `PersonalizationStorage` si l'API echoue. Determine `step` initial (0 si welcome jamais vu et aucune pref, sinon 1). |
| `SetTravelTypes` / `SetTravelStyle` / `SetBudget` / `SetCompanions` / `SetTravelFrequency` / `SetConstraints` | Setters in-state, pas de persistance immediate. |
| `PersonalizationNextStep` | Avance d'un step. Au passage de 0 -> 1, marque welcome comme vu. |
| `PersonalizationPreviousStep` | Recule d'un step (min 0). |
| `SkipPersonalization` | Marque prompt + welcome comme vus, emet `PersonalizationSkipped`. |
| `SaveAndFinishPersonalization` | Persiste **d'abord** vers l'API via `ProfileRepository.updateProfile(travelTypes, travelStyle?? 'flexible', budget, companions, travelFrequency, medicalConstraints: constraints)`. Sur succes : ecrit le cache local + marque prompt/welcome vus, emet `PersonalizationCompleted`. Sur echec : ne touche pas au cache local, emet erreur dans `saveError`. |

States : `PersonalizationInitial`, `PersonalizationLoading`, `PersonalizationLoaded(step, userId, selectedTravelTypes, travelStyle?, budget?, companions?, travelFrequency?, constraints?, isSaving, saveError?)`, `PersonalizationCompleted`, `PersonalizationSkipped`.

### PersonalizationStorage (`bagtrip/lib/service/personalization_storage.dart`)

Cache `SharedPreferences` user-scoped (cles suffixees par userId) :

| Cle | Contenu |
|-----|---------|
| `personalization_prompt_seen_{userId}` | bool, l'onboarding a ete vu/skip |
| `personalization_welcome_seen_{userId}` | bool, step 0 valide une fois |
| `personalization_travel_types_{userId}` | CSV des types |
| `personalization_travel_style_{userId}` | string |
| `personalization_budget_{userId}` | string |
| `personalization_companions_{userId}` | string |
| `personalization_travel_frequency_{userId}` | string |
| `personalization_constraints_{userId}` | string |

### Flow onboarding 6 etapes (`PersonalizationView`)

| Step | Question | Widget |
|------|----------|--------|
| 0 | Ecran de bienvenue (gradient, CTA Start + Skip) | `WelcomeStepContent` |
| 1 | Compagnons de voyage | `CompanionsStepContent` (single select) |
| 2 | Budget | `BudgetStepContent` (single select) |
| 3 | Types de voyages | `TravelTypesStepContent` (multi-select) |
| 4 | Frequence de voyage | `TravelFrequencyStepContent` (single select) |
| 5 | Contraintes (texte libre) | `ConstraintsStepContent` |

`PersonalizationView` ecoute `state.saveError` pour afficher un `SnackBar(l10n.errorNetwork)`. Sur `PersonalizationCompleted` ou `PersonalizationSkipped`, navigation selon le query parameter `from` : `createTripAi` -> `PlanTripRoute`, `profile` -> `ProfileRoute`, defaut -> `HomeRoute`. AppBar utilise `PremiumStepIndicator(current, total: 5)`.

### Tests mobile

- `bagtrip/test/blocs/user_profile_bloc_test.dart`, `personalization_bloc_test.dart`, `settings_bloc_test.dart`
- `bagtrip/test/service/personalization_storage_test.dart`, `settings_storage_test.dart`
- `bagtrip/test/personalization/personalization_view_test.dart` + 8 widget tests (welcome/budget/companions/types/frequency/constraints/chips/cards)
- `bagtrip/test/profile/profile_view_test.dart`, `recent_bookings_section_test.dart`

---

## Flux

### Onboarding post-signup

1. `SignUp/Login` reussit -> `LoginPage`/`SplashPage` recupere `user.isProfileCompleted` depuis `/auth/me`.
2. Si `isProfileCompleted == false` ET `PersonalizationStorage.hasSeenPersonalizationPrompt(userId) == false`, redirection vers `PersonalizationRoute()`.
3. `PersonalizationBloc.LoadPersonalization` charge l'API puis fallback local, determine step initial (0 si welcome jamais vu, sinon 1).
4. L'utilisateur traverse les steps via `PersonalizationNextStep` / `PersonalizationPreviousStep`.
5. Au step 5, `SaveAndFinishPersonalization` PUT `/v1/profile` puis cache local + flags vus. Navigation vers `HomeRoute`.

### Edition profil voyageur depuis le tab profil

1. `ProfileView` -> tap "Travel preferences" -> `PersonalizationRoute(from: 'profile').push()`.
2. Bloc recharge les preferences existantes (API en priorite), demarre au step 1 (welcome skip car deja vu).
3. Save -> retour `ProfileRoute` puis `UserProfileBloc.LoadUserProfile` est rejoue au prochain mount (state initial garde l'ancienne lecture jusqu'au reload manuel).

### Edition nom / telephone

1. `PersonalInfoPage` -> tap modifier -> `showAdaptiveEditDialog` -> PATCH `/v1/auth/me` via `AuthRepository.updateUser`.
2. `UserProfileBloc.UpdateUserName` / `UpdateUserPhone` emet `isUpdating: true` puis applique la valeur retournee par l'API ou rollback silencieux + log Crashlytics si echec.

### Settings (langue/theme)

1. `SettingsPage` -> `PreferencesSection` -> tap -> `SettingsBloc.ChangeLanguage` / `ChangeTheme`.
2. Persistance immediate dans `SharedPreferences` (cles globales). L'app racine ecoute `SettingsBloc` pour appliquer `ThemeMode` et `Locale`.

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Avatar / upload photo | Aucun champ `avatar_url` sur `User` cote backend, ni endpoint d'upload, ni picker mobile. L'avatar est genere a partir des initiales du nom dans `ProfileHeaderCard`. | P1 |
| Notification preferences absentes | Aucun endpoint, ni modele, ni UI pour gerer les notifications (push, email, in-app). Le scope mentionne "notifications" dans la page settings mais seuls langue et theme sont presents dans `PreferencesSection`. Les notifications FCM sont controlees au niveau OS uniquement. | P0 |
| `is_completed` ignore frequence et contraintes | `ProfileService.create_or_update_profile` calcule `is_completed = all([travel_types, travel_style, budget, companions])`. Les champs `travel_frequency` et `medical_constraints` collectes aux steps 4 et 5 de l'onboarding n'entrent pas dans le critere de completion. Consequence : un utilisateur peut completer son profil sans renseigner ces deux champs. | P2 |
| `travelStyle` non collecte par l'onboarding | Le flow personnalisation ne contient pas de step "travel style". `SaveAndFinishPersonalization` envoie `travelStyle: current.travelStyle ?? 'flexible'`. La valeur par defaut `'flexible'` est ecrite cote API meme si l'utilisateur n'a jamais ete questionne. | P1 |
| Settings non synchronises cote serveur | `SettingsBloc` persiste uniquement dans `SharedPreferences` locales (cles globales, pas user-scoped). Changement d'appareil = perte du theme/langue. Pas de table `user_settings` ni d'endpoint. | P2 |
| Edition email impossible | `PersonalInfoSection` n'expose pas `onEditEmail`. Pas de flow de changement d'email avec reverification cote backend. | P2 |
| Validation des valeurs preferences | Les champs `budget`, `companions`, `travelStyle`, `travelFrequency` sont des strings libres cote API. Aucune validation d'enum, aucun controle de coherence avec les IDs envoyes par les widgets de selection. Un client malveillant peut PUT n'importe quelle string. | P1 |
| `PreferencesSection` non i18n pour les langues | Les labels `'Français'` et `'English'` sont en dur dans `_buildLanguageRow` au lieu d'utiliser une cle l10n ou un enum. Le label sert aussi de valeur stockee dans `SharedPreferences`, ce qui couple l'affichage et la cle. | P2 |
| Strings personnalization step 5 en dur | `PersonalizationView._stepTitle` et `_stepSubtitle` retournent `'Contraintes'` et `'Des restrictions ou contraintes pour votre voyage ?'` en francais hardcode pour le step 5 (lignes 222 et 239). Pas de cle l10n. | P2 |
| Skip de l'onboarding non re-proposable | Une fois `personalization_prompt_seen_{userId}` mis a true, l'utilisateur ne revoit jamais l'invite a configurer (sauf via la carte profile). Pas de reset ni de rappel au bout de N jours sans preferences. | P2 |
| Pas de logout flush du cache personnalization | `PersonalizationStorage` utilise des cles user-scoped donc cohabite OK entre comptes, mais aucun flush actif au logout / delete account. Sur un appareil partage, les preferences d'un compte supprime restent en `SharedPreferences`. | P2 |
