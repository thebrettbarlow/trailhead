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
  local env="$1"
  local target_org="$2"
  local module_dir="$3"
  local manifest_path
  local test_class_list_path

  if [[ -f "${root_dir}/${module_dir}/package.xml" ]]; then
    manifest_path="${root_dir}/${module_dir}/package.xml"
  elif [[ -f "${root_dir}/force-app/${module_dir}/package.xml" ]]; then
    manifest_path="${root_dir}/force-app/${module_dir}/package.xml"
  else
    echo "Error: Manifest file not found at '${root_dir}/force-app/${module_dir}/package.xml' or '${root_dir}/${module_dir}/package.xml'."
    exit 1
  fi

  if [[ -f "${root_dir}/${module_dir}/test-classes.json" ]]; then
    test_class_list_path="${root_dir}/${module_dir}/test-classes.json"
  elif [[ -f "${root_dir}/force-app/${module_dir}/test-classes.json" ]]; then
    test_class_list_path="${root_dir}/force-app/${module_dir}/test-classes.json"
  else
    echo "Error: Test class list file not found at '${root_dir}/force-app/${module_dir}/test-classes.json' or '${root_dir}/${module_dir}/test-classes.json'."
    exit 1
  fi

  if [[ "$env" == "prod" ]]; then
    echo "Running test class names from ${test_class_list_path}..."
    class_names_output=$(jq -r '.[] | "--tests=\(.)"' "${test_class_list_path}")

    if [[ -z "${class_names_output}" ]]; then
      echo "No test classes found."
      sf project deploy start \
        --ignore-conflicts \
        --target-org="${target_org}" \
        --manifest="${manifest_path}" \
        --concise \
        --dry-run \
        --test-level=NoTestRun
    else
      # `class_names_output` needs to be expanded
      # shellcheck disable=SC2086
      sf project deploy start \
        --ignore-conflicts \
        --target-org="${target_org}" \
        --manifest="${manifest_path}" \
        --concise \
        --dry-run \
        --test-level=RunSpecifiedTests \
        ${class_names_output}
    fi
  else
    sf project deploy start \
      --ignore-conflicts \
      --target-org="${target_org}" \
      --manifest="${manifest_path}" \
      --concise \
      --dry-run
  fi
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

list_apex_tests_script="${root_dir}/scripts/list-apex-tests.mjs"
replace_placeholders_script="${root_dir}/scripts/replace-placeholders.sh"

check_executable "${replace_placeholders_script}"

"${replace_placeholders_script}" "$env" "$target_org" "$module_dir" "$output_file"

echo "Verifying ${module_dir} manifest..."
verify_manifest "$env" "$target_org" "$module_dir"
