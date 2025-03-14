# Configuring Email

Contains notes about configuring email in Salesforce.

---

## DKIM

Configuring DKIM can be completed in three steps:

1. Create a DKIM key
2. Update DNS records
3. Activate the DKIM key

### 1. Create a DKIM key

1. Find the "DKIM Keys" menu in Setup
2. Create a new DKIM key with the following recommended values:
   - Key Size: 2048-bit
   - Selector: Domain name without ending
     - For example: `truehands` for `truehands.dev`
     - This just needs to be unique
   - Alternate Selector: Same as selector, but with `2` at the end
     - For example: `truehands2` for `truehands.dev`
   - Domain: Full domain name
     - Example: `truehands.dev`
   - Domain Match Pattern: Same as Domain
     - This should automatically populate

### 2. Update DNS records

After creating the DKIM key, the following values will be generated:

- CNAME Record
- Alternate CNAME Record

The values will look like this:

```text
truehands._domainkey.truehands.dev IN CNAME truehands.abcdef.custdkim.salesforce.com.
truehands2._domainkey.truehands.dev IN CNAME truehands2.ghijkl.custdkim.salesforce.com.
```

Add the following DNS records:

- CNAME: `[selector]._domainkey.[domain]` ->
  `[selector].abcdef.custdkim.salesforce.com`
- CNAME: `[alternate_selector]._domainkey.[domain]` ->
  `[alternate_selector].ghijkl.custdkim.salesforce.com`

For example:

- CNAME: `truehands._domainkey.truehands.dev` ->
  `truehands.abcdef.custdkim.salesforce.com`
- CNAME: `truehands2._domainkey.truehands.dev` ->
  `truehands2.ghijkl.custdkim.salesforce.com`

_Use the DNS only setting in Cloudflare. Do not use the proxy._

### 3. Activate the DKIM key

After adding the DNS records, go back to the DKIM key that was created in Setup.
Refresh the page until you see a message like:

> This DKIM key is ready for activation. Both the TXT and CNAME records have
> been published in DNS.

Click the "Activate" button to activate the key.

## Email Relay

Configuring this allows for emails to be sent from Salesforce in a way that
verifies TLS and requires SMTP auth.

An email relay can be configured in three steps:

1. Get credentials to use for SMTP auth
2. Create an email relay
3. Create an email domain filter

### 1. Get credentials to use for SMTP auth

There is general info about this on the Proton Mail website
[here](https://proton.me/support/smtp-submission).

1. Go to Settings in Proton Mail
2. Find the IMAP/SMTP tab
3. Find the SMTP section and click the "Generate token" button
   - Set the Token Name to `Salesforce`

### 2. Create an email relay

1. Find the "Email Relays" menu in Salesforce Setup
2. Click the "Create Email Relay" button
3. Enter the following values:
   - Host: Domain of the address email will be sent from
     - For example: `truehands.dev`
   - Port: `587` (should be the same as the port in Proton)
   - TLS Setting: `Required Verify`
   - Enable SMTP Auth: `TRUE`
   - Auth Type: `Auth Login`
   - Username: Value from the `SMTP username` field in Proton
   - Password: Value from the `SMTP token` field in Proton
   - Confirm Password: Same as Password

### 3. Create an email domain filter

1. Find the "Email Domain Filters" menu in Salesforce Setup
2. Click the "Create Email Domain Filter" button
3. Enter the following values:
   - Sender Domain: Domain of the address email will be sent from
     - For example: `contact@truehands.dev`
   - Recipient Domain: `*`
   - Email Relay: Name of the email relay created in step 2
   - Active: `TRUE`

## Organization-Wide Email Address

We have configured `no-reply@truehands.dev` as the default no-reply address for
the org because we must have this set. All websites will have the "Built by True
Hands" footer, so if an email goes out to a different brand, it won't be totally
unexpected to be sent from the True Hands domain. Ideally we'll always send out
brand-specific emails, but it seems like there's no way around this.

## Metadata Coverage

As of March 2025, none of these email-related objected are supported by the
Metadata API. This includes:

- DKIM
- Email Relay
- Email Domain Filter
- Organization-Wide Email Address
