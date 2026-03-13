# ──────────────────────────────────────────────────────────────
#  BagTrip — Makefile
# ──────────────────────────────────────────────────────────────
.DEFAULT_GOAL := help
SHELL := /bin/bash

# ── Variables ────────────────────────────────────────────────
COMPOSE      := docker compose
FLUTTER_DIR  := bagtrip
ADMIN_APP_DIR := admin-panel/application
API_DIR      := api

# ── Colors ───────────────────────────────────────────────────
CYAN    := \033[36m
GREEN   := \033[32m
YELLOW  := \033[33m
RED     := \033[31m
BOLD    := \033[1m
RESET   := \033[0m

info  = @printf "$(CYAN)[info]$(RESET) %s\n" $(1)
ok    = @printf "$(GREEN)[ok]$(RESET)   %s\n" $(1)
warn  = @printf "$(YELLOW)[warn]$(RESET) %s\n" $(1)
err   = @printf "$(RED)[err]$(RESET)  %s\n" $(1)

# ── Phony targets ────────────────────────────────────────────
.PHONY: help init \
        dev dev-docker dev-mobile stop logs \
        dev-clean \
        check lint lint-api lint-admin lint-mobile test test-api test-mobile \
        db-migrate db-revision db-shell \
        shell-api shell-admin

# ══════════════════════════════════════════════════════════════
#  HELP
# ══════════════════════════════════════════════════════════════

help: ## Show this help
	@printf "\n$(BOLD)$(CYAN) BagTrip$(RESET) — Development commands\n\n"
	@printf "$(BOLD) Setup$(RESET)\n"
	@printf "  $(CYAN)make init$(RESET)            Setup project (env, deps, hooks)\n"
	@printf "\n"
	@printf "$(BOLD) Development$(RESET)\n"
	@printf "  $(CYAN)make dev$(RESET)             Start Docker services + Flutter app\n"
	@printf "  $(CYAN)make dev-docker$(RESET)      Start Docker services only (db, api, admin)\n"
	@printf "  $(CYAN)make dev-mobile$(RESET)      Start Flutter app only\n"
	@printf "  $(CYAN)make stop$(RESET)            Stop Docker services\n"
	@printf "  $(CYAN)make logs$(RESET)            Follow Docker logs\n"
	@printf "\n"
	@printf "$(BOLD) Cleanup$(RESET)\n"
	@printf "  $(CYAN)make dev-clean$(RESET)       Remove volumes, caches, build artifacts\n"
	@printf "\n"
	@printf "$(BOLD) Quality$(RESET)\n"
	@printf "  $(CYAN)make check$(RESET)           Run pre-commit on all files\n"
	@printf "  $(CYAN)make lint$(RESET)            Run all linters (api + admin + mobile)\n"
	@printf "  $(CYAN)make test$(RESET)            Run all tests (api + mobile)\n"
	@printf "\n"
	@printf "$(BOLD) Database$(RESET)\n"
	@printf "  $(CYAN)make db-migrate$(RESET)      Run Alembic migrations (upgrade head)\n"
	@printf "  $(CYAN)make db-revision$(RESET)     Create new Alembic revision (MSG=...)\n"
	@printf "  $(CYAN)make db-shell$(RESET)        Open psql shell in db container\n"
	@printf "\n"
	@printf "$(BOLD) Utilities$(RESET)\n"
	@printf "  $(CYAN)make shell-api$(RESET)       Bash shell in api container\n"
	@printf "  $(CYAN)make shell-admin$(RESET)     Shell in admin-panel container\n"
	@printf "\n"

# ══════════════════════════════════════════════════════════════
#  SETUP
# ══════════════════════════════════════════════════════════════

init: ## Setup project (env, deps, hooks)
	@# ── .env ──
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		printf "$(GREEN)[ok]$(RESET)   .env created from .env.example\n"; \
	else \
		printf "$(GREEN)[ok]$(RESET)   .env already exists\n"; \
	fi
	@# ── Docker ──
	@if ! command -v docker &>/dev/null; then \
		printf "$(RED)[err]$(RESET)  Docker is not installed — https://docs.docker.com/get-docker/\n"; \
		exit 1; \
	else \
		printf "$(GREEN)[ok]$(RESET)   Docker found\n"; \
	fi
	@# ── Flutter ──
	@if ! command -v flutter &>/dev/null; then \
		printf "$(YELLOW)[warn]$(RESET) Flutter not found — https://docs.flutter.dev/get-started/install\n"; \
	else \
		printf "$(GREEN)[ok]$(RESET)   Flutter found — installing dependencies…\n"; \
		cd $(FLUTTER_DIR) && flutter pub get; \
	fi
	@# ── pre-commit ──
	@if ! command -v pre-commit &>/dev/null; then \
		printf "$(YELLOW)[warn]$(RESET) pre-commit not found — https://pre-commit.com/#install\n"; \
	else \
		printf "$(GREEN)[ok]$(RESET)   pre-commit found — installing hooks…\n"; \
		pre-commit install; \
	fi
	@printf "\n$(GREEN)[ok]$(RESET)   Project initialized!\n"

# ══════════════════════════════════════════════════════════════
#  DEVELOPMENT
# ══════════════════════════════════════════════════════════════

dev: ## Start Docker services + Flutter app
	@printf "$(CYAN)[info]$(RESET) Starting Docker services…\n"
	@$(COMPOSE) up -d --build
	@printf "\n$(GREEN)[ok]$(RESET)   Services ready:\n"
	@printf "       API          http://localhost:3000\n"
	@printf "       API Docs     http://localhost:3000/docs\n"
	@printf "       Admin Panel  http://localhost:8000\n\n"
	@printf "$(CYAN)[info]$(RESET) Starting Flutter app (hot reload: r/R, quit: q)…\n\n"
	@cd $(FLUTTER_DIR) && flutter run

dev-docker: ## Start Docker services only (db, api, admin)
	@printf "$(CYAN)[info]$(RESET) Starting Docker services…\n"
	@$(COMPOSE) up -d --build
	@printf "\n$(GREEN)[ok]$(RESET)   Services ready:\n"
	@printf "       API          http://localhost:3000\n"
	@printf "       API Docs     http://localhost:3000/docs\n"
	@printf "       Admin Panel  http://localhost:8000\n\n"

dev-mobile: ## Start Flutter app only
	@printf "$(CYAN)[info]$(RESET) Starting Flutter app (hot reload: r/R, quit: q)…\n\n"
	@cd $(FLUTTER_DIR) && flutter run

stop: ## Stop Docker services
	@printf "$(CYAN)[info]$(RESET) Stopping services…\n"
	@$(COMPOSE) down
	$(call ok,"Services stopped")

logs: ## Follow Docker logs
	@$(COMPOSE) logs -f

# ══════════════════════════════════════════════════════════════
#  CLEANUP
# ══════════════════════════════════════════════════════════════

dev-clean: ## Remove volumes, caches, build artifacts
	@printf "$(YELLOW)[warn]$(RESET) This will remove:\n"
	@printf "       - Docker volumes & orphan containers\n"
	@printf "       - Flutter build cache ($(FLUTTER_DIR)/)\n"
	@printf "       - node_modules, .next, coverage ($(ADMIN_APP_DIR)/)\n"
	@printf "       - __pycache__, .pytest_cache, .ruff_cache ($(API_DIR)/)\n\n"
	@printf "Continue? [y/N] " && read ans && [ "$${ans}" = "y" ] || (printf "$(CYAN)[info]$(RESET) Aborted\n" && exit 1)
	@printf "\n"
	@printf "$(CYAN)[info]$(RESET) Stopping and removing Docker resources…\n"
	@$(COMPOSE) down -v --remove-orphans
	@if command -v flutter &>/dev/null; then \
		printf "$(CYAN)[info]$(RESET) Cleaning Flutter…\n"; \
		cd $(FLUTTER_DIR) && flutter clean; \
	fi
	@printf "$(CYAN)[info]$(RESET) Cleaning admin-panel…\n"
	@rm -rf $(ADMIN_APP_DIR)/node_modules $(ADMIN_APP_DIR)/.next $(ADMIN_APP_DIR)/coverage
	@printf "$(CYAN)[info]$(RESET) Cleaning API caches…\n"
	@find $(API_DIR) -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf $(API_DIR)/.pytest_cache $(API_DIR)/.ruff_cache
	@printf "\n$(GREEN)[ok]$(RESET)   Clean complete\n"

# ══════════════════════════════════════════════════════════════
#  QUALITY
# ══════════════════════════════════════════════════════════════

check: ## Run pre-commit on all files
	@pre-commit run --all-files

lint: lint-api lint-admin lint-mobile ## Run all linters

lint-api: ## Lint API (ruff check + format)
	@printf "$(CYAN)[info]$(RESET) Linting API…\n"
	@$(COMPOSE) exec api uv run ruff check .
	@$(COMPOSE) exec api uv run ruff format --check .
	$(call ok,"API lint passed")

lint-admin: ## Lint admin-panel (type-check + lint + format)
	@printf "$(CYAN)[info]$(RESET) Linting admin-panel…\n"
	@$(COMPOSE) exec admin-panel npm run check-all
	$(call ok,"Admin lint passed")

lint-mobile: ## Lint Flutter app (analyze + format)
	@printf "$(CYAN)[info]$(RESET) Linting Flutter app…\n"
	@cd $(FLUTTER_DIR) && flutter analyze
	@cd $(FLUTTER_DIR) && dart format --set-exit-if-changed .
	$(call ok,"Mobile lint passed")

test: test-api test-mobile ## Run all tests

test-api: ## Run API tests (pytest)
	@printf "$(CYAN)[info]$(RESET) Running API tests…\n"
	@$(COMPOSE) exec api uv run pytest
	$(call ok,"API tests passed")

test-mobile: ## Run Flutter tests
	@printf "$(CYAN)[info]$(RESET) Running Flutter tests…\n"
	@cd $(FLUTTER_DIR) && flutter test
	$(call ok,"Mobile tests passed")

# ══════════════════════════════════════════════════════════════
#  DATABASE
# ══════════════════════════════════════════════════════════════

db-migrate: ## Run Alembic migrations (upgrade head)
	@printf "$(CYAN)[info]$(RESET) Running migrations…\n"
	@$(COMPOSE) exec api uv run alembic upgrade head
	$(call ok,"Migrations applied")

db-revision: ## Create Alembic revision (MSG="description")
	@if [ -z "$(MSG)" ]; then \
		printf "$(RED)[err]$(RESET)  MSG is required: make db-revision MSG=\"add users table\"\n"; \
		exit 1; \
	fi
	@printf "$(CYAN)[info]$(RESET) Creating revision: $(MSG)\n"
	@$(COMPOSE) exec api uv run alembic revision -m "$(MSG)"
	$(call ok,"Revision created")

db-shell: ## Open psql shell in db container
	@$(COMPOSE) exec db psql -U $${POSTGRES_USER:-postgres} -d $${POSTGRES_DB:-bagtrip}

# ══════════════════════════════════════════════════════════════
#  UTILITIES
# ══════════════════════════════════════════════════════════════

shell-api: ## Bash shell in api container
	@$(COMPOSE) exec api /bin/bash

shell-admin: ## Shell in admin-panel container
	@$(COMPOSE) exec admin-panel /bin/sh
