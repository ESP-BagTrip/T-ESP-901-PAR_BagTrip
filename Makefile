# Docker-centric Makefile for BagTrip
# No external dependencies required except Docker & Docker Compose

.PHONY: help init start stop logs clean shell-api shell-admin setup-env build

# Default target
.DEFAULT_GOAL := help

# Colors
CYAN := [36m
RESET := [0m

help: ## Show this help message
	@echo "$(CYAN)BagTrip Docker Stack$(RESET)"
	@echo "$(CYAN)Available commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2}'

setup-env: ## Setup .env file from .env.example
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(CYAN)✓ Created .env from .env.example$(RESET)"; \
	else \
		echo "$(CYAN)✓ .env already exists$(RESET)"; \
	fi

build: setup-env ## Build Docker images
	@echo "$(CYAN)Building Docker images...$(RESET)"
	@docker compose build

init: build ## Initialize the project (build images)
	@echo "$(CYAN)✓ Project initialized. Run 'make start' to launch.$(RESET)"

start: ## Start all services in background
	@echo "$(CYAN)Starting services...$(RESET)"
	@docker compose up -d
	@echo "$(CYAN)✓ Services started$(RESET)"
	@echo "$(CYAN)  API: http://localhost:3000$(RESET)"
	@echo "$(CYAN)  Admin Panel: http://localhost:8000$(RESET)"
	@echo "$(CYAN)  Mobile Web: http://localhost:5000$(RESET)"

stop: ## Stop all services
	@echo "$(CYAN)Stopping services...$(RESET)"
	@docker compose down
	@echo "$(CYAN)✓ Services stopped$(RESET)"

logs: ## Follow logs of all services
	@docker compose logs -f

clean: stop ## Stop services and remove volumes (reset data)
	@echo "$(CYAN)Cleaning up...$(RESET)"
	@docker compose down -v
	@echo "$(CYAN)✓ Clean complete$(RESET)"

shell-api: ## Open a shell in the API container
	@docker compose exec api /bin/bash

shell-admin: ## Open a shell in the Admin Panel container
	@docker compose exec admin-panel /bin/sh

lint: ## Run linters (inside containers)
	@echo "$(CYAN)Running API linters...$(RESET)"
	@docker compose run --rm --no-deps api uv run ruff check .
	@echo "$(CYAN)Running Admin linters...$(RESET)"
	@docker compose run --rm --no-deps admin-panel npm run lint
	@echo "$(CYAN)Running Mobile linters...$(RESET)"
	@docker compose run --rm --no-deps mobile-web flutter analyze