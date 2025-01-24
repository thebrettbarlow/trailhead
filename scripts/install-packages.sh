#!/usr/bin/env bash

##
# Installs the required packages for a module.
#
# Usage:
#   install-packages.sh <target-org> <module-dir>
#

set -e

usage() {
  echo "Usage: install-packages.sh <target-org> <module-dir>"
  exit 1
}

validate_params() {
  if [[ -z "$1" ]]; then
    echo "First parameter target-org is required"
    exit 1
  fi

  local module_dir="$2"
  if [[ -z "${module_dir}" ]]; then
    echo "Error: Second parameter 'module-dir' is required."
    usage
  fi

  if [[ ! -d "${root_dir}/${module_dir}" && ! -d "${root_dir}/force-app/${module_dir}" ]]; then
    echo "Error: Module directory '${root_dir}/${module_dir}' or '${root_dir}/force-app/${module_dir}' does not exist."
    exit 1
  fi
}

is_package_installed() {
  local package_name="$1"
  sf package installed list --target-org="${target_org}" | grep -q "${package_name}"
}

install_packages() {
  local json_file="$1"
  local packages
  packages=$(jq -r '.packages[]' "${json_file}")

  for package in ${packages}; do
    if ! is_package_installed "${package}"; then
      echo "Installing package: ${package}"
      sf package install --package "${package}" --target-org="${target_org}" --wait 10
    else
      echo "Package already installed: ${package}"
    fi
  done
}

get_installed_packages() {
  sf package installed list --target-org="${target_org}" > "${installed_packages_file}"
}

cleanup() {
  rm -f "${installed_packages_file}"
}

# Main script execution
root_dir=$(git rev-parse --show-toplevel)
installed_packages_file=$(mktemp)

validate_params "$1" "$2"
target_org="$1"
module_dir="$2"

# Set up trap for cleanup
trap cleanup EXIT

# Get all installed packages at start
get_installed_packages

# Main logic: Iterate over all `installed_packages.json` files in subdirectories
find "${root_dir}/${module_dir}" -name "installed_packages.json" | while read -r json_file; do
  install_packages "$json_file"
done
