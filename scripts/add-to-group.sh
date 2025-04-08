#!/usr/bin/env bash

set -e

##
# Adds a user to a group if they are not already a member.
#
# Usage:
#   add-to-group.sh <target-org> <username> <group-name>
#

validate_params() {
  if [[ -z "$1" ]]; then
    echo "Error: First parameter 'target-org' is required."
    exit 1
  fi

  if [[ -z "$2" ]]; then
    echo "Error: Second parameter 'username' is required."
    exit 1
  fi

  if [[ -z "$3" ]]; then
    echo "Error: Third parameter 'group-name' is required."
    exit 1
  fi
}

check_group_membership() {
  local target_org="$1"
  local username="$2"
  local group_name="$3"

  local query_result
  query_result=$(sf data query -q "SELECT COUNT() FROM GroupMember WHERE Group.DeveloperName = '${group_name}' AND UserOrGroup.Username = '${username}'" --target-org="${target_org}" --json)

  local total_size
  total_size=$(echo "${query_result}" | jq '.result.totalSize')

  if [[ "${total_size}" -gt 0 ]]; then
    return 0
  else
    return 1
  fi
}

add_to_group() {
  local target_org="$1"
  local username="$2"
  local group_name="$3"

  local user_id
  user_id=$(sf data query --target-org="${target_org}" --query="SELECT Id FROM User WHERE Username = '${username}'" --json | jq --raw-output '.result.records[0].Id')

  local group_id
  group_id=$(sf data query --target-org="${target_org}" --query="SELECT Id FROM Group WHERE DeveloperName = '${group_name}'" --json | jq --raw-output '.result.records[0].Id')

  sf data create record \
    --target-org="${target_org}" \
    --sobject='GroupMember' \
    --values="GroupId=${group_id} UserOrGroupId=${user_id}"

  echo "User '${username}' successfully added to group '${group_name}'."
}

# Main script execution
validate_params "$1" "$2" "$3"

if check_group_membership "$1" "$2" "$3"; then
  echo "User '${2}' is already a member of the group '${3}'. Skipping addition."
else
  add_to_group "$1" "$2" "$3"
fi
