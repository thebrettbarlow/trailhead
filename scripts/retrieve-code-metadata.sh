#!/usr/bin/env bash

##
# Retrieves code-related metadata (e.g. classes, triggers, lwc, etc.).
#
# Usage:
#   retrieve-code-metadata.sh <target-org>
#

set -e

# Function to display usage information
usage() {
  echo "Usage: retrieve-manifest.sh <target-org>"
  exit 1
}

# Function to validate input parameters
validate_params() {
  local target_org="$1"

  if [[ -z "${target_org}" ]]; then
    echo "Error: First parameter 'target-org' is required."
    usage
  fi
}

# Main function to retrieve metadata
retrieve_metadata() {
  local target_org="$1"

  sf project retrieve start \
    --ignore-conflicts \
    --target-org="${target_org}" \
    --metadata=ApexClass \
    --metadata=ApexComponent \
    --metadata=ApexPage \
    --metadata=ApexTrigger \
    --metadata=AuraDefinitionBundle \
    --metadata=LightningComponentBundle \
    --metadata=StaticResource
}

# Main script execution
validate_params "$1"
retrieve_metadata "$1"
