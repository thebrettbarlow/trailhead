#!/usr/bin/env bash

set -e

##
# Script to retrieve and move website metadata for all websites in the websites directory
#
# Usage:
#   retrieve-websites.sh <target-org>
#

# Function to display usage information
usage() {
  echo "Usage: retrieve-websites.sh <target-org>"
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

to_pascal_case() {
  echo "$1" | awk -F- '{ for (i=1; i<=NF; i++) { $i = toupper(substr($i, 1, 1)) tolower(substr($i, 2)) } } 1' | tr -d ' '
}

# Get the list of website directories, filtering out non-directories
website_dirs=()
for dir in force-app/websites/*; do
  if [[ -d "$dir" ]]; then
    website_dirs+=("$dir")
  fi
done

# Function to move source to target directory
move_source_to_target() {
  local source_dir=$1
  local target_dir=$2

  # Make sure both directories exist first
  if [[ ! -d "${source_dir}" ]]; then
    echo "Source directory ${source_dir} does not exist"
    exit 1
  fi
  if [[ ! -d "${target_dir}" ]]; then
    echo "Target directory ${target_dir} does not exist"
    exit 1
  fi

  # Start fresh in the target directory
  rm -rf "${target_dir}"
  mkdir -p "${target_dir}"

  # Copy everything from the source directory and then remove it
  cp -r "${source_dir}/"* "${target_dir}"
  rm -rf "${source_dir}"

  # This metadata file doesn't seem to get re-created in the source dir
  target_dir_name="$(basename "${target_dir}")"
  if ! git checkout -- "${target_dir}/${target_dir_name}.digitalExperience-meta.xml"; then
    echo "Warning: Failed to checkout ${target_dir}/${target_dir_name}.digitalExperience-meta.xml"
    echo "This is expected the first time you retrieve metadata for a website."
  fi
}

# Main script execution
target_org="$1"
validate_params "${target_org}"

sf project retrieve start \
  --ignore-conflicts \
  --target-org="${target_org}" \
  --metadata=CspTrustedSite \
  --metadata=CustomSite \
  --metadata=DigitalExperienceBundle \
  --metadata=DigitalExperienceConfig \
  --metadata=NavigationMenu \
  --metadata=Network

# Iterate through each website directory and retrieve metadata
for website_dir in "${website_dirs[@]}"; do
  website_name=$(basename "${website_dir}")
  pascal_case_name=$(to_pascal_case "$website_name")

  # Mapping of source to target directories for digital experience bundles
  source_dir="force-app/main/default/digitalExperiences/site/${pascal_case_name}1"
  target_dir="force-app/websites/${website_name}/digitalExperiences/site/${pascal_case_name}1"

  # Create target directory if it doesn't exist
  mkdir -p "${target_dir}"

  # Move the retrieved metadata to the correct location
  if [[ -d "${source_dir}" ]]; then
    move_source_to_target "${source_dir}" "${target_dir}"
  else
    echo "Source directory ${source_dir} does not exist after retrieve"
    exit 1
  fi

done

# Formatting these to reduce the number of files in the git diff
npx prettier --write "force-app/websites/**/*.{json,xml}"

# Removing tags that are hard to deploy
find force-app/websites -name "*.site-meta.xml" -exec sed -i '' '/<siteAdmin>/d' {} \;
find force-app/websites -name "*.site-meta.xml" -exec sed -i '' '/<siteGuestRecordDefaultOwner>/d' {} \;

# We set this to `true` in production after deploying domains to the Salesforce CDN
find force-app/websites -name "*.network-meta.xml" -exec sed -i '' '/<enableImageOptimizationCDN>/d' {} \;
