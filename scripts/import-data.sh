#!/usr/bin/env bash

##
# Imports the data for a module.
#
# Usage:
#   import-data.sh <target-org> <module-dir>
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

find_plan_file() {
  local root_dir="$1"
  local module_dir="$2"
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
  local module_dir="$2"
  local root_dir
  local plan_file

  root_dir=$(git rev-parse --show-toplevel)
  plan_file=$(find_plan_file "$root_dir" "$module_dir")

  sf data import tree \
    --target-org="$target_org" \
    --plan="$plan_file"
}

# Main script execution
validate_params "$1" "$2"
import_data "$1" "$2"
