# Authentification & Autorisation

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'API BagTrip utilise un systeme d'authentification multi-methode : email/password classique et OAuth (Google, Apple). L'authentification repose sur des **JWT** (JSON Web Tokens) signes en HS256, avec un mecanisme de **refresh token rotation** pour la securite. L'autorisation s'appuie sur un systeme de **roles** (Owner/Viewer pour les trips) et de **plans** (FREE/PREMIUM/ADMIN) pour le gating des features.

## Methodes d'authentification

### 1. Email / Password

**Routes** : `POST /v1/auth/register` et `POST /v1/auth/login`

**Inscription** :
1. Verification qu'aucun utilisateur n'existe avec cet email
2. Hash du mot de passe avec **bcrypt** (`bcrypt.hashpw` + `gensalt`)
3. Creation du user en DB
4. Creation d'un client Stripe (graceful si echec)
5. Generation de l'access token + refresh token
6. Set des cookies httpOnly + retour JSON

**Connexion** :
1. Recherche du user par email
2. Verification du mot de passe avec `bcrypt.checkpw`
3. Generation de l'access token + refresh token
4. Set des cookies httpOnly + retour JSON

**Validation** : mot de passe minimum 6 caracteres, email valide (`EmailStr` Pydantic).

### 2. Google Sign-In

**Route** : `POST /v1/auth/google`
**Fichier verifier** : `api/src/api/auth/google_token_verifier.py`

**Fonctionnement** :
1. Reception d'un `idToken` (Firebase ID token ou Google OAuth token)
2. Verification du token :
   - **Dev** : decode sans verification de signature, verifie juste l'issuer
   - **Production** : verification complete RS256 via les cles publiques Google
3. Extraction de l'email et du nom depuis les claims
4. Recherche ou creation de l'utilisateur
5. Pour les nouveaux utilisateurs sociaux : mot de passe factice hashe (jamais utilise)

**Issuers acceptes** :
- Firebase : `https://securetoken.google.com/{PROJECT_ID}` (audience = project_id)
- Google OAuth : `https://accounts.google.com` (audience = `GOOGLE_OAUTH_CLIENT_ID`)

**Cache des cles publiques** : les cles Google sont cachees 1 heure (`_google_public_keys_cache`).

### 3. Apple Sign-In

**Route** : `POST /v1/auth/apple`
**Fichier verifier** : `api/src/api/auth/apple_token_verifier.py`

**Fonctionnement** :
1. Reception d'un `idToken` (Apple ID token)
2. Verification du token :
   - **Dev** : decode sans verification de signature, verifie l'issuer (`https://appleid.apple.com`)
   - **Production** : verification complete RS256 via Apple JWKS
3. Extraction de l'email (peut etre masque → fallback `{sub}@privaterelay.appleid.com`)
4. Recherche ou creation de l'utilisateur

**JWKS Apple** : telechargees depuis `https://appleid.apple.com/auth/keys`, cachees 1 heure.

**Audience production** : `APPLE_BUNDLE_ID`

## Tokens JWT

### Access Token

**Fichier** : `api/src/api/auth/routes.py` (`create_access_token`)

| Champ | Valeur |
|-------|--------|
| Algorithme | HS256 |
| Secret | `JWT_SECRET` (env) |
| Payload | `{userId, exp, type: "access"}` |
| Expiration | `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` (defaut: 60 min) |
| Format | `Bearer` token dans le header `Authorization` |

### Refresh Token

**Fichier** : `api/src/api/auth/routes.py` (`create_refresh_token`)

| Champ | Valeur |
|-------|--------|
| Format | `secrets.token_urlsafe(64)` (opaque, pas un JWT) |
| Stockage | Table `RefreshToken` en DB (user_id, token, expires_at, revoked) |
| Expiration | `JWT_REFRESH_TOKEN_EXPIRE_DAYS` (defaut: 30 jours) |

### Rotation de tokens

**Route** : `POST /v1/auth/refresh`

1. Verification du refresh token en DB (non revoque, non expire)
2. **Revocation** de l'ancien token (`revoked = True`)
3. Generation d'un nouveau access token + nouveau refresh token
4. Mise a jour des cookies

Ce mecanisme empeche la reutilisation d'un refresh token vole : chaque refresh genere un nouveau pair de tokens.

### Cookies

**Fichier** : `api/src/utils/cookies.py`

Trois cookies sont definis a chaque authentification :

| Cookie | httpOnly | Path | Max-Age | Usage |
|--------|----------|------|---------|-------|
| `access_token` | Oui | `/` | `expires_in` | Admin panel (Next.js) |
| `refresh_token` | Oui | `/v1/auth` | 30 jours | Refresh uniquement |
| `auth-status` | Non | `/` | `expires_in` | Front JS (detecter si connecte) |

Parametres configures : `COOKIE_SECURE` (HTTPS), `COOKIE_DOMAIN`, `samesite=lax`.

## Middleware JWT (`api/src/api/auth/middleware.py`)

### `verify_jwt_token(token) -> str | None`

Decode et verifie un token JWT. Retourne le `userId` ou `None` si invalide/expire.

Verification :
- Decode avec `settings.JWT_SECRET`, algorithme `HS256`
- Verifie que `type` est `"access"` (ou absent pour retro-compatibilite)
- Retourne `payload["userId"]`

### `get_current_user` (FastAPI Dependency)

Mode dual : accepte le JWT depuis un cookie OU un header Bearer.

Ordre de priorite :
1. **Cookie** `access_token` (pour l'admin panel Next.js)
2. **Header** `Authorization: Bearer <token>` (pour l'app mobile)

Enchainement :
1. Extraction du token
2. `verify_jwt_token(token)` → userId
3. Query DB `User.id == userId`
4. Retourne l'objet `User` ou leve `401 Unauthorized`

## Guards (Dependencies FastAPI)

### Admin Guard (`api/src/api/auth/admin_guard.py`)

```python
async def require_admin(current_user = Depends(get_current_user)) -> User:
    if current_user.plan != "ADMIN":
        raise AppError("FORBIDDEN", 403, "Admin access required")
    return current_user
```

Utilise par toutes les routes `/admin/*`.

### Plan Guard (`api/src/api/auth/plan_guard.py`)

#### `require_ai_quota`

Verifie que l'utilisateur a encore du quota IA pour le mois courant :

1. Determine le plan de l'utilisateur
2. Recupere la limite mensuelle (`ai_generations_per_month`)
3. Auto-reset si changement de mois
4. Leve `AppError("AI_QUOTA_EXCEEDED", 402)` si quota epuise

Limites :
- FREE : 3 generations/mois
- PREMIUM/ADMIN : illimite

Utilise par : suggestions d'activites, suggestions de bagages, plan-trip stream, post-trip suggestion.

#### `require_premium`

Verifie que l'utilisateur a un plan PREMIUM ou ADMIN :
```python
if PlanService.get_plan(current_user).value == "FREE":
    raise AppError("UPGRADE_REQUIRED", 402, "Premium feature — upgrade your plan.")
```

Utilise par : post-trip suggestion.

### Trip Access Guards (`api/src/api/auth/trip_access.py`)

Systeme de roles Owner/Viewer pour les trips partages.

#### `TripAccess` dataclass

```python
@dataclass
class TripAccess:
    trip: Trip
    role: TripRole  # OWNER ou VIEWER
```

#### `get_trip_access` (lecture)

1. Cherche le trip par `tripId`
2. Si `trip.user_id == current_user.id` → `OWNER`
3. Sinon, cherche dans `TripShare` → `VIEWER`
4. Si pas d'acces → `AppError("TRIP_NOT_FOUND", 404)` (masque l'existence du trip)

Utilise pour les endpoints de lecture (GET).

#### `get_trip_owner_access` (ecriture)

Comme `get_trip_access` mais leve `AppError("FORBIDDEN", 403)` si le role n'est pas `OWNER`.

Utilise pour les endpoints d'ecriture (POST, PUT, PATCH, DELETE).

#### Masquage des donnees pour les viewers

Les routes appliquent le masquage cote serveur pour les viewers :

| Ressource | Champs masques pour VIEWER |
|-----------|---------------------------|
| Activities | `estimatedCost = None` |
| Accommodations | `pricePerNight, currency, bookingReference = None` |
| Budget Items | Liste vide retournee |
| Budget Summary | `total_spent = 0, remaining = 0, by_category = {}` |
| Flight Offers | Prix masques dans offer_json |
| Flight Orders | `paymentId = None` |
| Trip Home | `totalExpenses = 0` dans les stats |

## Logout

### `POST /v1/auth/logout`

1. Recupere le refresh token depuis le body ou le cookie
2. Marque le token comme revoque en DB
3. Supprime les cookies d'authentification

### `POST /v1/auth/logout-all`

1. Marque **tous** les refresh tokens de l'utilisateur comme revoques
2. Supprime les cookies d'authentification

## Rate Limiting sur les endpoints auth

**Fichier** : `api/src/middleware/rate_limit.py`

Rate limiter per-IP sur les endpoints d'authentification :
- **Limite** : 5 requetes/minute
- **Endpoints** : `/v1/auth/login`, `/register`, `/google`, `/apple`, `/refresh`
- **Implementation** : `TTLCache` (cachetools) avec maxsize 10000
- **Reponse 429** : `{"detail": "Too many requests. Please try again later.", "retry_after": 60}`

## Schemas (`api/src/api/auth/schemas.py`)

| Schema | Champs |
|--------|--------|
| `SignupRequest` | email (EmailStr), password (min 6), fullName?, phone? |
| `LoginRequest` | email (EmailStr), password |
| `GoogleSignInRequest` | idToken |
| `AppleSignInRequest` | idToken |
| `RefreshTokenRequest` | refresh_token |
| `LogoutRequest` | refresh_token? |
| `UpdateUserRequest` | fullName?, phone? |
| `UserResponse` | id, email, fullName, phone, createdAt, updatedAt, isProfileCompleted, plan, aiGenerationsRemaining, planExpiresAt |
| `AuthResponse` | access_token, refresh_token, expires_in, token_type, user |

## Flux complet d'authentification

```
Client                          API
  |                              |
  |-- POST /v1/auth/register --> |
  |                              |-- Hash password (bcrypt)
  |                              |-- Create User in DB
  |                              |-- Create Stripe Customer
  |                              |-- create_access_token() → JWT HS256
  |                              |-- create_refresh_token() → opaque, stored in DB
  |                              |-- set_auth_cookies()
  | <-- 201 AuthResponse ------- |
  |                              |
  |-- GET /v1/auth/me ---------> |
  |   (Bearer: <access_token>)   |-- verify_jwt_token()
  |                              |-- Query User by userId
  | <-- 200 UserResponse ------- |
  |                              |
  |-- POST /v1/auth/refresh ---> |
  |   {refresh_token: "..."}     |-- Find token in DB (non-revoked)
  |                              |-- Revoke old token
  |                              |-- Create new access + refresh tokens
  | <-- 200 AuthResponse ------- |
  |                              |
  |-- POST /v1/auth/logout ----> |
  |   {refresh_token: "..."}     |-- Revoke token in DB
  |                              |-- clear_auth_cookies()
  | <-- 204 ------------------- |
```

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| JWT_SECRET par defaut en production | La valeur par defaut est `"dev-secret-key-change-in-production"`. Pas de validation forcee pour empecher son utilisation en production. Fichier : `api/src/config/env.py` ligne 50 | P0 |
| Pas de password reset | Aucun endpoint pour la reinitialisation de mot de passe (forgot password, reset via email). Fichier : `api/src/api/auth/routes.py` | P1 |
| Pas de verification d'email | Les emails ne sont pas verifies lors de l'inscription. Pas d'endpoint de confirmation. Fichier : `api/src/api/auth/routes.py` | P1 |
| Pas de changement de mot de passe | Aucun endpoint pour changer le mot de passe (necessiterait la verification de l'ancien mot de passe). Fichier : `api/src/api/auth/routes.py` | P1 |
| Pas de suppression de compte | Aucun endpoint pour supprimer son compte utilisateur (RGPD). Fichier : `api/src/api/auth/routes.py` | P1 |
| Refresh token cleanup | Les refresh tokens revoques ou expires ne sont jamais nettoyes de la DB. Pas de job de purge. Fichier : `api/src/models/refresh_token.py` | P2 |
| Apple Sign-In dev mode trop permissif | En dev mode, le token Apple est decode sans aucune verification de signature, seulement un warning si l'issuer ne correspond pas. Fichier : `api/src/api/auth/apple_token_verifier.py` lignes 39-48 | P2 |
| Pas de brute-force protection avancee | Le rate limiter auth est per-IP (5/min) mais pas de lockout apres N tentatives echouees sur un compte. Fichier : `api/src/middleware/rate_limit.py` | P2 |
| Pas de logging des connexions | Les connexions reussies/echouees ne sont pas loguees de maniere structuree (IP, user-agent, etc.) pour l'audit. Fichier : `api/src/api/auth/routes.py` | P2 |
