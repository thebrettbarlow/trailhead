#!/usr/bin/env bash

##
# Updates the manifests for all modules.
#
# Usage:
#   update-manifests.sh
#

set -e

usage() {
  echo "Usage: update-manifests.sh"
  exit 1
}

update_manifest() {
  local module_dir="$1"
  local module_path

  if [[ -d "${root_dir}/${module_dir}" ]]; then
    module_path="${root_dir}/${module_dir}"
  else
    module_path="${root_dir}/force-app/${module_dir}"
  fi

  sf project generate manifest \
    --source-dir="${module_path}" \
    --output-dir="${module_path}" \
    --type=package

  # Remove trailing slashes from <members> entries
  sed -i '' 's#\(<members>[^<]*\)/\(</members>\)#\1\2#g' "${module_path}/package.xml"
}

# Function to get relative path
relative_path() {
  perl -MFile::Spec -e 'print File::Spec->abs2rel($ARGV[0], $ARGV[1])' "$1" "$2"
}

# Main script execution
root_dir=$(git rev-parse --show-toplevel)

# Find all directories containing a package.xml
find "${root_dir}" -name "package.xml" -exec dirname {} \; | sort | while read -r dir; do
  relative_dir=$(relative_path "${dir}" "${root_dir}")
  update_manifest "${relative_dir}"
done

npx prettier --write "**/package.xml"
