.PHONY: help init install-pre-commit install-deps

# Default target
help:
	@echo "Available targets:"
	@echo "  init              - Complete project initialization (pre-commit + dependencies)"
	@echo "  install-pre-commit - Install pre-commit hooks only"
	@echo "  install-deps      - Install all project dependencies only"
	@echo ""
	@echo "Usage: make init"

# Main initialization target
init: install-pre-commit install-deps
	@echo "✅ Project initialization complete!"
	@echo "🚀 You can now start developing with pre-commit hooks active"

# Install pre-commit and git hooks
install-pre-commit:
	@echo "📦 Installing pre-commit..."
	@if ! command -v pre-commit &> /dev/null; then \
		echo "Installing pre-commit via pip..."; \
		python3 -m pip install pre-commit; \
	else \
		echo "pre-commit already installed"; \
	fi
	@echo "🔧 Installing git hooks..."
	@pre-commit install --install-hooks
	@echo "✅ Pre-commit hooks installed successfully"

# Install all project dependencies
install-deps:
	@echo "📦 Installing API dependencies..."
	@cd api && npm install
	@echo "📦 Installing Admin Panel dependencies..."
	@cd admin-panel && npm install
	@echo "✅ All dependencies installed successfully"

install-bloc-extension:
	@echo "🔧 Installing Bloc extension for VS Code..."
	code --install-extension felixangelov.bloc --force
	@echo "✅ Bloc extension installed successfully"
