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
  echo "Warning: API container is not running. Coverage for API might be stale."
fi

echo "Running Admin Panel tests with coverage..."
if [ -d "admin-panel/application" ]; then
  cd admin-panel/application && npm run test:coverage && cd ../..
else
  echo "Warning: Admin Panel directory not found."
fi

echo "Starting SonarQube analysis..."

# On laisse SonarScanner lire les propriétés de sonar-project.properties par défaut.
# On ne passe que les overrides nécessaires.
SONAR_ARGS=""
if [ -n "${SONAR_TOKEN}" ]; then
  SONAR_ARGS="${SONAR_ARGS} -Dsonar.token=${SONAR_TOKEN}"
fi

# Si SONAR_PROJECT_KEY est définie dans .env, on l'utilise, sinon on laisse le fichier .properties
if [ -n "${SONAR_PROJECT_KEY}" ]; then
  SONAR_ARGS="${SONAR_ARGS} -Dsonar.projectKey=${SONAR_PROJECT_KEY}"
fi

# Idem pour l'organisation (utile pour SonarCloud)
if [ -n "${SONAR_ORGANIZATION}" ]; then
  SONAR_ARGS="${SONAR_ARGS} -Dsonar.organization=${SONAR_ORGANIZATION}"
fi

set -x
sonar-scanner ${SONAR_ARGS}
