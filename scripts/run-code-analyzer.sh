#!/usr/bin/env bash

##
# Runs the code analyzer on the project root.
#
# Usage:
#   run-code-analyzer.sh --mode <lint|save>

set -e

usage() {
  echo "Usage: run-code-analyzer.sh --mode <lint|save>"
  echo
  echo "Modes:"
  echo "  lint   Run analyzer and fail on errors above severity threshold"
  echo "  save   Run analyzer and store results in output files"
  exit 1
}

mode=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      shift
      if [[ "$1" != "lint" && "$1" != "save" ]]; then
        echo "Error: mode must be either 'lint' or 'save'"
        exit 1
      fi
      mode="$1"
      shift
      ;;
    *)
      usage
      ;;
  esac
done

if [[ -z "$mode" ]]; then
  echo "Error: --mode is required"
  usage
fi

root_dir=$(git rev-parse --show-toplevel)

# Common flags for both modes
common_flags=(
  --rule-selector=Recommended
  --workspace="${root_dir}/common"
  --workspace="${root_dir}/force-app"
  --config-file="${root_dir}/code-analyzer.yml"
)

if [ "$mode" = "save" ]; then
  sf code-analyzer run "${common_flags[@]}" \
    --output-file="${root_dir}/code-analyzer/results.csv" \
    --output-file="${root_dir}/code-analyzer/results.json" \
    --output-file="${root_dir}/code-analyzer/results.html"
else
  sf code-analyzer run "${common_flags[@]}" \
    --severity-threshold=3
fi
