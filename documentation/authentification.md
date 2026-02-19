# Systeme d'authentification — BagTrip

## Vue d'ensemble

L'authentification BagTrip repose sur un systeme **access token + refresh token** avec verification des tokens OAuth tiers (Google, Apple). Le backend emet des JWT HS256 courte duree (1h) accompagnes de refresh tokens longue duree (30j) stockes en base.

```
┌──────────┐         ┌──────────────┐         ┌──────────────┐
│  Mobile   │────────>│  Backend API │────────>│  PostgreSQL  │
│  Flutter  │<────────│  FastAPI     │<────────│              │
└──────────┘         └──────────────┘         └──────────────┘
     │                      │
     │                      ├── Google Public Keys (RSA)
     │                      └── Apple JWKS
     │
     ├── FlutterSecureStorage (access_token, refresh_token)
     ├── Dio interceptor (auto-refresh on 401)
     └── AuthBloc (state management)
```

---

## Backend (api/)

### Configuration

Toute la config auth est centralisee dans `api/src/config/env.py` (classe `Settings`) :

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `JWT_SECRET` | `str` | **aucun** (requis) | Cle de signature HS256 — le serveur refuse de demarrer si absente |
| `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` | `int` | `60` | Duree de vie access token (minutes) |
| `JWT_REFRESH_TOKEN_EXPIRE_DAYS` | `int` | `30` | Duree de vie refresh token (jours) |
| `GOOGLE_FIREBASE_PROJECT_ID` | `str` | `bagtrip-7d2d8` | Audience attendue pour les tokens Firebase |
| `GOOGLE_OAUTH_CLIENT_ID` | `str \| None` | `None` | Audience secondaire (simulateur iOS) |
| `APPLE_BUNDLE_ID` | `str \| None` | `None` | Audience attendue pour les tokens Apple (production) |
| `NODE_ENV` | `str` | `development` | `development` = verification OAuth souple, `production` = verification RS256 complete |

### Endpoints

Tous sous le prefixe `/v1/auth`.

| Methode | Route | Auth requise | Description |
|---------|-------|:------------:|-------------|
| POST | `/register` | Non | Inscription email/password |
| POST | `/login` | Non | Connexion email/password |
| POST | `/google` | Non | Connexion via Google ID Token |
| POST | `/apple` | Non | Connexion via Apple ID Token |
| GET | `/me` | Oui | Informations de l'utilisateur courant |
| POST | `/refresh` | Non | Echanger un refresh token contre un nouveau couple access+refresh |
| POST | `/logout` | Oui | Revoquer un refresh token specifique |
| POST | `/logout-all` | Oui | Revoquer tous les refresh tokens de l'utilisateur |

### Format de reponse auth

Les endpoints `register`, `login`, `google`, `apple` et `refresh` retournent :

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "dGhpcyBpcyBhIHJlZnJl...",
  "expires_in": 3600,
  "token_type": "Bearer",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "createdAt": "2025-12-11T14:24:32Z",
    "updatedAt": null
  }
}
```

### Tokens

**Access token** — JWT HS256, courte duree.

```
Header:  { "alg": "HS256", "typ": "JWT" }
Payload: { "userId": "uuid", "exp": <timestamp>, "type": "access" }
Signe avec: JWT_SECRET
```

- Duree : 60 minutes (configurable)
- Envoye dans le header `Authorization: Bearer <access_token>` pour toutes les requetes authentifiees
- Le middleware (`api/src/api/auth/middleware.py`) decode et verifie le token, puis extrait `userId`
- Les anciens tokens (sans champ `type`) sont acceptes pour retro-compatibilite

**Refresh token** — Token opaque, longue duree.

- Genere via `secrets.token_urlsafe(64)`
- Stocke en clair dans la table `refresh_tokens`
- Duree : 30 jours (configurable)
- Utilise uniquement pour appeler `POST /v1/auth/refresh`

### Table refresh_tokens

```sql
CREATE TABLE refresh_tokens (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id),
    token      VARCHAR NOT NULL,             -- token brut, index unique
    expires_at TIMESTAMPTZ NOT NULL,
    revoked    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX  ix_refresh_tokens_user_id ON refresh_tokens (user_id);
CREATE UNIQUE INDEX ix_refresh_tokens_token ON refresh_tokens (token);
```

Le modele SQLAlchemy correspondant est dans `api/src/models/refresh_token.py`. La table est creee automatiquement au demarrage via une migration dans `api/src/migrations/migrate_refresh_tokens.py` (idempotent).

### Flow d'authentification

#### Email/Password

```
1. POST /v1/auth/register { email, password }
   └─> Hash bcrypt du password → creation User → generation access+refresh tokens → AuthResponse

2. POST /v1/auth/login { email, password }
   └─> Lookup User par email → verification bcrypt → generation access+refresh tokens → AuthResponse
```

#### Google OAuth

```
Mobile                          Backend                         Google
  │                               │                               │
  ├── google_sign_in SDK ────────>│                               │
  │   (obtient Google ID Token)   │                               │
  │                               │                               │
  ├── POST /auth/google ─────────>│                               │
  │   { idToken }                 │                               │
  │                               ├── Fetch cles publiques ──────>│
  │                               │   googleapis.com/oauth2/v1/certs
  │                               │   (cache 1h en memoire)       │
  │                               │                               │
  │                               ├── Verifier signature RS256    │
  │                               ├── Verifier audience + issuer  │
  │                               ├── Extraire email, nom         │
  │                               ├── Trouver/creer User          │
  │                               ├── Generer access+refresh      │
  │<── AuthResponse ──────────────┤                               │
```

**Audiences acceptees** (production) :
- `bagtrip-7d2d8` (Firebase, device reel) avec issuer `https://securetoken.google.com/bagtrip-7d2d8`
- `GOOGLE_OAUTH_CLIENT_ID` (simulateur iOS) avec issuer `https://accounts.google.com`

**En developpement** (`NODE_ENV != "production"`) : le token est decode sans verification de signature (seul l'issuer est verifie en warning).

#### Apple Sign-In

```
Mobile                          Backend                         Apple
  │                               │                               │
  ├── SignInWithApple SDK ───────>│                               │
  │   (obtient Apple ID Token)    │                               │
  │                               │                               │
  ├── POST /auth/apple ──────────>│                               │
  │   { idToken }                 │                               │
  │                               ├── Fetch JWKS ────────────────>│
  │                               │   appleid.apple.com/auth/keys │
  │                               │   (cache 1h en memoire)       │
  │                               │                               │
  │                               ├── Trouver cle par kid         │
  │                               ├── Verifier signature RS256    │
  │                               ├── Verifier aud=APPLE_BUNDLE_ID│
  │                               ├── Verifier iss=appleid.apple  │
  │                               ├── Extraire email (ou sub)     │
  │                               ├── Trouver/creer User          │
  │                               ├── Generer access+refresh      │
  │<── AuthResponse ──────────────┤                               │
```

Si Apple ne fournit pas l'email (utilisateur masque), un email `{sub}@privaterelay.appleid.com` est genere.

#### Refresh

```
1. POST /v1/auth/refresh { refresh_token }
   └─> Lookup en DB → verifier non-revoque et non-expire
   └─> Revoquer l'ancien token (rotation)
   └─> Generer nouveau couple access+refresh → AuthResponse
```

La rotation garantit qu'un refresh token ne peut etre utilise qu'une seule fois.

#### Logout

```
1. POST /v1/auth/logout { refresh_token }  (header: Authorization: Bearer <access_token>)
   └─> Revoquer le refresh token en DB (revoked = true) → 204

2. POST /v1/auth/logout-all  (header: Authorization: Bearer <access_token>)
   └─> Revoquer TOUS les refresh tokens du user → 204
```

### Rate limiting

Les endpoints auth sont proteges par un rate limiter per-IP (`api/src/middleware/rate_limit.py`) :

- **Limite** : 5 requetes par minute par IP
- **Endpoints concernes** : `/v1/auth/login`, `/v1/auth/register`, `/v1/auth/google`, `/v1/auth/apple`, `/v1/auth/refresh`
- **Reponse si depasse** : HTTP 429 avec header `Retry-After`
- **Implementation** : `cachetools.TTLCache` (auto-expiration, pas besoin de Redis)

L'IP est extraite via le header `X-Forwarded-For` (pour les reverse proxies) ou `request.client.host`.

### Fichiers cles — Backend

| Fichier | Role |
|---------|------|
| `api/src/config/env.py` | Configuration centralisee (JWT_SECRET, expirations, OAuth) |
| `api/src/api/auth/routes.py` | Tous les endpoints auth |
| `api/src/api/auth/middleware.py` | Verification JWT, extraction user courant |
| `api/src/api/auth/schemas.py` | Schemas Pydantic (AuthResponse, RefreshTokenRequest, etc.) |
| `api/src/api/auth/google_token_verifier.py` | Verification tokens Google (RS256 + cache cles) |
| `api/src/api/auth/apple_token_verifier.py` | Verification tokens Apple (JWKS + cache cles) |
| `api/src/models/refresh_token.py` | Modele SQLAlchemy refresh_tokens |
| `api/src/middleware/rate_limit.py` | Rate limiting per-IP sur endpoints auth |

---

## Mobile (bagtrip/)

### Stockage des tokens

`bagtrip/lib/service/storage_service.dart` utilise `FlutterSecureStorage` (Keychain iOS / EncryptedSharedPreferences Android) :

| Cle | Contenu |
|-----|---------|
| `access_token` | JWT HS256 courte duree |
| `refresh_token` | Token opaque longue duree |
| `jwt_token` | Legacy (ancienne cle, lue en fallback par `getToken()`) |

Methodes principales :
- `saveTokens(accessToken, refreshToken)` — sauvegarde les deux d'un coup
- `getToken()` — retourne l'access token (fallback sur la cle legacy)
- `getRefreshToken()` — retourne le refresh token
- `deleteToken()` — supprime les 3 cles

### Auto-refresh sur 401

`bagtrip/lib/service/api_client.dart` contient un interceptor Dio qui :

1. **Ajoute le token** a chaque requete (`Authorization: Bearer <access_token>`)
2. **Sur erreur 401** :
   - Tente un refresh via `POST /auth/refresh` (avec un Dio separe pour eviter la boucle d'interceptor)
   - Si succes : sauvegarde les nouveaux tokens et rejoue la requete originale
   - Si echec : supprime les tokens locaux (l'utilisateur sera redirige vers le login)
3. Un flag `_isRefreshing` empeche les appels concurrents de refresh

### AuthService

`bagtrip/lib/service/auth_service.dart` expose :

| Methode | Description |
|---------|-------------|
| `login(email, password)` | POST /auth/login → sauvegarde access+refresh |
| `register(email, password, fullName)` | POST /auth/register → sauvegarde access+refresh |
| `loginWithGoogle()` | Google SDK → POST /auth/google → sauvegarde access+refresh |
| `loginWithApple()` | Apple SDK → POST /auth/apple → sauvegarde access+refresh |
| `getCurrentUser()` | GET /auth/me |
| `isAuthenticated()` | Verifie si un token existe en storage |
| `logout()` | POST /auth/logout (best-effort) puis clearAll() |

### AuthBloc (state management)

`bagtrip/lib/auth/bloc/` gere l'etat d'authentification via le pattern BLoC :

**Events** :
- `LoginRequested` — login email/password
- `RegisterRequested` — inscription
- `GoogleSignInRequested` — login Google
- `AppleSignInRequested` — login Apple
- `LogoutRequested` — deconnexion
- `AuthModeChanged` — bascule login/register dans l'UI

**States** :
- `AuthInitial` — pas connecte
- `AuthLoading` — requete en cours
- `AuthSuccess` — connecte (contient `AuthResponse`)
- `AuthError` — erreur (contient message)
- `AuthModeChangedState` — bascule UI

Le `AuthBloc` est fourni globalement dans `main.dart` via `MultiBlocProvider`, ce qui permet au bouton de deconnexion dans le profil (`LogoutButton`) d'y acceder sans BlocProvider local.

### AuthResponse (modele Dart)

`bagtrip/lib/models/auth_response.dart` :

```dart
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User user;
}
```

Le `fromJson` supporte les deux formats pour retro-compatibilite :
- Nouveau : `{ "access_token": "...", "refresh_token": "...", "expires_in": 3600 }`
- Legacy : `{ "token": "..." }` (refresh_token = `""`, expiresIn = 3600)

### Fichiers cles — Mobile

| Fichier | Role |
|---------|------|
| `bagtrip/lib/service/storage_service.dart` | Stockage securise des tokens |
| `bagtrip/lib/service/api_client.dart` | Client HTTP Dio avec auto-refresh |
| `bagtrip/lib/service/auth_service.dart` | Logique metier d'authentification |
| `bagtrip/lib/models/auth_response.dart` | Modele de reponse auth |
| `bagtrip/lib/auth/bloc/auth_bloc.dart` | State management auth |
| `bagtrip/lib/auth/bloc/auth_event.dart` | Events auth (login, logout, etc.) |
| `bagtrip/lib/auth/bloc/auth_state.dart` | States auth |
| `bagtrip/lib/main.dart` | MultiBlocProvider global (AuthBloc + ProfileBloc) |
| `bagtrip/lib/pages/login_page.dart` | Page de connexion/inscription |
| `bagtrip/lib/profile/widgets/logout_button.dart` | Bouton de deconnexion (via AuthBloc) |
