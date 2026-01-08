#!/bin/bash
# Script to run tests with coverage for SonarQube

set -e

echo "Running Flutter tests with coverage..."

# Run tests with coverage
flutter test --coverage

# The coverage data will be in coverage/lcov.info
# SonarQube can read this file directly

echo "Coverage report generated at: coverage/lcov.info"
echo "You can now import this into SonarQube"
