#!/bin/bash

set -e

##
# Creates a scratch org
#
# This is useful if you'd like to experiment with metadata from a Trailhead
# module in a scratch org.
#
# The Trailhead UI does not currently support connecting to scratch orgs (as of
# January 2025). This is because the "Connect Org" button opens
# `login.salesforce.com` and we need to use either `test.salesforce.com` or the
# scratch org's instance url (My Domain) to login.
##

target_org="trailhead--scratch"

echo "Creating scratch org..."
sf org create scratch \
  --alias="${target_org}" \
  --definition-file=config/project-scratch-def.json \
  --duration-days=30 \
  --set-default

echo "Opening scratch org..."
sf org open \
  --target-org="${target_org}" \
  --path=lightning

echo "Done"
