#!/usr/bin/env bash

##
# Updates the manifest for a single module.
#
# Usage:
#   update-manifest.sh <module-dir>
#

set -e

usage() {
  echo "Usage: update-manifest.sh <module-dir>"
  exit 1
}

# Validate input parameters
if [[ -z "$1" ]]; then
  echo "Error: 'module-dir' parameter is required."
  usage
fi

module_dir="$1"
root_dir=$(git rev-parse --show-toplevel)

# Determine the full module directory path
if [[ -d "${root_dir}/${module_dir}" ]]; then
  module_path="${root_dir}/${module_dir}"
elif [[ -d "${root_dir}/force-app/${module_dir}" ]]; then
  module_path="${root_dir}/force-app/${module_dir}"
else
  echo "Error: Module directory '${root_dir}/force-app/${module_dir}' or '${root_dir}/${module_dir}' does not exist."
  exit 1
fi

# Generate the manifest
sf project generate manifest \
  --source-dir="${module_path}" \
  --output-dir="${module_path}" \
  --type=package

# Remove trailing slashes from <members> entries
sed -i '' 's#\(<members>[^<]*\)/\(</members>\)#\1\2#g' "${module_path}/package.xml"
