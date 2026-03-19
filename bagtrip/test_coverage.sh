#!/bin/bash
# Script to run tests with coverage for SonarQube

set -e
set -x # Add this line for debugging

echo "Running Flutter tests with coverage..."

# Change to the bagtrip directory to ensure flutter test runs correctly
cd "$(dirname "$0")"

# Run tests with coverage
flutter test --coverage test/service

# The coverage data will be in coverage/lcov.info
# SonarQube can read this file directly

echo "Coverage report generated at: coverage/lcov.info"
echo "You can now import this into SonarQube"
