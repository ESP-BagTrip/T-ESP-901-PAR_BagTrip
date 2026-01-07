# Global Makefile to manage all services

.PHONY: help init db api ai-studio admin mobile pre-commit start start-bg stop setup-optional-all build-images logs logs-api logs-db

# Default target
.DEFAULT_GOAL := help

# Colors
CYAN := \033[36m
RESET := \033[0m

help: ## Show this help message
	@echo "$(CYAN)Available commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2}'

install-uv: ## Install uv if not present (optional - for local development)
	@echo "$(CYAN)Checking for uv...$(RESET)"
	@command -v uv >/dev/null 2>&1 || (echo "$(CYAN)Installing uv...$(RESET)" && curl -LsSf https://astral.sh/uv/install.sh | sh)

setup-scripts: ## Make all setup scripts executable
	@echo "$(CYAN)Setting up script permissions...$(RESET)"
	@chmod +x scripts/*.sh 2>/dev/null || true
	@echo "$(CYAN)✓ Scripts are now executable$(RESET)"

setup-python: install-uv ## Auto-install Python 3.14+ using uv if needed
	@echo "$(CYAN)Setting up Python 3.14+ (automatic installation via uv)...$(RESET)"
	@$(MAKE) setup-api

setup-api: install-uv ## Set up API locally (optional - Docker is recommended)
	@bash scripts/setup-api.sh

check-node: ## Check if Node.js and npm are installed
	@echo "$(CYAN)Checking for Node.js and npm...$(RESET)"
	@if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then \
		NODE_VERSION=$$(node --version); \
		NPM_VERSION=$$(npm --version); \
		echo "$(CYAN)✓ Node.js $$NODE_VERSION and npm $$NPM_VERSION found$(RESET)"; \
	else \
		echo "$(CYAN)✗ Node.js and/or npm not found$(RESET)"; \
		echo "$(CYAN)Please install Node.js from https://nodejs.org/$(RESET)"; \
		exit 1; \
	fi

check-flutter: ## Check if Flutter SDK is installed
	@echo "$(CYAN)Checking for Flutter SDK...$(RESET)"
	@if command -v flutter >/dev/null 2>&1; then \
		FLUTTER_VERSION=$$(flutter --version | head -n 1 | awk '{print $$2}'); \
		echo "$(CYAN)✓ Flutter $$FLUTTER_VERSION found$(RESET)"; \
	else \
		echo "$(CYAN)✗ Flutter SDK not found$(RESET)"; \
		echo "$(CYAN)Please install Flutter from https://flutter.dev/docs/get-started/install$(RESET)"; \
		exit 1; \
	fi

check-docker: ## Check if Docker and Docker Compose are installed
	@echo "$(CYAN)Checking for Docker and Docker Compose...$(RESET)"
	@if command -v docker >/dev/null 2>&1 && command -v docker compose >/dev/null 2>&1; then \
		DOCKER_VERSION=$$(docker --version | awk '{print $$3}' | cut -d, -f1); \
		COMPOSE_VERSION=$$(docker compose version --short 2>/dev/null || echo "unknown"); \
		echo "$(CYAN)✓ Docker $$DOCKER_VERSION and Docker Compose $$COMPOSE_VERSION found$(RESET)"; \
	else \
		echo "$(CYAN)✗ Docker and/or Docker Compose not found$(RESET)"; \
		echo "$(CYAN)Please install Docker from https://docs.docker.com/get-docker/$(RESET)"; \
		exit 1; \
	fi

setup-admin: check-node ## Set up Admin Panel (Next.js)
	@bash scripts/setup-admin-panel.sh

setup-bagtrip: check-flutter ## Set up Bagtrip (Flutter)
	@bash scripts/setup-bagtrip.sh

setup-pre-commit: ## Install pre-commit tool and set up git hooks
	@bash scripts/setup-pre-commit.sh

pre-commit: ## Run pre-commit hooks on all files
	@echo "$(CYAN)Running pre-commit hooks...$(RESET)"
	@pre-commit run --all-files

setup-linters: ## Set up all linters and formatters
	@bash scripts/setup-linters.sh

setup-env: ## Copy .env.example to .env if it doesn't exist
	@echo "$(CYAN)Setting up environment file...$(RESET)"
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			cp .env.example .env; \
			echo "$(CYAN)✓ Created .env from .env.example$(RESET)"; \
			echo "$(CYAN)⚠ Please review and update .env with your configuration$(RESET)"; \
		else \
			echo "$(CYAN)⚠ .env.example not found, skipping environment setup$(RESET)"; \
		fi; \
	else \
		echo "$(CYAN)✓ .env file already exists$(RESET)"; \
	fi

build-images: ## Build Docker images for backend services
	@echo "$(CYAN)Building Docker images...$(RESET)"
	@docker compose build db api
	@echo "$(CYAN)✓ Docker images built successfully$(RESET)"

# Optional setup targets (not included in default init)
setup-optional-all: setup-admin setup-bagtrip ## Set up all optional components (Admin Panel + Mobile App)
	@echo ""
	@echo "$(CYAN)✓ All optional components set up!$(RESET)"

kill-postgres: ## Kill all PostgreSQL instances outside Docker (with validation prompt)
	@echo "$(CYAN)Checking for PostgreSQL processes outside Docker...$(RESET)"
	@if command -v pgrep >/dev/null 2>&1 && command -v ps >/dev/null 2>&1; then \
		ALL_PG_PIDS=$$(pgrep -f postgres 2>/dev/null || true); \
		if [ -z "$$ALL_PG_PIDS" ]; then \
			echo "$(CYAN)✓ No PostgreSQL processes found$(RESET)"; \
		else \
			PG_PIDS_OUTSIDE_DOCKER=""; \
			for pid in $$ALL_PG_PIDS; do \
				PROC_CMD=$$(ps -p $$pid -o command= 2>/dev/null || true); \
				if [ -n "$$PROC_CMD" ] && ! echo "$$PROC_CMD" | grep -q docker; then \
					PG_PIDS_OUTSIDE_DOCKER="$$PG_PIDS_OUTSIDE_DOCKER $$pid"; \
				fi; \
			done; \
			PG_PIDS_OUTSIDE_DOCKER=$$(echo $$PG_PIDS_OUTSIDE_DOCKER | xargs); \
			if [ -n "$$PG_PIDS_OUTSIDE_DOCKER" ]; then \
				echo "$(CYAN)The following PostgreSQL processes were found (outside Docker):$(RESET)"; \
				ps -p $$PG_PIDS_OUTSIDE_DOCKER -o pid,user,command 2>/dev/null || true; \
				echo ""; \
				echo -n "$(CYAN)Do you want to kill these processes? [y/N] $(RESET)"; \
				read -r response; \
				if [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
					echo "$(CYAN)Killing PostgreSQL processes...$(RESET)"; \
					for pid in $$PG_PIDS_OUTSIDE_DOCKER; do \
						kill -9 $$pid 2>/dev/null || true; \
					done; \
					echo "$(CYAN)✓ PostgreSQL processes killed$(RESET)"; \
				else \
					echo "$(CYAN)⚠ Skipping PostgreSQL process termination$(RESET)"; \
				fi; \
			else \
				echo "$(CYAN)✓ No PostgreSQL processes found outside Docker$(RESET)"; \
			fi; \
		fi; \
	else \
		echo "$(CYAN)⚠ pgrep or ps not available, skipping PostgreSQL process check$(RESET)"; \
	fi

db: kill-postgres ## Kill PostgreSQL instances outside Docker, then start database container
	@echo "$(CYAN)Checking Docker daemon...$(RESET)"
	@docker ps >/dev/null 2>&1 || (echo "$(CYAN)✗ Docker daemon is not running$(RESET)" && echo "$(CYAN)Please start Docker Desktop or Docker daemon and try again$(RESET)" && exit 1)
	@echo "$(CYAN)Starting PostgreSQL database container...$(RESET)"
	@docker compose up -d db || (echo "$(CYAN)✗ Failed to start database container$(RESET)" && echo "$(CYAN)Make sure Docker is running and try again$(RESET)" && exit 1)
	@echo "$(CYAN)✓ Database container started$(RESET)"
	@echo "$(CYAN)Waiting for database to be ready...$(RESET)"
	@sleep 3
	@echo "$(CYAN)✓ Database is ready$(RESET)"

start: ## Start the complete backend stack in Docker (database + API)
	@echo "$(CYAN)Starting backend stack with Docker Compose...$(RESET)"
	@docker compose up db api
	@echo "$(CYAN)Backend stack stopped$(RESET)"

start-bg: ## Start the complete backend stack in background (database + API)
	@echo "$(CYAN)Starting backend stack in background...$(RESET)"
	@docker compose up -d db api
	@echo "$(CYAN)✓ Database and API started in background$(RESET)"
	@echo "$(CYAN)View API logs: docker compose logs -f api$(RESET)"
	@echo "$(CYAN)Stop services: docker compose down$(RESET)"

stop: ## Stop all running Docker services
	@echo "$(CYAN)Stopping all services...$(RESET)"
	@docker compose down
	@echo "$(CYAN)✓ All services stopped$(RESET)"

logs: ## Show logs from running Docker containers
	@docker compose logs -f

logs-api: ## Show logs from API container only
	@docker compose logs -f api

logs-db: ## Show logs from database container only
	@docker compose logs -f db

verify-install: ## Verify all tools are properly installed and display status
	@echo "$(CYAN)Verifying installation...$(RESET)"
	@echo ""
	@echo "$(CYAN)Required Tools:$(RESET)"
	@echo -n "  Docker: "; command -v docker >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)✗$(RESET)"
	@echo -n "  Docker Compose: "; command -v docker compose >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)✗$(RESET)"
	@echo -n "  Docker daemon: "; docker ps >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)✗ (not running)$(RESET)"
	@echo -n "  pre-commit: "; command -v pre-commit >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)✗$(RESET)"
	@echo ""
	@echo "$(CYAN)Optional Tools (for local dev):$(RESET)"
	@echo -n "  uv: "; command -v uv >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not installed$(RESET)"
	@echo -n "  Python 3.14+: "; python3 -c "import sys; exit(0 if sys.version_info >= (3, 14) else 1)" 2>/dev/null && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not installed$(RESET)"
	@echo -n "  Node.js: "; command -v node >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not installed$(RESET)"
	@echo -n "  npm: "; command -v npm >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not installed$(RESET)"
	@echo -n "  Flutter: "; command -v flutter >/dev/null 2>&1 && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not installed$(RESET)"
	@echo ""
	@echo "$(CYAN)Docker Images:$(RESET)"
	@echo -n "  BagTrip API image: "; docker images | grep -q bagtrip-api && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not built$(RESET)"
	@echo ""
	@echo "$(CYAN)Configuration:$(RESET)"
	@echo -n "  .env file: "; [ -f .env ] && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)✗$(RESET)"
	@echo ""
	@echo "$(CYAN)Running Containers:$(RESET)"
	@echo -n "  Database container: "; docker ps --format '{{.Names}}' | grep -q BagTrip-db && echo "$(CYAN)✓ running$(RESET)" || echo "$(CYAN)○ not running$(RESET)"
	@echo -n "  API container: "; docker ps --format '{{.Names}}' | grep -q BagTrip-api && echo "$(CYAN)✓ running$(RESET)" || echo "$(CYAN)○ not running$(RESET)"
	@echo ""
	@echo "$(CYAN)Optional Dependencies:$(RESET)"
	@echo -n "  Admin Panel (local): "; [ -d admin-panel/application/node_modules ] && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not installed$(RESET)"
	@echo -n "  Mobile App (local): "; [ -d bagtrip/.dart_tool ] && echo "$(CYAN)✓$(RESET)" || echo "$(CYAN)○ not installed$(RESET)"
	@echo ""

init: check-docker setup-env build-images setup-pre-commit setup-linters ## Build Docker images and set up development environment
	@echo ""
	@echo "$(CYAN)✓ Docker images built successfully!$(RESET)"
	@echo "$(CYAN)Next steps:$(RESET)"
	@echo "$(CYAN)  1. Configure .env with your API keys$(RESET)"
	@echo "$(CYAN)  2. Run 'make start' to launch the backend in Docker$(RESET)"
	@echo "$(CYAN)  3. API will be available at http://localhost:3000$(RESET)"
	@echo ""
	@echo "$(CYAN)Optional:$(RESET)"
	@echo "$(CYAN)  - Run 'make setup-admin' for Admin Panel (local)$(RESET)"
	@echo "$(CYAN)  - Run 'make setup-bagtrip' for Mobile App (local)$(RESET)"
	@echo "$(CYAN)  - Run 'make install-uv && make setup-api' for local API development$(RESET)"

api: ## Start only the API in Docker (foreground)
	@echo "$(CYAN)Starting API container...$(RESET)"
	@docker compose up api

api-studio: ## Start the AI Studio (LangGraph)
	@echo "$(CYAN)Starting AI Studio...$(RESET)"
	@cd api && langgraph dev

admin: admin-dev ## Alias for admin-dev
admin-dev: ## Start the Admin Panel (Next.js)
	@echo "$(CYAN)Starting Admin Panel...$(RESET)"
	@cd admin-panel/application && npm run dev

mobile: mobile-dev ## Alias for mobile-dev
mobile-dev: ## Start the Mobile App (Flutter)
	@echo "$(CYAN)Starting Mobile App...$(RESET)"
	@cd bagtrip && flutter run

dev: help ## Alias for help
