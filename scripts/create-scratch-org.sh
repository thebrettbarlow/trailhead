#!/usr/bin/env bash

##
# Creates a scratch org in one step.
#
# Usage:
#   create-scratch-org.sh <org-alias>
#

set -e

validate_params() {
  if [[ -z "$1" ]]; then
    echo "First parameter org-alias is required"
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

create_scratch_org() {
  local org_alias="$1"
  sf org create scratch \
    --alias="$org_alias" \
    --definition-file="${root_dir}/config/project-scratch-def.json" \
    --duration-days=30 \
    --set-default
}

create_community() {
  local org_alias="$1"
  local community_name="$2"
  local url_path_prefix="$3"
  local template_name="$4"
  local authentication_type="$5"

  "${create_community_script}" "$org_alias" "$community_name" "$url_path_prefix" "$template_name" "$authentication_type"
}

deploy_manifest() {
  local org_alias="$1"
  local module_dir="$2"
  echo "Deploying manifest..."
  "${deploy_manifest_script}" "$org_alias" "$module_dir"
}

import_sample_data() {
  local org_alias="$1"
  local module_dir="$2"
  echo "Importing sample data..."
  "${import_data_script}" "$org_alias" "data/${module_dir}"
}

install_packages() {
  local org_alias="$1"
  echo "Installing packages..."
  "${install_packages_script}" "$org_alias" "3p"
}

run_tests() {
  local org_alias="$1"
  echo "Running all tests..."
  sf apex test run \
    --target-org="$org_alias" \
    --wait=10 \
    --code-coverage
}

open_scratch_org() {
  local org_alias="$1"
  echo "Opening scratch org..."
  sf org open \
    --target-org="$org_alias" \
    --path=lightning
}

# TODO: remove what is not needed

# Main script execution
validate_params "$1"

org_alias="$1"
root_dir=$(git rev-parse --show-toplevel)

create_community_script="${root_dir}/scripts/create-and-wait-for-community.sh"
deploy_manifest_script="${root_dir}/scripts/deploy-manifest.sh"
import_data_script="${root_dir}/scripts/import-data.sh"
install_packages_script="${root_dir}/scripts/install-packages.sh"

check_executable "$create_community_script"
check_executable "$deploy_manifest_script"
check_executable "$import_data_script"
check_executable "$install_packages_script"

echo "Creating scratch org..."
create_scratch_org "$org_alias"
install_packages "$org_alias"

# Placeholder values for community parameters
community_name="CommunityName"
url_path_prefix="communityname"
template_name="Build Your Own (LWR)"
authentication_type="AUTHENTICATED_WITH_PUBLIC_ACCESS_ENABLED"
create_community "$org_alias" "$community_name" "$url_path_prefix" "$template_name" "$authentication_type"

# TODO: replace with real modules
deploy_manifest "$org_alias" "example1"
deploy_manifest "$org_alias" "example2"

import_sample_data "$org_alias" "example1"
import_sample_data "$org_alias" "example2"

run_tests "$org_alias"
open_scratch_org "$org_alias"

echo "Done"
