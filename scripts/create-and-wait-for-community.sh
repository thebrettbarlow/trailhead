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
  local target_org=$1
  local name=$2
  local url_path_prefix=$3
  local template_name=$4
  local authentication_type=$5

  if [ -z "$authentication_type" ]; then
    sf community create \
      --target-org="${target_org}" \
      --name="${name}" \
      --url-path-prefix="${url_path_prefix}" \
      --template-name="${template_name}" \
      --json
  else
    sf community create \
      --target-org="${target_org}" \
      --name="${name}" \
      --url-path-prefix="${url_path_prefix}" \
      --template-name="${template_name}" \
      templateParams.AuthenticationType="${authentication_type}" \
      --json
  fi
}

build_query() {
  local record_id=$1
  echo "SELECT Status FROM BackgroundOperation WHERE Id = '${record_id}'"
}

# Function to run query
run_query() {
  local query=$1
  local target_org=$2
  sf data query --query="${query}" --target-org="${target_org}" --json
}

# Function to wait for community creation
wait_for_community() {
  local record_id=$1
  local target_org=$2

  local query
  query=$(build_query "${record_id}")

  local status
  while [[ "${status}" != "Error" && "${status}" != "Complete" ]]; do
    status=$(run_query "${query}" "${target_org}" | jq -r '.result.records[0].Status')
    echo "Current status: ${status}"
    sleep 5
  done

  if [[ "${status}" == "Error" ]]; then
    echo "Community creation failed."
    exit 1
  fi

  echo "Community created successfully."
}

# Main script execution
validate_params "$1" "$2" "$3" "$4"

echo "Creating the $2 community..."
job_id=$(create_community "$@" | jq -r '.result.jobId')

echo "BackgroundOperation Id: $job_id"
target_org="$1"

echo "Waiting for the community to be created..."
wait_for_community "$job_id" "$target_org"
