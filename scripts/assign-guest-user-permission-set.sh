#!/usr/bin/env bash

set -e

##
# Assigns a permission set to a Guest User if not already assigned.
#
# Usage:
#   assign-guest-user-permission-set.sh <target-org> <community-name> <permission-set-name>
#

validate_params() {
  if [[ -z "$1" ]]; then
    echo "Error: First parameter 'target-org' is required."
    exit 1
  fi

  if [[ -z "$2" ]]; then
    echo "Error: Second parameter 'community-name' is required."
    exit 1
  fi

  if [[ -z "$3" ]]; then
    echo "Error: Third parameter 'permission-set-name' is required."
    exit 1
  fi
}

get_guest_user_username() {
  local target_org="$1"
  local community_name="$2"

  sf data query --target-org="${target_org}" --query="SELECT Username FROM User WHERE Profile.Name = '${community_name} Profile'" --json | jq --raw-output '.result.records[0].Username'
}

check_executable() {
  local script_path="$1"
  if [[ ! -x "${script_path}" ]]; then
    echo "Error: ${script_path} is not executable"
    exit 1
  fi
}

# Main script execution
validate_params "$1" "$2" "$3"

target_org="$1"
community_name="$2"
permission_set_name="$3"

root_dir=$(git rev-parse --show-toplevel)
assign_permission_set_script="${root_dir}/scripts/assign-permission-set.sh"

check_executable "${assign_permission_set_script}"

guest_user_username=$(get_guest_user_username "${target_org}" "${community_name}")
"${assign_permission_set_script}" "${target_org}" "${guest_user_username}" "${permission_set_name}"
