# CI/CD -- Workflows, Hooks, Quality Gates

> Derniere mise a jour : 2026-03-26

## Vue d'ensemble

La pipeline CI/CD de BagTrip s'appuie sur trois niveaux complementaires :

1. **Pre-commit hooks** -- Verification locale avant chaque commit (linting API + mobile)
2. **GitHub Actions CI** -- Verification automatique sur push/PR (analyze, tests, coverage, golden tests)
3. **GitHub Actions PR checks** -- Validation de la PR elle-meme (titre semantique, analyse de taille)

Il n'existe pas de pipeline de deploiement (CD) -- ni de staging, ni de production automatisee.

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

- **Push** sur : `main`, `develop`, `feat/SMP-54-add-postgresql-prisma`
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

#### 3. Flutter Golden Tests (`flutter-goldens`)

- **Condition** : changements dans `bagtrip/`
- **Actions** :
  - `flutter test --tags=golden`
  - En cas d'echec : upload `test/goldens/failures/` comme artifact (retention 7 jours)

#### 4. API Checks (`api-checks`)

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
| Flutter Goldens | ... |
| API Checks | ... |
```

### Diagramme de dependances

```
detect-changes
  |
  |---> flutter-analyze ----\
  |---> flutter-test --------\---> quality-gate ---> report
  |---> flutter-goldens -----/
  |---> api-checks ---------/
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

## GitHub Actions -- Golden Update

**Fichier** : `.github/workflows/golden-update.yml`

### Declencheur

- **`workflow_dispatch`** uniquement (manuel depuis l'interface GitHub)
- **Input** : `commit_message` (defaut : `chore: update golden test baselines`)

### Actions

1. Checkout avec `GITHUB_TOKEN`
2. Setup Flutter (stable, cache)
3. `flutter test --tags=golden --update-goldens`
4. `git add bagtrip/test/goldens/`
5. Si des fichiers ont change : commit et push automatique avec le message configurable
6. Le commit est fait par `github-actions[bot]`

## Commandes Makefile -- Quality

Le Makefile fournit des equivalents locaux pour toutes les verifications CI :

| CI Job | Commande locale |
|--------|----------------|
| Flutter Analyze + Format | `make lint-mobile` |
| Flutter Test | `make test-mobile` |
| Flutter Test + Coverage | `make coverage` (seuil 60%) |
| Flutter Golden Tests | `make golden-test` |
| Flutter Golden Update | `make golden-update` |
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
| Pipeline de deploiement (CD) | Aucun workflow de deploiement n'existe. Pas de deploy vers un serveur, PaaS, ou container registry. Les fichiers `.env.prod.example` et les variables de production sont documentes mais aucune automation de deploiement n'est en place. | P0 |
| Tests admin-panel en CI | Le workflow `ci.yml` ne couvre pas l'admin-panel. Ni le lint, ni les tests Cypress, ni le type-check ne sont executes en CI. Le `detect-changes` ne filtre pas `admin-panel/`. | P0 |
| Hook pre-commit admin-panel | `.pre-commit-config.yaml` ne couvre que `api/` et `bagtrip/`. L'admin-panel n'a aucun hook pre-commit. | P1 |
| Branch protection rules | Les workflows definissent un `quality-gate` mais aucune configuration de branch protection n'est visible dans le repo. Il faut configurer GitHub pour exiger le passage du quality-gate avant merge. | P1 |
| E2E tests en CI | Les tests E2E Flutter (`integration_test/`) ne sont pas executes en CI. `make test` les inclut en local mais le workflow `ci.yml` n'a pas de job dedie (necessiterait un simulateur iOS/Android ou un device farm). | P1 |
| Couverture API | Aucun seuil de couverture n'est configure pour l'API (pytest). Seul Flutter a un seuil a 60%. | P2 |
| Notifications d'echec CI | Aucune integration Slack/Discord/email pour les echecs CI. Les developpeurs doivent verifier manuellement sur GitHub. | P2 |
| Cache Docker layers en CI | Les jobs CI ne utilisent pas de cache Docker. Les images sont reconstruites a chaque run. Cela n'affecte pas les jobs actuels (qui n'utilisent pas Docker) mais serait necessaire si des tests d'integration avec la BDD etaient ajoutes. | P2 |
| Dependabot / Renovate | Aucune automation de mise a jour des dependances n'est configuree (ni `.github/dependabot.yml`, ni `renovate.json`). | P2 |
