#!/usr/bin/env bash

##
# Updates the manifest of a module.
#
# Usage:
#   update-manifest.sh <module-dir>
#

set -e

usage() {
  echo "Usage: update-manifest.sh <module-dir>"
  exit 1
}

validate_params() {
  local module_dir="$1"

  if [[ -z "${module_dir}" ]]; then
    echo "Error: First parameter 'module-dir' is required."
    usage
  fi

  if [[ ! -d "${root_dir}/force-app/${module_dir}" ]]; then
    echo "Error: Module directory '${root_dir}/force-app/${module_dir}' does not exist."
    exit 1
  fi
}

update_manifest() {
  local module_dir="$1"

  sf project generate manifest \
    --source-dir="${root_dir}/force-app/${module_dir}" \
    --output-dir="${root_dir}/force-app/${module_dir}" \
    --type=package

  npm run format
}

# Main script execution
root_dir=$(git rev-parse --show-toplevel)
validate_params "$1"
update_manifest "$1"
