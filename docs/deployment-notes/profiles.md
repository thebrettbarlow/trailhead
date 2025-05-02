# Profiles

Contains notes about deploying profiles.

---

## Minimum Access - Salesforce

This profile grants minimum access to Salesforce.

### Missing Page Layout Assignments

While working on a feature related to Leads, we saw some unexpected behavior
(parts of the Flexipage wouldn't load, the New button from the Leads tab didn't
work). After looking into it, we discovered that this profile did not have a
Lead Page Layout assigned to it. The issue was resolved by assigning the Lead
Page Layout to this profile.

This happened for the following objects:

- Lead
- Account
- Contact
- Opportunity
- Case (both the open and closed case Page Layouts)
- Task
- Event
