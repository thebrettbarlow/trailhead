#!/usr/bin/env bash

##
# Retrieves metadata via a manifest for a module.
#
# Usage:
#   retrieve-manifest.sh <target-org> <module-dir>
#

set -e

# Function to display usage information
usage() {
  echo "Usage: retrieve-manifest.sh <target-org> <module-dir>"
  exit 1
}

# Function to validate input parameters
validate_params() {
  local target_org="$1"
  local module_dir="$2"

  if [[ -z "${target_org}" ]]; then
    echo "Error: First parameter 'target-org' is required."
    usage
  fi

  if [[ -z "${module_dir}" ]]; then
    echo "Error: Second parameter 'module-dir' is required."
    usage
  fi

  if [[ ! -d "${root_dir}/force-app/${module_dir}" ]]; then
    echo "Error: Module directory '${root_dir}/force-app/${module_dir}' does not exist."
    exit 1
  fi

  if [[ ! -f "${root_dir}/force-app/${module_dir}/package.xml" ]]; then
    echo "Error: package.xml file not found at '${root_dir}/force-app/${module_dir}/package.xml'."
    exit 1
  fi
}

# Main function to retrieve metadata
retrieve_metadata() {
  local target_org="$1"
  local module_dir="$2"

  sf project retrieve start \
    --ignore-conflicts \
    --target-org="${target_org}" \
    --manifest="${root_dir}/force-app/${module_dir}/package.xml"

  npm run format
}

# Main script execution
root_dir=$(git rev-parse --show-toplevel)
validate_params "$1" "$2"
retrieve_metadata "$1" "$2"
