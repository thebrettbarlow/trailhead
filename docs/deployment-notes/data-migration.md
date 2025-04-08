# Data Migration

Contains notes about doing data migration.

---

## Using the Salesforce CLI `tree` import and export commands

They've implemented pagination so these seem to work better with larger volumes
of records compared to previous versions. I was able to import a tree of all
Accounts, Contacts, Opportunities, Projects, Work Items, Time Entries, Tasks,
and Events. This list was filtered to only Accounts with Client Projects, but it
still contained these records (from the command output):

```text
wrote 42 records to Project__c.json
wrote 4 records to Contact.json
wrote 17 records to Account.json
wrote 2 records to Opportunity.json
wrote 3 records to Event.json
wrote 10 records to Task.json
wrote 457 records to Time_Entry__c.json
wrote 323 records to Work_Item__c.json
```

## Unique identifiers for legacy data

Salesforce has a text field type called External ID. This can be configured to
be a unique identifier for a record that is not the Salesforce ID.

For each object being migrated into Salesforce, create an External ID field to
hold the ID from the legacy system. This makes it easy to retry steps of the
data migration because we can use these External ID fields to write data to
Salesforce multiple times without having to look up the Salesforce ID of the
newly created record.

This also means our export -> import process looks something like:

1. `SELECT * FROM {legacy system}` > export to CSV
2. Modify the CSV header containing the ID from the legacy system
   - Replace the legacy ID column with the External ID field name
   - Map other legacy fields to Salesforce fields
3. Import the CSV to Salesforce
