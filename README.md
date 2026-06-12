# BagTrip

Student Project

## Prerequisites

- **Docker & Docker Compose** (required) — [Install Docker](https://docs.docker.com/get-docker/)
- **Flutter SDK** (required for mobile dev) — [Install Flutter](https://docs.flutter.dev/get-started/install)
- **pre-commit** (recommended) — [Install pre-commit](https://pre-commit.com/#install)

> Python, Node.js and all other dependencies run inside Docker containers — no local install needed.

## Quick Start

```bash
git clone <repository-url>
cd BagTrip

# Setup project (env file, dependencies, git hooks)
make init

# Edit .env and fill in your API keys (Amadeus, Google, Stripe, etc.)

# Start everything (Docker services + Flutter app)
make dev
```

## Development

```bash
make dev            # Start Docker services + Flutter app (full local)
make dev-docker     # Start Docker services only (db, api, admin-panel)
make dev-mobile     # Start Flutter app only
make pre-prod       # Flutter only → https://api.dev.bagtrip.fr (admin: https://dev.bagtrip.fr)
make prod           # Flutter only → https://api.bagtrip.fr (admin: https://bagtrip.fr)
make stop           # Stop Docker services
make logs           # Follow Docker logs
```

Services available after `make dev` or `make dev-docker`:

| Service     | URL                          |
|-------------|------------------------------|
| API         | http://localhost:3000         |
| API Docs    | http://localhost:3000/docs    |
| Admin Panel | http://localhost:8000         |

`make pre-prod` and `make prod` only run the Flutter app — they assume the
remote backend (api + admin) is already deployed on the VPS via the CD
pipeline (see [`documentations/ci-cd.md`](./documentations/ci-cd.md)).

### Remote environments

| Environment | Branch | Admin URL | API URL | VPS path |
|-------------|--------|-----------|---------|----------|
| **Pre-prod** | `develop` | https://dev.bagtrip.fr | https://api.dev.bagtrip.fr | `/opt/bagtrip-preprod` |
| **Production** | `main` | https://bagtrip.fr | https://api.bagtrip.fr | `/opt/bagtrip` |

Each push to `develop` or `main` triggers `CI Quality Gates`; on success the
`CD` workflow rebuilds and restarts the matching stack on the VPS. Pre-prod
also drops and re-imports the production database before each deploy so it
mirrors current production data.

## Code Quality

```bash
make check          # Run pre-commit hooks on all files
make lint           # Run all linters (api + admin + mobile)
make test           # Run all tests (api + mobile)
```

Individual targets are also available: `lint-api`, `lint-admin`, `lint-mobile`, `test-api`, `test-mobile`.

## Database

```bash
make db-migrate                     # Run Alembic migrations (upgrade head)
make db-revision MSG="add column"   # Create a new Alembic revision
make db-shell                       # Open psql shell
```

## Cleanup

```bash
make dev-clean      # Remove Docker volumes, caches, build artifacts (with confirmation)
```

## Utilities

```bash
make shell-api      # Bash shell in the API container
make shell-admin    # Shell in the admin-panel container
make help           # Show all available commands
```

## Project Structure

```
BagTrip/
├── api/                    # Backend (FastAPI + SQLAlchemy + PostgreSQL)
│   ├── src/                # Application source code
│   ├── alembic/            # Database migrations
│   └── Dockerfile          # Production multi-stage build
├── admin-panel/
│   └── application/        # Admin Panel (Next.js)
│       └── Dockerfile      # Production multi-stage build (standalone)
├── bagtrip/                # Mobile app (Flutter)
├── compose.yml             # Dev Docker Compose
├── compose.prod.yml        # Production Docker Compose (parameterized)
├── Caddyfile               # Internal reverse proxy (prod + pre-prod)
├── .github/workflows/
│   ├── ci.yml              # CI Quality Gates (lint, test, SonarQube scan)
│   └── cd.yml              # CD pipeline (main → prod, develop → pre-prod)
├── .pre-commit-config.yaml # Pre-commit hooks
└── Makefile                # Development automation
```
