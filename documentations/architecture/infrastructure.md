# Infrastructure -- Docker, Compose, Makefile, Scripts

> Derniere mise a jour : 2026-04-09

## Vue d'ensemble

L'infrastructure BagTrip repose sur Docker Compose et un Makefile racine comme point d'entree unique. Le mobile Flutter tourne nativement sur la machine hote (pas de conteneur).

Trois environnements coexistent :

| Environnement | Branche | Stack | URLs publiques |
|---------------|---------|-------|----------------|
| **Dev local** | n'importe quelle branche | `compose.yml` (Dockerfile.dev, hot reload) | `http://localhost:3000` / `http://localhost:8000` |
| **Pre-production** | `develop` (auto) | `compose.prod.yml` sur `/opt/bagtrip-preprod` | `https://dev.bagtrip.fr` / `https://api.dev.bagtrip.fr` |
| **Production** | `main` (auto) | `compose.prod.yml` sur `/opt/bagtrip` | `https://bagtrip.fr` / `https://api.bagtrip.fr` |

Le pipeline CD (cf. [`ci-cd.md`](../ci-cd.md)) deploie automatiquement chaque push sur `develop`/`main` apres passage du Quality Gate.

## Docker Compose dev (`compose.yml`)

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

## Docker Compose production (`compose.prod.yml`)

Le meme fichier `compose.prod.yml` est utilise pour la production et la pre-production. Les valeurs specifiques par environnement sont injectees via `.env.production` (jamais commit, owne `deploy:deploy`, mode `0600` sur le VPS).

### Services

| Service | Image / Build | Port loopback | Notes |
|---------|--------------|---------------|-------|
| `postgres` | `postgres:15-alpine` | -- | Volume `postgres_data`, `pg_isready` healthcheck |
| `redis` | `redis:7-alpine` | -- | RDB save 60s, `redis-cli ping` healthcheck |
| `api` | Build `api/Dockerfile` (multi-stage uv) | -- (`expose: 3000`) | `alembic upgrade head` au demarrage, healthcheck `curl /health` |
| `admin` | Build `admin-panel/application/Dockerfile` (multi-stage Next.js standalone) | -- (`expose: 8000`) | `NEXT_PUBLIC_API_URL` inline au build via build-arg |
| `caddy` | `caddy:2-alpine` | `127.0.0.1:${CADDY_HOST_PORT}:80` | Reverse proxy interne, route `bagtrip.fr` -> admin et `api.bagtrip.fr` -> api par Host header |

### Variables surchargeables (env -> defaut prod)

| Variable | Defaut (prod) | Pre-prod |
|----------|---------------|----------|
| `CADDY_HOST_PORT` | `8081` | `8082` |
| `API_ALLOWED_ORIGINS` | `https://bagtrip.fr` | `https://dev.bagtrip.fr` |
| `API_COOKIE_DOMAIN` | `.bagtrip.fr` | `.dev.bagtrip.fr` |
| `ADMIN_NEXT_PUBLIC_API_URL` | `https://api.bagtrip.fr` | `https://api.dev.bagtrip.fr` |

### Variables forcees (jamais surchargees, definies dans le compose)

`NODE_ENV=production`, `PORT=3000`, `DATABASE_URL`, `REDIS_URL=redis://redis:6379/0`, `COOKIE_SECURE=true`. Cela evite que `.env.production` puisse les casser par erreur.

### Variables sensibles (`.env.production`)

| Variable | Source |
|----------|--------|
| `AMADEUS_CLIENT_ID` / `AMADEUS_CLIENT_SECRET` | https://developers.amadeus.com (test mode) |
| `LLM_API_KEY` | OVH GPT-OSS endpoint |
| `JWT_SECRET` | `openssl rand -base64 64` |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | Generes au setup, distincts entre prod et pre-prod |
| `STRIPE_SECRET_KEY` / `STRIPE_WEBHOOK_SECRET` | Stripe test mode |

`AMADEUS_BASE_URL` n'est pas force : il garde le defaut du code (`https://test.api.amadeus.com`) puisque les cles sont en mode test.

### Reverse proxy interne (`Caddyfile`)

```Caddyfile
{
    auto_https off
    admin off
}

http://bagtrip.fr, http://dev.bagtrip.fr {
    reverse_proxy admin:8000
}

http://api.bagtrip.fr, http://api.dev.bagtrip.fr {
    reverse_proxy api:3000
}
```

Multi-host syntax : le meme Caddyfile sert prod et pre-prod. Le proxy edge global (sur le VPS, hors de ce repo) preserve le `Host` header et route les flux vers `127.0.0.1:8081` (prod) ou `127.0.0.1:8082` (pre-prod), termine le TLS Let's Encrypt et ajoute les headers de securite (HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy).

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
| `make dev` | Lance Docker services (`compose up -d --build`) + Flutter app (full local) |
| `make dev-docker` | Lance Docker services uniquement (db, api, admin) |
| `make dev-mobile` | Lance Flutter uniquement (auto-detecte le device + API host) |
| `make pre-prod` | Lance Flutter pointant vers `https://api.dev.bagtrip.fr` (admin remote sur `https://dev.bagtrip.fr`) |
| `make prod` | Lance Flutter pointant vers `https://api.bagtrip.fr` (admin remote sur `https://bagtrip.fr`) |
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

### Production / pre-prod (`.env.production`)

Le fichier `.env.production` n'est jamais commit (gitignore via `.env.*`). Il vit uniquement sur le VPS, owne `deploy:deploy`, mode `0600`.

Source de verite des variables : [`api/src/config/env.py`](../../api/src/config/env.py) (Pydantic Settings, validateurs stricts). Le fichier `.env.prod.example` historique est obsolete -- ne pas s'y fier.

Variables sensibles a fournir :

- `AMADEUS_CLIENT_ID`, `AMADEUS_CLIENT_SECRET` -- cles Amadeus
- `LLM_API_KEY` -- cle OVH GPT-OSS
- `JWT_SECRET` -- genere via `openssl rand -base64 64`
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`

Variables d'environnement (overrides pre-prod) -- cf. section "Docker Compose production" plus haut.

Variables forcees par le compose (jamais a mettre dans `.env.production`) : `NODE_ENV`, `DATABASE_URL`, `REDIS_URL`, `ALLOWED_ORIGINS`, `COOKIE_DOMAIN`, `COOKIE_SECURE`.

### Admin Panel (`admin-panel/application/.env.local.example`)

- `NEXT_PUBLIC_API_URL` -- URL du backend (defaut : `http://localhost:3000`)
- `NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY` -- cle Stripe publique

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Backup BDD prod | Aucun script de backup/restore PostgreSQL n'est present dans `scripts/`. La pre-prod fait un dump-and-restore depuis la prod a chaque deploy (cf. `cd.yml`), mais aucun snapshot regulier de la prod elle-meme n'est en place. | P1 |
| Mobile web desactive | Le service `mobile-web` est commente dans `compose.yml`. Le Dockerfile Flutter web n'est pas present dans `bagtrip/`. | P2 |
| Monitoring / alerting | Aucun systeme d'alerting (Uptime Kuma, healthchecks.io, Sentry...) sur les endpoints prod et pre-prod. Seul le smoke test `curl /health` du job CD valide le deploy. | P1 |
| Logs centralises | Seul `docker logs` est disponible. Pas de Loki / Datadog / etc. | P2 |
| Scaling horizontal API | Les schedulers (`trip_status_job`, `notification_job`) tournent in-process. Une seconde instance API enverrait des notifications en double. Pour scaler il faudrait extraire vers Celery/Temporal ou un lock applicatif. | P2 |
| Rotation des secrets | Les secrets dans `.env.production` (JWT_SECRET, POSTGRES_PASSWORD) sont generes une fois au setup. Aucun mecanisme de rotation n'est en place. | P2 |
