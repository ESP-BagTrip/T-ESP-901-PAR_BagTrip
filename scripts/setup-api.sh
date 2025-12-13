#!/bin/bash
# Setup script for API (Python/FastAPI)

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

PROJECT_ROOT=$(get_project_root)
API_DIR="$PROJECT_ROOT/api"

info "Setting up API (Python/FastAPI)..."

# Check if uv is installed
if ! command_exists uv; then
    error "uv is not installed. Please run 'make install-uv' first."
    exit 1
fi

# Check if Python 3.14+ is available
PYTHON_VERSION=$(check_python_version 3 14 || echo "")
if [ -z "$PYTHON_VERSION" ]; then
    info "Python 3.14+ not found. Installing via uv..."
    cd "$API_DIR"

    # Install Python 3.14 using uv
    info "Installing Python 3.14..."
    uv python install 3.14 || {
        error "Failed to install Python 3.14 via uv"
        exit 1
    }

    # Pin Python version for this project
    info "Pinning Python 3.14 for this project..."
    uv python pin 3.14 || {
        warning "Failed to pin Python version, continuing anyway..."
    }

    success "Python 3.14 installed via uv"
else
    success "Python $PYTHON_VERSION found"
fi

# Install dependencies
cd "$API_DIR"
info "Installing API dependencies..."
uv sync --group dev || {
    error "Failed to install API dependencies"
    exit 1
}

success "API setup complete!"

