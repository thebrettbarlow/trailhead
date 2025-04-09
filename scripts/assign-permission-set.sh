#!/usr/bin/env bash

##
# Assigns a permission set to a user if not already assigned.
#
# Usage:
#   assign-permission-set.sh <target-org> <username> <permission-set-name>
#

set -e

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
    echo "Error: Third parameter 'permission-set-name' is required."
    exit 1
  fi
}

check_permission_set() {
  local target_org="$1"
  local username="$2"
  local permission_set_name="$3"

  local query_result
  query_result=$(sf data query -q "SELECT COUNT() FROM PermissionSetAssignment WHERE Assignee.Username = '${username}' AND PermissionSet.Name = '${permission_set_name}'" --target-org="${target_org}" --json)

  local total_size
  total_size=$(echo "${query_result}" | jq '.result.totalSize')

  if [[ "${total_size}" -gt 0 ]]; then
    return 1 # Permission set is already assigned
  else
    return 0 # Permission set is not assigned
  fi
}

assign_permission_set() {
  local target_org="$1"
  local username="$2"
  local permission_set_name="$3"

  sf org assign permset \
    --target-org="${target_org}" \
    --name="${permission_set_name}" \
    --on-behalf-of="${username}"

  echo "Permission set '${permission_set_name}' successfully assigned to user '${username}'."
}

# Main script execution
validate_params "$1" "$2" "$3"

if check_permission_set "$1" "$2" "$3"; then
  assign_permission_set "$1" "$2" "$3"
else
  echo "User '${2}' already has the permission set '${3}' assigned. Skipping assignment."
fi
