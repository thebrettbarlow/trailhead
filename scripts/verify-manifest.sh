#!/usr/bin/env bash

##
# Verifies the manifest for a module can be deployed.
#
# Usage:
#   verify-manifest.sh <env> <target-org> <module-dir>
#

set -e

# Function to print usage
usage() {
  echo "Usage: $0 <env> <target-org> <module-dir>"
  exit 1
}

# Validate input parameters
validate_params() {
  if [[ -z "$1" ]]; then
    echo "First parameter env is required"
    exit 1
  fi

  if [[ -z "$2" ]]; then
    echo "Second parameter target-org is required"
    exit 1
  fi

  if [[ -z "$3" ]]; then
    echo "Third parameter module-dir is required"
    exit 1
  fi

  if [[ ! -d "${root_dir}/force-app/$3" && ! -d "${root_dir}/$3" ]]; then
    echo "Error: Module directory '${root_dir}/force-app/$3' or '${root_dir}/$3' does not exist."
    exit 1
  fi
}

check_executable() {
  local script_path="$1"
  if [[ ! -x "$script_path" ]]; then
    echo "Error: $script_path is not executable"
    exit 1
  fi
}

# Verify the manifest
verify_manifest() {
  local target_org="$1"
  local module_dir="$2"
  local manifest_path

  if [[ -f "${root_dir}/${module_dir}/package.xml" ]]; then
    manifest_path="${root_dir}/${module_dir}/package.xml"
  elif [[ -f "${root_dir}/force-app/${module_dir}/package.xml" ]]; then
    manifest_path="${root_dir}/force-app/${module_dir}/package.xml"
  else
    echo "Error: Manifest file not found at '${root_dir}/force-app/${module_dir}/package.xml' or '${root_dir}/${module_dir}/package.xml'."
    exit 1
  fi

  sf project deploy start \
    --ignore-conflicts \
    --target-org="${target_org}" \
    --manifest="${manifest_path}" \
    --concise \
    --dry-run
}

# Function to clean up temporary files and revert changes
cleanup() {
  echo "Reverting changes..."
  if [[ -f "${output_file}" ]]; then
    while read -r file; do
      if [[ -f "${file}.bak" ]]; then
        mv "${file}.bak" "${file}"
      fi
    done < "${output_file}"
  fi
  echo "Deleting temporary directory..."
  rm -rf "${temp_dir}"
  echo "Cleanup complete."
}

# Main script execution
if [[ "$#" -ne 3 ]]; then
  usage
fi

env=$1
target_org=$2
module_dir=$3

root_dir=$(git rev-parse --show-toplevel)
validate_params "$env" "$target_org" "$module_dir"

# Create a temporary directory for output
temp_dir=$(mktemp -d)
output_file="${temp_dir}/modified_files.txt"

trap cleanup EXIT

# Replace placeholders
replace_placeholders_script="${root_dir}/scripts/replace-placeholders.sh"

check_executable "${replace_placeholders_script}"

"${replace_placeholders_script}" "$env" "$module_dir" "$output_file"
verify_manifest "$target_org" "$module_dir"
