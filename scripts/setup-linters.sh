#!/bin/bash
# Setup script for linters and formatters

set -e

CYAN='\033[36m'
RESET='\033[0m'

echo -e "${CYAN}Setting up linters and formatters...${RESET}"

# The linters are already configured in:
# - API: ruff (installed via uv in setup-api.sh)
# - Admin Panel: ESLint and Prettier (installed via npm in setup-admin-panel.sh)
# - Mobile: flutter_lints (installed via flutter pub get in setup-bagtrip.sh)

echo -e "${CYAN}Linters and formatters are configured:${RESET}"
echo -e "${CYAN}  - API: ruff (Python)${RESET}"
echo -e "${CYAN}  - Admin Panel: ESLint & Prettier (TypeScript/JavaScript)${RESET}"
echo -e "${CYAN}  - Mobile: flutter_lints (Dart)${RESET}"

echo -e "${CYAN}✓ Linters setup complete!${RESET}"

