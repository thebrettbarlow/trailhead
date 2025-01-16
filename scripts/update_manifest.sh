#!/bin/bash

set -e

project_dir="${1}"
if [[ -z "${project_dir}" ]]; then
  echo "First parameter project_dir is required"
  exit 1
fi

root_dir=$(git rev-parse --show-toplevel)

sf project generate manifest \
  --source-dir="${root_dir}/force-app/${project_dir}" \
  --output-dir="${root_dir}/force-app/${project_dir}" \
  --type=package

npm run format
