#!/usr/bin/env bash

##
# Runs all tests in all modules.
#
# Usage:
#   run-tests.sh <target-org>
#

set -e

usage() {
  echo "Usage: run-tests.sh <target-org>"
  exit 1
}

validate_params() {
  local target_org="$1"

  if [[ -z "${target_org}" ]]; then
    echo "Error: First parameter 'target-org' is required."
    usage
  fi
}

check_executable() {
  local file_path="$1"

  if [[ ! -x "${file_path}" ]]; then
    echo "Error: ${file_path} is not executable"
    exit 1
  fi
}

run_tests() {
  local target_org="$1"
  local root_dir
  root_dir=$(git rev-parse --show-toplevel)

  local apex_test_operator_script="${root_dir}/scripts/apex-test-operator.sh"

  check_executable "${apex_test_operator_script}"

  "${apex_test_operator_script}" "${target_org}" "dev/beginner" "run"
}

# Main script execution
target_org="$1"
validate_params "${target_org}"
run_tests "${target_org}"
