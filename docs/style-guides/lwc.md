# Lightning Web Component Style Guide

This is a collection of best practices for writing Lightning Web Components.

---

## Imports

- Keep imports in alphabetical order.

### Importing Schema

Use the following format when importing schema via `@salesforce/schema`:

- When needed, import the object before its fields
- Prefix each field with the name of the object
  - This allows them to be grouped together when sorted alphabetically

For example:

```js
import Work_Item from '@salesforce/schema/Work_Item__c';
import Work_Item_Deliverable from '@salesforce/schema/Work_Item__c.Deliverable__c';
import Work_Item_Priority from '@salesforce/schema/Work_Item__c.Priority__c';
import Work_Item_Status from '@salesforce/schema/Work_Item__c.Status__c';
import Work_Item_Title from '@salesforce/schema/Work_Item__c.Title__c';
```
