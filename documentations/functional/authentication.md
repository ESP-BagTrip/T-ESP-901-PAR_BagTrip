# Authentification

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

L'authentification BagTrip couvre tout le cycle de vie de l'identite : inscription email/mot de passe, connexion classique, OAuth social Google et Apple, rotation des refresh tokens, deconnexion mono ou multi-device, reset password par token a usage unique, suppression de compte RGPD et registration FCM. L'architecture suit le pattern BLoC + Repository cote mobile (Flutter) et FastAPI + SQLAlchemy 2.0 cote backend, avec un `UserCreationService` partage qui garantit qu'inscription email, Google et Apple produisent toutes les memes effets de bord (creation client Stripe, claim des invitations de partage en attente).

L'API supporte deux modes d'authentification simultanes : cookies httpOnly (admin panel Next.js) et header Bearer (app mobile Flutter). Les acces sensibles sont gardes par trois dependencies FastAPI dedies : `require_admin`, `require_premium`/`require_ai_quota` et `get_trip_access`/`get_trip_owner_access`/`get_trip_editor_access`.

---

## Cote Backend (API FastAPI)

### Endpoints

Tous les endpoints sont prefixes par `/v1/auth` (`api/src/api/auth/routes.py`).

| Methode | Route | Description |
|---------|-------|-------------|
| POST | `/register` | Inscription email/password. Cree client Stripe et claim les invitations en attente. Retourne access + refresh tokens. |
| POST | `/login` | Connexion email/password. Verifie le hash bcrypt. Retourne une paire de tokens. |
| POST | `/google` | Connexion/inscription via Google ID token (Firebase ou OAuth). |
| POST | `/apple` | Connexion/inscription via Apple ID token. Gere le relay prive (`{sub}@privaterelay.appleid.com`). |
| POST | `/refresh` | Rotation : revoque l'ancien refresh token et emet une nouvelle paire. |
| POST | `/logout` | Revoque le refresh token donne (body ou cookie). 204. |
| POST | `/logout-all` | Revoque tous les refresh tokens de l'utilisateur courant. 204. |
| POST | `/forgot-password` | Envoie un token de reset (200 systematique pour ne pas leaker l'existence du compte). |
| POST | `/reset-password` | Reinitialise le mot de passe a partir du token. |
| GET | `/me` | Retourne le profil de l'utilisateur courant (plan, quota IA, completion profil). |
| PATCH | `/me` | Met a jour le nom et/ou le telephone. |
| DELETE | `/me` | Suppression de compte RGPD : cascade complete + suppression du client Stripe. 204. |

### Schemas Pydantic (`api/src/api/auth/schemas.py`)

Tous les schemas requete heritent de `BagtripRequestModel` (camelCase en entree, snake_case en interne).

- `SignupRequest` : `email` (EmailStr), `password` (min 6 chars), `fullName?`, `phone?`
- `LoginRequest` : `email`, `password`
- `GoogleSignInRequest` / `AppleSignInRequest` : `idToken`
- `RefreshTokenRequest` : `refresh_token`
- `LogoutRequest` : `refresh_token?` (fallback cookie)
- `ForgotPasswordRequest` : `email`
- `ResetPasswordRequest` : `token`, `new_password` (min 6 chars)
- `UpdateUserRequest` : `fullName?`, `phone?`
- `AuthResponse` : `access_token`, `refresh_token`, `expires_in`, `token_type="Bearer"`, `user` (UserResponse)
- `UserResponse` : `id`, `email`, `fullName?`, `phone?`, `createdAt`, `updatedAt?`, `isProfileCompleted`, `plan`, `aiGenerationsRemaining?`, `planExpiresAt?` (aliases camelCase via `Field(alias=...)` + `populate_by_name=True`)

### Tokens JWT

- **Access token** : HS256, payload `{userId, exp, type: "access"}`, duree `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` (defaut 60 min).
- **Refresh token** : opaque, `secrets.token_urlsafe(64)`, persiste en table `refresh_tokens`, duree `JWT_REFRESH_TOKEN_EXPIRE_DAYS` (defaut 30 jours).
- **Rotation** : chaque appel `/refresh` flip `revoked=True` sur l'ancien et emet une nouvelle paire. Un token revoque ne peut plus etre echange.
- **Secret** : `JWT_SECRET` (env).
- **Helper centralise** : `_build_auth_response()` factorise la generation des tokens, le set des cookies et la lecture du `plan_info` pour les flows register/login/google/apple/refresh — evite la derive entre handlers.

### Modeles SQLAlchemy

- `User` (`api/src/models/user.py`, table `users`) : `id` UUID, `email` unique, `password_hash`, `full_name?`, `phone?`, `stripe_customer_id?`, `plan` (defaut `FREE`), `stripe_subscription_id?`, `plan_expires_at?`, `ai_generations_count`, `ai_generations_reset_at?`, `password_reset_token?`, `password_reset_expires?`, `banned_at?`, `ban_reason?`, `deleted_at?`, `created_at`, `updated_at`. Le `password_reset_token` stocke uniquement le SHA-256 du token (`_hash_reset_token()`), jamais le clair.
- `RefreshToken` (`api/src/models/refresh_token.py`, table `refresh_tokens`) : `id`, `user_id` (FK indexe), `token` (unique indexe), `expires_at`, `revoked`, `created_at`.

### Middleware (`api/src/api/auth/middleware.py`)

La dependency `get_current_user` lit le token dans l'ordre :
1. Cookie httpOnly `access_token` (admin panel).
2. Header `Authorization: Bearer <token>` (mobile).

Decode HS256, verifie `type == "access"` (un refresh token presente comme access est rejete), charge l'utilisateur depuis la DB. Erreurs : 401 si token manquant ou invalide, 404 si l'user n'existe pas.

### Cookies (`api/src/utils/cookies.py`)

Trois cookies positionnes a la connexion :

| Cookie | httpOnly | Path | Duree |
|--------|----------|------|-------|
| `{prefix}access_token` | oui | `/` | `expires_in` (access) |
| `{prefix}refresh_token` | oui | `/v1/auth` | 30 jours |
| `{prefix}auth-status` | non | `/` | `expires_in` |

`COOKIE_SECURE`, `COOKIE_DOMAIN` et `COOKIE_NAME_PREFIX` controles par env. `clear_auth_cookies()` supprime les trois.

### Verification OAuth Google (`api/src/api/auth/google_token_verifier.py`)

- **Dev** (`NODE_ENV != "production"`) : `jwt.get_unverified_claims()`, check du issuer parmi `securetoken.google.com/{project_id}`, `accounts.google.com`, `accounts.google.com`. Mismatch logge un warning sans rejeter.
- **Production** : recuperation des cles publiques Google (cache 1 h), verification RS256. Essaie d'abord l'audience Firebase (`GOOGLE_FIREBASE_PROJECT_ID`, device reel), puis OAuth (`GOOGLE_OAUTH_CLIENT_ID`, simulator). Reject si aucune audience ne matche.

### Verification OAuth Apple (`api/src/api/auth/apple_token_verifier.py`)

- **Dev** : `jwt.get_unverified_claims()`, check `iss == "https://appleid.apple.com"`.
- **Production** : recuperation JWKS Apple (cache 1 h), verification RS256, audience = `APPLE_BUNDLE_ID` (raise si non configure).
- Relay prive : si pas d'email mais un `sub`, le route `/apple` synthese `{sub}@privaterelay.appleid.com` cote handler.

### Service `UserCreationService` (`api/src/services/user_creation_service.py`)

Point d'entree unique pour register/google/apple. Sequence atomique :

1. Insert `User`, flush pour recuperer `user.id`.
2. Creation client Stripe via `StripeClient.create_customer(idempotency_key=f"user-{user.id}-customer-create-v1")`. Failure = rollback + `AppError("STRIPE_CUSTOMER_CREATION_FAILED", 503)`.
3. `db.commit()` + `db.refresh()`.
4. `_claim_pending_invites()` (best-effort) : reattache les invitations `TripShare` adressees a l'email.

### Guards d'autorisation

- **`require_admin`** (`api/src/api/auth/admin_guard.py`) : verifie `user.plan == "ADMIN"`, raise `AppError("FORBIDDEN", 403)`.
- **`require_premium`** (`api/src/api/auth/plan_guard.py`) : reconcilie le plan local avec Stripe via `PlanService.reconcile_plan_with_stripe()`. Si FREE, raise `AppError("UPGRADE_REQUIRED", 402)`.
- **`require_ai_quota`** : appelle `PlanService.check_ai_generation_quota()` qui reconcilie d'abord avec Stripe pour ne pas bloquer un user fraichement abonne dont le webhook n'a pas encore atterri.
- **`get_trip_access`** (`api/src/api/auth/trip_access.py`) : resout Owner / Editor / Viewer via la table `trip_shares`. Retourne un `TripAccess(trip, role)`. Aucun match = 404 (jamais 403, pour ne pas leaker l'existence du trip).
- **`get_trip_owner_access`** : derive de `get_trip_access`, raise 403 si role != OWNER.
- **`get_trip_editor_access`** : autorise OWNER + EDITOR.

### Suppression de compte (RGPD)

`DELETE /me` (`api/src/api/auth/routes.py`) :

1. Suppression client Stripe (best-effort, logge sur echec).
2. Cascade sur les trips de l'utilisateur : `Activity`, `Accommodation`, `BaggageItem`, `BudgetItem`, `FlightSearch`, `FlightOffer`, `FlightOrder`, `ManualFlight`, `TripTraveler`, `TripShare`, `Feedback`, `BookingIntent`, `Notification`.
3. Cascade sur les ressources user-scoped : `BookingIntent`, `DeviceToken`, `Notification`, `RefreshToken`, `TripShare`, `Feedback`, `TravelerProfile`.
4. Suppression de la ligne `users`.

---

## Cote Mobile (Flutter)

### AuthBloc (`bagtrip/lib/auth/bloc/auth_bloc.dart`)

| Event | Description |
|-------|-------------|
| `LoginRequested(email, password)` | Connexion email/password. |
| `RegisterRequested(email, password, fullName?)` | Inscription email/password. |
| `GoogleSignInRequested` | Flow Google natif puis POST `/auth/google`. |
| `AppleSignInRequested` | Flow Apple natif puis POST `/auth/apple`. |
| `LogoutRequested` | Unregister FCM token, POST `/auth/logout`, clear cache local. |
| `DeleteAccountRequested` | DELETE `/auth/me` puis `LogoutRequested`. |
| `AuthModeChanged(isLoginMode)` | Toggle UI login/sign-up. |
| `UserRefreshRequested` | Re-fetch `/auth/me` pour re-emettre `AuthSuccess`. |
| `OptimisticPremiumActivated` | Flip local `plan = PREMIUM` apres PaymentSheet OK (sans appel serveur). |
| `ConfirmPremiumActivation` | Reconcilie `/auth/me` a 500 ms / 2 s / 5 s post-paiement. |

States : `AuthInitial`, `AuthLoading(method?)`, `AuthSuccess(authResponse)`, `AuthError(error, isLoginMode)`, `AuthModeChangedState(isLoginMode)`.

Apres `AuthSuccess`, `_registerDeviceToken()` demande la permission notifications et enregistre le token FCM via `NotificationRepository.registerDeviceToken`. Avant `LogoutRequested`, `_unregisterDeviceToken()` desinscrit le device courant. Les `CancelledError` Google/Apple retombent en `AuthInitial` au lieu d'un `AuthError` visible.

### AuthRepository (`bagtrip/lib/repositories/auth_repository.dart`)

Interface abstraite implementee dans `bagtrip/lib/service/auth_service.dart` (`AuthRepositoryImpl`).

| Methode | Endpoint | Retour |
|---------|----------|--------|
| `login(email, password)` | POST `/auth/login` | `Result<AuthResponse>` |
| `register(email, password, fullName)` | POST `/auth/register` | `Result<AuthResponse>` |
| `loginWithGoogle()` | SDK Google + POST `/auth/google` | `Result<AuthResponse>` |
| `loginWithApple()` | SDK Apple + POST `/auth/apple` | `Result<AuthResponse>` |
| `logout()` | POST `/auth/logout` (best-effort) + clear local | `Result<void>` |
| `getCurrentUser()` | GET `/auth/me` | `Result<User?>` |
| `updateUser({fullName?, phone?})` | PATCH `/auth/me` | `Result<User>` |
| `isAuthenticated()` | Lecture token storage | `Result<bool>` |
| `forgotPassword(email)` | POST `/auth/forgot-password` | `Result<void>` |
| `deleteAccount()` | DELETE `/auth/me` + clear local | `Result<void>` |

Toutes les methodes mappent `DioException` via `ApiClient.mapDioError()` et passent les `Failure` par `loggedFailure()` pour tracker Crashlytics.

### Modeles Freezed

- `AuthResponse` (`bagtrip/lib/models/auth_response.dart`) : `accessToken`, `refreshToken` (defaut `''`), `expiresIn` (defaut 3600), `user`.
- `User` (`bagtrip/lib/models/user.dart`) : `id`, `email`, `fullName?`, `phone?`, `stripeCustomerId?`, `isProfileCompleted`, `createdAt?`, `updatedAt?`, `plan`, `aiGenerationsRemaining?`, `planExpiresAt?`. Properties calculees : `isFree`, `isPremium`, `isAdmin`.

### LoginPage (`bagtrip/lib/pages/login_page.dart`)

Page unique login/sign-up :

- iOS : `CupertinoSlidingSegmentedControl` pour le toggle. Android : toggle custom arrondi.
- Boutons Google + Apple cote a cote, separateur "ou continuer par email".
- Champs email/password (+ fullName en sign-up). Validation client : format email, password min 6 chars.
- Lien "Mot de passe oublie" -> push `ForgotPasswordPage`.
- Liens CGU / politique de confidentialite (callbacks placeholders).
- Post-`AuthSuccess` : check `PersonalizationStorage.hasSeenPersonalizationPrompt`. Si non vu -> `PersonalizationRoute`, sinon `HomeRoute`.

### ForgotPasswordPage (`bagtrip/lib/pages/forgot_password_page.dart`)

Formulaire email + bouton `Envoyer`. Appelle `AuthRepository.forgotPassword()`. Affiche l'ecran de confirmation quel que soit le resultat (Success ou Failure) pour ne pas leaker l'existence d'un compte. Aucun ecran `ResetPasswordPage` cote app : le token est consomme cote API mais aucun deep link mobile ne le passe a l'utilisateur (cf. `Ce qu'il manque`).

### Widgets reutilisables

- `AuthTextField` (`bagtrip/lib/auth/widgets/auth_text_field.dart`) : champ texte stylise, etat erreur visuel.
- `SocialLoginButton` (`bagtrip/lib/auth/widgets/social_login_button.dart`) : bouton Google/Apple avec loading state, themes clair/sombre.
- `AuthListener` (`bagtrip/lib/auth/widgets/auth_listener.dart`) : wrappe `MaterialApp.router` au niveau de `main.dart`, ecoute `AuthEventBus.onUnauthenticated` et redirige vers `/login`.

### AuthEventBus + interceptor refresh (`bagtrip/lib/core/auth_event_bus.dart`, `bagtrip/lib/service/api_client.dart`)

Bus broadcast statique. L'`ApiClient` (Dio) intercepte chaque 401 :

1. Single-guard `_isRefreshing` evite les refresh concurrents.
2. POST `/auth/refresh` avec le refresh token stocke, via un `_refreshDioFactory(baseUrl)` separe (pas d'interceptor loop).
3. Si succes : sauvegarde la nouvelle paire et rejoue la requete originale.
4. Si echec : `_storageService.deleteToken()` + `AuthEventBus.fireUnauthenticated()` -> `AuthListener` redirige vers `/login`.

---

## Flux d'authentification

### Inscription email/password

```
LoginPage (mode Sign Up)
  -> AuthBloc.RegisterRequested(email, password, fullName?)
    -> AuthRepository.register()
      -> POST /v1/auth/register
        -> bcrypt hash password
        -> UserCreationService.create_and_setup_user()
          -> INSERT User -> flush
          -> StripeClient.create_customer(idempotency_key=...)
          -> commit + claim_pending_invites
        -> _build_auth_response() : access + refresh + cookies
      -> StorageService.saveTokens()
    -> AuthBloc emet AuthSuccess
      -> CrashlyticsService.setUserId()
      -> _registerDeviceToken() (FCM)
    -> LoginView verifie hasSeenPersonalizationPrompt
      -> non -> PersonalizationRoute
      -> oui -> HomeRoute
```

### Connexion OAuth Google ou Apple

```
LoginPage -> AuthBloc.GoogleSignInRequested / AppleSignInRequested
  -> AuthRepository.loginWithGoogle() / loginWithApple()
    -> SDK natif obtient idToken (CancelledError si annulation)
    -> POST /v1/auth/google ou /v1/auth/apple
      -> verify_google_id_token() / verify_apple_id_token()
        -> dev : claims non verifies + check issuer
        -> prod : RS256 + JWKS + audience
      -> Lookup user par email (Apple : fallback {sub}@privaterelay)
      -> Si absent : UserCreationService.create_and_setup_user(dummy_hash)
      -> _build_auth_response()
    -> Meme suite que l'inscription
```

### Refresh token avec rotation

```
ApiClient interceptor onError (401)
  -> _isRefreshing guard
  -> POST /v1/auth/refresh { refresh_token }
    -> SELECT refresh_tokens WHERE token=? AND revoked=false AND expires_at>now
    -> revoque l'ancien (revoked=true)
    -> create_access_token() + create_refresh_token()
    -> set_auth_cookies()
  -> StorageService.saveTokens(new pair)
  -> Replay requete originale avec le nouveau Bearer
  -> Si refresh echoue -> AuthEventBus.fireUnauthenticated() -> /login
```

### Logout (single + all)

```
Profile -> LogoutRequested
  -> CrashlyticsService.clearUserId()
  -> _unregisterDeviceToken() (FCM)
  -> POST /v1/auth/logout { refresh_token? }
    -> UPDATE refresh_tokens SET revoked=true WHERE token=? AND user_id=?
    -> clear_auth_cookies()
  -> CacheService.clearAll() + StorageService.clearAll()
  -> AuthInitial -> /login

Settings -> "Se deconnecter de tous mes appareils"
  -> POST /v1/auth/logout-all
    -> UPDATE refresh_tokens SET revoked=true WHERE user_id=?
```

### Reset password

```
LoginPage -> ForgotPasswordPage
  -> AuthRepository.forgotPassword(email)
    -> POST /v1/auth/forgot-password
      -> Si user existe : raw = secrets.token_urlsafe(32)
      -> user.password_reset_token = sha256(raw)
      -> user.password_reset_expires = now + 1h
      -> commit
      -> dev only : retourne debug_reset_token dans le body
    -> Toujours 200 (ne leak pas l'existence)
  -> Ecran de confirmation (peu importe Success/Failure)

[Out-of-band : delivery du raw token a l'utilisateur — non implemente]

POST /v1/auth/reset-password { token, new_password }
  -> SELECT user WHERE password_reset_token = sha256(token) AND expires > now
  -> bcrypt(new_password) -> user.password_hash
  -> reset_token / reset_expires = NULL
  -> 200
```

---

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Envoi du mail de reset password | `POST /forgot-password` genere et persiste le hash du token, mais en dev seul le `debug_reset_token` est retourne dans le body. En prod aucun mailer n'est branche : le token n'arrive jamais a l'utilisateur. Manque integration SES/Sendgrid + template HTML/FR/EN. | P0 |
| Ecran mobile `ResetPasswordPage` | `POST /reset-password` existe cote API, mais aucun ecran Flutter ne consomme le token. Manque deep link `bagtrip://reset-password?token=...` + page formulaire `new_password` + confirm. | P0 |
| Verification email post-inscription | L'utilisateur est authentifie immediatement apres `/register` sans confirmer l'email. Manque flow de double opt-in (token de verification + endpoint `/verify-email`). | P1 |
| Rate limiting sur les endpoints auth | Aucun rate limit applique sur `/login`, `/register`, `/refresh`, `/forgot-password`. Le middleware Redis `RateLimiter` (`api/src/middleware/rate_limit.py`) existe mais n'est pas branche sur ces routes. Risque brute force / enum. | P1 |
| Changement de mot de passe (user connecte) | Aucun endpoint `PATCH /auth/password` permettant a un user authentifie de changer son mot de passe sans passer par le flow `forgot-password`. | P1 |
| Tests backend auth | Aucun fichier sous `api/tests/api/auth/` ne couvre `routes.py`. Les flows Google/Apple, refresh rotation, logout-all, reset-password ne sont pas testes cote serveur. Les tests Flutter existent (`bagtrip/test/blocs/auth_bloc_test.dart`, `repositories/auth_repository_test.dart`, `integration/auth_flow_test.dart`). | P1 |
| Cleanup des refresh tokens expires | Aucun job dans `api/src/jobs/` ne purge `refresh_tokens` ou les `password_reset_token` expires. La table grossit indefiniment. Manque cron quotidien `DELETE WHERE revoked=true OR expires_at<now-30d`. | P2 |
| Detection de reuse de refresh token | Le contrat documente la detection de reuse comme indicateur de vol, mais le code se contente de revoquer l'ancien token a la rotation. Un refresh deja revoque qui revient devrait declencher un `logout-all` automatique sur tout le compte. | P2 |
| Fusion comptes email + social | Un user inscrit par email puis connecte via Google avec le meme email se voit retourner son compte existant sans flag indiquant que plusieurs providers sont desormais lies. Manque table `user_oauth_providers` pour tracer les liaisons. | P2 |
| Verification de signature en dev | `google_token_verifier.py` et `apple_token_verifier.py` skip la verification RS256 si `NODE_ENV != "production"`. Acceptable en dev, mais le flag doit etre verifie en staging/preprod (incident d'avril 2026 rappelle qu'un staging mal configure peut leak). | P2 |
| CGU et politique de confidentialite | Les callbacks des liens dans `login_page.dart` sont des placeholders. Manque URL + flag d'acceptation persiste a la creation de compte (obligation legale RGPD). | P2 |
