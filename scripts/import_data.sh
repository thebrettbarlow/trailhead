#!/bin/bash

set -e

target_org="trailhead"

project_dir="${1}"
if [[ -z "${project_dir}" ]]; then
  echo "First parameter project_dir is required"
  exit 1
fi

root_dir=$(git rev-parse --show-toplevel)
plan_file=$(find "${root_dir}/data/${project_dir}" -name "*-plan.json" -print -quit)

sf data import tree \
  --target-org="${target_org}" \
  --plan="${plan_file}"
