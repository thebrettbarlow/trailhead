#!/usr/bin/env bash

##
# Apex Test Operator Script
#
# This script either lists or runs Apex test classes, depending on the "operation" parameter.
#
# Usage:
#   apex-test-operator.sh <target-org> <module-dir> <operation>
#
# <operation>: "list" or "run"
#

set -e

target_org="${1}"
if [[ -z "${target_org}" ]]; then
  echo "First parameter 'target-org' is required."
  exit 1
fi

module_dir="${2}"
if [[ -z "${module_dir}" ]]; then
  echo "Second parameter 'module-dir' is required."
  exit 1
fi

operation="${3}"
if [[ -z "${operation}" ]]; then
  echo "Third parameter 'operation' ('list' or 'run') is required."
  exit 1
fi

# Convert operation to lowercase for consistency
operation=$(echo "${operation}" | tr '[:upper:]' '[:lower:]')

root_dir=$(git rev-parse --show-toplevel)
package_xml_path="${root_dir}/force-app/${module_dir}/package.xml"
list_apex_tests_script="${root_dir}/scripts/list-apex-tests.mjs"

if [[ ! -f "${package_xml_path}" ]]; then
  echo "Error: package.xml file not found at ${package_xml_path}."
  exit 1
fi

if [[ ! -f "${list_apex_tests_script}" ]]; then
  echo "Error: list-apex-tests.mjs file not found at ${list_apex_tests_script}."
  exit 1
fi

if [[ "${operation}" == "list" ]]; then
  echo "Listing test classes from ${package_xml_path}..."
  class_names=$(node "${list_apex_tests_script}" "${package_xml_path}" "${target_org}" "comma-separated")

  if [[ -z "${class_names}" ]]; then
    echo "No test classes found."
    exit 0
  fi

  echo "Test classes: ${class_names}"

elif [[ "${operation}" == "run" ]]; then
  echo "Retrieving test class names from ${package_xml_path}..."
  class_names_output=$(node "${list_apex_tests_script}" "${package_xml_path}" "${target_org}" "script-flags")

  if [[ -z "${class_names_output}" ]]; then
    echo "No test classes found."
    exit 0
  fi

  # `class_names_output` needs to be expanded
  # shellcheck disable=SC2086
  sf apex test run \
    --target-org="${target_org}" \
    --wait=10 \
    --test-level=RunSpecifiedTests \
    --concise \
    ${class_names_output}

else
  echo "Invalid operation '${operation}'. Supported operations are: 'list' or 'run'."
  exit 1
fi
