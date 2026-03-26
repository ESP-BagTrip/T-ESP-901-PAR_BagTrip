# Profil voyageur et personnalisation

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip propose un profil voyageur en deux volets : les **informations personnelles** (nom, email, telephone) gerees via les endpoints auth, et les **preferences de voyage** (types de voyages, style, budget, compagnons, frequence, contraintes) gerees par un profil voyageur dedie. Un onboarding de personnalisation en 6 etapes guide les nouveaux utilisateurs pour collecter ces preferences, qui alimentent ensuite les recommandations IA de l'application. Le tout est persiste a la fois localement (SharedPreferences) et sur le serveur (table `traveler_profiles`).

---

## Cote Backend (API FastAPI)

### Endpoints profil voyageur

Prefixe `/v1/profile` (fichier `api/src/api/profile/routes.py`).

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/v1/profile` | Recupere le profil voyageur. Cree un profil vide si aucun n'existe. |
| PUT | `/v1/profile` | Cree ou met a jour le profil (upsert) avec les preferences. |
| GET | `/v1/profile/completion` | Verifie la completion du profil et retourne les champs manquants. |

Les informations personnelles (nom, telephone) sont gerees par les endpoints auth :

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/v1/auth/me` | Retourne les infos utilisateur incluant `isProfileCompleted`. |
| PATCH | `/v1/auth/me` | Met a jour `fullName` et/ou `phone`. |

### Schemas profil (`api/src/api/profile/schemas.py`)

- **ProfileCreateUpdateRequest** : `travelTypes` (list[str]?), `travelStyle` (str?), `budget` (str?), `companions` (str?)
- **ProfileResponse** : `id`, `travelTypes`, `travelStyle`, `budget`, `companions`, `isCompleted`, `createdAt`, `updatedAt`
- **ProfileCompletionResponse** : `isCompleted` (bool), `missingFields` (list[str])

### Modele TravelerProfile (`api/src/models/traveler_profile.py`)

Table `traveler_profiles` : `id` (UUID), `user_id` (FK users, unique), `travel_types` (JSON), `travel_style` (String), `budget` (String), `companions` (String), `medical_constraints` (String), `is_completed` (Boolean), `created_at`, `updated_at`.

Relation 1:1 avec `users` via `user_id` unique.

### ProfileService (`api/src/services/profile_service.py`)

Service stateless avec trois methodes :

- **get_profile** : recherche le profil par `user_id`.
- **create_or_update_profile** : upsert qui accepte `travel_types`, `travel_style`, `budget`, `companions`, `medical_constraints`. Calcule `is_completed = True` quand les 4 champs principaux sont remplis (`travel_types`, `travel_style`, `budget`, `companions`).
- **check_completion** : retourne `(bool, list[str])` avec le statut et la liste des champs manquants parmi `travelTypes`, `travelStyle`, `budget`, `companions`.

### Integration avec l'auth

L'endpoint `GET /v1/auth/me` appelle `ProfileService.check_completion` pour inclure `isProfileCompleted` dans la reponse `UserResponse`. Cela permet au mobile de savoir si l'onboarding a ete complete sans requete supplementaire.

---

## Cote Mobile (Flutter)

### Architecture profil

Le profil est structure en trois zones dans l'app :

1. **ProfileView** (`bagtrip/lib/profile/view/profile_view.dart`) : page principale du tab profil, affiche le header (avatar initiales, nom, date d'inscription) et des liens de navigation vers les sous-pages.
2. **PersonalInfoPage** (`bagtrip/lib/profile/view/personal_info_page.dart`) : edition du nom et du telephone via des dialogues adaptatifs.
3. **SettingsPage** (`bagtrip/lib/profile/view/settings_page.dart`) : preferences applicatives (langue, theme).

### UserProfileBloc (`bagtrip/lib/profile/bloc/user_profile_bloc.dart`)

Events :

| Event | Description |
|-------|-------------|
| `LoadUserProfile` | Charge les donnees utilisateur (auth) + profil voyageur (profile API) |
| `ResetUserProfile` | Reinitialise le state a `UserProfileInitial` |
| `UpdateUserName` | Met a jour le nom via `AuthRepository.updateUser` |
| `UpdateUserPhone` | Met a jour le telephone via `AuthRepository.updateUser` |

State `UserProfileLoaded` contient : `name`, `email`, `phone`, `memberSince`, `travelTypes`, `travelStyle`, `budget`, `companions`, `isUpdating`.

Le bloc charge les donnees en deux appels :
1. `AuthRepository.getCurrentUser()` pour les infos personnelles
2. `ProfileRepository.getProfile()` pour les preferences de voyage

### ProfileRepository (`bagtrip/lib/repositories/profile_repository.dart`)

Interface abstraite :
- `getProfile()` -> `Result<TravelerProfile>`
- `updateProfile({travelTypes?, travelStyle?, budget?, companions?})` -> `Result<TravelerProfile>`
- `checkCompletion()` -> `Result<ProfileCompletion>`

### Modele TravelerProfile (`bagtrip/lib/models/traveler_profile.dart`)

Modele Freezed : `id`, `travelTypes` (List<String>, defaut []), `travelStyle?`, `budget?`, `companions?`, `isCompleted` (defaut false), `createdAt?`, `updatedAt?`.

Modele companion `ProfileCompletion` : `isCompleted`, `missingFields` (List<String>).

### Widgets profil

- **ProfileHeaderCard** (`bagtrip/lib/profile/widgets/profile_header_card.dart`) : avatar avec initiales (gradient primary->secondary), nom, "Membre depuis {date}". Bouton edit sur l'avatar.
- **PersonalInfoSection** (`bagtrip/lib/profile/widgets/personal_info_section.dart`) : affiche nom, email (non editable), telephone. Boutons "Modifier" pour nom et telephone. Utilise `AdaptivePlatform.select` pour les icones.
- **ExperiencePersonalizationSection** (`bagtrip/lib/profile/widgets/experience_personalization_section.dart`) : affiche les preferences de voyage sous forme de chips. Lien vers le flow de personnalisation. Si aucune preference, affiche un message invitant a configurer.
- **PreferencesSection** (`bagtrip/lib/profile/widgets/preferences_section.dart`) : selection de la langue et du theme (light/dark/system) via le `SettingsBloc`.
- **LogoutButton** (`bagtrip/lib/profile/widgets/logout_button.dart`) : bouton de deconnexion qui dispatche `LogoutRequested` et navigue vers `/login`.
- **ProfileFooter** (`bagtrip/lib/profile/widgets/profile_footer.dart`) : pied de page du profil.

---

## Onboarding de personnalisation

### Flow en 6 etapes

L'onboarding est gere par le `PersonalizationBloc` (`bagtrip/lib/personalization/bloc/personalization_bloc.dart`) avec 6 etapes (step 0 a 5) :

| Step | Contenu | Widget |
|------|---------|--------|
| 0 | Ecran de bienvenue | `WelcomeStepContent` |
| 1 | Compagnons de voyage (solo, couple, famille, amis...) | `CompanionsStepContent` |
| 2 | Budget (economique, modere, confort, luxe) | `BudgetStepContent` |
| 3 | Types de voyages (multi-select : plage, culture, nature, aventure...) | `TravelTypesStepContent` |
| 4 | Frequence de voyage | `TravelFrequencyStepContent` |
| 5 | Contraintes (texte libre, ex: allergies, mobilite) | `ConstraintsStepContent` |

### PersonalizationBloc (`bagtrip/lib/personalization/bloc/personalization_bloc.dart`)

Events :

| Event | Description |
|-------|-------------|
| `LoadPersonalization` | Charge les preferences existantes (API puis fallback local) |
| `SetTravelTypes` | Met a jour le set de types de voyage |
| `SetTravelStyle` | Met a jour le style de voyage |
| `SetBudget` | Met a jour le budget |
| `SetCompanions` | Met a jour les compagnons |
| `SetTravelFrequency` | Met a jour la frequence |
| `SetConstraints` | Met a jour les contraintes |
| `PersonalizationNextStep` | Passe a l'etape suivante |
| `PersonalizationPreviousStep` | Retourne a l'etape precedente |
| `SkipPersonalization` | Saute l'onboarding (marque comme vu) |
| `SaveAndFinishPersonalization` | Sauvegarde locale + API puis termine |

States : `PersonalizationInitial`, `PersonalizationLoading`, `PersonalizationLoaded(step, userId, selectedTravelTypes, travelStyle?, budget?, companions?, travelFrequency?, constraints?)`, `PersonalizationCompleted`, `PersonalizationSkipped`.

### Logique de chargement

Le bloc essaye d'abord de charger depuis l'API (`ProfileRepository.getProfile`), puis en fallback depuis le stockage local (`PersonalizationStorage`). Si l'utilisateur n'a jamais vu l'ecran de bienvenue et n'a pas de preferences existantes, il demarre au step 0 (welcome). Sinon, il demarre au step 1.

### PersonalizationStorage (`bagtrip/lib/service/personalization_storage.dart`)

Stockage local via `SharedPreferences`, avec des cles prefixees par userId :
- `personalization_prompt_seen_{userId}` : l'onboarding a ete vu/skip
- `personalization_welcome_seen_{userId}` : l'ecran de bienvenue a ete vu
- `personalization_travel_types_{userId}` : types de voyage (CSV)
- `personalization_budget_{userId}` : budget
- `personalization_companions_{userId}` : compagnons
- `personalization_travel_style_{userId}` : style
- `personalization_travel_frequency_{userId}` : frequence
- `personalization_constraints_{userId}` : contraintes

### Sauvegarde (`SaveAndFinishPersonalization`)

1. Sauvegarde locale de tous les champs dans SharedPreferences
2. Marque l'onboarding comme vu (`setPersonalizationPromptSeen`, `setPersonalizationWelcomeSeen`)
3. Persiste vers le backend via `ProfileRepository.updateProfile` (best effort -- pas de retry en cas d'echec)
4. Emet `PersonalizationCompleted`

### PersonalizationView (`bagtrip/lib/personalization/view/personalization_view.dart`)

Vue qui ecoute le bloc :
- Sur `PersonalizationCompleted` ou `PersonalizationSkipped`, navigue en fonction du parametre `from` :
  - `createTripAi` -> `PlanTripRoute`
  - `profile` -> `ProfileRoute`
  - defaut -> `HomeRoute`
- Step 0 : ecran de bienvenue avec gradient, bouton "Start" et "Skip"
- Steps 1-5 : AppBar avec indicateur de progression (`PremiumStepIndicator`), contenu scrollable, bouton "Continuer" / "Terminer"
- Step 1 affiche aussi un bouton "Skip" sous le CTA

### Point d'entree de la personnalisation

La personnalisation est accessible depuis :
1. **Post-inscription** : la `LoginPage` redirige vers `PersonalizationRoute` si l'utilisateur n'a jamais vu le prompt
2. **Profil** : via le lien "Preferences de voyage" dans `ProfileView`, qui navigue vers `PersonalizationRoute(from: 'profile')`

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Photo de profil / avatar | Aucun upload de photo. L'avatar est genere a partir des initiales du nom (`profile_header_card.dart`). Le modele `User` n'a pas de champ `avatar_url`. | P1 |
| Frequence et contraintes non persistees en API | `SaveAndFinishPersonalization` dans `personalization_bloc.dart` (ligne 260) appelle `profileRepository.updateProfile` avec `travelTypes`, `travelStyle`, `budget`, `companions` mais PAS `travelFrequency` ni `constraints`. Ces deux champs restent uniquement en local (SharedPreferences). Le champ `medical_constraints` existe en base (`traveler_profile.py`) mais n'est pas expose dans le schema Pydantic `ProfileCreateUpdateRequest`. | P0 |
| Frequence de voyage absente du modele backend | Le champ `travelFrequency` n'existe pas dans le modele `TravelerProfile` SQLAlchemy ni dans les schemas API. Il est uniquement stocke localement. | P1 |
| Frequence de voyage absente du modele Flutter | Le modele Freezed `TravelerProfile` (`bagtrip/lib/models/traveler_profile.dart`) ne contient pas de champ `travelFrequency`. | P1 |
| Pas de synchronisation bidirectionnelle | Quand l'utilisateur modifie ses preferences depuis un autre appareil, les donnees locales (SharedPreferences) ne sont pas mises a jour automatiquement. Le `LoadPersonalization` tente l'API d'abord mais la frequence/contraintes restent locales. | P2 |
| Tests profil Flutter absents | Aucun test dans `bagtrip/test/` pour `UserProfileBloc` ou les widgets profil. Seul `personalization_bloc_test.dart` existe pour la personnalisation. | P1 |
| Tests profil backend absents | Aucun fichier de test dans `api/tests/` pour les routes ou le service profil. | P1 |
| Edition email impossible | L'email est affiche comme non editable dans `PersonalInfoSection` (pas de `onEdit` passe pour le champ email). Pas de flow de changement d'email. | P2 |
| Validation des valeurs de preferences | Les champs `budget`, `companions`, `travelStyle` sont des strings libres cote API. Aucune validation d'enum ou de valeurs autorisees. | P2 |
| String en dur dans PersonalizationView | La step 5 (contraintes) a un titre et sous-titre en dur en francais dans `personalization_view.dart` (lignes 210, 228) au lieu d'utiliser les cles l10n. | P2 |
