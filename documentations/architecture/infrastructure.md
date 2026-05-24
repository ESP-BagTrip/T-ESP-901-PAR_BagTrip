# Infrastructure BagTrip

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

L'infrastructure BagTrip s'organise autour de trois stacks (API FastAPI, admin Next.js, mobile Flutter) orchestres par un `Makefile` unique en local et par Docker Compose en production. Le tout tient sur un seul VPS OVH derriere un reverse-proxy edge Caddy (cf. `vps-inventory.md`).

Principes structurants :

- Un seul point d'entree dev : `make <cible>`. Le Makefile racine pilote `docker compose`, `uv` (Python), `npm` (admin) et `flutter`. Aucune commande directe n'est attendue cote contributeur.
- Iso dev / prod : le Dockerfile prod (`api/Dockerfile`, `admin-panel/Dockerfile`) construit exactement les images deployees. Les variantes `.dev` ajoutent hot-reload + bind mounts mais partagent les bases.
- Reseau interne dockerise : seul Caddy expose des ports vers l'exterieur en prod. Les services parlent entre eux via le DNS Docker (`api`, `postgres`, `redis`, `tempo`).
- Dynamique mobile : le Makefile detecte automatiquement le device Flutter cible (simulateur vs telephone physique) et injecte le bon `API_BASE_URL` via `--dart-define`. Un telephone physique attaque l'IP LAN du Mac, pas `localhost`.

## Setup local

Un `make init` suffit pour bootstrap : copie `.env.example`, verifie Docker/Flutter/pre-commit, installe les hooks et les deps Flutter. Les deps API sont installees a la construction de l'image (`uv sync --frozen` dans le Dockerfile dev).

### Cibles `make` principales

| Cible | Action |
|---|---|
| `make init` | Copie `.env.example` -> `.env`, verifie Docker, lance `flutter pub get`, installe les hooks pre-commit |
| `make dev` | Stack complete : `docker compose up -d --build` + `stripe listen` background + `flutter run` foreground |
| `make dev-docker` | Stack docker seule (db, redis, api, admin) + `stripe listen` background |
| `make dev-mobile` | Flutter seul, API attendue sur `localhost:3000` (ou LAN si device physique) |
| `make pre-prod` | Flutter pointe vers `https://api.dev.bagtrip.fr/v1` (aucun docker local) |
| `make prod` | Flutter pointe vers `https://api.bagtrip.fr/v1` (aucun docker local) |
| `make stop` | `docker compose down` + arret du forwarder Stripe |
| `make logs` | `docker compose logs -f` |
| `make dev-clean` | Down + volumes, `flutter clean`, purge `node_modules`/`.next`, `__pycache__`, `.ruff_cache` |
| `make check` | `pre-commit run --all-files` sur l'ensemble du repo |
| `make lint` | Lint API (ruff) + admin (`npm run check-all`) + mobile (`flutter analyze` + `dart format --set-exit-if-changed`) |
| `make test` | `pytest` API + `flutter test` + `flutter test integration_test/` |
| `make coverage` | Couverture Flutter, seuil plancher 30 % via `lcov --summary` |
| `make db-reset` | DROP + CREATE database + `alembic upgrade head` (confirmation interactive) |
| `make db-revision MSG="..."` | `alembic revision -m "..."` dans le container API |
| `make db-shell` | `psql` dans le container `db` |
| `make shell-api` / `make shell-admin` | Bash/sh dans le container correspondant |
| `make stripe-listen` | `stripe listen --forward-to localhost:3000/v1/stripe/webhooks` au premier plan |

Les cibles de tests / lint passent toutes par `docker compose exec`, garantissant que le code tourne dans le meme runtime que la CI.

## Docker Compose dev

Le fichier `compose.yml` decrit la stack locale, baptisee `BagTrip`. Quatre services tournent par defaut ; trois autres (`mobile-web`, `sonarqube`, `sonar-scanner`) sont laisses commentes pour reference.

| Service | Image / build | Port host | Volumes | Role |
|---|---|---|---|---|
| `db` | `postgres:15` | aucun (expose 5432) | `postgres_data` | Base de donnees principale. Joignable uniquement via le reseau compose (`db:5432`) |
| `redis` | `redis:7-alpine` | aucun (expose 6379) | `redis_data` | Cache, rate-limit, locks distribues, idempotency keys |
| `api` | build `./api/Dockerfile.dev` | `3000:3000` | bind `./api/src`, `pyproject.toml`, `uv.lock`, `alembic*` | FastAPI avec `uvicorn --reload`, hot-reload sur edition |
| `admin-panel` | build `./admin-panel/Dockerfile.dev` | `8000:8000` | bind `./admin-panel`, volume nomme `admin_node_modules`, masque `/app/.next` | Next.js dev server avec `WATCHPACK_POLLING=true` |

Le service `api` execute en startup `uv sync && uv run alembic upgrade head && uv run uvicorn ... --reload`, ce qui garantit que les migrations sont a jour a chaque `make dev`. Les variables sensibles (`AMADEUS_*`, `LLM_API_KEY`, `STRIPE_*`) sont injectees depuis `.env` ; les optionnelles utilisent la syntaxe `${VAR:-}` pour ne pas casser le boot si absentes.

Aucun port `db`/`redis` n'est expose au host pour eviter les collisions avec un Postgres local et reduire la surface d'attaque. Pour debugger : `make db-shell` ou `docker compose exec redis redis-cli`.

## Docker Compose prod

Le fichier `compose.prod.yml` est lance sur le VPS via `docker compose -f compose.prod.yml --env-file .env.production up -d --build`. Cinq services tournent en parallele ; le meme fichier sert la prod (`/opt/bagtrip`) et la pre-prod (`/opt/bagtrip-preprod`).

| Service | Image / build | Expose | Healthcheck | Restart |
|---|---|---|---|---|
| `postgres` | `postgres:15-alpine` | interne | `pg_isready -U $POSTGRES_USER` toutes les 10 s | `unless-stopped` |
| `redis` | `redis:7-alpine` avec `--save 60 1 --loglevel warning` | interne | `redis-cli ping` toutes les 10 s | `unless-stopped` |
| `api` | build `./api/Dockerfile` | `3000` interne | Healthcheck dans le Dockerfile (`curl /health`) | `unless-stopped`, depend `postgres` + `redis` healthy |
| `admin` | build `./admin-panel/Dockerfile` avec `ARG NEXT_PUBLIC_API_URL` | `8000` interne | n/a | `unless-stopped`, depend `api` started, `read_only: true`, `cap_drop: ALL` + capabilities minimales, tmpfs `/tmp` et `/app/.next/cache` |
| `caddy` | `caddy:2-alpine` | bind `127.0.0.1:${CADDY_HOST_PORT:-8081}:80` | n/a | `unless-stopped`, monte `./Caddyfile` en read-only, volumes `caddy_data` / `caddy_config` |

Quelques specificites prod :

- L'API exporte ses traces OpenTelemetry vers `tempo:4317` (stack observabilite multi-homed sur le reseau bagtrip). Override possible via `API_OTEL_EXPORTER_OTLP_ENDPOINT`.
- L'admin est durci : `read_only`, `no-new-privileges`, capabilities ramenees au strict minimum (CHOWN, DAC_OVERRIDE, SETGID, SETUID pour le user `nextjs`). Suite directe de l'incident cryptominer 2026-04-26 (cf. memory).
- Caddy n'ecoute que sur `127.0.0.1:8081` : le reverse-proxy edge OVH (sur le port 80/443 public) forward vers ce port en preservant le header `Host`.
- Les volumes `postgres_data`, `redis_data`, `caddy_data`, `caddy_config` sont les seuls etats persistants ; tout le reste est ephemere.

## Dockerfiles

Strategie : multi-stage pour les images prod, single-stage pour les variantes dev avec bind mounts.

`api/Dockerfile` (prod, 3 stages) :

1. `base` : `python:3.12-slim` + variables d'env (`PYTHONDONTWRITEBYTECODE`, `UV_PROJECT_ENVIRONMENT=/app/.venv`).
2. `build` : copie `uv` depuis `ghcr.io/astral-sh/uv:latest`, installe les deps via `uv sync --frozen --no-dev`. Le lockfile garantit la reproductibilite.
3. `runtime` : copie le `.venv` du stage build + le code source (`src`, `alembic`, `alembic.ini`), ajoute `curl` pour le healthcheck, expose 3000. CMD : `alembic upgrade head && exec uvicorn ... --proxy-headers --forwarded-allow-ips='*'` (necessaire derriere Caddy).

`api/Dockerfile.dev` : single-stage, installe `uv` puis `uv sync --frozen` sans `--no-dev`. Pas de copie de code : tout est bind-mount via compose pour le hot-reload.

`admin-panel/Dockerfile` (prod, 3 stages) :

1. `deps` : `node:20-alpine` + `npm ci` a partir du lockfile.
2. `builder` : copie les deps + source, injecte les ARGs `NEXT_PUBLIC_API_URL` et `NEXT_PUBLIC_COOKIE_NAME_PREFIX` (Next.js inline les `NEXT_PUBLIC_*` au build), lance `npm run build`. `NEXT_TELEMETRY_DISABLED=1`.
3. `runtime` : cree un user non-root `nextjs`, copie `.next/standalone` + `.next/static` + `public`, expose 8000, `node server.js`.

`admin-panel/Dockerfile.dev` : single-stage, `npm ci` puis entrypoint custom (`docker-entrypoint.sh`) qui re-installe si `package.json` a change. `npm run dev` par defaut, hot-reload via Webpack polling.

Aucun Dockerfile mobile : Flutter tourne sur l'hote (simulateur ou device physique). L'option `bagtrip/Dockerfile.dev` reste commentee dans le compose pour un futur build web.

## Reverse proxy Caddy

`Caddyfile` minimal, identique en prod et pre-prod :

```
{
    auto_https off
    admin off
}

http://bagtrip.fr, http://dev.bagtrip.fr {
    @metrics path /metrics /metrics/* /api/metrics /api/metrics/*
    respond @metrics 404
    reverse_proxy admin:8000
}

http://api.bagtrip.fr, http://api.dev.bagtrip.fr {
    @metrics path /metrics /metrics/*
    respond @metrics 404
    reverse_proxy api:3000
}
```

Caracteristiques :

- `auto_https off` : la terminaison TLS est faite par le Caddy edge OVH (couche au-dessus), ce Caddy ne sert que de routeur applicatif HTTP.
- `admin off` : l'API admin Caddy (port 2019) est desactivee, on ne veut pas de control plane expose.
- Le routage se fait sur le `Host` header preserve par l'edge : memes services derriere prod et pre-prod, c'est l'hostname qui decide. Permet de partager un seul Caddyfile pour les deux stacks `/opt/bagtrip` et `/opt/bagtrip-preprod`.
- Les paths `/metrics` sont blackholes en 404 : Prometheus scrappe directement le container API via le reseau Docker interne, jamais via Caddy.

## Environment variables

Les `.env.example` et `.env.prod.example` documentent les variables attendues. En dev seules trois sont strictement requises, le reste a des defauts.

### `.env.example` (dev)

| Variable | Requis | Defaut | Role |
|---|---|---|---|
| `AMADEUS_CLIENT_ID` / `AMADEUS_CLIENT_SECRET` | oui | - | Acces API Amadeus (vols, hotels) |
| `LLM_API_KEY` | oui | - | Cle OVH GPT-OSS pour l'agent de planification |
| `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_DB` | non | `postgres`/`postgres`/`bagtrip` | Credentials DB locale |
| `STRIPE_SECRET_KEY` | non | vide | `sk_test_...`, requis pour tout flow Stripe |
| `STRIPE_PUBLISHABLE_KEY` | non | vide | `pk_test_...`, lu par le Makefile et injecte via `--dart-define` Flutter |
| `STRIPE_WEBHOOK_SECRET` | non | vide | `whsec_...`, fourni par `make stripe-listen` au premier lancement |
| `STRIPE_SUCCESS_URL` / `STRIPE_CANCEL_URL` / `STRIPE_PORTAL_RETURN_URL` | non | deeplinks `bagtrip://` | Retours Stripe Checkout |
| `ENABLE_PLAN_EXPIRATION_JOB` | non | `false` | Active le downgrade horaire des Premium expires |
| `ENABLE_ZOMBIE_PI_JOB` | non | `false` | Active le cleanup quotidien des PaymentIntents bloques |
| `LANGCHAIN_TRACING_V2` / `LANGCHAIN_API_KEY` | non | vide | Tracing LangSmith |
| `UNSPLASH_ACCESS_KEY` | non | vide | Images de destinations |

### `.env.prod.example` (prod)

Tout est requis (sauf section LangSmith). Inclut en plus : `DATABASE_URL` complet, `AMADEUS_BASE_URL=https://api.amadeus.com` (vs sandbox en dev), `LLM_MODEL` / `LLM_API_BASE`, `JWT_SECRET` (>= 64 chars via `openssl rand -base64 64`), `JWT_ACCESS_TOKEN_EXPIRE_MINUTES`, `JWT_REFRESH_TOKEN_EXPIRE_DAYS`, `GOOGLE_FIREBASE_PROJECT_ID`, `GOOGLE_OAUTH_CLIENT_ID`, `APPLE_BUNDLE_ID`. Cles Stripe en `sk_live_` / `whsec_` live. `NODE_ENV=production`.

Variables specifiques compose.prod.yml (lues a la construction ou au runtime) : `API_ALLOWED_ORIGINS`, `API_COOKIE_DOMAIN`, `API_COOKIE_NAME_PREFIX`, `API_OTEL_EXPORTER_OTLP_ENDPOINT`, `API_OTEL_SERVICE_NAME`, `API_OTEL_TRACES_SAMPLER_ARG`, `ADMIN_NEXT_PUBLIC_API_URL`, `ADMIN_NEXT_PUBLIC_COOKIE_NAME_PREFIX`, `CADDY_HOST_PORT`. Les prefixes `ADMIN_` / `API_` permettent de coexister prod et pre-prod sur le meme VPS avec deux `.env.production` distincts.

## Build mobile dynamic

Le Makefile encapsule toute la logique de selection du device et de resolution de l'hote API. C'est la partie la plus subtile cote infra, parce qu'un telephone physique branche en USB ne peut pas atteindre `localhost` sur le Mac.

### Detection du device

`detect_device` (macro Makefile) :

1. Si `FLUTTER_DEVICE=<id>` est passe en parametre, on l'utilise tel quel.
2. Sinon, `flutter devices` est parse pour recuperer le premier iPhone / iPad / Android connecte (le bullet `U+2022` est remplace par `|` pour awk).

### Resolution de l'API host

`resolve_api_host` :

- Si pas de device detecte : `localhost`.
- Si le device matche `simulator|emulator|macos|linux|windows|chrome` : `localhost` (le simulateur partage l'espace reseau du Mac).
- Sinon (device physique) : on parcourt `en0` ... `en6`, puis `bridge0`, en utilisant `ipconfig getifaddr`. La premiere IP non-loopback et non-link-local (`169.254.*`) gagne. Fallback : `ifconfig | grep inet`.

### Injection dans Flutter

Le build final assemble l'URL `http://$(API_HOST):3000/v1` et injecte deux `--dart-define` :

```bash
flutter run -d <device> \
  --dart-define=API_BASE_URL=http://192.168.1.42:3000/v1 \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
```

`STRIPE_PUBLISHABLE_KEY` est extrait du `.env` racine (`grep STRIPE_PUBLISHABLE_KEY`). Si absente, un warning est affiche : la PaymentSheet va alors echouer bruyamment au premier appel, jamais silencieusement.

Pour les cibles distantes (`make pre-prod` / `make prod`), la macro de resolution est court-circuitee : l'URL est figee (`https://api.dev.bagtrip.fr/v1` ou `https://api.bagtrip.fr/v1`) et seule la detection du device reste active.

Cote Dart, `API_BASE_URL` est lu via `const String.fromEnvironment('API_BASE_URL', defaultValue: '...')` dans la config app (`bagtrip/lib/config/`). Pas d'AndroidManifest a editer pour `usesCleartextTraffic` : la config dev Android autorise deja le HTTP local sur le LAN range.

## Scripts setup

Le repertoire `scripts/` regroupe les setups par stack, appeles directement ou inderectement par `make init` :

- `setup-api.sh` : verifie `uv`, lance `uv sync` dans `api/`. Echoue si `uv` absent (suggere `make install-uv`, qui delegue a l'installer officiel astral).
- `setup-admin-panel.sh` : verifie Node + npm, lance `npm install` dans `admin-panel/`.
- `setup-bagtrip.sh` : verifie le SDK Flutter, lance `flutter pub get` dans `bagtrip/`.
- `setup-linters.sh` : purement informatif, rappelle que ruff / ESLint / Prettier / flutter_lints sont installes par les autres setups.
- `setup-pre-commit.sh` : installe `pre-commit` (via `uv tool install`, sinon `pipx`, sinon `pip`/`pip3` avec fallback `--break-system-packages`), puis `pre-commit install` a la racine du repo.
- `run-sonar-analysis.sh` : charge `.env`, verifie `sonar-scanner`, declenche `./bagtrip/test_coverage.sh` puis l'analyse SonarCloud. Exclut `api/tests/**`, `bagtrip/test/**`, `admin-panel/cypress/**`. Utilise en CI sur la pipeline qualite.

Tous les scripts sont idempotents et utilisent `set -e`. La sortie console est uniformisee avec un prefixe cyan `[info]` / `OK`.

## Ce qu'il manque

- Aucune migration vers Kubernetes / Nomad : tout tient en `docker compose` sur un seul VPS. La scalabilite horizontale necessiterait de sortir Postgres et Redis vers un managed (cf. `cost-self-host-vs-managed.md`).
- Pas d'IaC declarative (Terraform / Pulumi) : le VPS a ete provisionne a la main, l'infra applicative est versionnee mais pas le serveur lui-meme. Risque de derive si une recreation est necessaire.
- Pas de pipeline de deploiement automatise sur ce repo : les images sont buildees sur le VPS via `docker compose up -d --build`. Pas de registry pousse depuis la CI, pas de blue/green, pas de rollback automatique.
- Pas de healthcheck cote `admin` (le service Next.js n'expose pas d'endpoint `/health` dedie ; on se contente du `depends_on: service_started`).
- Backup Postgres : non documente dans le repo. A confirmer cote VPS (cf. `vps-inventory.md`).
- TLS : delegue au Caddy edge OVH. Aucune configuration cert/ACME dans ce repo, donc dependance forte a la couche superieure.
- Pas de stack mobile-web buildee : le service `bagtrip` reste commente dans `compose.yml`. Le PWA n'est pas une cible officielle.
- Le `make coverage` Flutter n'a pas d'equivalent unifie pour API (la couverture cote API est mesuree par la CI, pas par une cible make). A consolider si besoin.
