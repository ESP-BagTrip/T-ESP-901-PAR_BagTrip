#!/bin/bash
# Setup script for linters and formatters

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

PROJECT_ROOT=$(get_project_root)
API_DIR="$PROJECT_ROOT/api"
ADMIN_DIR="$PROJECT_ROOT/admin-panel/application"
BAGTRIP_DIR="$PROJECT_ROOT/bagtrip"

info "Setting up linters and formatters..."

# Python linter (ruff)
info "Checking Python linter (ruff)..."
if command_exists uv; then
    cd "$API_DIR"
    # Check if ruff is installed via uv
    if uv run ruff --version >/dev/null 2>&1; then
        RUFF_VERSION=$(uv run ruff --version | awk '{print $2}')
        success "ruff $RUFF_VERSION found (via uv)"
    else
        warning "ruff not found in API dependencies, but it should be installed with 'uv sync --group dev'"
    fi
else
    warning "uv not found, skipping ruff check"
fi

# Node.js linters (ESLint, Prettier)
info "Checking Node.js linters..."
if [ -d "$ADMIN_DIR/node_modules" ]; then
    cd "$ADMIN_DIR"
    if [ -f "node_modules/.bin/eslint" ]; then
        ESLINT_VERSION=$(npm list eslint --depth=0 2>/dev/null | grep eslint | awk '{print $2}' | tr -d '@' || echo "installed")
        success "ESLint found"
    else
        warning "ESLint not found in node_modules"
    fi

    if [ -f "node_modules/.bin/prettier" ]; then
        PRETTIER_VERSION=$(npm list prettier --depth=0 2>/dev/null | grep prettier | awk '{print $2}' | tr -d '@' || echo "installed")
        success "Prettier found"
    else
        warning "Prettier not found in node_modules"
    fi
else
    warning "Admin Panel node_modules not found, run 'make setup-admin' first"
fi

# Flutter linter
info "Checking Flutter linter..."
if command_exists flutter; then
    cd "$BAGTRIP_DIR"
    if [ -f "analysis_options.yaml" ]; then
        success "Flutter linter configuration found"

        # Run flutter analyze to verify
        info "Running flutter analyze to verify setup..."
        flutter analyze --no-fatal-infos >/dev/null 2>&1 || {
            warning "Flutter analyze found some issues (non-fatal)"
        }
    else
        warning "analysis_options.yaml not found"
    fi
else
    warning "Flutter not found, skipping Flutter linter check"
fi

success "Linters setup complete!"

