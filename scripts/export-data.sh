#!/usr/bin/env bash

##
# Exports the data for a module.
#
# Usage:
#   export-data.sh <target-org> <module-dir>
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

check_soql_file() {
  local root_dir="$1"
  local module_dir="$2"
  local soql_file="${root_dir}/data/${module_dir}/query.soql"

  if [[ ! -f "$soql_file" ]]; then
    echo "Error: SOQL file not found at $soql_file."
    exit 1
  fi
}

export_data() {
  local target_org="$1"
  local module_dir="$2"
  local root_dir

  root_dir=$(git rev-parse --show-toplevel)

  check_soql_file "$root_dir" "$module_dir"

  sf data export tree \
    --target-org="${target_org}" \
    --plan \
    --query="${root_dir}/data/${module_dir}/query.soql" \
    --output-dir="${root_dir}/data/${module_dir}"

  npm run format
}

# Main script execution
validate_params "$1" "$2"
export_data "$1" "$2"
