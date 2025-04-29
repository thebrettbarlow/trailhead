#!/bin/bash

set -e

##
# Authenticates to a Salesforce org and sets CLI aliases.
#
# Usage:
#   connect-to-org.sh <org-alias> [my-domain-url-part]
#

read_my_domain_prefix() {
  read -r -p "\
Enter the My Domain prefix for your org.
This is the part of the URL after \`https://\` and before \`.lightning.force.com\`
For example: \`dreamy-whale-123abc.scratch\`
\
" my_domain_url_part
}

org_alias="${1}"
if [[ -z "${org_alias}" ]]; then
  echo "First parameter org-alias is required"
  exit 1
fi

if [[ -z "${2}" ]]; then
  read_my_domain_prefix
else
  my_domain_url_part="${2}"
fi

if [[ -z "${my_domain_url_part}" ]]; then
  echo "Second parameter my_domain_url_part is required"
  exit 1
fi

sf org login web \
  --alias="${org_alias}" \
  --instance-url="https://${my_domain_url_part}.my.salesforce.com" \
  --set-default
