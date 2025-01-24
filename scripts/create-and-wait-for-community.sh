#!/usr/bin/env bash

set -e

##
# Creates a community and waits for it to be created.
#
# Usage:
#   create-and-wait-for-community.sh \
#     <target-org> \
#     <name> \
#     <url-path-prefix> \
#     <template-name> \
#     [authentication-type]
#

# Function to check required parameters
validate_params() {
  if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]]; then
    echo "First 4 parameters are required: target-org, name, url-path-prefix, template-name"
    exit 1
  fi
}

# Function to create community
create_community() {
  sf community create \
    --target-org="$1" \
    --name="$2" \
    --url-path-prefix="$3" \
    --template-name="$4" \
    ${5:+--authentication-type="$5"}
}

# Function to wait for community creation
wait_for_community() {
  local job_id="$1"
  local target_org="$2"
  while true; do
    status=$(sf community list --target-org="$target_org" --json | jq -r ".result | map(select(.jobId == \"$job_id\")) | .[0].status")
    if [[ "$status" == "Succeeded" ]]; then
      echo "Community created successfully."
      break
    elif [[ "$status" == "Failed" ]]; then
      echo "Community creation failed."
      exit 1
    else
      echo "Waiting for community to be created..."
      sleep 10
    fi
  done
}

# Main script execution
validate_params "$1" "$2" "$3" "$4"

echo "Creating the community..."
job_id=$(create_community "$@" | jq -r '.result.jobId')

echo "BackgroundOperation Id: $job_id"
target_org="$1"

echo "Waiting for the community to be created..."
wait_for_community "$job_id" "$target_org"
