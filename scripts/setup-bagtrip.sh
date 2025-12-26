#!/bin/bash
# Setup script for Bagtrip (Flutter)

set -e

CYAN='\033[36m'
RESET='\033[0m'

echo -e "${CYAN}Setting up Bagtrip (Flutter)...${RESET}"

cd "$(dirname "$0")/../bagtrip" || exit 1

# Check if Flutter is installed
if ! command -v flutter >/dev/null 2>&1; then
    echo -e "${CYAN}✗ Flutter SDK not found${RESET}"
    echo -e "${CYAN}Please install Flutter from https://flutter.dev/docs/get-started/install${RESET}"
    exit 1
fi

# Install Flutter dependencies
echo -e "${CYAN}Installing Flutter dependencies...${RESET}"
flutter pub get

echo -e "${CYAN}✓ Bagtrip setup complete!${RESET}"

