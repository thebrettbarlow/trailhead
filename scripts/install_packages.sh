#!/bin/bash

set -e # Stop execution on any error

project_dir="${1}"
if [[ -z "${project_dir}" ]]; then
  echo "First parameter project_dir is required"
  exit 1
fi

root_dir=$(git rev-parse --show-toplevel)

# Function to fetch currently installed packages
get_installed_packages() {
  echo "Fetching currently installed packages..."
  sf package installed list --json | jq '.result[] | .SubscriberPackageVersionId' > /tmp/installed_packages.txt
}

# Function to check if a package is already installed
is_package_installed() {
  local package_id=\$1
  grep -q "\"$package_id\"" /tmp/installed_packages.txt
}

# Function to validate JSON against schema
validate_json() {
  local json_file=$1
  local schema_file="$root_dir/.schemas/installed_packages.schema.json"
  local validate_script="$root_dir/scripts/validate-json.js"

  # Ensure the schema file exists
  if [[ ! -f "$schema_file" ]]; then
    echo "Warning: Schema file not found. Skipping JSON schema validation."
    return 0
  fi

  echo "Validating JSON schema for $json_file..."
  if ! node "$validate_script" "$schema_file" "$json_file"; then
    echo "Error: JSON validation failed for $json_file"
    exit 1
  fi
}

# Function to install packages from a given JSON file
install_packages() {
  local json_file=$1

  # Debugging statement to show the passed argument
  echo "Attempting to install packages from: $json_file"

  # Check if the JSON file exists
  if [[ ! -f "$json_file" ]]; then
    echo "Error: $json_file not found. Skipping module..."
    return 1
  fi

  # Validate JSON against schema
  validate_json "$json_file"

  echo "Processing $json_file..."

  # Use jq to parse the JSON and install each package
  jq -c '.[]' "$json_file" | while read -r package; do
    # Extract fields from the JSON file
    name=$(echo "$package" | jq -r '.Name')
    package_id=$(echo "$package" | jq -r '.PackageVersionId')
    security=$(echo "$package" | jq -r '.SecurityType')

    # Check if the package is already installed
    if is_package_installed "$package_id"; then
      echo "Package $name (ID: $package_id) is already installed. Skipping."
      continue
    fi

    echo "Installing package: $name (ID: $package_id) with SecurityType: $security"

    # Install the package
    if sf package install --package="$package_id" --security-type="$security" --no-prompt --wait=10; then
      echo "Successfully installed $name."
    else
      echo "Error: Failed to install $name (ID: $package_id). Continuing with next package."
    fi
  done
}

# Cleanup function
cleanup() {
  rm -f /tmp/installed_packages.txt
}

# Set up trap for cleanup
trap cleanup EXIT

# Get all installed packages at start
get_installed_packages

# Main logic: Iterate over all `installed_packages.json` files in subdirectories
find "${root_dir}/force-app/${project_dir}" -name "installed_packages.json" | while read -r json_file; do
  install_packages "$json_file"
done
