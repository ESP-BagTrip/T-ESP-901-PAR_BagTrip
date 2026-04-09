# CI/CD -- Workflows, Hooks, Quality Gates

> Derniere mise a jour : 2026-04-09

## Vue d'ensemble

La pipeline CI/CD de BagTrip s'appuie sur cinq niveaux complementaires :

1. **Pre-commit hooks** -- Verification locale avant chaque commit (linting API + mobile)
2. **GitHub Actions CI Quality Gates** -- Verification automatique sur push/PR (lint, tests, coverage)
3. **GitHub Actions PR checks** -- Validation de la PR elle-meme (titre semantique, analyse de taille)
4. **SonarQube self-hosted** -- Analyse statique + quality gate via `sonar.bagtrip.fr`
5. **GitHub Actions CD** -- Deploiement automatique apres CI : `main` -> production, `develop` -> pre-production

## Pre-commit hooks

**Fichier** : `.pre-commit-config.yaml`

Version minimale requise : `3.0.0`

### Hooks configures

| Hook | Scope | Action |
|------|-------|--------|
| `check-added-large-files` | Tous les fichiers | Empeche les fichiers volumineux d'etre commites (pre-commit-hooks v6.0.0) |
| `api-lint-format` | `^api/` | Execute `ruff format src/` puis `ruff check src/` |
| `mobile-lint-format` | `^bagtrip/` | Execute `flutter analyze` puis `dart format .` |

### Installation

```bash
make init           # installe pre-commit + hooks
# ou
pre-commit install  # directement
# ou
scripts/setup-pre-commit.sh  # script standalone
```

Le script `setup-pre-commit.sh` tente l'installation via `uv tool install`, `pipx`, `pip3` ou `pip` dans cet ordre.

### Limites

- **Pas de hook admin-panel** : les fichiers dans `admin-panel/` ne declenchent aucun hook pre-commit
- **Hooks locaux uniquement** : les deux hooks `api-lint-format` et `mobile-lint-format` utilisent `language: system`, ce qui suppose que `uv`, `ruff`, `flutter` et `dart` sont installes localement
- **`pass_filenames: false`** : les hooks lint l'ensemble du repertoire concerne, pas seulement les fichiers modifies

## GitHub Actions -- CI Quality Gates

**Fichier** : `.github/workflows/ci.yml`

### Declencheurs

- **Push** sur : `main`, `develop`, plus quelques branches feat historiques
- **Pull request** vers les memes branches
- **Concurrence** : `ci-${{ github.ref }}` avec `cancel-in-progress: true` (annule les runs en cours sur la meme branche)

### Detection de changements

Le job `detect-changes` utilise `dorny/paths-filter@v3` pour ne lancer que les jobs pertinents :

| Filtre | Chemins surveilles |
|--------|--------------------|
| `flutter` | `bagtrip/**`, `.github/workflows/ci.yml` |
| `api` | `api/**`, `.github/workflows/ci.yml` |

### Jobs

#### 1. Flutter Analyze (`flutter-analyze`)

- **Condition** : changements dans `bagtrip/`
- **Runner** : `ubuntu-latest`
- **Actions** :
  - Setup Flutter (channel stable, cache active)
  - Cache `~/.pub-cache` (cle : `pubspec.lock` hash)
  - `flutter pub get`
  - `flutter analyze` -- zero issues requis
  - `dart format --set-exit-if-changed .` -- formatage verifie

#### 2. Flutter Test (`flutter-test`)

- **Condition** : changements dans `bagtrip/`
- **Actions** :
  - `flutter test --coverage`
  - Upload `coverage/lcov.info` comme artifact (retention 7 jours)
  - **Seuil de couverture : 60%** -- le job echoue si la couverture de lignes est inferieure
  - Ecrit un resume dans `$GITHUB_STEP_SUMMARY` avec le pourcentage

#### 3. API Checks (`api-checks`)

- **Condition** : changements dans `api/`
- **Actions** :
  - Setup Python 3.12 + uv (`astral-sh/setup-uv@v4`)
  - Cache `~/.cache/uv` (cle : `uv.lock` hash)
  - `uv sync`
  - `uv run ruff check .` -- lint
  - `uv run ruff format --check .` -- formatage
  - `uv run pytest` -- tests

#### 5. Quality Gate (`quality-gate`)

- **Condition** : `always()` (s'execute meme si des jobs precedents sont skipped)
- **Logique** : verifie que tous les jobs sont `success` ou `skipped`. Echoue si un job a `failure`.
- Ce job est le "gate keeper" que les branch protection rules peuvent cibler.

#### 6. CI Report (`report`)

- **Condition** : `always()`
- **Action** : genere un tableau recapitulatif dans `$GITHUB_STEP_SUMMARY` :

```
| Check | Status |
|-------|--------|
| Flutter Analyze | Passed/Skipped/Failed |
| Flutter Test | ... |
| API Checks | ... |
```

### Diagramme de dependances

```
detect-changes
  |
  |---> flutter-analyze ----\
  |---> flutter-test --------\---> sonar ---> quality-gate ---> report
  |---> api-checks ---------/
```

## SonarQube self-hosted

**Instance** : `https://sonar.bagtrip.fr` (self-hosted SonarQube Community 26.x). Le CI publie les analyses sur cette instance, qui remplace l'usage initial de SonarCloud.

### Job `sonar` dans `ci.yml`

- **Action** : `SonarSource/sonarqube-scan-action@v4`
- **Declencheur** : apres `flutter-test` ou `api-checks` avec succes
- **Variables d'environnement** :
  - `SONAR_TOKEN` -- token `PROJECT_ANALYSIS_TOKEN` scope au projet `bagtrip` (secret GitHub Actions)
  - `SONAR_HOST_URL` -- `https://sonar.bagtrip.fr` (secret GitHub Actions)
- **Coverage agregee** : downloads des artifacts `flutter-coverage` et `api-coverage` vers les chemins attendus par `sonar-project.properties`

### Configuration (`sonar-project.properties`)

```properties
sonar.projectKey=ESP-BagTrip_T-ESP-901-PAR_BagTrip
sonar.projectName=BagTrip
sonar.sources=api/src,admin-panel/application/src,bagtrip/lib
sonar.tests=api/tests,bagtrip/test
sonar.python.coverage.reportPaths=api/coverage.xml
sonar.javascript.lcov.reportPaths=admin-panel/application/coverage/lcov.info
sonar.dart.lcov.reportPaths=bagtrip/coverage/lcov.info
```

La cle `sonar.organization` (utile uniquement sur SonarCloud) a ete retiree lors de la migration.

### Acces utilisateur

Le projet `bagtrip` est en visibilite **private**. Seuls les comptes explicitement provisionnes peuvent le consulter (5 comptes individuels, permissions `user` + `codeviewer`). Aucun compte n'a de permission globale.

## GitHub Actions -- CD (deploiement automatique)

**Fichier** : `.github/workflows/cd.yml`

### Declencheurs

- **`workflow_run`** sur la completion de `CI Quality Gates`
- **Branches** : `main`, `develop`
- **Condition** : ne s'execute que si la conclusion CI est `success`

### Jobs

#### 1. `deploy-production` (main -> /opt/bagtrip)

- **Condition** : `workflow_run.head_branch == 'main' && conclusion == 'success'`
- **Concurrence** : `deploy-production` avec `cancel-in-progress: true` (annule les deploys en cours)
- **Action** : `appleboy/ssh-action@v1` -> SSH sur le VPS en tant que `deploy`
- **Script** :
  1. `cd /opt/bagtrip`
  2. `git fetch origin main && git reset --hard origin/main`
  3. `docker compose -f compose.prod.yml --env-file .env.production up -d --build`
  4. Smoke test : `curl --resolve api.bagtrip.fr:8081:127.0.0.1 -H 'Host: api.bagtrip.fr' http://127.0.0.1:8081/health`

#### 2. `deploy-preprod` (develop -> /opt/bagtrip-preprod)

- **Condition** : `workflow_run.head_branch == 'develop' && conclusion == 'success'`
- **Concurrence** : `deploy-preprod` avec `cancel-in-progress: true`
- **Specificite** : avant chaque deploy, la base pre-prod est **droppee et restauree depuis la prod** pour qu'elle reflete les donnees courantes.
- **Script** :
  1. `cd /opt/bagtrip-preprod`
  2. `git fetch origin develop && git reset --hard origin/develop`
  3. `docker compose down`
  4. `docker compose up -d postgres` (uniquement la BDD pre-prod, pour pouvoir restaurer)
  5. `dropdb` puis `createdb` la BDD `bagtrip` pre-prod
  6. `pg_dump -U bagtrip -d bagtrip --no-owner --no-acl` (depuis le conteneur prod) piped vers `psql -U bagtrip -d bagtrip` (vers le conteneur pre-prod)
  7. `docker compose up -d --build` (l'API rejoue `alembic upgrade head` sur les donnees clonees -- no-op si pas de nouvelle migration)
  8. Smoke test : `curl --resolve api.dev.bagtrip.fr:8082:127.0.0.1 -H 'Host: api.dev.bagtrip.fr' http://127.0.0.1:8082/health`

### Secrets requis

| Secret | Usage |
|--------|-------|
| `OVH_HOST` | IP / hostname du VPS |
| `OVH_USER` | Utilisateur SSH (`deploy`) |
| `OVH_SSH_KEY` | Cle privee ed25519 dediee BagTrip CD |
| `SONAR_TOKEN` | Token analyse SonarQube (PROJECT_ANALYSIS_TOKEN) |
| `SONAR_HOST_URL` | `https://sonar.bagtrip.fr` |

### Diagramme du flux complet

```
push develop                   push main
     |                              |
     v                              v
CI Quality Gates             CI Quality Gates
   (lint + tests +              (lint + tests +
    sonar scan)                  sonar scan)
     |                              |
     v                              v
  success?                       success?
     |                              |
     v                              v
deploy-preprod                 deploy-production
 (clone prod data,              (rebuild & restart
  rebuild & restart              /opt/bagtrip)
  /opt/bagtrip-preprod)
     |                              |
     v                              v
https://dev.bagtrip.fr         https://bagtrip.fr
https://api.dev.bagtrip.fr     https://api.bagtrip.fr
```

## GitHub Actions -- PR Checks

**Fichier** : `.github/workflows/pr-checks.yml`

### Declencheurs

- **Pull request** : `opened`, `synchronize`, `reopened`, `ready_for_review`

### Jobs

#### 1. PR Validation (`pr-validation`)

- **Condition** : PR non-draft (`github.event.pull_request.draft == false`)
- **Action** : verifie le titre de la PR avec `amannn/action-semantic-pull-request@v5`
- **Types autorises** : `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`
- **Scope** : non requis (`requireScope: false`)
- **Pattern du sujet** : ne doit PAS commencer par une majuscule (`^(?![A-Z]).+$`)

#### 2. PR Size Analysis (`size-analysis`)

- **Action** : analyse la taille de la PR via `actions/github-script@v7`
- **Calcul** : `git diff --stat origin/<base>...HEAD`
- **Labels automatiques** :

| Taille | Total de changements |
|--------|---------------------|
| XS | <= 10 lignes |
| S | 11-100 lignes |
| M | 101-500 lignes |
| L | 501-1000 lignes |
| XL | > 1000 lignes |

- Poste un commentaire automatique avec le detail (fichiers, insertions, deletions)
- Ajoute un label `size/<xs|s|m|l|xl>` a la PR

## Commandes Makefile -- Quality

Le Makefile fournit des equivalents locaux pour toutes les verifications CI :

| CI Job | Commande locale |
|--------|----------------|
| Flutter Analyze + Format | `make lint-mobile` |
| Flutter Test | `make test-mobile` |
| Flutter Test + Coverage | `make coverage` (seuil 60%) |
| Flutter E2E Tests | `make test-e2e` |
| API Lint + Format | `make lint-api` |
| API Tests | `make test-api` |
| Admin Lint + Types + Format | `make lint-admin` |
| Pre-commit (tous les hooks) | `make check` |
| Tout | `make test` (api + mobile + e2e) |

## Linters et formatters

### API (Python)

**Outil** : ruff (`api/ruff.toml`)

| Parametre | Valeur |
|-----------|--------|
| `line-length` | 100 |
| `target-version` | `py313` |
| `select` | E, W, F, I, N, UP, B, C4, SIM |
| `ignore` | E501, B008, N815, N803 |
| `quote-style` | double |
| `indent-style` | space |
| `isort.known-first-party` | `["src"]` |

N815 et N803 sont ignores pour les parametres API Amadeus qui utilisent du mixedCase.

### Admin Panel (TypeScript)

**Outils** : ESLint (Next.js), Prettier, TypeScript (`tsc --noEmit`)

La commande `npm run check-all` enchaine : `type-check` -> `lint` -> `format:check`

### Mobile (Dart/Flutter)

**Outils** : `flutter analyze` (flutter_lints), `dart format`

## Ce qu'il manque

| Element | Description | Priorite |
|---------|-------------|----------|
| Tests admin-panel en CI | Le workflow `ci.yml` ne couvre pas l'admin-panel. Ni le lint, ni les tests Cypress, ni le type-check ne sont executes en CI. Le `detect-changes` ne filtre pas `admin-panel/`. | P0 |
| Hook pre-commit admin-panel | `.pre-commit-config.yaml` ne couvre que `api/` et `bagtrip/`. L'admin-panel n'a aucun hook pre-commit. | P1 |
| Branch protection rules | Les workflows definissent un `quality-gate` mais aucune configuration de branch protection n'est visible dans le repo. Il faut configurer GitHub pour exiger le passage du quality-gate (et idealement du job CD) avant merge. | P1 |
| Rollback automatique CD | Les jobs CD ne savent pas rollback : si le smoke test echoue apres `compose up`, le service est dans un etat casse jusqu'a intervention manuelle. Idealement, capturer l'image courante avant le `up` et la redeployer si le healthcheck echoue. | P1 |
| E2E tests en CI | Les tests E2E Flutter (`integration_test/`) ne sont pas executes en CI. `make test` les inclut en local mais le workflow `ci.yml` n'a pas de job dedie (necessiterait un simulateur iOS/Android ou un device farm). | P1 |
| Couverture API | Aucun seuil de couverture n'est configure pour l'API (pytest). Seul Flutter a un seuil a 60%. | P2 |
| Notifications d'echec CI/CD | Aucune integration Slack/Discord/email pour les echecs CI ou CD. Les developpeurs doivent verifier manuellement sur GitHub. | P2 |
| Cache Docker layers en CI | Les jobs CI ne utilisent pas de cache Docker. Les images sont reconstruites a chaque run. Cela n'affecte pas les jobs actuels (qui n'utilisent pas Docker) mais serait necessaire si des tests d'integration avec la BDD etaient ajoutes. | P2 |
| Dependabot / Renovate | Aucune automation de mise a jour des dependances n'est configuree (ni `.github/dependabot.yml`, ni `renovate.json`). | P2 |
