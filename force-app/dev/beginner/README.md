# Developer Beginner Trail

Contains the source code for Brett Barlow's Trailhead Developer Beginner
challenges.

---

## General Notes

Some of the challenges required granting the Admin profile access to metadata
that was created, but this becomes hard to manage in a repo where the Admin
profile could possibly be stored in multiple folders. As a workaround, the
`Energy_Consultations_User` Permission Set was created and can be assigned to
the user in the org.

## Assign Permission Set to User

If needed, run this script to assign the Permission Set:

```shell
sf org assign permset \
  --name="Energy_Consultations_User" \
  --target-org="trailhead"
```
