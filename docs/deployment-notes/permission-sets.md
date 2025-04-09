# Permission Sets

## Naming

Use the following conventions when naming Permission Sets:

- `{feature} User`: To be assigned to a regular user
- `{feature} Admin`: To be assigned to a user with admin privileges to the
  feature
- `{feater} API User`: To be assigned to an integration user
- `{feater} Guest User`: To be assigned to a guest user

## Setting the License field

Set this field when the permissions contained in the Permission Set depend on a
specific license. A simple example is access to the Account and Contact tabs.
Those options are only available to users with the "Salesforce" license.
