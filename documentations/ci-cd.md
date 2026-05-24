# CI / CD

> Derniere mise a jour : 2026-05-23

## Vue d'ensemble

BagTrip s'appuie sur deux workflows GitHub Actions complementaires, un scan de
supply-chain transverse, et une instance SonarQube self-hosted pour boucler la
quality gate :

1. `ci.yml` (CI Quality Gates) tourne sur push / PR vers `main` ou `develop`.
   Il detecte les stacks modifiees (Flutter / API / Admin) via path-filter
   `dorny/paths-filter@v3` puis enchaine lint, tests, coverage, Trivy et
   SonarQube. Sur `main` et `develop` (ou PR ciblant ces branches) le filtre
   est ignore : tous les jobs sont forces pour garantir une analyse complete.
2. `cd.yml` se declenche en `workflow_run` apres une CI verte. `main` ->
   production (`/opt/bagtrip`), `develop` -> pre-prod (`/opt/bagtrip-preprod`)
   avec restauration prealable de la base prod dans la pre-prod.
3. Pre-commit hooks (`.pre-commit-config.yaml`) jouent les memes outils en
   local avant chaque commit pour eviter les allers-retours CI.
4. SonarQube self-hosted (`https://sonar.bagtrip.fr`) agrege les rapports de
   coverage (API + Admin) sur les branches protegees uniquement.

L'host VPS OVH heberge prod et pre-prod cote a cote, derriere Traefik
(`api.bagtrip.fr:8081` / `api.dev.bagtrip.fr:8082`).

## Workflow CI (ci.yml)

Concurrence : `ci-${{ github.ref }}` avec `cancel-in-progress: true`. Les
runs en cours sur une meme ref sont annules a chaque nouveau push.

Permissions : `contents:read`, `pull-requests:read`,
`security-events:write` (necessaire pour publier le SARIF Trivy dans l'onglet
Code scanning de GitHub).

### detect-changes

Sortie : booleens `flutter`, `api`, `admin`, plus `protected` (true sur
`main` / `develop`). Sur branche protegee, `force=true` court-circuite les
filtres pour reexecuter toute la pipeline. Filtres :

- `flutter` : `bagtrip/**`, `.github/workflows/ci.yml`
- `api` : `api/**`, `.github/workflows/ci.yml`
- `admin` : `admin-panel/**`, `.github/workflows/ci.yml`

### flutter-analyze

Setup Flutter stable + cache `~/.pub-cache` (cle = hash de `pubspec.lock`).
Steps :

- `flutter pub get`
- `flutter analyze` (zero issue requis, configuration dans
  `bagtrip/analysis_options.yaml` : `flutter_lints` + lints additionnels
  `prefer_const_constructors`, `require_trailing_commas`, `avoid_print`,
  `exhaustive_cases`, `unnecessary_*`, etc.)
- `dart format --set-exit-if-changed .`

### flutter-test

Memes setup et cache. Execute `bash test_coverage.sh` qui :

1. lance `flutter test --coverage`,
2. filtre `coverage/lcov.info` via `lcov --remove` pour exclure le code
   genere (`*.g.dart`, `*.freezed.dart`, `lib/l10n/app_localizations*.dart`,
   `lib/gen/**`, `lib/firebase_options.dart`), le bootstrap (`lib/main.dart`,
   `lib/config/service_locator.dart`), le routing
   (`lib/navigation/route_definitions*.dart`, `app_router.dart`,
   `app_shell.dart`, `page_transitions.dart`) et les pages Stripe
   (`lib/pages/payment/*`),
3. enforce un seuil `COVERAGE_THRESHOLD=60` localement.

La CI uploade `bagtrip/coverage/lcov.info` en artifact (retention 7j) puis
enforce un seuil minimum de 30% dans le job summary via `lcov --summary` (le
script local vise 60%, la gate CI bloque a 30% pour absorber les filtres
agressifs sur les ouvertures de PR).

### api-checks

Setup Python 3.12 + `astral-sh/setup-uv@v4` + cache `~/.cache/uv`
(cle = hash de `uv.lock`). Steps sequentiels :

- `uv sync` (installe deps `dev` : ruff, mypy, bandit, pytest, pytest-cov,
  pytest-asyncio, passlib).
- `uv run ruff check src/` (regles `E,W,F,I,N,UP,B,C4,SIM` definies dans
  `api/ruff.toml`, ignores `E501,B008,N815,N803` pour les types Amadeus
  mixedCase).
- `uv run ruff format --check src/` (`line-length=100`, `quote-style=double`).
- `uv run mypy src/` (Python 3.12, plugin `pydantic.mypy`,
  `warn_redundant_casts`, `warn_unreachable`). Overrides actuels :
  `src.integrations.amadeus.*`, `src.integrations.aviation_data.*`,
  `src.integrations.stripe.*` (SDK non types) et dette Sprint 5 sur
  certains services / routes encore non strict.
- `uv run bandit -c pyproject.toml -r src/ --severity-level medium
  --confidence-level medium`. Skips contextuels : B101 (asserts), B311
  (RNG non-crypto). B104 reste actif.
- Coverage services gate : `uv run pytest tests/services tests/utils
  tests/config tests/agent --cov=src.services --cov-fail-under=70`.
- Coverage API gate : `uv run pytest tests/api --cov=src.api
  --cov-fail-under=70`.
- Full coverage XML pour Sonar : `uv run pytest --cov=src --cov-report=xml
  :coverage.xml` puis `sed` pour reecrire `<source>src</source>` en
  `<source>api/src</source>` (mapping SonarQube). Upload artifact
  `api-coverage` (retention 7j).

### admin-checks

Setup Node 22.x + cache npm (`admin-panel/package-lock.json`). Steps :

- `npm ci --prefer-offline --no-audit`
- `cp .env.local.example .env.local`
- `npm run type-check` (`tsc --noEmit`)
- `npm run lint` (ESLint Next.js core-web-vitals + `@typescript-eslint`,
  cf. `admin-panel/.eslintrc.json` : `no-unused-vars: error`,
  `no-explicit-any: warn`, `prefer-const: error`, `no-var: error`)
- `npm run format:check` (Prettier)
- `npx vitest run --coverage` (env jsdom, reporter `text` + `lcov`,
  exclusions setup + `components/ui/**` + `app/app/dev/**`)
- Upload `admin-panel/coverage/lcov.info` en artifact `admin-coverage`.
- `npm run build` (Next.js production build, garantit que la PR ne casse pas
  le build).

### quality-gate / report

`quality-gate` execute `if: always()` et passe si chaque dependance est
`success`, `skipped` ou `cancelled`. Il sert de cible aux branch protection
rules GitHub. `report` ecrit un tableau recapitulatif dans
`$GITHUB_STEP_SUMMARY`.

## Quality gates

| Stack | Outil | Seuil |
|---|---|---|
| Flutter | `flutter analyze` (flutter_lints + customs) | 0 issue |
| Flutter | `dart format --set-exit-if-changed` | 0 diff |
| Flutter | Coverage CI (`lcov --summary`) | 30% |
| Flutter | Coverage local (`test_coverage.sh`) | 60% |
| API | `ruff check src/` | 0 issue |
| API | `ruff format --check src/` | 0 diff |
| API | `mypy src/` (Python 3.12, pydantic plugin) | 0 erreur hors overrides |
| API | `bandit --severity-level medium --confidence-level medium` | 0 finding |
| API | `pytest tests/services` coverage `src.services` | 70% |
| API | `pytest tests/api` coverage `src.api` | 70% |
| Admin | `tsc --noEmit` | 0 erreur |
| Admin | `eslint` (Next.js + typescript) | 0 issue |
| Admin | `prettier --check` | 0 diff |
| Admin | `vitest run --coverage` | tests verts |
| Admin | `next build` | build OK |
| Supply-chain | `trivy fs` HIGH / CRITICAL | 0 vulnerabilite non waivee |
| Sonar | Quality Gate projet `bagtrip` | conditions Sonar par defaut |

## Trivy scan

Job `trivy-scan`, declenche des qu'au moins une stack est modifiee. Deux
passes successives sur `aquasecurity/trivy-action@v0.36.0` :

1. Scan `fs` en format `table` avec `severity: HIGH,CRITICAL`,
   `ignore-unfixed: true`, `exit-code: 1`. Le job echoue si une CVE non
   waivee est detectee. Le fichier `.trivyignore` accepte des waivers mais
   chaque entree doit porter une `expiry: YYYY-MM-DD` qui force un re-audit.
2. Re-scan identique en `format: sarif` (output `trivy-results.sarif`),
   uploade via `github/codeql-action/upload-sarif@v3` (`category: trivy`)
   dans l'onglet Security > Code scanning.

Couverture : manifests + lockfiles (`uv.lock`, `package-lock.json`,
`pubspec.lock`) plus Dockerfiles. Aucun build d'image n'est requis ; Trivy
walk le repo a froid.

## SonarQube

Instance self-hosted `https://sonar.bagtrip.fr` (Community 26.x, projet en
visibilite **private**, 5 comptes individuels en `user` + `codeviewer`).

Job `sonar` dans `ci.yml`. Conditions :

- `needs.detect-changes.outputs.protected == 'true'` (branches `main` /
  `develop` ou PR les ciblant).
- Au moins un des jobs (`flutter-test`, `api-checks`, `admin-checks`) doit
  etre `success`.

Steps :

1. Checkout `fetch-depth: 0` (Sonar a besoin de l'historique git pour
   l'analyse de blame).
2. Download artifacts `flutter-coverage` -> `bagtrip/coverage`,
   `api-coverage` -> `api`, `admin-coverage` -> `admin-panel/coverage`.
3. `SonarSource/sonarqube-scan-action@v4` avec `SONAR_TOKEN` et
   `SONAR_HOST_URL` en secrets.

Configuration (`sonar-project.properties`) :

- `sonar.projectKey=ESP-BagTrip_T-ESP-901-PAR_BagTrip`,
  `sonar.projectName=BagTrip`.
- `sonar.sources=api/src,admin-panel/src` (le code Dart est exclu car la
  Community Edition ne ship pas d'analyseur Dart -- l'inclure mettrait
  toute la stack Flutter a 0% et ferait chuter la moyenne).
- `sonar.tests=api/tests` + `sonar.test.inclusions=**/*.test.ts*,
  **/*.spec.ts*` pour les tests admin co-localises (a ne PAS dupliquer dans
  `sonar.tests` sous peine de double-comptage).
- `sonar.python.coverage.reportPaths=api/coverage.xml`,
  `sonar.javascript.lcov.reportPaths=admin-panel/coverage/lcov.info`.
- Exclusions standards : `venv`, `node_modules`, `.next`, `cypress`,
  `migrations`, `seeds`, fichiers `*.pyc` et `__pycache__`.

Script utilitaire local : `scripts/run-sonar-analysis.sh` (lance le scan
depuis un poste de dev avec un `.env` charge ; reste sur l'URL legacy
SonarCloud, ne pas utiliser pour le scan officiel).

## Workflow CD (cd.yml)

Trigger : `workflow_run` sur completion du workflow `CI Quality Gates`,
filtre branches `main` et `develop`. Chaque job teste explicitement
`github.event.workflow_run.conclusion == 'success'`. Deploiement via
`appleboy/ssh-action@v1` sur le VPS OVH en tant qu'utilisateur `deploy`.

### deploy-production (main -> /opt/bagtrip)

Concurrence `deploy-production` + `cancel-in-progress: true`. Script :

```bash
cd /opt/bagtrip
git fetch origin main
git reset --hard origin/main
docker compose -f compose.prod.yml --env-file .env.production up -d --build
sleep 10
curl -fsS --max-time 30 \
  --resolve api.bagtrip.fr:8081:127.0.0.1 \
  -H 'Host: api.bagtrip.fr' \
  http://127.0.0.1:8081/health
```

L'API rejoue `alembic upgrade head` au boot ; pas d'etape migration
explicite dans le workflow.

### deploy-preprod (develop -> /opt/bagtrip-preprod)

Concurrence `deploy-preprod`. Specificite : la base pre-prod est dropee
puis restauree depuis la prod a chaque deploy, pour avoir des donnees
realistes. Sequence :

1. `git fetch origin develop && git reset --hard origin/develop` dans
   `/opt/bagtrip-preprod`.
2. `docker compose -f compose.prod.yml --env-file .env.production down`
   (libere les connexions DB).
3. `docker compose ... up -d postgres` (seule la DB pre-prod, on attend
   `pg_isready`).
4. Lecture des mots de passe Postgres depuis chaque `.env.production`
   (prod + pre-prod, fichiers locaux au VPS).
5. `dropdb --if-exists bagtrip` puis `createdb bagtrip` sur le container
   `bagtrip-preprod-postgres-1`. `DROP DATABASE` ne pouvant pas tourner
   dans une transaction, les wrappers CLI sont obligatoires.
6. Pipe `pg_dump -U bagtrip -d bagtrip --no-owner --no-acl --clean
   --if-exists` (depuis `bagtrip-postgres-1`) vers `psql -U bagtrip -d
   bagtrip -v ON_ERROR_STOP=1` (vers `bagtrip-preprod-postgres-1`).
7. `docker compose ... up -d --build` -- l'API rejoue
   `alembic upgrade head` sur les donnees clonees (no-op s'il n'y a pas
   de nouvelle migration depuis le dump).
8. Health check : `curl --resolve api.dev.bagtrip.fr:8082:127.0.0.1
   -H 'Host: api.dev.bagtrip.fr' http://127.0.0.1:8082/health`.

Secrets requis cote GitHub : `OVH_HOST`, `OVH_USER`, `OVH_SSH_KEY`,
`SONAR_TOKEN`, `SONAR_HOST_URL`.

## Pre-commit hooks

Fichier `.pre-commit-config.yaml`, version minimale `3.0.0`.

| Hook | Scope | Action |
|---|---|---|
| `check-added-large-files` | tous | bloque les fichiers volumineux (pre-commit-hooks v6.0.0) |
| `api-lint-format` | `^api/` | `cd api && uv run ruff format src/ && uv run ruff check src/` |
| `api-mypy` | `^api/(src\|pyproject.toml)/.*\.(py\|toml)$` | `uv run mypy src/` |
| `api-bandit` | meme scope que mypy | `uv run bandit -c pyproject.toml -r src/ --severity-level medium --confidence-level medium` |
| `mobile-lint-format` | `^bagtrip/` | `flutter analyze && dart format .` |
| `admin-lint-format` | `^admin-panel/` | `npm run format && npm run lint:fix && rm -rf .next/types && npm run type-check` |

Tous les hooks tournent en `language: system` (uv / flutter / dart / npm
attendus localement) avec `pass_filenames: false` : ils relancent la totalite
du repertoire de la stack concernee a chaque trigger. Installation :
`make init` ou `pre-commit install` ou
`scripts/setup-pre-commit.sh` (tente `uv tool install`, `pipx`, `pip3`,
`pip` dans cet ordre).

Equivalents Makefile pour rejouer une stack : `make lint-api`,
`make lint-mobile`, `make lint-admin`, `make test-api`, `make test-mobile`,
`make test-e2e`, `make coverage`, `make check` (pre-commit sur tous les
fichiers).

## Conventions

### Branches

Format : `task/smp-{ticket}` (ex. `task/smp-311`). Base et target PR :
`develop`. Hotfix : `fix/smp-{ticket}-{slug}` autorise. `main` recoit
uniquement les merges depuis `develop` apres validation pre-prod.

### Commits

Format Conventional Commits : `type(scope): description`. Types acceptes :
`feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `style`, `perf`,
`ci`, `build`. Le `scope` est optionnel et generalement le numero de
ticket (`feat(SMP-311): add origin city field`). Le sujet ne doit pas
commencer par une majuscule.

### Pull Requests

Titre `type(SMP-XXX): description courte` (< 70 caracteres). Body en
trois sections obligatoires :

```markdown
## Problem
Bullet points concis decrivant les problemes / besoins.

## Solution
Description de ce qui resout chaque item de Problem, organisee par
sous-feature si la PR couvre plusieurs sujets.

## Test plan
- [x] Tests automatises qui passent (API / Flutter / hooks)
- [ ] Tests manuels a effectuer par le reviewer
```

Chaque item de `Problem` doit avoir un item correspondant dans `Solution`.
Le test plan distingue ce qui est verifie automatiquement de ce qui
necessite un test manuel. Une PR sans description specifique
("amelioration", "mise a jour") est rejetee.

## Ce qu'il manque

| Element | Description | Priorite |
|---|---|---|
| Branch protection rules | `quality-gate` existe comme cible mais aucune protection GitHub n'est codifiee dans le repo. Forcer le passage de `quality-gate` + revue avant merge sur `main` et `develop`. | P0 |
| Rollback automatique CD | Aucun rollback si le health check post-deploy echoue. Capturer l'image courante avant `compose up` et la redeployer en cas d'echec. | P1 |
| E2E en CI | Les flows Flutter `integration_test/` (FT1 -> FT5) ne sont pas executes dans `ci.yml`. Requiert un device farm ou un emulateur Android headless. | P1 |
| Migration de la pre-prod | Le `pg_dump | psql` se fait depuis le VPS, sans snapshot intermediaire. Stocker un dump horodate avant la restoration permettrait un rollback rapide. | P1 |
| Trivy waivers expires | `.trivyignore` impose un `expiry`, mais aucun job ne verifie qu'aucun waiver expire (au-dela du fail naturel a la prochaine CI). Ajouter un check dedie. | P2 |
| Notifications echec | Aucun webhook Slack / Discord sur echec CI ou CD. Les developpeurs verifient manuellement sur GitHub. | P2 |
| Cache Docker layers | Les jobs n'utilisent pas de cache Docker (les tests ne montent pas de container). Necessaire si on ajoute des tests d'integration backed par Postgres. | P2 |
| Renovate / Dependabot | Aucune automation pour les mises a jour de dependances (`.github/dependabot.yml` absent, pas de `renovate.json`). | P2 |
| SonarQube Dart | Le plugin Dart n'est pas installe sur l'instance Sonar -- `bagtrip/lib` n'est pas analyse cote Sonar (juste cote `flutter analyze`). | P3 |
