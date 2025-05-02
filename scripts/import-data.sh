#!/usr/bin/env bash

##
# Imports the data for a module.
#
# Usage:
#   import-data.sh <target-org> <module-dir>
#

set -e

usage() {
  echo "Usage: $0 <target-org> <module-dir>"
  exit 1
}

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

check_valid_node_script() {
  local script_path="$1"
  if ! node -c "$script_path" &> /dev/null; then
    echo "Error: $script_path is not a valid Node script"
    exit 1
  fi
}

find_plan_file() {
  local module_dir="$1"
  local plan_file

  plan_file=$(find "${root_dir}/data/${module_dir}" -name "*-plan.json" -print -quit)
  if [[ -z "$plan_file" ]]; then
    echo "Error: Plan file not found in ${root_dir}/data/${module_dir}."
    exit 1
  fi

  echo "$plan_file"
}

import_data() {
  local target_org="$1"
  local plan_file="$2"

  sf data import tree \
    --target-org="$target_org" \
    --plan="$plan_file"
}

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
if [[ "$#" -ne 2 ]]; then
  usage
fi

target_org="$1"
module_dir="$2"

root_dir=$(git rev-parse --show-toplevel)
validate_params "$target_org" "$module_dir"

# Create a temporary directory for output
temp_dir=$(mktemp -d)
output_file="${temp_dir}/modified_files.txt"

trap cleanup EXIT

# Prepare for import
prepare_tree_import_script="${root_dir}/scripts/prepare-tree-import.mjs"

check_valid_node_script "${prepare_tree_import_script}"

node "${prepare_tree_import_script}" "$target_org" "$module_dir" "$output_file"
plan_file=$(find_plan_file "$module_dir")
import_data "$target_org" "$plan_file"
