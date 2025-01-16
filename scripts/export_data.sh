#!/bin/bash

set -e

target_org="trailhead"

project_dir="${1}"
if [[ -z "${project_dir}" ]]; then
  echo "First parameter project_dir is required"
  exit 1
fi

root_dir=$(git rev-parse --show-toplevel)

sf data export tree \
  --target-org="${target_org}" \
  --plan \
  --query="${root_dir}/data/${project_dir}/query.soql" \
  --output-dir="${root_dir}/data/${project_dir}"
