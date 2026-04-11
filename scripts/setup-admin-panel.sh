#!/bin/bash
# Setup script for Admin Panel (Next.js)

set -e

CYAN='\033[36m'
RESET='\033[0m'

echo -e "${CYAN}Setting up Admin Panel (Next.js)...${RESET}"

cd "$(dirname "$0")/../admin-panel" || exit 1

# Check if Node.js and npm are installed
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    echo -e "${CYAN}✗ Node.js and/or npm not found${RESET}"
    echo -e "${CYAN}Please install Node.js from https://nodejs.org/${RESET}"
    exit 1
fi

# Install npm dependencies
echo -e "${CYAN}Installing npm dependencies...${RESET}"
npm install

echo -e "${CYAN}✓ Admin Panel setup complete!${RESET}"

