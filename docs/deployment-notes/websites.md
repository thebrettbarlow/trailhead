# Websites

Contains notes about deploying websites.

---

## Add Custom Domain for Website

These steps assume we would like the website to load at the root domain of the
website. It handles redirecting `www.` to the root domain.

### 1. Add the following DNS records:

- CNAME: `www` -> `www.[domain].00dfk000004xv0guac.live.siteforce.com`
- CNAME: `_acme-challenge.www` ->
  `_acme-challenge.www.[domain].00dfk000004xv0guac.live.siteforce.com`

For example:

- CNAME: `www` -> `www.truehands.dev.00dfk000004xv0guac.live.siteforce.com`
- CNAME: `_acme-challenge.www` ->
  `_acme-challenge.www.truehands.dev.00dfk000004xv0guac.live.siteforce.com`

_Use the DNS only setting in Cloudflare. Do not use the proxy._

### 2. Create the Domain in Salesforce

You should be able to create the Domain in the Salesforce Setup menu a few
minutes after creating the DNS records. When creating the Domain, use the
following:

- Domain Name: `www.[domain]` (e.g. `www.truehands.dev`)
- Domain Configuration Option:
  `Serve the domain with the Salesforce Content Delivery Network (CDN)`
- Allow HSTS preloading registration: `TRUE`
- Associated Org: `Production`

This starts an async process that can take 1-2 days to complete.

### 3. Add Custom URLs

After the domain has been provisioned, you can add a Custom URL for the website.
Go back to the Domain in the Salesforce Setup menu and create a new Custom URL.
Enter the Experience Cloud site that hosts the website in the `Site` field.
Leave the rest of the values as their defaults.

### 4. Redirect www to the root domain

We use a single `root_to_www` Bulk Redirect List that handles all redirects from
the root domain to `www.`.

Add the new website's root domain to the `root_to_www` list
[here](https://dash.cloudflare.com/0cb141f051a4d6608628509bfde26bc6/bulk-redirects/redirect-list/4c399bb4873a47c0b90b3d7c5f2f6782/edit-redirects).

- `Source URL`: `[domain]`
- `Target URL`: `https://www.[domain]`
- `Status`: `301`
- `Edit parameters`: Set the following to `TRUE`:
  - `Preserve query string`
  - `Subpath matching`
  - `Preserve path suffix`

### 5. Add root domain DNS records

After adding the website to the redirect list, we can add the following DNS
records:

- A: `@` -> `192.0.2.1` (Proxy status: Proxied)
- AAAA: `@` -> `100::` (Proxy status: Proxied)

Wait a few minutes for the DNS records to propagate.
