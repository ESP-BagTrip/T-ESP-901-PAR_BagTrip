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
API_PORT     := 3000

# ── API URL detection ────────────────────────────────────────
# Detect the Flutter target device and resolve the right API host.
#   • Simulator / desktop  → localhost (same machine)
#   • Physical device      → Mac's LAN IP so the phone can reach the API
#
# FLUTTER_DEVICE can be overridden:  make dev FLUTTER_DEVICE=<device-id>
FLUTTER_DEVICE ?=

# Resolve the host dynamically (called in recipes via $(shell …) or inline)
# Tries multiple interfaces: en0 (Wi-Fi), en1-en6, bridge*, then any non-loopback.
define resolve_api_host
$(shell \
	device="$(1)"; \
	if [ -z "$$device" ]; then \
		echo "localhost"; \
	elif echo "$$device" | grep -qiE "simulator|emulator|macos|linux|windows|chrome"; then \
		echo "localhost"; \
	else \
		ip=""; \
		for iface in en0 en1 en2 en3 en4 en5 en6 bridge0; do \
			candidate=$$(ipconfig getifaddr $$iface 2>/dev/null); \
			if [ -n "$$candidate" ] && echo "$$candidate" | grep -qvE "^169\.254\.|^127\."; then \
				ip="$$candidate"; break; \
			fi; \
		done; \
		if [ -z "$$ip" ]; then \
			ip=$$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | grep -v "169.254" | head -1 | awk '{print $$2}'); \
		fi; \
		if [ -n "$$ip" ]; then echo "$$ip"; else echo "localhost"; fi; \
	fi \
)
endef

# Auto-detect connected device when FLUTTER_DEVICE is empty
# flutter devices output: "iPhone de yanis (mobile) • <id> • ios • ..."
# The bullet is U+2022; we split on it and grab the device id (field 2).
define detect_device
$(shell \
	if [ -n "$(FLUTTER_DEVICE)" ]; then \
		echo "$(FLUTTER_DEVICE)"; \
	else \
		flutter devices 2>/dev/null | grep -iE "iPhone|iPad|Android" | head -1 | \
		sed 's/•/|/g' | awk -F'|' '{gsub(/^[ \t]+|[ \t]+$$/,"",$$2); print $$2}'; \
	fi \
)
endef

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
        test-e2e \
        coverage golden-test golden-update \
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
	@printf "  $(CYAN)make test$(RESET)            Run all tests (api + mobile + e2e)\n"
	@printf "  $(CYAN)make test-e2e$(RESET)        Run E2E integration tests\n"
	@printf "  $(CYAN)make coverage$(RESET)        Run Flutter tests with coverage (60%% threshold)\n"
	@printf "  $(CYAN)make golden-test$(RESET)     Verify golden tests haven't drifted\n"
	@printf "  $(CYAN)make golden-update$(RESET)   Regenerate golden reference files\n"
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
	@printf "       API          http://localhost:$(API_PORT)\n"
	@printf "       API Docs     http://localhost:$(API_PORT)/docs\n"
	@printf "       Admin Panel  http://localhost:8000\n\n"
	@$(MAKE) --no-print-directory _flutter-run

dev-docker: ## Start Docker services only (db, api, admin)
	@printf "$(CYAN)[info]$(RESET) Starting Docker services…\n"
	@$(COMPOSE) up -d --build
	@printf "\n$(GREEN)[ok]$(RESET)   Services ready:\n"
	@printf "       API          http://localhost:$(API_PORT)\n"
	@printf "       API Docs     http://localhost:$(API_PORT)/docs\n"
	@printf "       Admin Panel  http://localhost:8000\n\n"

dev-mobile: ## Start Flutter app only
	@$(MAKE) --no-print-directory _flutter-run

# Internal: detect device, resolve API host, inject --dart-define, run Flutter
_flutter-run:
	$(eval DEVICE := $(call detect_device))
	$(eval API_HOST := $(call resolve_api_host,$(DEVICE)))
	$(eval API_URL := http://$(API_HOST):$(API_PORT)/v1)
	$(eval DEVICE_FLAG := $(if $(DEVICE),-d $(DEVICE),))
	@printf "$(CYAN)[info]$(RESET) Target device: $(if $(DEVICE),$(DEVICE),auto)\n"
	@printf "$(CYAN)[info]$(RESET) API URL:       $(API_URL)\n"
	@if [ "$(API_HOST)" != "localhost" ]; then \
		printf "$(YELLOW)[warn]$(RESET) Physical device detected — using LAN IP $(API_HOST)\n"; \
		printf "       Make sure your Mac firewall allows port $(API_PORT)\n\n"; \
	fi
	@printf "$(CYAN)[info]$(RESET) Starting Flutter app (hot reload: r/R, quit: q)…\n\n"
	@cd $(FLUTTER_DIR) && flutter run $(DEVICE_FLAG) \
		--dart-define=API_BASE_URL=$(API_URL)

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

test: test-api test-mobile test-e2e ## Run all tests

test-api: ## Run API tests (pytest)
	@printf "$(CYAN)[info]$(RESET) Running API tests…\n"
	@$(COMPOSE) exec api uv run pytest
	$(call ok,"API tests passed")

test-mobile: ## Run Flutter tests
	@printf "$(CYAN)[info]$(RESET) Running Flutter tests…\n"
	@cd $(FLUTTER_DIR) && flutter test
	$(call ok,"Mobile tests passed")

test-e2e: ## Run E2E integration tests
	@printf "$(CYAN)[info]$(RESET) Running E2E integration tests…\n"
	@cd $(FLUTTER_DIR) && flutter test integration_test/
	$(call ok,"E2E tests passed")

test-e2e-%: ## Run single E2E test (e.g. make test-e2e-ft3_active_trip)
	@printf "$(CYAN)[info]$(RESET) Running E2E test: $*…\n"
	@cd $(FLUTTER_DIR) && flutter test integration_test/$*_test.dart
	$(call ok,"E2E test $* passed")

coverage: ## Run Flutter tests with coverage (60% threshold)
	@printf "$(CYAN)[info]$(RESET) Running Flutter tests with coverage…\n"
	@cd $(FLUTTER_DIR) && flutter test --coverage
	@printf "$(GREEN)[ok]$(RESET)   Coverage report: $(FLUTTER_DIR)/coverage/lcov.info\n"
	@if command -v lcov &>/dev/null; then \
		COVERAGE=$$(lcov --summary $(FLUTTER_DIR)/coverage/lcov.info 2>&1 | grep 'lines' | sed 's/.*: *\([0-9.]*\)%.*/\1/'); \
		printf "$(CYAN)[info]$(RESET) Line coverage: $${COVERAGE}%%\n"; \
		if [ "$$(echo "$$COVERAGE < 60" | bc -l)" -eq 1 ]; then \
			printf "$(RED)[err]$(RESET)  Coverage $${COVERAGE}%% below 60%% threshold\n"; \
			exit 1; \
		else \
			printf "$(GREEN)[ok]$(RESET)   Coverage meets 60%% threshold\n"; \
		fi; \
	else \
		printf "$(YELLOW)[warn]$(RESET) lcov not installed — skipping threshold check\n"; \
	fi

golden-test: ## Verify golden tests haven't drifted
	@printf "$(CYAN)[info]$(RESET) Running golden tests…\n"
	@cd $(FLUTTER_DIR) && flutter test --tags=golden
	$(call ok,"Golden tests passed")

golden-update: ## Regenerate golden reference files
	@printf "$(CYAN)[info]$(RESET) Regenerating golden files…\n"
	@cd $(FLUTTER_DIR) && flutter test --tags=golden --update-goldens
	$(call ok,"Goldens updated — review and commit the new .png files")

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
