# Onboarding & Profil voyageur — BagTrip

## Vue d'ensemble

Le module onboarding permet de collecter les preferences de voyage de l'utilisateur en 4 etapes apres l'inscription. Les preferences sont persistees **en backend** (PostgreSQL) et **en local** (SharedPreferences) en fallback. Le splash screen redirige automatiquement vers le flow de personnalisation si le profil est incomplet.

```
┌──────────┐         ┌──────────────┐         ┌──────────────┐
│  Mobile   │────────>│  Backend API │────────>│  PostgreSQL  │
│  Flutter  │<────────│  FastAPI     │<────────│              │
└──────────┘         └──────────────┘         └──────────────┘
     │                      │
     │                      └── Table traveler_profiles
     │
     ├── SharedPreferences (fallback local)
     ├── ProfileApiService (sync backend)
     └── PersonalizationBloc (state management)
```

### Donnees collectees

| Etape | Champ | Type | Description |
|:-----:|-------|------|-------------|
| 1 | `travelTypes` | `list[str]` | Types de voyage preferes (multi-select) : plage, aventure, ville, gastronomie, wellness, fete |
| 2 | `travelStyle` | `str` | Style d'organisation : planifie, flexible, spontane |
| 3 | `budget` | `str` | Budget habituel : economique, modere, luxe |
| 4 | `companions` | `str` | Compagnons de voyage : solo, couple, famille, amis |

---

## Backend (api/)

### Table traveler_profiles

```sql
CREATE TABLE traveler_profiles (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id),
    travel_types  JSONB,                            -- liste de strings
    travel_style  VARCHAR,
    budget        VARCHAR,
    companions    VARCHAR,
    is_completed  BOOLEAN NOT NULL DEFAULT FALSE,   -- calcule automatiquement
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE UNIQUE INDEX ix_traveler_profiles_user_id ON traveler_profiles (user_id);
```

Le modele SQLAlchemy correspondant est dans `api/src/models/traveler_profile.py`. La table est creee automatiquement au demarrage via une migration idempotente dans `api/src/migrations/migrate_traveler_profiles.py`.

Le champ `is_completed` est **calcule cote serveur** a chaque upsert : il vaut `true` uniquement si les 4 champs (`travel_types`, `travel_style`, `budget`, `companions`) sont tous renseignes.

### Endpoints

Tous sous le prefixe `/v1/profile`. Toutes les routes requierent un access token valide (`Authorization: Bearer <token>`).

| Methode | Route | Description |
|---------|-------|-------------|
| GET | `/v1/profile` | Recuperer le profil (cree un profil vide si inexistant) |
| PUT | `/v1/profile` | Creer ou mettre a jour le profil (upsert) |
| GET | `/v1/profile/completion` | Verifier la completion et lister les champs manquants |

#### GET /v1/profile

Retourne le profil du user authentifie. Si aucun profil n'existe, en cree un vide automatiquement.

**Reponse** :
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "travelTypes": ["plage", "aventure"],
  "travelStyle": "flexible",
  "budget": "modere",
  "companions": "solo",
  "isCompleted": true,
  "createdAt": "2026-01-15T10:30:00Z",
  "updatedAt": "2026-01-15T10:35:00Z"
}
```

#### PUT /v1/profile

Upsert du profil : cree un nouveau profil ou met a jour l'existant. Le champ `isCompleted` est recalcule automatiquement.

**Body** :
```json
{
  "travelTypes": ["plage", "gastronomie"],
  "travelStyle": "aventure",
  "budget": "modere",
  "companions": "solo"
}
```

Tous les champs sont optionnels — seuls les champs fournis sont mis a jour.

**Reponse** : meme format que `GET /v1/profile`.

#### GET /v1/profile/completion

Verifie si le profil est complet et retourne la liste des champs manquants.

**Reponse** :
```json
{
  "isCompleted": false,
  "missingFields": ["travelStyle", "companions"]
}
```

### Integration avec /me

L'endpoint `GET /v1/auth/me` inclut desormais le champ `isProfileCompleted` :

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "createdAt": "2026-01-15T10:30:00Z",
  "updatedAt": null,
  "isProfileCompleted": true
}
```

Ce champ est calcule dynamiquement a chaque appel via `ProfileService.check_completion()`. Les endpoints d'authentification (`register`, `login`, `google`, `apple`, `refresh`) retournent `false` par defaut (le profil n'a pas encore ete rempli a l'inscription).

### ProfileService

`api/src/services/profile_service.py` expose 3 methodes statiques :

| Methode | Description |
|---------|-------------|
| `get_profile(db, user_id)` | Retourne le `TravelerProfile` ou `None` |
| `create_or_update_profile(db, user_id, ...)` | Upsert + recalcul `is_completed` |
| `check_completion(db, user_id)` | Retourne `(bool, list[str])` — completion + champs manquants |

### Fichiers cles — Backend

| Fichier | Role |
|---------|------|
| `api/src/models/traveler_profile.py` | Modele SQLAlchemy TravelerProfile |
| `api/src/migrations/migrate_traveler_profiles.py` | Migration idempotente (creation table + index) |
| `api/src/api/profile/schemas.py` | Schemas Pydantic (request, response, completion) |
| `api/src/api/profile/routes.py` | Endpoints API profil (GET, PUT, completion) |
| `api/src/services/profile_service.py` | Logique metier profil |
| `api/src/api/auth/schemas.py` | UserResponse avec `isProfileCompleted` |
| `api/src/api/auth/routes.py` | Endpoint `/me` enrichi avec completion profil |

---

## Mobile (bagtrip/)

### Flow de navigation au demarrage

```
SplashPage
    │
    ├── waitForBackendReady()
    ├── authService.getCurrentUser()
    │
    ├── user != null ?
    │   ├── user.isProfileCompleted == false ?
    │   │   ├── PersonalizationStorage.hasSeenPrompt(user.id) ?
    │   │   │   ├── non  ──> context.go('/personalization')
    │   │   │   └── oui  ──> context.go('/home')
    │   │   └── oui ──> context.go('/home')
    │   └── oui ──> context.go('/home')
    │
    └── user == null ?
        ├── OnboardingStorage.hasSeenOnboarding() ?
        │   ├── oui ──> context.go('/login')
        │   └── non ──> context.go('/onboarding')
```

Le double-check (API `isProfileCompleted` + local `hasSeenPrompt`) garantit que :
- Un utilisateur dont le profil est deja complet en backend ne voit jamais le flow
- Un utilisateur qui a skip le flow en local n'est pas bloque (il pourra completer plus tard depuis la page profil)

### ProfileApiService

`bagtrip/lib/service/profile_api_service.dart` expose :

| Methode | Endpoint | Description |
|---------|----------|-------------|
| `getProfile()` | GET /profile | Recuperer le profil backend |
| `updateProfile({...})` | PUT /profile | Upsert du profil |
| `checkCompletion()` | GET /profile/completion | Verifier completion |

### Modeles Dart

**TravelerProfile** (`bagtrip/lib/models/traveler_profile.dart`) :

```dart
class TravelerProfile {
  final String id;
  final List<String> travelTypes;
  final String? travelStyle;
  final String? budget;
  final String? companions;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

**ProfileCompletion** (meme fichier) :

```dart
class ProfileCompletion {
  final bool isCompleted;
  final List<String> missingFields;
}
```

**User** (`bagtrip/lib/models/user.dart`) — champ ajoute :

```dart
final bool isProfileCompleted; // default false, parse depuis json['isProfileCompleted']
```

### PersonalizationBloc

`bagtrip/lib/personalization/bloc/personalization_bloc.dart` gere le flow de personnalisation en 4 etapes via le pattern BLoC.

**Dependencies** :
- `AuthService` — recuperer l'utilisateur courant
- `PersonalizationStorage` — persistance locale (SharedPreferences)
- `ProfileApiService` — persistance backend

**Events** :

| Event | Description |
|-------|-------------|
| `LoadPersonalization` | Charger les preferences existantes (API d'abord, fallback local) |
| `SetTravelTypes` | Selectionner les types de voyage (etape 1) |
| `SetTravelStyle` | Choisir le style de voyage (etape 2) |
| `SetBudget` | Choisir le budget (etape 3) |
| `SetCompanions` | Choisir les compagnons (etape 4) |
| `PersonalizationNextStep` | Passer a l'etape suivante |
| `PersonalizationPreviousStep` | Revenir a l'etape precedente |
| `SkipPersonalization` | Passer le flow (marque comme vu en local) |
| `SaveAndFinishPersonalization` | Sauvegarder en local + backend, puis terminer |

**States** :

| State | Description |
|-------|-------------|
| `PersonalizationInitial` | Etat initial (pas charge) |
| `PersonalizationLoading` | Chargement en cours |
| `PersonalizationLoaded` | Donnees chargees (step, userId, preferences) |
| `PersonalizationCompleted` | Sauvegarde terminee — naviguer vers home |
| `PersonalizationSkipped` | Flow passe — naviguer vers home |

**Strategie de persistance** :

```
LoadPersonalization:
    1. Tenter ProfileApiService.getProfile()
    2. Si echec → fallback PersonalizationStorage (local)
    3. Emettre PersonalizationLoaded avec les donnees

SaveAndFinishPersonalization:
    1. Sauvegarder en local (PersonalizationStorage) — toujours
    2. Sauvegarder en backend (ProfileApiService.updateProfile) — best effort (try/catch)
    3. Emettre PersonalizationCompleted
```

Le local-first garantit que le flow fonctionne meme sans connexion reseau.

### Fichiers cles — Mobile

| Fichier | Role |
|---------|------|
| `bagtrip/lib/service/profile_api_service.dart` | Client API profil backend |
| `bagtrip/lib/models/traveler_profile.dart` | Modeles TravelerProfile + ProfileCompletion |
| `bagtrip/lib/models/user.dart` | Modele User avec `isProfileCompleted` |
| `bagtrip/lib/service/api_client.dart` | Client HTTP Dio (methode `put()` ajoutee) |
| `bagtrip/lib/service/personalization_storage.dart` | Persistance locale SharedPreferences |
| `bagtrip/lib/personalization/bloc/personalization_bloc.dart` | BLoC : state management + sync API/local |
| `bagtrip/lib/personalization/bloc/personalization_event.dart` | Events du BLoC |
| `bagtrip/lib/personalization/bloc/personalization_state.dart` | States du BLoC |
| `bagtrip/lib/pages/splash_page.dart` | Splash screen avec redirection profil incomplet |
