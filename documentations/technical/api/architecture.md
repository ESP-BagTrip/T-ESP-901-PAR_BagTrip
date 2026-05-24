# Architecture Backend API

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

L'API BagTrip est une application **FastAPI** (Python 3.12) qui sert de backend pour
l'app mobile Flutter et le panneau d'administration Next.js. Elle suit un layering
strict **Route -> Service -> Repository/Model -> Integration wrapper**, avec une
base PostgreSQL via SQLAlchemy 2.0 (`Mapped[T]` typed declarative), des
migrations Alembic, Redis pour les compteurs distribues (rate limit, locks,
idempotence), et un agent IA LangGraph pour la planification de voyage en SSE.

L'application tourne sous **Uvicorn** (ASGI) dans Docker, avec un lifespan FastAPI
qui orchestre le bootstrap (init HTTP client, check DB, seeds, schedulers) et le
teardown propre des resources.

Stack runtime cle :

- **FastAPI 0.124+** + Uvicorn standard
- **Pydantic v2** (`BaseModel` + `BaseSettings`)
- **SQLAlchemy 2.0** typed declarative + Alembic
- **Redis 5+** (optionnel, fallback in-memory)
- **httpx 0.28+** AsyncClient singleton
- **LangGraph 0.2+** pour l'agent IA
- **Prometheus + OpenTelemetry** pour l'observabilite

## Structure des fichiers

```
api/src/
|-- main.py                      # Entree FastAPI : lifespan, middlewares, routers, handlers
|-- enums.py                     # Enums partages (TripStatus, ActivityCategory, ...)
|-- config/
|   |-- env.py                   # Pydantic Settings + validators NODE_ENV
|   |-- database.py              # SQLAlchemy engine, SessionLocal, get_db()
|   `-- plans.py                 # UserPlan + PLAN_LIMITS (FREE/PREMIUM/ADMIN)
|-- api/                         # Couche routes (controllers HTTP)
|   |-- common/
|   |   |-- pagination.py        # PaginationParams, paginate(), Page[T]
|   |   |-- error_handler.py     # @handle_app_errors
|   |   |-- base_schema.py       # Schemas Pydantic de base (camelCase, alias)
|   |   `-- redaction.py         # redact_for_viewer() role-aware
|   |-- auth/                    # JWT + refresh rotation + OAuth (Google, Apple)
|   |-- trips/, activities/, accommodations/, baggage/, budget_items/
|   |-- travelers/, shares/, invites/, feedback/
|   |-- flights/                 # searches, offers, orders, manual, info
|   |-- booking_intents/         # Intent + booking orchestration
|   |-- payments/, subscription/, stripe/webhooks/
|   |-- notifications/, device_tokens/
|   |-- profile/, travel/, hotels/
|   |-- ai/                      # SSE plan-trip + post-trip suggestion
|   `-- admin/                   # Routes admin (back-office)
|-- services/                    # Logique metier (un service par domaine)
|-- models/                      # Modeles SQLAlchemy Mapped[T] typed
|-- agent/                       # Agent LangGraph (graph, nodes, tools, prompts)
|-- integrations/
|   |-- http_client.py           # httpx.AsyncClient singleton
|   |-- redis_client.py          # get_redis_client() memoise + fallback
|   |-- amadeus/, airlabs/, unsplash/, firebase/, stripe/
|   `-- aviation_data/, open_meteo/, travelpayouts/
|-- middleware/
|   |-- request_id.py            # X-Request-ID + contextvar + log filter
|   |-- security_headers.py      # HSTS, CSP, X-Frame, X-Content-Type, Referrer
|   `-- rate_limit.py            # Redis-backed sliding window + in-memory fallback
|-- utils/
|   |-- unit_of_work.py          # Transaction context manager
|   |-- errors.py                # AppError + create_http_exception
|   |-- distributed_lock.py      # Lock Redis pour schedulers
|   |-- idempotency.py           # Cache idempotent (Redis ou memoire)
|   |-- logger.py                # Logger structure JSON
|   |-- cookies.py, locale.py, timeout.py, iata_timezone.py
|-- jobs/                        # Schedulers asyncio (status, notifs, plan expiration, ...)
|-- migrations/                  # Migrations Alembic (versions/) + scripts ad-hoc legacy
`-- seeds/                       # create_admin() bootstrap
```

## Configuration

### Pydantic Settings (`config/env.py`)

Toute la config passe par `Settings(BaseSettings)` charge depuis `.env` via
`python-dotenv`. La validation est appliquee au boot par Pydantic v2 et un
helper `_format_missing_env_error()` produit un message lisible avant
`sys.exit(1)`.

**Variables obligatoires** (raise au boot si absentes) :

- `DATABASE_URL` : connection string PostgreSQL
- `AMADEUS_CLIENT_ID` / `AMADEUS_CLIENT_SECRET` : API Amadeus (vols, hotels)
- `LLM_API_KEY` : cle LLM (OVHcloud AI Endpoints par defaut)
- `JWT_SECRET` : signature des tokens JWT (validator refuse la valeur par
  defaut en production)

**Variables optionnelles** avec fallback gracieux :

- `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` : paiements (webhook secret
  obligatoire en production, validator dedie)
- `FIREBASE_SERVICE_ACCOUNT_PATH` : push FCM (desactive si absent)
- `AIRLABS_API_KEY` : infos vol temps reel
- `UNSPLASH_ACCESS_KEY` : images de couverture
- `REDIS_URL` : fallback in-memory si absent (rate limit, locks, idempotence)
- `OTEL_EXPORTER_OTLP_ENDPOINT` : tracing distribue (silent en dev)
- `LANGCHAIN_API_KEY` : tracing LangSmith

**Validators production** (`@field_validator`) :

- `JWT_SECRET` ne peut pas etre la valeur par defaut
- `COOKIE_SECURE` doit etre `True`
- `STRIPE_WEBHOOK_SECRET` doit etre defini

### Database (`config/database.py`)

SQLAlchemy synchrone avec `psycopg2-binary`. Le helper `clean_database_url()`
retire le parametre Prisma `?schema=` pour compatibilite. Pool tune pour la
fan-out des endpoints home/trip-detail :

- `pool_size=20` (le defaut 5 sature en burst)
- `max_overflow=10` connexions supplementaires sous pic
- `pool_timeout=30` secondes d'attente max pour une connexion libre
- `pool_recycle=1800` recycle les connexions toutes les 30 minutes (NAT,
  PGBouncer, RDS idle-timeouts)
- `pool_pre_ping=True` : `SELECT 1` avant chaque emprunt, fail-fast sur
  sockets morts

`get_db()` est la dependency FastAPI qui yield une session puis la close en
`finally`. Toutes les routes la consomment via `Depends(get_db)`.

### Plans (`config/plans.py`)

Trois tiers (`UserPlan` StrEnum) avec leurs limites dans `PLAN_LIMITS` :

| Limite | FREE | PREMIUM | ADMIN |
|---|---|---|---|
| `ai_generations_per_month` | 3 | illimite (None) | illimite |
| `viewers_per_trip` | 2 | 10 | illimite |
| `offline_notifications` | False | True | True |
| `post_voyage_ai` | False | True | True |

Le `PlanService` consomme ces constantes pour les quotas et le gating de
features. Le plan ADMIN n'est jamais souscrit via Stripe, il est attribue
manuellement au seed et a la creation de back-office accounts.

## Layering

Le code respecte un layering strict, chaque couche a une responsabilite
unique et ne communique qu'avec la suivante.

### Route (`src/api/<feature>/routes.py`)

Responsabilites uniquement HTTP :

- Parsing du request body (schemas Pydantic v2)
- Auth via `Depends(get_current_user)` ou `Depends(get_trip_access)`
- Pagination via `Depends(PaginationParams)`
- Appel au service metier
- Mapping de la reponse (schemas camelCase via `alias_generator=to_camel`)
- Decorator `@handle_app_errors` pour normaliser les erreurs

**Interdit dans une route** :

- Appel direct a un client d'integration (`amadeus_client`, `stripe.Customer`,
  `httpx.get(...)`)
- Import d'un modele ORM pour faire de l'enrichissement metier
- Logique conditionnelle business (calculs, validations cross-table)

### Service (`src/services/`)

Toute la logique metier. Un service par domaine, statique ou instancie. Les
services consomment :

- Les modeles ORM via la session SQLAlchemy
- Les wrappers d'integration (`AmadeusService`, `StripeGatewayService`,
  `AirLabsService`, `LLMService`)
- D'autres services (uniquement de bas niveau vers haut niveau, pas de
  cycles)

Regles :

- Pas de god-object (> ~600 LoC = decoupage par sous-domaine, cf. `admin/`)
- Helper `paginate()` partout, jamais de count/offset/limit manuel
- Transaction via `with unit_of_work(db):` pour toute mutation multi-row
- `logger.exception(...)` sur tout catch, jamais de `except Exception: pass`

### Model (`src/models/`)

Structure SQLAlchemy 2.0 typed declarative : `Mapped[T]` + `mapped_column(...)`.
Les relations sont declarees avec `Mapped[list["Child"]]` ou
`Mapped["Parent"]`, les cycles resolus via `TYPE_CHECKING`. Pas de methodes
metier sur les modeles (data only).

### Integration wrapper (`src/integrations/`)

Clients vers les services externes. Exposes par un service facade
(`AmadeusService` wrap `amadeus_client`, `StripeGatewayService` wrap le SDK
Stripe). Aucune route ne consomme un integration directement. Tous partagent
le `httpx.AsyncClient` singleton via `get_http_client()`.

## Middlewares

Ordre d'enregistrement dans `main.py` (FastAPI execute en ordre inverse, donc
le dernier enregistre voit le request en premier) :

1. **CORS** (`fastapi.middleware.cors`) : origines lues depuis
   `settings.ALLOWED_ORIGINS` (comma-separated), `allow_credentials=True`,
   methodes et headers `*`.
2. **Rate limit** (`rate_limit_middleware`) : per-user (JWT), 5 req/min sur
   `/agent/chat`, `/v1/ai/*`, `/suggest`. Retourne `429` avec `Retry-After` et
   `X-RateLimit-Remaining`.
3. **Auth rate limit** (`auth_rate_limit_middleware`) : per-IP, 5 req/min sur
   `/v1/auth/login`, `/register`, `/google`, `/apple`, `/refresh`. Protection
   credential stuffing.
4. **Security headers** (`security_headers_middleware`) : HSTS (si
   `COOKIE_SECURE`), CSP `default-src 'none'`, `X-Frame-Options: DENY`,
   `X-Content-Type-Options: nosniff`, `Referrer-Policy: no-referrer`,
   `Permissions-Policy`, COOP/CORP `same-origin`.
5. **Request ID** (`request_id_middleware`) : reflete `X-Request-ID` entrant
   ou genere un UUID4, expose via `contextvars.ContextVar`, injecte dans
   chaque log ligne par `RequestIdLogFilter` (template `[rid=%(request_id)s]`).
   Capture aussi le trace id OTEL pour correlation Loki/Tempo.

Backend Redis vs in-memory : `_CounterStore` dans `rate_limit.py` essaie Redis
via `pipeline.incr().expire()` (atomique multi-worker) et tombe sur un
`cachetools.TTLCache` per-process si Redis est indisponible. La methode `ttl()`
retourne le TTL Redis ou la fenetre complete en fallback memoire.

## Pagination

Toutes les listes paginees passent par `src/api/common/pagination.py` :

- **`PaginationParams`** : dependency FastAPI avec `page: int >= 1` (default 1)
  et `limit: int 1..100` (default 20). `pagination.offset` calcule
  `(page - 1) * limit`. Constructeur alternatif `PaginationParams.of(page,
  limit)` pour usage hors FastAPI (services, tests, jobs).
- **`paginate(query, params, serializer)`** : pipeline
  `count() -> offset().limit().all() -> map(serializer)`. Retourne un
  `PageResult[T]` dataclass avec `items`, `total`, `page`, `limit`,
  `total_pages` (et `as_tuple()` pour migration legacy).
- **`Page[T]`** : reponse Pydantic generique camelCase (alias `totalPages`),
  construite via `Page.from_result(result)`.

Usage standard :

```python
@router.get("/things")
def list_things(
    pagination: PaginationParams = Depends(PaginationParams),
    db: Session = Depends(get_db),
) -> Page[ThingResponse]:
    query = ThingService.list_query(db)
    result = paginate(query, pagination, ThingResponse.model_validate)
    return Page.from_result(result)
```

Aucune route ne doit reimplementer `offset = (page-1)*limit / count() /
offset().limit()` inline.

## Error handling

### `AppError` (`utils/errors.py`)

Exception applicative custom portant :

- `code` (str) : code machine (`TRIP_NOT_FOUND`, `AI_QUOTA_EXCEEDED`, ...)
- `status_code` (int) : HTTP status
- `message` (str) : message user-facing (mappe vers l10n cote Flutter par
  `toUserFriendlyMessage`)
- `detail` (dict | None) : contexte supplementaire

### Exception handlers globaux (`main.py`)

- `@app.exception_handler(AppError)` : JSONResponse avec status, body
  `{detail: {error, code, ...detail}}`. Log en DEBUG si niveau actif.
- `@app.exception_handler(Exception)` : 500 generique. En production le body
  ne contient que `{error: "Internal server error"}` ; en DEBUG il inclut le
  type, le message et la traceback complete (pour faciliter le debug local
  sans leak prod).

### `@handle_app_errors` (`api/common/error_handler.py`)

Decorator obligatoire sur les nouvelles routes. Laisse passer `AppError`
intact (le handler global le mappe) et convertit toute autre exception en
`AppError("INTERNAL_ERROR", 500, ...)` apres log avec `exc_info=True`. Permet
aux services de juste lever `AppError(...)` sans boilerplate try/except.

```python
@router.get("/things")
@handle_app_errors
async def list_things(...):
    return await ThingService.list_things(...)
```

## Transactions unit_of_work

`src/utils/unit_of_work.py` expose un context manager qui wrap commit/rollback
autour d'une session existante :

```python
with unit_of_work(db):
    booking.status = "CONFIRMED"
    db.add(BudgetItem(...))
    db.add(FlightOrder(...))
# commit unique a la sortie, rollback automatique sur exception
```

Caracteristiques :

- N'ouvre pas une nouvelle session : wrap la session request-scoped existante
- Detecte les contextes imbriques via `db.in_nested_transaction()` : seul le
  frame outermost commit, les inner deviennent no-op (services composables)
- Log `unit_of_work rollback` avec type d'exception sur erreur, puis re-raise

Regle : tout service qui mute plus d'une ligne ou plusieurs tables passe par
`unit_of_work`. Pas de `db.commit()` multiples manuels dans une meme operation
metier.

## Lifespan

`@asynccontextmanager async def lifespan(app)` dans `main.py` orchestre boot
et shutdown. Phase boot :

1. **`init_http_client()`** : cree le `httpx.AsyncClient` singleton partage
   par toutes les integrations (`max_connections=100`, `keepalive=20`,
   timeout 30s par defaut, override per-call).
2. **`check_database_connection()`** : execute `SELECT 1` via le pool. Raise
   `ConnectionError` si KO, ce qui empeche le demarrage.
3. **Migration legacy `migrate_trips_table`** : ad-hoc, kept pour
   compatibilite. Le schema canonique est gere par Alembic
   (`alembic upgrade head`).
4. **`StripeProductsService.initialize_products()`** : cree/idempotente les
   produits + prix Premium sur Stripe. Graceful si echec (warn log).
5. **`create_default_admin()`** : seed l'admin par defaut si la table est
   vide. Graceful si echec.
6. **Schedulers asyncio** lances en `asyncio.create_task()` :
   - `trip_status_scheduler` : transitions automatiques de TripStatus
   - `notification_scheduler` : dispatch des notifications planifiees
   - `plan_expiration_scheduler` : downgrade auto PREMIUM->FREE
   - `zombie_payment_intents_scheduler` : cleanup des PaymentIntents stuck
   - `currency_refresh_scheduler` : refresh ECB toutes les 12h
   (lock distribue Redis pour multi-worker, cf. `utils/distributed_lock.py`)

Phase shutdown :

- Cancel de chaque task scheduler, await avec `contextlib.suppress(CancelledError)`
- `close_http_client()` ferme proprement le pool httpx

Observabilite branchee apres l'app : **Prometheus** (`/metrics`,
`Instrumentator` du package `prometheus_fastapi_instrumentator` filtrant
`/metrics`, `/health`, `/`) et **OpenTelemetry** (si
`OTEL_EXPORTER_OTLP_ENDPOINT` est defini : FastAPI / SQLAlchemy / Redis /
HTTPX auto-instrumentes, export OTLP gRPC vers Tempo).

## Plans

Le gating des features premium s'appuie sur trois axes :

- **`UserPlan`** (FREE/PREMIUM/ADMIN) stocke dans `User.plan`.
- **`PLAN_LIMITS`** : dict centralise consomme par `PlanService.get_limits()`.
- **`SubscriptionService`** : checkout + portal Stripe pour souscrire/manager
  PREMIUM. Le `StripeWebhooksService` reagit aux events
  `customer.subscription.*` pour upgrader/downgrader le `User.plan`.

Le `plan_expiration_scheduler` downgrade automatiquement les utilisateurs
PREMIUM dont aucune subscription Stripe active n'est detectee (filet de
securite si un webhook a ete loupe).

Endpoints concernes par le gating :

- IA (plan trip, post-trip suggestion) : quota mensuel `ai_generations_per_month`
- Partage trip : limite `viewers_per_trip`
- Notifications offline + post-voyage IA : booleens

ADMIN bypass tous les quotas et expose `/admin/*` (back-office Next.js).

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| `startup.py` + `router_registry.py` | Le lifespan et l'inclusion des routers vivent encore dans `main.py` (~370 lignes). La regle CLAUDE.md cible un `main.py` minimal avec ces deux modules dedies. Refactor a faire. | P1 |
| Migrations legacy `migrate_trips_table` | Le script ad-hoc dans `migrations/` reste appele au boot pour compat. A retirer une fois sur que toutes les instances sont alignees Alembic. | P2 |
| Pagination cursor-based | `Page[T]` reste offset-based : sur les listes de notifications/activities, le cursor (keyset) eviterait les drifts en cas d'inserts concurrents. | P2 |
| Health check approfondi | `/health` retourne `{status: ok}` sans verifier DB ni dependances externes. Ajouter un `/health/ready` qui ping DB + Redis. | P2 |
| Override mypy services legacy | `pyproject.toml` liste encore 14 services + 5 routes en `ignore_errors = true` (dette Sprint 5 documentee). A reduire progressivement. | P2 |
