#!/usr/bin/env bash

##
# Exports the data for a module.
#
# Usage:
#   export-data.sh <target-org> <module-dir>
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

find_soql_file() {
  local module_dir="$1"
  local soql_file

  soql_file=$(find "${root_dir}/data/${module_dir}" -name "*.soql" -print -quit)
  if [[ -z "$soql_file" ]]; then
    echo "Error: SOQL file not found in ${root_dir}/data/${module_dir}."
    exit 1
  fi

  echo "$soql_file"
}

export_data() {
  local target_org="$1"
  local module_dir="$2"
  local soql_file="$3"

  sf data export tree \
    --target-org="${target_org}" \
    --plan \
    --query="${soql_file}" \
    --output-dir="${root_dir}/data/${module_dir}"
}

# Main script execution
if [[ "$#" -ne 2 ]]; then
  usage
fi

target_org="$1"
module_dir="$2"

root_dir=$(git rev-parse --show-toplevel)
validate_params "$1" "$2"

soql_file=$(find_soql_file "$module_dir")
export_data "$target_org" "$module_dir" "$soql_file"
