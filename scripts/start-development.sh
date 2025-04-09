#!/usr/bin/env bash

##
# Start Development
#
# Usage:
#   start-development.sh <target-org>

set -e

# Check if target-org parameter is provided
if [[ -z "${1}" ]]; then
  echo "Error: First parameter 'target-org' is required."
  exit 1
fi

# Check if lightning_app_name parameter is provided
if [[ -z "${2}" ]]; then
  # This is the name of the App in App Builder that local dev will connect to
  echo "Error: Second parameter 'lightning_app_name' is required."
  exit 1
fi

target_org="${1}"
lightning_app_name="${2}"

# Tail Apex debug logs
echo "Tailing Apex debug logs..."
sf apex tail log \
  --target-org="${target_org}" \
  --color &

# Start LWC local dev server
# https://developer.salesforce.com/docs/platform/lwc/guide/get-started-test-components.html#preview-a-lightning-app-generally-available
echo "Starting LWC local dev server..."
sf lightning dev app \
  --target-org="${target_org}" \
  --name="${lightning_app_name}" \
  --device-type=desktop &

# Start Prettier Apex parser server
# https://github.com/dangmai/prettier-plugin-apex?tab=readme-ov-file#-using-built-in-http-server
echo "Starting Prettier Apex parser server..."
npx start-apex-server &

# Wait for all processes to finish
wait
