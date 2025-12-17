#!/bin/bash
# Common utility functions for setup scripts

# Colors
CYAN='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

# Print colored messages
info() {
    echo -e "${CYAN}$1${RESET}"
}

success() {
    echo -e "${GREEN}✓ $1${RESET}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}

error() {
    echo -e "${RED}✗ $1${RESET}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Get the directory where the script is located
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Get the project root directory
get_project_root() {
    local script_dir=$(get_script_dir)
    echo "$(cd "$script_dir/.." && pwd)"
}

# Exit with error message
exit_with_error() {
    error "$1"
    exit 1
}

# Check if a tool is installed, exit if not
require_tool() {
    if ! command_exists "$1"; then
        exit_with_error "$1 is not installed. Please install it first."
    fi
}

# Check Python version
check_python_version() {
    local required_major=$1
    local required_minor=$2

    if command_exists python3; then
        local version=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')" 2>/dev/null)
        if [ -z "$version" ]; then
            return 1
        fi

        local major=$(echo "$version" | cut -d. -f1)
        local minor=$(echo "$version" | cut -d. -f2)

        if [ "$major" -gt "$required_major" ] || ([ "$major" -eq "$required_major" ] && [ "$minor" -ge "$required_minor" ]); then
            echo "$version"
            return 0
        fi
    fi

    return 1
}

