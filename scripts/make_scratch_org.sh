#!/bin/bash

set -e

##
# Creates a scratch org and deploys metadata to it
#
# This is useful when you'd like to restart where you left off based on metadata
# saved in the repository. It will not create a Trailhead Playground. Instead,
# it will create a scratch org and you will need to connect the org to Trailhead
# to complete the challenges.
#
# Follow these steps to connect the org to Trailhead:
#
# 1. Run this script to create the scratch org
# 2. Deploy metadata to the scratch org
# 3. Optionally deploy data to the scratch org (not required for all challenges)
# 4. Use `npm run sf:password:get` to get the password for the scratch org
# 4. Open the Trailhead UI
# 5. Click on the org picker in the "Hands-on Challenge" section
# 6. Click on "Connect Org"
# 7. Login with the username and password from step 4
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
