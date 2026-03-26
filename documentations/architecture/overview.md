# Architecture globale -- BagTrip

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

BagTrip est une application de planification de voyages organisee en monorepo avec trois sous-projets :

- **`bagtrip/`** -- Application mobile Flutter (iOS/Android)
- **`api/`** -- Backend FastAPI (Python 3.12+)
- **`admin-panel/`** -- Panel d'administration Next.js 15 (React 19)

Le monorepo est orchestre par un **Makefile racine** qui centralise toutes les commandes de developpement, qualite et deploiement, et un **compose.yml** qui definit les services Docker pour le dev local.

```
T-ESP-901-81605-PAR_Gospalaga/
|-- bagtrip/              # Flutter mobile app (Dart SDK ^3.8.0)
|-- api/                  # FastAPI backend (Python 3.12+, uv)
|-- admin-panel/          # Next.js 15 admin panel (Node 20)
|-- compose.yml           # Docker Compose dev stack
|-- Makefile              # Orchestrateur de commandes
|-- scripts/              # Scripts de setup individuels
|-- .pre-commit-config.yaml
|-- .github/workflows/    # CI/CD GitHub Actions
|-- documentations/       # Documentation projet
|-- kanban/               # Suivi sprint
|-- .env.example          # Variables d'env dev
|-- .env.prod.example     # Variables d'env production
```

## Stack technique

### Backend (`api/`)

| Composant | Technologie | Fichier de reference |
|-----------|-------------|---------------------|
| Framework web | FastAPI | `api/src/main.py` |
| ORM | SQLAlchemy 2.0 (declarative_base) | `api/src/config/database.py` |
| Base de donnees | PostgreSQL 15 | `compose.yml` |
| Migrations | Alembic (21 revisions) | `api/alembic/` |
| Package manager | uv + pyproject.toml | `api/pyproject.toml` |
| Auth | python-jose (JWT HS256), bcrypt, OAuth (Google/Apple via Firebase) | `api/src/api/auth/` |
| Linter | ruff (E, W, F, I, N, UP, B, C4, SIM) | `api/ruff.toml` |
| Paiements | Stripe (payment intents, subscriptions, webhooks) | `api/src/api/stripe/` |
| LLM / IA | LangChain + LangGraph, OVH GPT-OSS 120B | `api/src/agent/` |
| Vols | Amadeus API (recherche, prix, reservation) | `api/src/integrations/` |
| Notifications | Firebase Admin SDK (FCM push) | `api/src/jobs/notification_job.py` |
| Rate limiting | Middleware custom | `api/src/middleware/rate_limit.py` |
| Tests | pytest + pytest-asyncio | `api/tests/` |

### Mobile (`bagtrip/`)

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter (Dart SDK ^3.8.0) |
| State management | flutter_bloc / bloc |
| Navigation | go_router (type-safe @TypedGoRoute) |
| DI | get_it |
| Modeles | freezed + json_serializable |
| API client | Dio (JWT auto-inject, 401 refresh) |
| Cache | Hive (TTL 15min) |
| Assets | FlutterGen (couleurs, images, fonts) |
| i18n | flutter_localizations (EN + FR) |
| Tests | flutter test + golden tests + integration tests |

### Admin Panel (`admin-panel/application/`)

| Composant | Technologie |
|-----------|-------------|
| Framework | Next.js 15.5 (App Router, Turbopack) |
| Runtime | React 19, TypeScript |
| State / API | TanStack React Query |
| Formulaires | react-hook-form + @hookform/resolvers |
| UI | Radix UI, Tailwind CSS, lucide-react |
| Graphiques | Recharts |
| HTTP | Axios |
| Paiements | @stripe/stripe-js |
| E2E Tests | Cypress |
| Lint | ESLint + Prettier + tsc --noEmit |
| Port | 8000 |

## Flux global de l'application

```
[Mobile Flutter]  <-- JWT -->  [FastAPI Backend]  <-- SQL -->  [PostgreSQL 15]
       |                             |
       |                             |--- Amadeus API (vols)
       |                             |--- OVH GPT-OSS (IA / LangGraph agent)
       |                             |--- Stripe (paiements / subscriptions)
       |                             |--- Firebase Admin (push notifications)
       |                             |--- Open-Meteo (meteo, gratuit)
       |                             |--- Unsplash (images de couverture)
       |                             |--- AirLabs (info vols)
       |
[Admin Panel Next.js]  <-- HTTP -->  [FastAPI Backend /admin]
```

### Authentification

- Inscription/connexion par email + mot de passe (bcrypt hash, JWT HS256)
- OAuth via Google (Firebase) et Apple (Bundle ID)
- JWT access token (60 min) + refresh token (30 jours, rotation server-side via table `refresh_tokens`)
- Cote mobile : `ApiClient` (Dio) intercepte les 401 et rafraichit automatiquement le token

### Plans utilisateur

Trois niveaux definis dans `api/src/config/plans.py` :

| Plan | Generations IA/mois | Viewers/trip | Notifs offline | Post-voyage IA |
|------|--------------------:|-------------:|:--------------:|:--------------:|
| FREE | 3 | 2 | Non | Non |
| PREMIUM | illimite | 10 | Oui | Oui |
| ADMIN | illimite | illimite | Oui | Oui |

### Routes API

Toutes les routes sont prefixees `/v1/`. Le backend expose 24 modules de routes :

- **Auth** : `/v1/auth` (register, login, refresh, OAuth)
- **Trips** : `/v1/trips` (CRUD, statut, archivage)
- **Activities** : `/v1/trips/{tripId}/activities`
- **Accommodations** : `/v1/trips/{tripId}/accommodations`
- **Baggage** : `/v1/trips/{tripId}/baggage`
- **Budget** : `/v1/trips/{tripId}/budget-items`
- **Travelers** : `/v1/trips/{tripId}/travelers`
- **Shares** : `/v1/trips/{tripId}/shares`
- **Feedback** : `/v1/trips/{tripId}/feedback`
- **Flights** : recherches, offres, ordres, vols manuels, info
- **Booking Intents** : orchestration Stripe + Amadeus
- **Payments / Stripe** : webhooks, subscriptions
- **Notifications** : `/v1/notifications`, `/v1/device-tokens`
- **Travel** : `/v1/travel` (locations, inspirations)
- **Profile** : `/v1/profile` (profil voyageur)
- **AI** : planification de trip, post-trip analysis
- **Hotels** : recherche hoteliere
- **Admin** : `/admin` (panel d'administration)

### Jobs en arriere-plan

Deux schedulers asyncio lances au demarrage de l'API (`main.py` lifespan) :

1. **`trip_status_scheduler`** (`api/src/jobs/trip_status_job.py`) -- Transition automatique des statuts de trips (DRAFT -> PLANNED -> ONGOING -> COMPLETED)
2. **`notification_scheduler`** (`api/src/jobs/notification_job.py`) -- Envoi des notifications planifiees (rappels depart, H-4/H-1 vol, resume matinal, alertes budget)

### Seed de donnees

Au demarrage, l'API cree automatiquement :
- Les produits Stripe (via `StripeProductsService`)
- Un compte admin par defaut (via `api/src/seeds/create_admin.py`)

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Dockerfile production | Aucun `Dockerfile` de production n'existe pour l'API ni l'admin-panel. Seuls les `Dockerfile.dev` sont presents (`api/Dockerfile.dev`, `admin-panel/application/Dockerfile.dev`). | P0 |
| Compose de production | Pas de `compose.prod.yml` ni de `compose.override.yml`. Le `compose.yml` actuel est purement dev (volumes montes, --reload). | P0 |
| JWT_SECRET par defaut | `api/src/config/env.py` utilise `JWT_SECRET = "dev-secret-key-change-in-production"` comme valeur par defaut. Aucune validation ne bloque le demarrage en production avec cette valeur. | P0 |
| Tests API quasi-vides | Le repertoire `api/tests/` existe mais aucun TODO/FIXME n'a ete trouve dans le code API, suggerant une couverture minimale. `pytest` est configure mais le contenu des tests n'est pas visible dans les sources actuelles. | P1 |
| Agent service Flutter | `bagtrip/lib/service/agent_service.dart` contient deux `TODO: Implement in Epic 6.` -- fonctionnalites IA cote mobile non implementees. | P1 |
| Multi-destination mobile | `bagtrip/lib/service/location_service.dart` contient `TODO: Implement multi-destination search when backend supports it`. | P2 |
| Booking model deprecated | `api/src/models/booking.py` est marque deprecated dans `__init__.py` (remplace par `BookingIntent`) mais le model et la route persistent. Le routing `booking_router` est encore inclus dans `main.py` avec commentaire "DEPRECIE". | P2 |
| Admin panel lint pre-commit | Le hook pre-commit ne couvre pas l'admin-panel (`admin-panel/` n'a pas de hook dans `.pre-commit-config.yaml`). | P2 |
