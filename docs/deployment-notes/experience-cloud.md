# Deploying Experience Cloud

This page contains notes about deploying Experience Cloud.

---

## Publishing an Experience Cloud site

Either of the following are required to publish an Experience Cloud site:

- Create and Set Up Experiences AND be a member of the site
- Be a member of the site AND an experience admin or publisher in that site

The first one is the easiest option. To solve this, we create "API User"
permission sets for each Experience Cloud site and assign them to the GitHub
Actions user.

This permission set needs the `<license>` set to `Salesforce Integration` (not
`SalesforceAPIIntegrationPsl`).
