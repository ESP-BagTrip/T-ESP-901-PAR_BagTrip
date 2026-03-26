# Authentification

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

Le systeme d'authentification de BagTrip couvre l'ensemble du cycle de vie de l'identite utilisateur : inscription par email/mot de passe, connexion classique, OAuth social (Google et Apple), gestion des tokens JWT avec rotation des refresh tokens, et deconnexion. L'architecture suit le pattern BLoC + Repository cote mobile (Flutter) et FastAPI + SQLAlchemy cote backend. Un client Stripe est automatiquement cree a l'inscription pour preparer l'utilisateur aux fonctionnalites de paiement.

---

## Cote Backend (API FastAPI)

### Endpoints

Tous les endpoints sont prefixes par `/v1/auth` (fichier `api/src/api/auth/routes.py`).

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/register` | Inscription email/password. Cree un client Stripe. Retourne access + refresh tokens. |
| POST | `/login` | Connexion email/password. Retourne access + refresh tokens. |
| POST | `/google` | Connexion/inscription via Google ID token. Cree l'utilisateur si inexistant. |
| POST | `/apple` | Connexion/inscription via Apple ID token. Gere le relay prive Apple (email masque). |
| POST | `/refresh` | Rotation de token : revoque l'ancien refresh token, emet une nouvelle paire. |
| POST | `/logout` | Revoque le refresh token (body ou cookie). Supprime les cookies auth. |
| POST | `/logout-all` | Revoque tous les refresh tokens de l'utilisateur. |
| GET | `/me` | Retourne le profil de l'utilisateur courant (avec plan, quota IA, completion profil). |
| PATCH | `/me` | Met a jour le nom et/ou le telephone de l'utilisateur. |

### Schemas Pydantic (`api/src/api/auth/schemas.py`)

- **SignupRequest** : `email` (EmailStr), `password` (min 6 chars), `fullName?`, `phone?`
- **LoginRequest** : `email`, `password`
- **GoogleSignInRequest** / **AppleSignInRequest** : `idToken` (string)
- **AuthResponse** : `access_token`, `refresh_token`, `expires_in`, `token_type` ("Bearer"), `user` (UserResponse)
- **UserResponse** : `id`, `email`, `fullName?`, `phone?`, `createdAt`, `updatedAt?`, `isProfileCompleted`, `plan`, `aiGenerationsRemaining?`, `planExpiresAt?`
- **RefreshTokenRequest** : `refresh_token`
- **LogoutRequest** : `refresh_token?` (optionnel, fallback sur cookie)

### Tokens JWT

Configuration dans `api/src/config/env.py` :

- **Access token** : HS256, duree configurable via `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` (defaut : 60 min). Payload : `{ userId, exp, type: "access" }`.
- **Refresh token** : token opaque genere via `secrets.token_urlsafe(64)`, stocke en base dans la table `refresh_tokens`, duree configurable via `JWT_REFRESH_TOKEN_EXPIRE_DAYS` (defaut : 30 jours).
- **Rotation** : a chaque appel `/refresh`, l'ancien refresh token est revoque (`revoked = True`) et un nouveau est emis. Cela limite l'impact d'un token compromis.
- **Secret** : `JWT_SECRET` dans les variables d'environnement (defaut dev : `dev-secret-key-change-in-production`).

### Modele RefreshToken (`api/src/models/refresh_token.py`)

Table `refresh_tokens` : `id` (UUID), `user_id` (FK users), `token` (unique, indexe), `expires_at`, `revoked` (bool), `created_at`.

### Middleware d'authentification (`api/src/api/auth/middleware.py`)

La dependance `get_current_user` supporte deux modes :
1. **Cookie httpOnly** `access_token` (utilise par l'admin panel Next.js)
2. **Header Bearer** (utilise par l'application mobile Flutter)

Le token est decode avec HS256, le champ `type` est verifie (`access`), et l'utilisateur est charge depuis la base.

### Cookies (`api/src/utils/cookies.py`)

Trois cookies sont positionnes a la connexion :
- `access_token` : httpOnly, secure configurable, samesite=lax, duree = expires_in
- `refresh_token` : httpOnly, secure, samesite=lax, path=/v1/auth, duree = 30 jours
- `auth-status` : NON httpOnly (lisible par le JS du front admin), valeur "authenticated"

### Verification OAuth Google (`api/src/api/auth/google_token_verifier.py`)

- **Dev** : decodage sans verification de signature, check du issuer uniquement.
- **Production** : verification RS256 avec les cles publiques Google (cache 1h). Deux audiences testees : Firebase (`securetoken.google.com/{project_id}`) et Google OAuth (`accounts.google.com`).

### Verification OAuth Apple (`api/src/api/auth/apple_token_verifier.py`)

- **Dev** : decodage sans verification de signature, check du issuer (`appleid.apple.com`).
- **Production** : verification RS256 via Apple JWKS (cache 1h). Audience = `APPLE_BUNDLE_ID`.
- Gestion du relay prive Apple : si pas d'email, generation d'un email base sur le `sub` (`{sub}@privaterelay.appleid.com`).

### Gardes d'autorisation

- **AdminGuard** (`api/src/api/auth/admin_guard.py`) : verifie `user.plan == "ADMIN"`.
- **PlanGuard** (`api/src/api/auth/plan_guard.py`) :
  - `require_ai_quota` : verifie le quota mensuel de generations IA.
  - `require_premium` : verifie que le plan est PREMIUM ou ADMIN.
- **TripAccess** (`api/src/api/auth/trip_access.py`) : verifie l'acces Owner/Viewer sur un trip.

### Modele User (`api/src/models/user.py`)

Table `users` : `id` (UUID), `email` (unique, indexe), `password_hash`, `full_name?`, `phone?`, `stripe_customer_id?`, `plan` (defaut "FREE"), `stripe_subscription_id?`, `plan_expires_at?`, `ai_generations_count`, `ai_generations_reset_at?`, `created_at`, `updated_at`.

---

## Cote Mobile (Flutter)

### AuthBloc (`bagtrip/lib/auth/bloc/auth_bloc.dart`)

Le BLoC gere les events suivants :

| Event | Description |
|-------|-------------|
| `LoginRequested` | Connexion email/password |
| `RegisterRequested` | Inscription email/password + fullName optionnel |
| `GoogleSignInRequested` | Declenchement du flow Google Sign-In |
| `AppleSignInRequested` | Declenchement du flow Apple Sign-In |
| `LogoutRequested` | Deconnexion (clear cache + Crashlytics) |
| `AuthModeChanged` | Bascule login/inscription dans l'UI |

States emis : `AuthInitial`, `AuthLoading`, `AuthSuccess(authResponse)`, `AuthError(error, isLoginMode)`, `AuthModeChangedState(isLoginMode)`.

Apres une authentification reussie, le bloc enregistre automatiquement le FCM device token pour les push notifications via `NotificationRepository.registerDeviceToken`.

### AuthRepository (`bagtrip/lib/repositories/auth_repository.dart`)

Interface abstraite avec les methodes :
- `login(email, password)` -> `Result<AuthResponse>`
- `register(email, password, fullName)` -> `Result<AuthResponse>`
- `loginWithGoogle()` -> `Result<AuthResponse>`
- `loginWithApple()` -> `Result<AuthResponse>`
- `logout()` -> `Result<void>`
- `getCurrentUser()` -> `Result<User?>`
- `updateUser({fullName?, phone?})` -> `Result<User>`
- `isAuthenticated()` -> `Result<bool>`

### Modele AuthResponse (`bagtrip/lib/models/auth_response.dart`)

Modele Freezed : `accessToken`, `refreshToken` (defaut: ''), `expiresIn` (defaut: 3600), `user` (User).

### Modele User (`bagtrip/lib/models/user.dart`)

Modele Freezed avec proprietes calculees : `isFree`, `isPremium`, `isAdmin`. Champs : `id`, `email`, `fullName?`, `phone?`, `stripeCustomerId?`, `isProfileCompleted`, `createdAt?`, `updatedAt?`, `plan`, `aiGenerationsRemaining?`, `planExpiresAt?`.

### AuthEventBus (`bagtrip/lib/core/auth_event_bus.dart`)

Bus d'evenements broadcast qui emet `onUnauthenticated` lorsque l'API retourne un 401. L'`AuthListener` (widget wrapper) ecoute ce stream et redirige vers `/login`.

### LoginPage (`bagtrip/lib/pages/login_page.dart`)

Page unique pour login ET inscription, avec un toggle Login/Sign Up :
- **iOS** : `CupertinoSlidingSegmentedControl` pour le toggle.
- **Android** : toggle custom avec bordures arrondies.
- Boutons sociaux Google + Apple affiches cote a cote.
- Separateur "ou continuer par email".
- Champs email, mot de passe (+ fullName en mode inscription).
- Lien "Mot de passe oublie" (placeholder, non implemente).
- Texte legal CGU/politique de confidentialite (taps placeholder, non relies).
- Validation cote client : email format, password min 6 chars en inscription.
- Apres `AuthSuccess`, verifie si l'utilisateur a deja vu l'onboarding personalization :
  - Si oui -> `HomeRoute`
  - Si non -> `PersonalizationRoute`

### Widgets auth reutilisables

- **AuthTextField** (`bagtrip/lib/auth/widgets/auth_text_field.dart`) : champ texte stylise avec gestion d'erreur visuelle (bordure rouge).
- **SocialLoginButton** (`bagtrip/lib/auth/widgets/social_login_button.dart`) : bouton Google/Apple avec style clair/sombre, loading state.

---

## Flux d'authentification

### Inscription email/password

```
LoginPage (mode Sign Up)
  -> AuthBloc.RegisterRequested(email, password, fullName?)
    -> AuthRepository.register()
      -> API POST /v1/auth/register
        -> Hash bcrypt du mot de passe
        -> Creation User en base
        -> Creation client Stripe (best effort)
        -> Generation access + refresh tokens
        -> Set cookies auth
        -> Retourne AuthResponse
    -> AuthBloc emet AuthSuccess
      -> Enregistrement FCM token
      -> Check PersonalizationStorage.hasSeenPersonalizationPrompt
        -> Si non vu -> PersonalizationRoute
        -> Si deja vu -> HomeRoute
```

### Connexion OAuth Google/Apple

```
LoginPage
  -> AuthBloc.GoogleSignInRequested / AppleSignInRequested
    -> AuthRepository.loginWithGoogle() / loginWithApple()
      -> SDK Google/Apple natif -> obtention idToken
      -> API POST /v1/auth/google ou /v1/auth/apple
        -> Verification du token (dev: lenient, prod: RS256 + JWKS)
        -> Recherche utilisateur par email
        -> Si inexistant: creation avec dummy password + client Stripe
        -> Generation access + refresh tokens
        -> Retourne AuthResponse
    -> Meme flow post-auth que l'inscription
```

### Refresh token

```
ApiClient (Dio interceptor)
  -> 401 detecte
    -> POST /v1/auth/refresh avec refresh_token
      -> Revocation ancien token (rotation)
      -> Emission nouvelle paire access + refresh
    -> Retry de la requete originale avec le nouveau access token
  -> Si refresh echoue
    -> AuthEventBus.fireUnauthenticated()
    -> AuthListener redirige vers /login
```

### Deconnexion

```
LogoutButton.onTap
  -> AuthBloc.LogoutRequested
    -> CrashlyticsService.clearUserId()
    -> AuthRepository.logout()
      -> API POST /v1/auth/logout (revoque refresh token)
    -> CacheService.clearAll()
    -> AuthBloc emet AuthInitial
  -> Navigation vers LoginRoute
```

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Mot de passe oublie (reset password) | Le bouton "Forgot password" existe dans `login_page.dart` (lignes 399-424) mais le callback `onPressed` est vide (`() {}`). Aucun endpoint `/v1/auth/forgot-password` ou `/v1/auth/reset-password` n'existe cote API. | P0 |
| CGU et politique de confidentialite | Les liens dans `login_page.dart` (methodes `_onTermsTap` et `_onPrivacyTap`, lignes 137-143) sont des placeholders vides. Aucune URL n'est configuree. | P1 |
| Validation email (verification) | Pas de flow de verification d'email apres inscription (email de confirmation). L'utilisateur est directement authentifie. | P1 |
| Rate limiting sur les endpoints auth | Aucun rate limiting sur `/login`, `/register`, `/refresh`. Risque de brute force. | P1 |
| Tests backend auth | Aucun fichier de test dans `api/tests/` pour les routes d'authentification. Les tests Flutter existent (`bagtrip/test/blocs/auth_bloc_test.dart`, `bagtrip/test/repositories/auth_repository_test.dart`, `bagtrip/test/integration/auth_flow_test.dart`). | P1 |
| Changement de mot de passe | Aucun endpoint pour changer le mot de passe d'un utilisateur connecte. | P1 |
| Suppression de compte | Aucun endpoint ni flow pour la suppression de compte (obligation RGPD/Apple App Store). | P0 |
| Nettoyage des refresh tokens expires | Pas de cron/task pour purger les refresh tokens revoques ou expires de la table `refresh_tokens`. | P2 |
| Verification de signature en dev mode | En dev, les tokens Google/Apple sont decodes sans verification de signature (`google_token_verifier.py` ligne 41, `apple_token_verifier.py` ligne 39). Acceptable en dev, mais le flag `NODE_ENV` doit etre correctement positionne en production. | P2 |
| Gestion des comptes sociaux lies | Pas de detection de conflit quand un utilisateur s'inscrit par email puis tente un OAuth avec le meme email (ou vice versa). Le systeme retourne simplement l'utilisateur existant sans fusionner les methodes d'auth. | P2 |
