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

  if [[ ! -d "${root_dir}/${module_dir}" && ! -d "${root_dir}/force-app/${module_dir}" ]]; then
    echo "Error: Module directory '${root_dir}/force-app/${module_dir}' or '${root_dir}/${module_dir}' does not exist."
    exit 1
  fi
}

update_manifest() {
  local module_dir="$1"
  local module_path

  if [[ -d "${root_dir}/${module_dir}" ]]; then
    module_path="${root_dir}/${module_dir}"
  else
    module_path="${root_dir}/force-app/${module_dir}"
  fi

  sf project generate manifest \
    --source-dir="${module_path}" \
    --output-dir="${module_path}" \
    --type=package

  # Remove trailing slashes from <members> entries
  sed -i '' 's#\(<members>[^<]*\)/\(</members>\)#\1\2#g' "${module_path}/package.xml"
}

# Main script execution
root_dir=$(git rev-parse --show-toplevel)
validate_params "$1"
update_manifest "$1"
