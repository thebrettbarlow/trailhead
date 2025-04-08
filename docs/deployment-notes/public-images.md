# Referencing Public Images

Follow the steps below to get a url that can be used in a `src` for a public
image:

1. Create the File in production
2. Create a public link for the file
3. Use the following SOQL to retrieve the `ContentDownloadUrl`

```sql
SELECT
  ContentVersion.Title,
  ContentDownloadUrl
FROM
  ContentDistribution
```

We prefer this approach over the `/resource/StaticResourceName` approach because
this approach always loads the image. The static resource approach does not load
the image in the Experience Cloud builder.
