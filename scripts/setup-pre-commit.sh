#!/bin/bash
# Setup script for pre-commit hooks

set -e

CYAN='\033[36m'
RESET='\033[0m'

echo -e "${CYAN}Setting up pre-commit hooks...${RESET}"

# Check if pre-commit is installed
if ! command -v pre-commit >/dev/null 2>&1; then
    echo -e "${CYAN}Installing pre-commit...${RESET}"
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install pre-commit
    elif command -v pip >/dev/null 2>&1; then
        pip install pre-commit
    else
        echo -e "${CYAN}✗ pip or pip3 not found. Please install Python and pip first.${RESET}"
        exit 1
    fi
fi

cd "$(dirname "$0")/.." || exit 1

# Install pre-commit hooks
echo -e "${CYAN}Installing pre-commit hooks...${RESET}"
pre-commit install

echo -e "${CYAN}✓ Pre-commit setup complete!${RESET}"

