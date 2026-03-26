# Architecture Backend API

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'API BagTrip est une application **FastAPI** (Python) qui sert de backend pour l'application mobile Flutter et le panneau d'administration Next.js. Elle suit une architecture **layered** : Routes (controllers) -> Services -> Models (SQLAlchemy) -> PostgreSQL, avec des integrations externes (Amadeus, Stripe, Firebase, LLM) et un agent IA multi-noeud base sur LangGraph.

L'application est deployee via Docker et executee sous **Uvicorn** (ASGI), avec hot-reload en mode developpement.

## Structure des fichiers

```
api/src/
├── main.py                      # Point d'entree FastAPI, lifespan, routers, exception handlers
├── enums.py                     # Enums centralises (TripStatus, ActivityCategory, etc.)
├── config/
│   ├── env.py                   # Pydantic Settings (variables d'environnement)
│   ├── database.py              # SQLAlchemy engine, SessionLocal, Base, get_db()
│   └── plans.py                 # Constantes de plans (FREE / PREMIUM / ADMIN)
├── api/                         # Couche routes (controllers)
│   ├── auth/                    # Auth routes, middleware JWT, guards, verifiers OAuth
│   ├── trips/                   # CRUD trips
│   ├── activities/              # CRUD activities + suggest IA
│   ├── accommodations/          # CRUD hebergements
│   ├── baggage/                 # CRUD bagages + suggest IA
│   ├── budget_items/            # CRUD budget + summary
│   ├── travelers/               # CRUD travelers (passagers)
│   ├── shares/                  # Partage de trips
│   ├── feedback/                # Feedbacks post-voyage
│   ├── flights/                 # Sous-modules: searches, offers, orders, manual, info
│   ├── booking_intents/         # Intent de reservation + booking
│   ├── payments/                # Authorize / Capture / Cancel Stripe
│   ├── notifications/           # Notifications utilisateur
│   ├── device_tokens/           # Enregistrement tokens FCM
│   ├── profile/                 # Profil voyageur (onboarding)
│   ├── subscription/            # Stripe Checkout / Portal / Status
│   ├── admin/                   # Routes admin (CRUD global, dashboard, export CSV)
│   ├── travel/                  # Routes Amadeus publiques (locations, flight offers, inspirations)
│   ├── hotels/                  # Recherche hotels Amadeus
│   ├── ai/                      # Plan-trip SSE + post-trip suggestion
│   ├── booking/                 # [DEPRECATED] Ancien pattern de reservation
│   └── stripe/webhooks/         # Webhooks Stripe
├── services/                    # Logique metier
├── models/                      # Modeles SQLAlchemy (ORM)
├── agent/                       # Agent IA LangGraph (graph, nodes, tools, prompts)
├── integrations/                # Clients externes (Amadeus, AirLabs, Unsplash, Firebase, Stripe)
├── middleware/                  # Rate limiting
├── jobs/                        # Background jobs (trip status, notifications)
├── seeds/                       # Seed data (admin par defaut)
└── utils/                       # Utilitaires (errors, logger, cookies, timeout, idempotency)
```

## Configuration

### Variables d'environnement (`config/env.py`)

La configuration utilise **Pydantic Settings** (`BaseSettings`) avec validation automatique au demarrage. Les variables sont chargees depuis `.env` via `python-dotenv`.

Variables obligatoires :
- `DATABASE_URL` — PostgreSQL connection string
- `AMADEUS_CLIENT_ID` / `AMADEUS_CLIENT_SECRET` — API Amadeus
- `LLM_API_KEY` — Cle pour le modele LLM (gpt-oss-120b via OVH)
- `JWT_SECRET` — Secret pour la signature des tokens JWT

Variables optionnelles avec fallback gracieux :
- `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` — Payments (desactive si absent)
- `FIREBASE_SERVICE_ACCOUNT_PATH` — Push notifications (desactive si absent)
- `AIRLABS_API_KEY` — Infos vol temps reel (desactive si absent)
- `UNSPLASH_ACCESS_KEY` — Images de couverture (fallback continent-based si absent)
- `LANGCHAIN_API_KEY` — Tracing LangSmith (optionnel)

En cas de variables manquantes, l'application affiche un message d'erreur formate et `sys.exit(1)`.

### Database (`config/database.py`)

- **SQLAlchemy** synchrone avec `psycopg2-binary`
- `clean_database_url()` retire le parametre `?schema=` de Prisma pour compatibilite
- `pool_pre_ping=True` pour detecter les connexions mortes
- `get_db()` : dependance FastAPI qui gere le lifecycle de la session
- Migrations gerees par **Alembic** (pas d'autogenerate en local)

### Plans (`config/plans.py`)

Trois tiers : `FREE`, `PREMIUM`, `ADMIN` avec des limites specifiques :

| Limite | FREE | PREMIUM | ADMIN |
|--------|------|---------|-------|
| Generations IA / mois | 3 | Illimite | Illimite |
| Viewers par trip | 2 | 10 | Illimite |
| Notifications offline | Non | Oui | Oui |
| Post-voyage IA | Non | Oui | Oui |

## Cycle de vie de l'application (Lifespan)

Au demarrage (`main.py` lifespan) :

1. **Verification de la connexion DB** — `check_database_connection()` execute `SELECT 1`
2. **Initialisation des produits Stripe** — `StripeProductsService.initialize_products()` (graceful si echec)
3. **Creation de l'admin par defaut** — `create_default_admin()` (graceful si echec)
4. **Lancement du scheduler de statuts** — `trip_status_scheduler()` (asyncio task, voir `jobs/`)
5. **Lancement du scheduler de notifications** — `notification_scheduler()` (asyncio task, toutes les 30 min)

A l'arret : les tasks sont annulees proprement via `CancelledError`.

## Middleware

### CORS

Configure via `CORSMiddleware` avec origins depuis `settings.ALLOWED_ORIGINS` (comma-separated). Autorise toutes les methodes et headers.

### Rate Limiting (`middleware/rate_limit.py`)

Deux middlewares empiles :

1. **`auth_rate_limit_middleware`** — Per-IP, 5 requetes/minute sur les endpoints auth (`/v1/auth/login`, `/register`, `/google`, `/apple`, `/refresh`). Utilise `TTLCache` (cachetools) avec auto-expiration.

2. **`rate_limit_middleware`** — Per-user (JWT), 5 requetes/minute sur les endpoints IA (`/agent/chat`, `/v1/ai/*`, `/suggest`). Retourne `429` avec header `Retry-After` et `X-RateLimit-Remaining`.

La classe `RateLimiter` est in-memory (dict avec nettoyage des fenetres expirees). En production, Redis serait recommande.

## Gestion des erreurs

### `AppError` (`utils/errors.py`)

Classe d'exception custom avec :
- `code` (string) — code machine (ex: `TRIP_NOT_FOUND`, `AI_QUOTA_EXCEEDED`)
- `status_code` (int) — HTTP status
- `message` (string) — message user-facing
- `detail` (dict, optionnel) — donnees supplementaires

### Exception Handlers (dans `main.py`)

1. **`AppError`** → `create_http_exception()` → `JSONResponse` avec `{error, code, ...detail}`
2. **`Exception` generique** → `JSONResponse 500` avec traceback complete en mode debug

En mode `development` (`NODE_ENV`), les erreurs non gerees incluent le type d'exception et la traceback dans la reponse JSON.

## Utilitaires

### Logger (`utils/logger.py`)

Logger custom avec 4 niveaux (`DEBUG`, `INFO`, `WARN`, `ERROR`). En mode development, le niveau est `DEBUG`. Supporte le logging structure avec donnees JSON.

### Cookies (`utils/cookies.py`)

Helpers pour les cookies httpOnly d'authentification :
- `set_auth_cookies()` — set `access_token` (httpOnly), `refresh_token` (httpOnly, path `/v1/auth`), `auth-status` (non httpOnly, pour le front)
- `clear_auth_cookies()` — supprime les 3 cookies

### IdempotencyCache (`utils/idempotency.py`)

Cache in-memory (dict + lock threading) avec TTL de 5 minutes. Utilise pour deduplication des appels outils dans les agents IA. Cle = SHA256 du nom de l'outil + parametres normalises en JSON.

### Timeout decorators (`utils/timeout.py`)

- `with_timeout()` — pour fonctions async (via `asyncio.wait_for`)
- `with_timeout_sync()` — pour fonctions synchrones (via `ThreadPoolExecutor`)

Retournent une `fallback_value` en cas de timeout ou d'erreur.

## Services Layer

La logique metier est encapsulee dans des classes service statiques dans `services/`. Chaque service recoit une `Session` SQLAlchemy et manipule les modeles ORM :

| Service | Responsabilite |
|---------|---------------|
| `TripsService` | CRUD trips, pagination, groupement par statut, auto-transition |
| `ActivityService` | CRUD activities, pagination, suggestions IA, batch update |
| `AccommodationsService` | CRUD hebergements |
| `BaggageItemsService` | CRUD bagages, suggestions IA |
| `BudgetItemService` | CRUD budget items, summary avec alertes |
| `TravelersService` | CRUD travelers (passagers vol) |
| `TripShareService` | Partage de trips (invite par email) |
| `FeedbackService` | Feedbacks post-voyage |
| `FlightSearchService` | Recherche de vols (Amadeus) + persistance |
| `FlightOfferPricingService` | Re-pricing d'offres vol |
| `ManualFlightService` | Vols manuels (sans Amadeus) |
| `BookingIntentsService` | Creation d'intents de reservation |
| `BookingOrchestratorService` | Orchestration booking (intent + Amadeus + payment) |
| `StripePaymentsService` | PaymentIntent Stripe (authorize, capture, cancel) |
| `StripeWebhooksService` | Traitement des webhooks Stripe |
| `SubscriptionService` | Checkout + Portal Stripe pour Premium |
| `StripeProductsService` | Initialisation des produits Stripe |
| `NotificationService` | Creation + envoi FCM + deduplication |
| `DeviceTokenService` | Gestion des tokens FCM |
| `PlanService` | Quotas IA, gating features, plan info |
| `ProfileService` | Profil voyageur (onboarding) |
| `PostTripAIService` | Suggestions post-voyage via LLM |
| `LLMService` | Wrapper LLM (OpenAI-compatible via LangChain) |
| `AdminService` | CRUD admin global, metriques, export CSV |

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Rate limiting Redis | Le rate limiter est in-memory (`dict` + `TTLCache`). En multi-instance, il faut migrer vers Redis. Fichier : `middleware/rate_limit.py` ligne 62-66 | P1 |
| IdempotencyCache Redis | Le cache d'idempotence est in-memory. Commentaire dans `utils/idempotency.py` ligne 67 : "pour POC, en production utiliser Redis" | P1 |
| Tests unitaires backend | Aucun fichier de test n'est present dans `api/`. Il n'y a pas de repertoire `tests/` | P0 |
| Validation `NODE_ENV` en production | `JWT_SECRET` a une valeur par defaut `"dev-secret-key-change-in-production"` dans `config/env.py` ligne 50. Pas de validation forcee en production | P0 |
| Health check approfondi | L'endpoint `/health` ne verifie pas la connexion DB ni les services externes. Fichier : `main.py` lignes 229-231 | P2 |
| Structured logging / correlation ID | Le logger est basique (pas de request ID, pas de correlation entre requetes). Fichier : `utils/logger.py` | P2 |
| Graceful shutdown des sessions DB | Pas de fermeture explicite du pool de connexions au shutdown. Fichier : `config/database.py` | P2 |
