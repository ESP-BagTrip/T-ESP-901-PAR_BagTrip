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

echo "Starting SonarCloud analysis..."

set -x # Add this line for debugging

sonar-scanner \
  -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
  -Dsonar.organization=${SONAR_ORGANIZATION} \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.token=${SONAR_TOKEN} \
  -Dsonar.sources=${SONAR_SOURCES} \
  -Dsonar.tests=${SONAR_TESTS} \
  -Dsonar.coverage.jacoco.xmlReportPaths=${SONAR_COVERAGE_REPORT_PATH} \
  -Dsonar.python.version=${SONAR_PYTHON_VERSION} \
  -Dsonar.flutter.analyzer.reportPaths=${SONAR_COVERAGE_REPORT_PATH} \
  -Dsonar.exclusions=api/tests/**,bagtrip/test/**,admin-panel/application/cypress/**
