# Puppeteer

Notes about using Puppeteer to do deployment tasks.

---

## Automatically downgraded permissions

It seems that Salesforce detects the browser is being run using automation
instead of a normal use session and automatically downgrades the user's
permissions.

We saw this when writing a script to modify Page Layout Assignments. The user
had a System Admin Profile, but all the assignments were showing "Not Assigned"
instead of their current assignments.

We tried logging in using the following:

- `/secur/frontdoor.jsp?sid=${accessToken}`
- Username and password from a trusted IP (to avoid browser verification)
- Username and password with a browser verification
- Saving cookies from a normal browser session
- Using Salesforce Classic instead of Salesforce Lightning

None of these methods worked.

In an effort to document our work, here are some scripts that we tried:

- [store-browser-cookies.js](/docs/deployment-notes/puppeteer/store-browser-cookies.mjs)
- [configure-page-layout-assignments.js](/docs/deployment-notes/puppeteer/configure-page-layout-assignments.mjs)
- [IpRanges.xml](/docs/deployment-notes/puppeteer/IpRanges.xml) (renamed from
  `Security.settings-meta.xml`)
