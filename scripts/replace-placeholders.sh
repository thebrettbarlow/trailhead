#!/usr/bin/env bash

##
# Script to replace placeholders in files based on environment.
#
# Usage:
#   replace-placeholders.sh <env> <module-dir> <output-file>
#

set -e

# Create a temporary file for the cache
cache_file=$(mktemp)

# Function to clean up the cache file on exit
cleanup() {
  rm -f "${cache_file}"
}
trap cleanup EXIT

# Function to print usage
usage() {
  echo "Usage: $0 <env> <module-dir> <output-file>"
  exit 1
}

# Check if jq, sf, and gh CLI are installed
if ! command -v jq &> /dev/null; then
  echo "jq could not be found, please install jq."
  exit 1
fi

if ! command -v sf &> /dev/null; then
  echo "Salesforce CLI (sf) could not be found, please install Salesforce CLI."
  exit 1
fi

if ! command -v gh &> /dev/null; then
  echo "GitHub CLI (gh) could not be found, please install GitHub CLI."
  exit 1
fi

# Check for correct input parameters
if [[ "$#" -ne 3 ]]; then
  usage
fi

env=$1
module_dir=$2
output_file=$3

# Determine the root directory
root_dir=$(git rev-parse --show-toplevel)

# Determine the full module directory path
if [[ -d "${root_dir}/force-app/${module_dir}" ]]; then
  module_path="${root_dir}/force-app/${module_dir}"
elif [[ -d "${root_dir}/${module_dir}" ]]; then
  module_path="${root_dir}/${module_dir}"
else
  echo "Error: Module directory '${root_dir}/force-app/${module_dir}' or '${root_dir}/${module_dir}' does not exist."
  exit 1
fi

# Function to get the replacement value based on environment
get_replacement_value() {
  local placeholder=$1
  local env=$2
  local placeholders=$3
  local default_value
  local env_value

  # Check cache first
  cache_value=$(grep "^${placeholder}=" "${cache_file}" | cut -d'=' -f2-)
  if [[ -n "${cache_value}" ]]; then
    echo "${cache_value}"
    return
  fi

  default_value=$(echo "${placeholders}" | jq -r --arg p "${placeholder}" 'select(.placeholder == $p) | .default')
  env_value=$(echo "${placeholders}" | jq -r --arg p "${placeholder}" --arg e "${env}" 'select(.placeholder == $p) | .env[$e] // empty')

  if [[ -z "${env_value}" ]]; then
    echo "${placeholder}=${default_value}" >> "${cache_file}"
    echo "${default_value}"
  else
    # Check if env_value is an object
    if jq -e 'type == "object"' <<< "${env_value}" > /dev/null 2>&1; then
      local cli
      local command
      local key
      local value

      cli=$(echo "${env_value}" | jq -r '.cli')
      command=$(echo "${env_value}" | jq -r '.command')
      key=$(echo "${env_value}" | jq -r '.key')

      local prefix
      if [[ "${cli}" == "sf" ]]; then
        prefix="SF_JSON_TO_STDOUT=true"
      fi

      value=$(eval "${prefix}" "${cli}" "${command}" --json 2> /dev/null | jq -r --arg k "${key}" '.result[$k]')
      echo "${placeholder}=${value}" >> "${cache_file}"
      echo "${value}"
    else
      echo "${placeholder}=${env_value}" >> "${cache_file}"
      echo "${env_value}"
    fi
  fi
}

# Function to replace placeholders in files
replace_placeholders_in_file() {
  local file=$1
  local placeholders=$2
  local modified=false

  for placeholder in $(echo "${placeholders}" | jq -r '.placeholder'); do
    if grep -q "{{ ${placeholder} }}" "${file}"; then
      if [[ "$modified" == false ]]; then
        cp "${file}" "${file}.bak"
        modified=true
      fi
      local value
      value=$(get_replacement_value "${placeholder}" "${env}" "${placeholders}")
      if [[ "${value}" == "remove line" ]]; then
        echo "Removing line with ${placeholder} from ${file}" # Debug statement

        # Remove the line containing the placeholder using a temporary file
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed "/{{ ${placeholder} }}/d" "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
        else
          sed -i "/{{ ${placeholder} }}/d" "${file}"
        fi
      else
        escaped_value=$(printf '%s\n' "${value}" | sed -e 's/[\/&]/\\&/g')
        echo "Replacing ${placeholder} with ${value} in ${file}" # Debug statement

        # Use different `sed` syntax based on the OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
          sed "s|{{ ${placeholder} }}|${escaped_value}|g" "${file}" > "${file}.tmp" && mv "${file}.tmp" "${file}"
        else
          sed -i "s|{{ ${placeholder} }}|${escaped_value}|g" "${file}"
        fi
      fi
    fi
  done

  if [[ "$modified" == true ]]; then
    echo "${file}" >> "${output_file}"
  fi
}

# Find and replace placeholders in all files within the directory containing the placeholders.json file and its subdirectories
process_directory() {
  local dir=$1
  local placeholders_file=$2

  echo "Validating JSON file: ${placeholders_file}"
  if ! node "${root_dir}/scripts/validate-json.mjs" "${root_dir}/.schemas/placeholders.schema.json" "${placeholders_file}"; then
    echo "Validation failed for ${placeholders_file}. Exiting."
    exit 1
  fi

  placeholders=$(jq -r '.[]' "${placeholders_file}")

  find "${dir}" -type f ! -name "placeholders.json" | while read -r file; do
    replace_placeholders_in_file "${file}" "${placeholders}"
  done
}

# Initialize the output file
true > "${output_file}"

echo "Starting placeholder replacement..."

# Find all placeholders.json files starting from the module directory
find "${module_path}" -type f -name "placeholders.json" | while read -r placeholders_file; do
  dir=$(dirname "${placeholders_file}")
  process_directory "${dir}" "${placeholders_file}"
done

if [[ -s "${output_file}" ]]; then
  echo "Modified files are listed in ${output_file}"
else
  echo "No placeholders found to replace."
fi

echo "Placeholder replacement complete."
