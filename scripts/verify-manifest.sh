#!/usr/bin/env bash

##
# Verifies the manifest for a module can be deployed.
#
# Usage:
#   verify-manifest.sh <target-org> <module-dir>
#

set -e

validate_params() {
  if [[ -z "$1" ]]; then
    echo "First parameter target-org is required"
    exit 1
  fi

  if [[ -z "$2" ]]; then
    echo "Second parameter module-dir is required"
    exit 1
  fi
}

verify_manifest() {
  local target_org="$1"
  local module_dir="$2"
  local root_dir

  root_dir=$(git rev-parse --show-toplevel)

  if [[ ! -f "${root_dir}/force-app/${module_dir}/package.xml" ]]; then
    echo "Error: Manifest file not found at ${root_dir}/force-app/${module_dir}/package.xml."
    exit 1
  fi

  sf project deploy start \
    --ignore-conflicts \
    --target-org="${target_org}" \
    --manifest="${root_dir}/force-app/${module_dir}/package.xml" \
    --dry-run
}

# Main script execution
validate_params "$1" "$2"
verify_manifest "$1" "$2"
