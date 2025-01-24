#!/usr/bin/env bash

##
# Retrieves metadata via a manifest for a module.
#
# Usage:
#   retrieve-manifest.sh <target-org> <module-dir>
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

check_manifest_file() {
  local root_dir="$1"
  local module_dir="$2"
  local manifest_file="${root_dir}/force-app/${module_dir}/package.xml"

  if [[ ! -f "$manifest_file" ]]; then
    echo "Error: Manifest file not found at $manifest_file."
    exit 1
  fi
}

retrieve_metadata() {
  local target_org="$1"
  local module_dir="$2"
  local root_dir

  root_dir=$(git rev-parse --show-toplevel)

  check_manifest_file "$root_dir" "$module_dir"

  sf project retrieve start \
    --ignore-conflicts \
    --target-org="$target_org" \
    --manifest="${root_dir}/force-app/${module_dir}/package.xml"

  npm run format
}

# Main script execution
validate_params "$1" "$2"
retrieve_metadata "$1" "$2"
