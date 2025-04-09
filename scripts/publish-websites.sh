#!/usr/bin/env bash

set -e

##
# Script to publish all websites.
#
# Usage:
#   publish-websites.sh <target-org>
#

# Function to display usage information
usage() {
  echo "Usage: publish-websites.sh <target-org>"
  exit 1
}

# Function to validate input parameters
validate_params() {
  local target_org="$1"

  if [[ -z "${target_org}" ]]; then
    echo "Error: First parameter 'target-org' is required."
    usage
  fi
}

# List of websites to publish
community_names=(
  "AlohaDogClubSf"
  "BestCoastCraft"
  "BrettBarlow"
  "SfBikerBoy"
  "TrueHands"
)

# Main script execution
target_org="$1"
validate_params "${target_org}"

# Loop through each community and publish it
for community_name in "${community_names[@]}"; do
  echo "Publishing site: ${community_name}"
  if sf community publish -n "${community_name}" -o "${target_org}"; then
    echo "Successfully published ${community_name}"
  else
    echo "Failed to publish ${community_name}"
  fi

  # Getting errors when publishing too many at the same time
  sleep 5
done
