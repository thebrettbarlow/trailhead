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

get_scratch_org_username() {
  local org_alias="$1"
  sf org display --target-org="$org_alias" --json | jq --raw-output '.result.username'
}

get_entity_id() {
  local org_alias="$1"
  local entity_name="$2"
  local developer_name="${entity_name%__c}" # Remove the __c suffix
  local query="SELECT Id FROM CustomObject WHERE DeveloperName = '${developer_name}'"
  sf data query --target-org="$org_alias" --query="${query}" --use-tooling-api --json | jq --raw-output '.result.records[0].Id'
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
  echo "Deploying ${module_dir} manifest..."
  "${deploy_manifest_script}" scratch "$org_alias" "$module_dir"
}

deploy_metadata() {
  local org_alias="$1"
  local metadata="$2"
  echo "Deploying ${metadata}..."
  sf project deploy start \
    --target-org="$org_alias" \
    --metadata="$metadata" \
    --ignore-conflicts \
    --wait=10
}

add_to_group() {
  local org_alias="$1"
  local username="$2"
  local group_name="$3"

  echo "Adding user ${username} to group ${group_name}..."
  "${add_to_group_script}" "$org_alias" "$username" "$group_name"
}

assign_guest_user_permission_set() {
  local org_alias="$1"
  local community_name="$2"
  local permission_set_name="$3"

  echo "Assigning guest user permission set ${permission_set_name} to Community ${community_name}..."
  "${assign_guest_user_permission_set_script}" "$org_alias" "$community_name" "$permission_set_name"
}

assign_permission_set() {
  local org_alias="$1"
  local username="$2"
  local permission_set_name="$3"

  echo "Assigning permission set ${permission_set_name} to user ${username}..."
  "${assign_permission_set_script}" "$org_alias" "$username" "$permission_set_name"
}

create_test_user() {
  local org_alias="$1"

  # The `sf data update record` command requires that we create the user with a
  # Profile that has API Enabled. We will update the user to this Profile after.
  profile_id="$(sf data query \
    --target-org="${org_alias}" \
    --query="SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce'" \
    --json | jq --raw-output '.result.records[0].Id')"

  user_id="$(sf org create user \
    --target-org="${org_alias}" \
    --definition-file="${root_dir}/config/test-user.json" \
    --set-unique-username \
    permsets="SF_Doc_User,SF_Doc_Marketing_User,Access_Activities,Action_Execution_User,Delivery_User,Export_Reports,Finance_User,Lunatask_User,Marketing_User,Resume_User,Sales_User,True_Hands_Standard_User,True_Hands_User" \
    --json | jq --raw-output '.result.fields.id')"

  sf data update record \
    --target-org="${org_alias}" \
    --sobject=User \
    --record-id="${user_id}" \
    --values="ProfileId=${profile_id}"
}

import_data() {
  local org_alias="$1"
  local module_dir="$2"
  echo "Importing ${module_dir} sample data..."
  "${import_data_script}" "$org_alias" "$module_dir"
}

install_packages() {
  local org_alias="$1"
  local module_dir="$2"
  echo "Installing ${module_dir} packages..."
  "${install_packages_script}" "$org_alias" "force-app/${module_dir}"
}

install_3p_packages() {
  local org_alias="$1"
  echo "Installing 3p packages..."
  "${install_packages_script}" "$org_alias" "3p"
}

run_tests() {
  local org_alias="$1"
  echo "Running all tests..."
  sf apex test run \
    --target-org="$org_alias" \
    --wait=10
}

open_scratch_org() {
  local org_alias="$1"
  echo "Opening scratch org..."
  sf org open \
    --target-org="$org_alias" \
    --path=lightning
}

open_url() {
  local org_alias="$1"
  local url="$2"
  echo "Opening $url..."
  sf org open \
    --target-org="$org_alias" \
    --path="$url"
}

# Main script execution
validate_params "$1"

org_alias="$1"
root_dir=$(git rev-parse --show-toplevel)

add_to_group_script="${root_dir}/scripts/add-to-group.sh"
assign_guest_user_permission_set_script="${root_dir}/scripts/assign-guest-user-permission-set.sh"
assign_permission_set_script="${root_dir}/scripts/assign-permission-set.sh"
create_community_script="${root_dir}/scripts/create-and-wait-for-community.sh"
deploy_manifest_script="${root_dir}/scripts/deploy-manifest.sh"
import_data_script="${root_dir}/scripts/import-data.sh"
install_packages_script="${root_dir}/scripts/install-packages.sh"
publish_websites_script="${root_dir}/scripts/publish-websites.sh"

check_executable "$add_to_group_script"
check_executable "$assign_guest_user_permission_set_script"
check_executable "$assign_permission_set_script"
check_executable "$create_community_script"
check_executable "$deploy_manifest_script"
check_executable "$import_data_script"
check_executable "$install_packages_script"
check_executable "$publish_websites_script"

echo "Creating scratch org..."
create_scratch_org "$org_alias"

open_scratch_org "$org_alias"

echo "Done"
