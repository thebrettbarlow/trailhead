#!/usr/bin/env bash

##
# Runs the code analyzer on the project root.
#
# Usage:
#   run-code-analyzer.sh

set -e

usage() {
  echo "Usage: run-code-analyzer.sh"
  exit 1
}

if [[ $# -ne 0 ]]; then
  usage
fi

root_dir=$(git rev-parse --show-toplevel)

sf code-analyzer run \
  --rule-selector=Recommended \
  --workspace="${root_dir}/common" \
  --workspace="${root_dir}/force-app" \
  --config-file="${root_dir}/code-analyzer.yml" \
  --severity-threshold=3 \
  --output-file="${root_dir}/code-analyzer/results.csv" \
  --output-file="${root_dir}/code-analyzer/results.json" \
  --output-file="${root_dir}/code-analyzer/results.html"
