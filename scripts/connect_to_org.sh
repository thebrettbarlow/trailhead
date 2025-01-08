#!/bin/bash

set -e

##
# Authenticates to a Salesforce org and sets CLI aliases
#
# This is designed to be used after creating a new Trailhead Playground from the
# Trailhead UI. Follow these steps to connect to the Playground:
#
# 1. Create a new Playground from the Trailhead UI
# 2. Launch the Playground
# 3. Click on the "Get Your Login Credentials" tab and reset your password
# 4. Follow the instructions in your email to reset your password
# 5. Copy the portion of the URL between "https://" and ".lightning.force.com"
# 6. Run this script with the copied URL
# 7. Log in to the org with your new credentials
##

set -e

target_org="trailhead"

read -r -p "\
Enter the My Domain prefix for your org.
This is the part of the URL after \`https://\` and before \`.lightning.force.com\`
For example: \`curious-panda-2jit8z-dev-ed.trailblaze\`
\
" my_domain_url_part

sf auth web login \
  --alias="${target_org}" \
  --instance-url="https://${my_domain_url_part}.my.salesforce.com" \
  --set-default
