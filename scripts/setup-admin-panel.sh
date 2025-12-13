#!/bin/bash
# Setup script for Admin Panel (Next.js)

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

PROJECT_ROOT=$(get_project_root)
ADMIN_DIR="$PROJECT_ROOT/admin-panel/application"

info "Setting up Admin Panel (Next.js)..."

# Check Node.js and npm
if ! command_exists node; then
    exit_with_error "Node.js is not installed. Please install Node.js from https://nodejs.org/"
fi

if ! command_exists npm; then
    exit_with_error "npm is not installed. Please install npm (usually comes with Node.js)"
fi

NODE_VERSION=$(node --version)
NPM_VERSION=$(npm --version)
success "Node.js $NODE_VERSION and npm $NPM_VERSION found"

# Install dependencies
cd "$ADMIN_DIR"
info "Installing Admin Panel dependencies..."
npm install || {
    error "Failed to install Admin Panel dependencies"
    exit 1
}

success "Admin Panel setup complete!"

