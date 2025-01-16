#!/bin/bash

set -e

target_org="trailhead"

project_dir="${1}"
if [[ -z "${project_dir}" ]]; then
  echo "First parameter project_dir is required"
  exit 1
fi

root_dir=$(git rev-parse --show-toplevel)

sf project retrieve start \
  --ignore-conflicts \
  --target-org="${target_org}" \
  --manifest="${root_dir}/force-app/${project_dir}/package.xml"

npm run format
