# Authentification & Autorisation - Internals techniques

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

Ce document decrit les **internals techniques** du sous-systeme auth de l'API BagTrip : format JWT, rotation des refresh tokens, cookies, dependencies FastAPI, verifiers OAuth, rate limiting. Le pendant metier (parcours utilisateur, regles de validation, schemas exposes) est documente dans `documentations/functional/authentication.md` - les deux fichiers se completent et ne se recouvrent pas.

La surface d'attaque couverte ici est :
- vol d'access token -> mitigation par expiration courte + JWT signe
- vol de refresh token -> mitigation par rotation systematique + revoke chain sur reuse detecte
- vol de cookies -> mitigation par httpOnly, `Secure`, `SameSite=Lax`, path scoping
- credential stuffing -> rate limit Redis 5 req/min par IP sur tous les endpoints sensibles
- tampering du token (forge, alg=none) -> verification stricte HS256 avec secret, ou RS256 + JWKS pour les ID tokens OAuth
- escalade de privilege cross-trip -> dependency `TripAccess` qui renvoie 404 (jamais 403) pour ne pas leaker l'existence d'un trip

Stack auth : `python-jose` (JWT), `bcrypt` (passwords), `secrets.token_urlsafe(64)` (refresh tokens opaques), `redis` (rate limit + counters), `cachetools.TTLCache` (fallback in-memory).

## JWT internals

### Format et signature

| Champ | Valeur |
|-------|--------|
| Algorithme | `HS256` (HMAC-SHA256, symetrique) |
| Secret | `settings.JWT_SECRET` (env, charge au boot) |
| Lib | `jose.jwt.encode` / `jose.jwt.decode` |
| Payload | `{"userId": str(uuid), "exp": datetime, "type": "access"}` |
| Expiration access | `JWT_ACCESS_TOKEN_EXPIRE_MINUTES` (defaut 60 min) |

Construit dans `api/src/api/auth/routes.py::create_access_token` :

```python
expire = datetime.now(UTC) + timedelta(minutes=settings.JWT_ACCESS_TOKEN_EXPIRE_MINUTES)
payload = {"userId": str(user_id), "exp": expire, "type": "access"}
token = jwt.encode(payload, settings.JWT_SECRET, algorithm="HS256")
```

### Verification (`api/src/api/auth/middleware.py::verify_jwt_token`)

1. `jwt.decode(token, settings.JWT_SECRET, algorithms=["HS256"])` - la liste explicite empeche l'attaque `alg=none` ou la confusion HS256/RS256.
2. Verification du champ `type` : si present, doit valoir `"access"`. Si absent, accepte pour retrocompatibilite avec d'anciens tokens emis avant l'ajout du champ.
3. Retour de `payload["userId"]` ou `None` sur `JWTError` (signature invalide, token expire, format casse).

La signature symetrique HS256 est volontaire : pas de besoin de cle publique cote client, les tokens ne sont jamais valides par un tiers. Si l'API devait federer son auth (ex : passer le token a un microservice externe), une migration vers RS256 + JWKS serait necessaire.

## Refresh token rotation

### Format

Le refresh token **n'est pas un JWT** : c'est une chaine opaque generee via `secrets.token_urlsafe(64)` (~86 caracteres URL-safe, ~512 bits d'entropie). Elle est stockee en clair (TODO : sha256 en DB - voir "Ce qu'il manque") dans la table `refresh_tokens` :

| Colonne | Type | Role |
|---------|------|------|
| `id` | `UUID` | PK |
| `user_id` | `UUID FK users.id` | Owner |
| `token` | `String UNIQUE INDEX` | Valeur opaque |
| `expires_at` | `DateTime(tz)` | Maintenant + `JWT_REFRESH_TOKEN_EXPIRE_DAYS` (defaut 30j) |
| `revoked` | `Boolean` | Flag de revocation |
| `created_at` | `DateTime(tz)` | `server_default=now()` |

Fichier modele : `api/src/models/refresh_token.py`.

### Endpoint `POST /v1/auth/refresh`

Sequence (`api/src/api/auth/routes.py::refresh`) :

1. Query DB : `RefreshToken.token == req.refresh_token AND revoked == False`.
2. Si introuvable OU `expires_at < now()` -> `401 Invalid or expired refresh token`.
3. **Revocation immediate** de l'ancien token : `stored.revoked = True`.
4. Generation d'un nouveau pair access + refresh (`create_access_token` + `create_refresh_token`).
5. `db.commit()` atomique sur la revocation + insertion du nouveau token.
6. `set_auth_cookies(response, access_token, new_refresh, expires_in)` re-set les 3 cookies.
7. Retour `AuthResponse` complet (mobile lit le body, Next.js lit les cookies).

### Detection de reuse

Le contrat est : un refresh token n'est valide qu'**une seule fois**. Si un attaquant vole un refresh token et l'utilise avant la victime, la victime se retrouve avec un token marque `revoked = True`. Lors du prochain refresh legitime, la query du step 1 renvoie `None` -> 401 -> le client est forcement deconnecte et redirige vers login.

L'implementation actuelle **n'implemente pas encore le revoke-chain** : sur reuse detecte (refresh d'un token deja revoque), la specification de securite voudrait revoquer **tous** les tokens actifs de cet utilisateur (`logout-all` automatique) pour casser la session de l'attaquant. Aujourd'hui, le 401 protege la victime mais l'attaquant garde son access token jusqu'a son expiration naturelle (60 min). Voir "Ce qu'il manque".

### Logout

- `POST /v1/auth/logout` : revoque le refresh token courant (lu depuis le body ou le cookie `refresh_token`). Garde les autres sessions actives.
- `POST /v1/auth/logout-all` : `UPDATE refresh_tokens SET revoked = True WHERE user_id = ? AND revoked = False`. Tue toutes les sessions.

Les deux endpoints terminent par `clear_auth_cookies(response)`.

## Cookies

Trois cookies definis dans `api/src/utils/cookies.py::set_auth_cookies`. Le prefixe `COOKIE_NAME_PREFIX` permet de partitionner les environnements (dev / preprod / prod) sur le meme domaine.

| Cookie | httpOnly | Secure | SameSite | Path | Max-Age | Role |
|--------|----------|--------|----------|------|---------|------|
| `{prefix}access_token` | Oui | `COOKIE_SECURE` | `lax` | `/` | `expires_in` (3600s) | JWT access pour le admin panel Next.js (SSR) |
| `{prefix}refresh_token` | Oui | `COOKIE_SECURE` | `lax` | `/v1/auth` | 30j fixe | Rotation token, jamais envoye sur les autres routes |
| `{prefix}auth-status` | **Non** | `COOKIE_SECURE` | `lax` | `/` | `expires_in` | Sentinelle lisible par le JS du front pour afficher la UI connectee sans deballer le JWT |

Points cles :
- `httpOnly` sur les deux tokens : JavaScript ne peut pas les lire -> mitige le vol par XSS.
- `path="/v1/auth"` sur le refresh : il n'est envoye automatiquement que sur les endpoints d'auth, jamais sur les routes metier -> reduit la surface de leak (logs proxy, services tiers).
- `auth-status=authenticated` est intentionnellement public : c'est un flag UI, pas un token. Sa presence ne donne aucun droit cote serveur.
- `domain` configurable via `COOKIE_DOMAIN` pour partager les cookies entre `api.bagtrip.app` et `admin.bagtrip.app`.

Suppression : `clear_auth_cookies` doit reutiliser le **meme `path`** que le `set_cookie` pour effectivement supprimer le cookie (browsers matchent name + path).

## Middleware `get_current_user`

Fichier : `api/src/api/auth/middleware.py`. Dependency FastAPI utilisee partout pour resoudre l'utilisateur courant.

Le middleware est **dual-mode** : il accepte le token soit depuis un cookie, soit depuis un header `Authorization: Bearer`. Ordre de priorite :

1. **Cookie** `{prefix}access_token` (admin panel Next.js, fetch SSR / Server Actions).
2. **Header** `Authorization: Bearer <token>` (app mobile Flutter, qui ne gere pas les cookies cross-origin).

Sequence :

```python
token = request.cookies.get(access_cookie_name()) or (credentials and credentials.credentials)
if not token: raise 401
user_id = verify_jwt_token(token)
if not user_id: raise 401
user = db.query(User).filter(User.id == user_id).first()
if not user: raise 404 User not found
return user
```

Note : le 404 sur `User not found` est volontaire et distinct du 401 sur token invalide. Cela permet de detecter un user supprime tout en gardant un access token techniquement valide (cas edge : suppression admin + token encore en cache cote client).

`HTTPBearer(auto_error=False)` permet aux deux modes de coexister : sans header, FastAPI ne raise pas immediatement, on tombe sur la branche cookie.

## Guards

### `AdminGuard` (`api/src/api/auth/admin_guard.py`)

```python
async def require_admin(current_user = Depends(get_current_user)) -> User:
    if getattr(current_user, "plan", None) != "ADMIN":
        raise AppError("FORBIDDEN", 403, "Admin access required")
    return current_user
```

Utilisee par toutes les routes `/admin/*` (back-office Next.js). Le check est purement sur `user.plan == "ADMIN"`, pas de role table dedie.

### `PlanGuard` (`api/src/api/auth/plan_guard.py`)

Deux dependencies :

- **`require_ai_quota`** : appelle `PlanService.check_ai_generation_quota(db, user)`. Le service reconcilie d'abord avec Stripe (`reconcile_plan_with_stripe`) pour eviter de bloquer un user PREMIUM dont le webhook `customer.subscription.created` est en retard, puis verifie le compteur mensuel. Leve `AppError("AI_QUOTA_EXCEEDED", 402)`. Utilisee sur : plan-trip stream, activity suggestions, baggage suggestions, post-trip suggestion.
- **`require_premium`** : `PlanService.reconcile_plan_with_stripe(db, user)` -> si plan resolu == `FREE`, leve `AppError("UPGRADE_REQUIRED", 402, "Premium feature - upgrade your plan.")`. Utilisee sur les features premium-only (post-trip suggester).

Le `402 Payment Required` est volontaire (semantique HTTP) et permet au client mobile de declencher le paywall sans confusion avec 401/403.

### `TripAccess` (`api/src/api/auth/trip_access.py`)

Trois dependencies, toutes basees sur `_resolve_trip_access(db, trip_id, user_id)` :

| Dependency | Roles autorises | Usage |
|------------|-----------------|-------|
| `get_trip_access` | OWNER, EDITOR, VIEWER | GET (lecture) |
| `get_trip_editor_access` | OWNER, EDITOR | POST/PATCH/DELETE collaboratifs |
| `get_trip_owner_access` | OWNER | Operations destructives (delete trip, share, plan settings) |

Resolution :

1. `Trip.query(id=tripId)`. Si introuvable -> `404 TRIP_NOT_FOUND`.
2. Si `trip.user_id == current_user.id` -> `TripRole.OWNER`.
3. Sinon, lookup `TripShare(trip_id, user_id)` -> role declare (`OWNER` / `EDITOR` / `VIEWER`).
4. Sinon -> `404 TRIP_NOT_FOUND` **et pas 403**. Le 404 masque l'existence du trip a un attaquant qui tenterait d'enumerer les UUIDs.

Le retour est un dataclass `TripAccess(trip, role)`, ce qui evite une seconde query DB cote route et permet aux handlers d'appliquer le redact role-aware (`redact_for_viewer(response, access.role)`).

## OAuth verifiers dev vs prod

Deux verifiers, meme philosophie : permissif en dev pour faciliter le travail sur simulateur sans configuration complete, strict en prod.

### Google (`api/src/api/auth/google_token_verifier.py`)

**Dev (`NODE_ENV != "production"`)** :
- `jwt.get_unverified_claims(id_token)` : decode du payload sans verification de signature.
- Verifie uniquement que `iss` est dans la liste : `https://securetoken.google.com/{GOOGLE_FIREBASE_PROJECT_ID}`, `https://accounts.google.com`, `accounts.google.com`. Sinon, simple `logger.warning` - le token est quand meme accepte.

**Prod** :
- Fetch des cles publiques Google : `https://www.googleapis.com/oauth2/v1/certs`, cachees 1h en process (`_google_public_keys_cache`).
- Lookup `kid` dans le header non verifie -> selection de la cle.
- Premier essai : decode avec `algorithms=["RS256"]`, audience = `GOOGLE_FIREBASE_PROJECT_ID`, issuer = `https://securetoken.google.com/{project_id}` (token Firebase, cas device reel).
- Fallback : audience = `GOOGLE_OAUTH_CLIENT_ID`, issuer = `https://accounts.google.com` (token OAuth Google direct, cas simulateur).
- Si les deux echouent -> `JWTError("Google token verification failed for all known audiences")`.

### Apple (`api/src/api/auth/apple_token_verifier.py`)

**Dev** :
- `jwt.get_unverified_claims(id_token)`, verifie `iss == "https://appleid.apple.com"` avec simple warning si KO.

**Prod** :
- Fetch JWKS Apple : `https://appleid.apple.com/auth/keys`, cache 1h.
- Lookup `kid` dans la liste des cles -> `jwk.construct(matching_key)` pour reconstituer la cle RSA.
- `jwt.decode(id_token, public_key, algorithms=["RS256"], audience=APPLE_BUNDLE_ID, issuer="https://appleid.apple.com")`.
- Si `APPLE_BUNDLE_ID` n'est pas configure -> raise immediat (refus de marcher en mode degrade en prod).

Le cache JWKS partage entre processus n'existe pas (variable globale par worker). Acceptable car le TTL est court (1h) et le cold-start cost est negligeable (~50ms).

## Rate limit auth

Fichier : `api/src/middleware/rate_limit.py`. Middleware ASGI applique a tous les `POST` sur :

```
/v1/auth/login
/v1/auth/register
/v1/auth/google
/v1/auth/apple
/v1/auth/refresh
```

Parametres :

- **Limite** : 5 requetes / 60 secondes par IP (`_AUTH_RATE_LIMIT_MAX = 5`).
- **Cle** : `auth:{ip}`, ou `ip` provient de `X-Forwarded-For` (premier element, le proxy front est trusted) avec fallback sur `request.client.host`.
- **Backend** : Redis (`INCR` + `EXPIRE` dans un pipeline atomique) si `REDIS_URL` configure, sinon `cachetools.TTLCache(maxsize=10000, ttl=60)` en process.
- **Reponse 429** : `{"detail": "Too many requests. Please try again later.", "retry_after": 60}` + header `Retry-After: 60`.

Le backend Redis est obligatoire en multi-worker prod (uvicorn -w 4) : la TTLCache in-memory n'est pas partagee entre workers, le rate limit s'effondre des 4 IPs distinctes par worker. Le fallback memoire reste utile en local et garantit que le service ne tombe pas si Redis est indisponible (mode degrade explicite logge).

Le meme `_CounterStore` est reutilise par `ai_rate_limiter` (per-user, 5/min sur les endpoints IA) et `agent_chat_rate_limiter` (10/min) - l'abstraction Redis/memoire est unifiee.

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Reuse-chain revoke | Sur reutilisation d'un refresh token deja revoque, ne pas se contenter de renvoyer 401 : revoquer tous les tokens actifs de l'utilisateur (logout-all automatique) et idealement notifier le user par email. Aujourd'hui l'attaquant garde son access token jusqu'a son expiration. Fichier : `api/src/api/auth/routes.py::refresh` lignes 525-538 | P0 |
| Refresh token hashe en DB | Le token est stocke en clair dans `refresh_tokens.token`. Un dump DB leak des sessions valides. Stocker `sha256(token)` et comparer par hash. Fichier : `api/src/models/refresh_token.py` + `api/src/api/auth/routes.py::create_refresh_token` | P0 |
| JWT_SECRET non valide en prod | La valeur par defaut `"dev-secret-key-change-in-production"` est acceptee en prod sans erreur de boot. Ajouter une assertion dans `src/config/env.py` si `NODE_ENV == "production"`. Fichier : `api/src/config/env.py` | P0 |
| Apple dev mode trop permissif | En dev, signature non verifiee, issuer mismatch ne donne qu'un warning. Acceptable mais risque d'utiliser le mode dev en preprod par erreur. Forcer une verification minimum sur la dependence `NODE_ENV in ("staging", "production")`. Fichier : `api/src/api/auth/apple_token_verifier.py` lignes 39-48 | P1 |
| Cleanup refresh tokens expires | Aucun job de purge. La table grossit lineairement avec les sessions (revoked + expires_at < now()). Cron daily qui DELETE WHERE revoked = True OR expires_at < now() - 7 days. | P1 |
| Lockout par compte | Le rate limit est per-IP. Un attaquant avec un pool d'IPs peut bruteforce un compte specifique. Ajouter un compteur per-email avec lockout temporaire apres N echecs. Fichier : `api/src/api/auth/routes.py::login` | P2 |
| Logs structures auth | Connexions reussies/echouees pas loggees de maniere exploitable (IP, user-agent, latence, raison de l'echec). Bloque l'audit et la detection d'anomalies. | P2 |
| Token introspection endpoint | Pas de `/v1/auth/introspect` pour qu'un service tiers (admin panel SSR) verifie un token sans dupliquer la logique. Acceptable tant que tout passe par `get_current_user`, mais limite si on ouvre une seconde surface. | P3 |
