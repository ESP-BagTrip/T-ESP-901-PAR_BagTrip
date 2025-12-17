#!/bin/bash
# Setup script for Bagtrip (Flutter)

set -e

# Load utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

PROJECT_ROOT=$(get_project_root)
BAGTRIP_DIR="$PROJECT_ROOT/bagtrip"

info "Setting up Bagtrip (Flutter)..."

# Check Flutter
if ! command_exists flutter; then
    exit_with_error "Flutter SDK is not installed. Please install Flutter from https://flutter.dev/docs/get-started/install"
fi

FLUTTER_VERSION=$(flutter --version | head -n 1 | awk '{print $2}')
success "Flutter $FLUTTER_VERSION found"

# Install dependencies
cd "$BAGTRIP_DIR"
info "Installing Flutter dependencies..."
flutter pub get || {
    error "Failed to install Flutter dependencies"
    exit 1
}

# Check if build_runner is needed (for code generation)
if grep -q "build_runner" "$BAGTRIP_DIR/pubspec.yaml"; then
    info "Running build_runner for code generation..."
    flutter pub run build_runner build --delete-conflicting-outputs || {
        warning "build_runner failed, but continuing..."
    }
fi

success "Bagtrip setup complete!"

