# Global Makefile to manage all services

.PHONY: help install api-dev api-studio admin-dev mobile-dev dev

# Default target
.DEFAULT_GOAL := help

# Colors
CYAN := \033[36m
RESET := \033[0m

help: ## Show this help message
	@echo "$(CYAN)Available commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(CYAN)%-15s$(RESET) %s\n", $$1, $$2}'

install-uv: ## Install uv if not present
	@echo "$(CYAN)Checking for uv...$(RESET)"
	@command -v uv >/dev/null 2>&1 || (echo "$(CYAN)Installing uv...$(RESET)" && curl -LsSf https://astral.sh/uv/install.sh | sh)

install: install-uv ## Install dependencies for all services
	@echo "$(CYAN)Installing API dependencies...$(RESET)"
	@cd api && uv sync
	@echo "$(CYAN)Installing Admin Panel dependencies...$(RESET)"
	@cd admin-panel/application && npm install
	@echo "$(CYAN)Installing Mobile App dependencies...$(RESET)"
	@cd bagtrip && flutter pub get

api-dev: ## Start the Python API (FastAPI)
	@echo "$(CYAN)Starting API...$(RESET)"
	@cd api && uv run python -m src.main

api-studio: ## Start the AI Studio (LangGraph)
	@echo "$(CYAN)Starting AI Studio...$(RESET)"
	@cd api && langgraph dev

admin-dev: ## Start the Admin Panel (Next.js)
	@echo "$(CYAN)Starting Admin Panel...$(RESET)"
	@cd admin-panel/application && npm run dev

mobile-dev: ## Start the Mobile App (Flutter)
	@echo "$(CYAN)Starting Mobile App...$(RESET)"
	@cd bagtrip && flutter run

dev: help ## Alias for help
