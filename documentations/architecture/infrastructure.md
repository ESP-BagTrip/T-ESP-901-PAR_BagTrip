# Infrastructure -- Docker, Compose, Makefile, Scripts

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

L'infrastructure de developpement BagTrip repose sur Docker Compose pour orchestrer les services backend, et un Makefile racine comme point d'entree unique pour toutes les commandes. Le mobile Flutter tourne nativement sur la machine hote (pas de conteneur). Aucune infrastructure de production (Dockerfiles prod, orchestrateur, CDN, etc.) n'est en place.

## Docker Compose (`compose.yml`)

Le fichier `compose.yml` definit 3 services (+ 1 commente) :

### Services

| Service | Image / Build | Port | Conteneur |
|---------|--------------|------|-----------|
| `db` | `postgres:15` | 5432:5432 | BagTrip-db |
| `api` | Build depuis `api/Dockerfile.dev` | 3000:3000 | BagTrip-api |
| `admin-panel` | Build depuis `admin-panel/application/Dockerfile.dev` | 8000:8000 | BagTrip-admin-panel |
| ~~`mobile-web`~~ | commente (prevu pour Flutter web) | ~~5000~~ | ~~BagTrip-mobile-web~~ |

### Base de donnees (`db`)

```yaml
image: postgres:15
environment:
  POSTGRES_USER: ${POSTGRES_USER:-postgres}     # defaut: postgres
  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-postgres}
  POSTGRES_DB: ${POSTGRES_DB:-bagtrip}
volumes:
  - postgres_data:/var/lib/postgresql/data       # volume nomme persistant
```

Le volume `postgres_data` est declare au niveau du compose. Les identifiants par defaut sont `postgres/postgres/bagtrip`.

### API (`api`)

- **Build context** : `./api` avec `Dockerfile.dev`
- **Dockerfile.dev** : `python:3.12-slim` + copie de `uv` depuis `ghcr.io/astral-sh/uv:latest`
- **Volumes montes** (hot reload) : `src/`, `pyproject.toml`, `uv.lock`, `alembic/`, `alembic.ini`
- **Commande** : `uv sync && uv run uvicorn src.main:app --host 0.0.0.0 --port 3000 --reload`
- **PYTHONPATH** : `/app` (necessaire pour les imports `src.*` et Alembic)
- **Variables d'environnement injectees** :
  - `DATABASE_URL` : pointe vers le service `db` (host `db` au lieu de `localhost`)
  - `AMADEUS_CLIENT_ID`, `AMADEUS_CLIENT_SECRET`, `LLM_API_KEY` : requis, sans defaut
  - `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `LANGCHAIN_API_KEY` : optionnels (defaut vide)

### Admin Panel (`admin-panel`)

- **Build context** : `./admin-panel/application` avec `Dockerfile.dev`
- **Dockerfile.dev** : `node:20-alpine`, `npm ci`, `npm run dev`
- **Volumes** : repertoire complet monte, `node_modules` exclu via anonymous volume
- **Variables** : `NEXT_PUBLIC_API_URL=http://localhost:3000`, `WATCHPACK_POLLING=true` (hot reload Docker)
- **Port** : 8000 (Next.js dev avec Turbopack)

## Makefile racine

Le Makefile (`/Makefile`) est le point d'entree principal. Variables cles :

```makefile
COMPOSE      := docker compose
FLUTTER_DIR  := bagtrip
ADMIN_APP_DIR := admin-panel/application
API_DIR      := api
API_PORT     := 3000
```

### Commandes disponibles

#### Setup

| Commande | Description |
|----------|-------------|
| `make init` | Copie `.env.example` -> `.env`, verifie Docker/Flutter/pre-commit, installe les deps Flutter et les hooks |

#### Developpement

| Commande | Description |
|----------|-------------|
| `make dev` | Lance Docker services (`compose up -d --build`) + Flutter app |
| `make dev-docker` | Lance Docker services uniquement (db, api, admin) |
| `make dev-mobile` | Lance Flutter uniquement (auto-detecte le device + API host) |
| `make stop` | `compose down` |
| `make logs` | `compose logs -f` |
| `make dev-clean` | Supprime volumes Docker, caches Flutter, node_modules, __pycache__ (avec confirmation) |

#### Detection automatique du device Flutter

Le Makefile contient une logique de detection avancee :

1. **`detect_device`** : parse `flutter devices` pour trouver un iPhone/iPad/Android connecte
2. **`resolve_api_host`** : determine l'URL API en fonction du device :
   - Simulateur/emulateur -> `localhost`
   - Device physique -> IP LAN du Mac (scan des interfaces `en0`-`en6`, `bridge0`)
3. L'API URL est injectee via `--dart-define=API_BASE_URL=http://<host>:3000/v1`

#### Qualite

| Commande | Description |
|----------|-------------|
| `make check` | `pre-commit run --all-files` |
| `make lint` | Lint API + admin + mobile |
| `make lint-api` | `ruff check . && ruff format --check .` (dans le conteneur) |
| `make lint-admin` | `npm run check-all` dans le conteneur (tsc + eslint + prettier) |
| `make lint-mobile` | `flutter analyze && dart format --set-exit-if-changed .` |
| `make test` | Tous les tests : API + mobile + E2E |
| `make test-api` | `pytest` dans le conteneur |
| `make test-mobile` | `flutter test` |
| `make test-e2e` | `flutter test integration_test/` |
| `make test-e2e-<name>` | Test E2E individuel, ex: `make test-e2e-ft3_active_trip` |
| `make coverage` | Flutter tests + couverture (seuil 60%) |
| `make golden-test` | `flutter test --tags=golden` |
| `make golden-update` | `flutter test --tags=golden --update-goldens` |

#### Base de donnees

| Commande | Description |
|----------|-------------|
| `make db-migrate` | `alembic upgrade head` dans le conteneur |
| `make db-revision MSG="..."` | Cree une nouvelle revision Alembic |
| `make db-shell` | `psql` dans le conteneur db |

#### Utilitaires

| Commande | Description |
|----------|-------------|
| `make shell-api` | Shell bash dans le conteneur API |
| `make shell-admin` | Shell dans le conteneur admin |

## Makefile admin-panel (`admin-panel/application/Makefile`)

Le panel admin a son propre Makefile pour le developpement standalone (hors Docker) avec des commandes supplementaires :

| Commande | Description |
|----------|-------------|
| `make ci-install` | `npm ci` (optimise pour CI) |
| `make ci-test` | `check-all` + E2E Cypress |
| `make dev-https` | Next.js en HTTPS experimental |
| `make analyze` | Analyse du bundle (`ANALYZE=true npm run build`) |
| `make git-hooks` | Configure un hook pre-commit local |

## Scripts de setup (`scripts/`)

Cinq scripts bash de setup individuel :

| Script | Role |
|--------|------|
| `setup-api.sh` | Verifie `uv`, installe les deps Python |
| `setup-admin-panel.sh` | Verifie node/npm, `npm install` |
| `setup-bagtrip.sh` | Verifie Flutter, `flutter pub get` |
| `setup-linters.sh` | Informatif (les linters sont installes par les scripts ci-dessus) |
| `setup-pre-commit.sh` | Installe pre-commit (via uv/pipx/pip), puis `pre-commit install` |

Ces scripts sont independants du Makefile et peuvent etre executes manuellement.

## Variables d'environnement

### Developpement (`.env.example`)

Variables requises (3) :
- `AMADEUS_CLIENT_ID` -- cle API Amadeus
- `AMADEUS_CLIENT_SECRET` -- secret API Amadeus
- `LLM_API_KEY` -- cle API OVH GPT-OSS

Variables optionnelles : `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `LANGCHAIN_API_KEY`, `UNSPLASH_ACCESS_KEY`.

### Production (`.env.prod.example`)

Variables supplementaires requises en production :
- `DATABASE_URL` -- URL complete PostgreSQL
- `JWT_SECRET` -- secret JWT (minimum 64 caracteres, genere via `openssl rand -base64 64`)
- `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`, `JWT_REFRESH_TOKEN_EXPIRE_DAYS`
- `AMADEUS_BASE_URL` -- production endpoint (`https://api.amadeus.com`)
- `LLM_MODEL` -- `gpt-oss-120b`
- `LLM_API_BASE` -- endpoint OVH
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET` -- cles live
- `GOOGLE_FIREBASE_PROJECT_ID`, `GOOGLE_OAUTH_CLIENT_ID`, `APPLE_BUNDLE_ID`

### Admin Panel (`admin-panel/application/.env.local.example`)

- `NEXT_PUBLIC_API_URL` -- URL du backend (defaut : `http://localhost:3000`)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` -- cle Stripe publique

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Dockerfile production API | `api/Dockerfile.dev` existe mais aucun `Dockerfile` ou `Dockerfile.prod` n'est present. Le Dockerfile dev monte des volumes et utilise `--reload`, inadapte pour la production. | P0 |
| Dockerfile production admin | `admin-panel/application/Dockerfile.dev` utilise `npm run dev`. Aucun Dockerfile avec `npm run build` + `npm run start` n'existe. | P0 |
| Compose production | Aucun `compose.prod.yml`. Pas de configuration pour les replicas, health checks Docker, restart policies (sauf `always` sur `db`), ni de reverse proxy/load balancer. | P0 |
| Health check Docker | Seul le service `db` a `restart: always`. Aucun service n'a de `healthcheck:` Docker natif. L'API expose `/health` mais ce n'est pas utilise par Compose. | P1 |
| Migrations automatiques au demarrage | Les migrations Alembic ne sont pas executees automatiquement au lancement du conteneur API. Il faut lancer `make db-migrate` manuellement apres `make dev-docker`. | P1 |
| Mobile web desactive | Le service `mobile-web` est commente dans `compose.yml`. Le Dockerfile Flutter web n'est pas present dans `bagtrip/`. | P2 |
| Backup BDD | Aucun script de backup/restore PostgreSQL n'est present dans `scripts/`. | P1 |
| Securite .env | Le fichier `.env` est present dans le repo (visible dans le git status). Il devrait etre dans `.gitignore` (verifier qu'il ne contient pas de secrets commites). | P0 |
