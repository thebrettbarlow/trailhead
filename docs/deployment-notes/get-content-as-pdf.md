# Notes about using PageReference.getContentAsPdf()

This method returns a `Blob` representation of a Visualforce page as a PDF file.
It is commonly used to generate PDFs for printing, sending email attachments or
just saving a PDF to a record.

## PDF Showing Blank

### High Assurance Session Required

There is a known issue that describes why this happens. The full text is below
in case the url changes in the future.

In summary, the User has a Profile with Session Security Level set to High
Assurance. We need to change the Session Security Level to None.

We can enforce Multi-Factor Authentication by assigning a Permission Set that
contains the "Multi-Factor Authentication for User Interface Logins" permission.

#### Known Issue

**Two Factor authenticated user having session setting set as 'High Assurance'
and Async apex generated PDF attachment, file content shows as blank**
([link](https://issues.salesforce.com/issue/a028c00000qPxndAAC/two-factor-authenticated-user-having-session-setting-set-as-high-assurance-and-async-apex-generated-pdf-attachment-file-content-shows-as-blank))

| Created     | Last Updated | Reference ID |
| ----------- | ------------ | ------------ |
| Nov 6, 2017 | Feb 8, 2021  | W-4460717    |

##### Summary

> If an org has a user whose profile has session setting set as 'High Assurance'
> and when this user runs a job to create PDF attachment, the attachment data
> shows as null. When the same user was given Two-factor authentication using
> permission set 'Two-Factor Authentication for User Interface Logins' instead
> of profile session setting, the generated PDF attachment displays data. This
> is majorly happening in Async apex case.

##### Steps to Reproduce

1. Create a permission set "2factor" and assign to the user. The permission set
   should have the perm "Two-Factor Authentication for User Interface Logins"
2. Now go to developer console and run the batch job to update a record
3. The batch job updates the record object and process Builder is run on the
   object which creates a PDF attachment and attaches to the record object. PDF
   has data
4. Now remove the permission set and try to assign the session settings 'High
   Assurance' to the user profile
5. Now go to developer console and run the batch job
6. The batch job updates the record and process Builder is run which create a
   PDF attachment and attaches to the object. Now the PDF is null

##### Workaround

> The only workaround is to remove the session security level specification from
> user profile to None
