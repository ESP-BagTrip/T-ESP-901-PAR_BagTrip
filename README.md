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
make dev            # Start Docker services + Flutter app (interactive)
make dev-docker     # Start Docker services only (db, api, admin-panel)
make dev-mobile     # Start Flutter app only
make stop           # Stop Docker services
make logs           # Follow Docker logs
```

Services available after `make dev` or `make dev-docker`:

| Service     | URL                          |
|-------------|------------------------------|
| API         | http://localhost:3000         |
| API Docs    | http://localhost:3000/docs    |
| Admin Panel | http://localhost:8000         |

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
│   └── alembic/            # Database migrations
├── admin-panel/
│   └── application/        # Admin Panel (Next.js)
├── bagtrip/                # Mobile app (Flutter)
├── compose.yml             # Docker Compose configuration
├── .pre-commit-config.yaml # Pre-commit hooks
└── Makefile                # Development automation
```
