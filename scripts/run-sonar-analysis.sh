#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
  export $(cat .env | xargs)
else
  echo "Error: .env file not found. Please create one based on .env.example"
  exit 1
fi

# Ensure SonarScanner CLI is installed
if ! command -v sonar-scanner &> /dev/null
then
    echo "sonar-scanner could not be found. Please install it."
    echo "Refer to https://docs.sonarcloud.io/getting-started/sonarscanner-cli/"
    exit 1
fi

echo "Running Flutter tests with coverage..."
./bagtrip/test_coverage.sh

echo "Running API tests with coverage..."
# Use docker compose if it's running
if docker compose ps | grep -q "BagTrip-api"; then
  docker compose exec -T api uv run pytest --cov=src --cov-report=xml
  # Fix paths in coverage.xml for SonarScanner (must be relative to root)
  # 1. Set source root to '.'
  sed -i 's|<source>src</source>|<source>.</source>|g' api/coverage.xml
  # 2. Add 'api/src/' prefix to all filenames (if not already there)
  sed -i 's|filename="api/src/|filename="|g' api/coverage.xml
  sed -i 's|filename="|filename="api/src/|g' api/coverage.xml
else
  echo "Error: API container is not running. Please start it with 'make dev-docker' or 'make dev'."
  exit 1
fi

echo "Starting SonarCloud analysis..."

set -x # Add this line for debugging

sonar-scanner \
  -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
  -Dsonar.organization=${SONAR_ORGANIZATION} \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.token=${SONAR_TOKEN} \
  -Dsonar.sources=. \
  -Dsonar.tests=. \
  -Dsonar.python.coverage.reportPaths=api/coverage.xml \
  -Dsonar.dart.lcov.reportPaths=bagtrip/coverage/lcov.info \
  -Dsonar.javascript.lcov.reportPaths=admin-panel/application/coverage/lcov.info \
  -Dsonar.python.version=${SONAR_PYTHON_VERSION:-3.12} \
  -Dsonar.exclusions=api/tests/**,bagtrip/test/**,admin-panel/application/cypress/**,**/node_modules/**,**/build/**,**/.next/**
