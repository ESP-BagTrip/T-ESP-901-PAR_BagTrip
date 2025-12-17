#!/bin/bash
# Setup script for pre-commit hooks

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

PROJECT_ROOT=$(get_project_root)

info "Setting up pre-commit..."

# Check if pre-commit is already installed
if command_exists pre-commit; then
    PRE_COMMIT_VERSION=$(pre-commit --version | awk '{print $2}')
    success "pre-commit $PRE_COMMIT_VERSION already installed"
else
    info "Installing pre-commit..."

    # Try different installation methods
    if command_exists pipx; then
        info "Installing pre-commit via pipx..."
        pipx install pre-commit || {
            error "Failed to install pre-commit via pipx"
            exit 1
        }
    elif command_exists pip3; then
        info "Installing pre-commit via pip3..."
        pip3 install pre-commit || {
            error "Failed to install pre-commit via pip3"
            exit 1
        }
    elif command_exists brew; then
        info "Installing pre-commit via Homebrew..."
        brew install pre-commit || {
            error "Failed to install pre-commit via Homebrew"
            exit 1
        }
    else
        exit_with_error "Could not install pre-commit. Please install manually:\n  pipx install pre-commit  (recommended)\n  pip3 install pre-commit\n  brew install pre-commit  (macOS)"
    fi

    success "pre-commit installed"
fi

# Install git hooks
cd "$PROJECT_ROOT"
info "Installing pre-commit git hooks..."
pre-commit install --install-hooks || {
    warning "Failed to install pre-commit hooks. Continuing..."
}

success "pre-commit setup complete!"

