#!/bin/bash
# Script to run tests with coverage for SonarQube

set -e
set -x # Add this line for debugging

COVERAGE_THRESHOLD=60

echo "Running Flutter tests with coverage..."

# Change to the bagtrip directory to ensure flutter test runs correctly
cd "$(dirname "$0")"

# Run tests with coverage
flutter test --coverage test/service

# The coverage data will be in coverage/lcov.info
# SonarQube can read this file directly

echo "Coverage report generated at: coverage/lcov.info"

# Check coverage threshold
if command -v lcov &> /dev/null; then
  COVERAGE=$(lcov --summary coverage/lcov.info 2>&1 | grep 'lines' | sed 's/.*: *\([0-9.]*\)%.*/\1/')
  echo "Line coverage: ${COVERAGE}%"
  if [ "$(echo "$COVERAGE < $COVERAGE_THRESHOLD" | bc -l)" -eq 1 ]; then
    echo "FAIL: Coverage ${COVERAGE}% is below threshold ${COVERAGE_THRESHOLD}%"
    exit 1
  else
    echo "PASS: Coverage ${COVERAGE}% meets threshold ${COVERAGE_THRESHOLD}%"
  fi
else
  echo "lcov not installed — skipping threshold check"
  echo "Install with: brew install lcov"
fi
