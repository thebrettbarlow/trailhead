#!/bin/bash

set -e

target_org="trailhead--scratch"

sf project retrieve start \
  --ignore-conflicts \
  --target-org="${target_org}" \
  --help # TODO: replace with --metadata the first time we need this

npm run format
