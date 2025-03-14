#!/usr/bin/env bash

##
# Updates the lists of test classes for all modules.
#
# This is needed because we identify tests classes by querying for their SymbolTable and checking if
# it contains `@IsTest` annotated methods. During a deployment, these will not be present in the
# target org until the deployment has completed. We use this to keep an up-to-date list of test
# classes that can be used during deployments.
#
# This works because we can list test classes based on the metadata in the org we were developing in.
#
# Usage:
#   update-test-class-lists.sh <target-org>
#

set -e

usage() {
  echo "Usage: $0 <target-org>"
  exit 1
}

update_test_class_list() {
  local module_dir="$1"
  local manifest_path

  if [[ -f "${root_dir}/${module_dir}/package.xml" ]]; then
    manifest_path="${root_dir}/${module_dir}/package.xml"
  elif [[ -f "${root_dir}/force-app/${module_dir}/package.xml" ]]; then
    manifest_path="${root_dir}/force-app/${module_dir}/package.xml"
  else
    echo "Error: Manifest file not found at '${root_dir}/force-app/${module_dir}/package.xml' or '${root_dir}/${module_dir}/package.xml'."
    exit 1
  fi

  echo "Retrieving test class names from ${manifest_path}..."
  node "${list_apex_tests_script}" "${manifest_path}" "${target_org}" "json" > "${root_dir}/${module_dir}/test-classes.json"
}

# Function to get relative path
relative_path() {
  perl -MFile::Spec -e 'print File::Spec->abs2rel($ARGV[0], $ARGV[1])' "$1" "$2"
}

# Main script execution
if [[ $# -ne 1 ]]; then
  usage
fi

target_org="$1"

root_dir=$(git rev-parse --show-toplevel)
list_apex_tests_script="${root_dir}/scripts/list-apex-tests.mjs"

# Find all directories containing a package.xml
find "${root_dir}" -name "package.xml" -exec dirname {} \; | sort | while read -r dir; do
  relative_dir=$(relative_path "${dir}" "${root_dir}")
  update_test_class_list "${relative_dir}"
done

npx prettier --write "**/test-classes.json"
