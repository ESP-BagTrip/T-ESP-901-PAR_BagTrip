#!/bin/bash
# Setup script for API (Python/FastAPI)

set -e

CYAN='\033[36m'
RESET='\033[0m'

echo -e "${CYAN}Setting up API (Python/FastAPI)...${RESET}"

cd "$(dirname "$0")/../api" || exit 1

# Check if uv is installed
if ! command -v uv >/dev/null 2>&1; then
    echo -e "${CYAN}✗ uv is not installed. Please run 'make install-uv' first.${RESET}"
    exit 1
fi

# Install Python dependencies using uv
echo -e "${CYAN}Installing Python dependencies...${RESET}"
uv sync

echo -e "${CYAN}✓ API setup complete!${RESET}"

