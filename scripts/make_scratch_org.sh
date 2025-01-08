#!/bin/bash

set -e

target_org="trailhead--scratch"

echo "Creating scratch org..."
sf org create scratch \
  --alias="${target_org}" \
  --definition-file=config/project-scratch-def.json \
  --duration-days=30 \
  --set-default

echo "Deploying metadata..."
sf project deploy start \
  --target-org="${target_org}" \
  --source-dir=force-app \
  --wait=10 \
  --ignore-conflicts \
  --verbose

echo "Running all tests..."
sf apex test run \
  --target-org="${target_org}" \
  --wait=10 \
  --code-coverage

echo "Opening scratch org..."
sf org open \
  --target-org="${target_org}" \
  --path=lightning

echo "Done"
