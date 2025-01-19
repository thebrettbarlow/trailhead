# Brett Barlow's Trailhead Challenges

Contains the source code for Brett Barlow's Trailhead challenges.

Follow along here: https://www.salesforce.com/trailblazer/brett

## Repository Structure

Code is organized into folders based on the Trailhead module. For example, the
[Developer Beginner](https://trailhead.salesforce.com/content/learn/trails/force_com_dev_beginner)
module is in [force-app/dev/beginner](force-app/dev/beginner).

Each folder contains a `package.xml` file that contains the metadata for the
module.

## Completing Challenges

To make it easier to reference our work later, we will create a folder for each
module that we work on. Use this command to create the folder with an empty
`package.xml` file:

```shell
project_dir="" # For example: dev/beginner

mkdir -p force-app/${project_dir}
sf project generate manifest \
  --source-dir="force-app/${project_dir}" \
  --output-dir="force-app/${project_dir}" \
  --type=package
```

As you work through the challenge, add entries to the `package.xml` file so the
source can be retrieved later. Alternatively, you can
`sf project retrieve start --metadata=foo` and run the command
[below](#updating-packagexml-files) to update the `package.xml` file.

### Retrieving Metadata

Use this command to retrieve metadata defined in the `package.xml` file:

```shell
project_dir="" # For example: dev/beginner
target_org="trailhead"

sf project retrieve start \
  --manifest="force-app/${project_dir}/package.xml"
```

### Updating `package.xml` Files

While working on a module, you can update the `package.xml` file to contain all
metadata in the folder with this command:

```shell
project_dir="" # For example: dev/beginner

sf project generate manifest \
  --target-org="${target_org}" \
  --source-dir="force-app/${project_dir}" \
  --output-dir="force-app/${project_dir}" \
  --type=package
```
