# Data for Trailhead Challenges

Contains configuration files for exporting and importing data for Trailhead
challenges.

---

## Getting Started

1. Create a directory in [/data](/data) in a way that mirrors the structure in
   [force-app](/force-app).
2. Create a `query.soql` file that contains the SOQL query to export the data.
3. Follow the steps in [Exporting Data](#exporting-data) to export the data.

Run this command to create the directory and an empty `query.soql` file:

```shell
project_dir="" # For example: dev/beginner

mkdir -p "data/${project_dir}"
touch "data/${project_dir}/query.soql"
```

When data needs to be imported, follow the steps in
[Importing Data](#importing-data) to import the data.

## Exporting Data

Create a `query.soql` file that contains the SOQL query to export the data.

Prefer to use the `sf data export tree` command to export data. Include the
`--plan` flag because it supports more than 200 records.

For example:

```shell
project_dir="" # For example: dev/beginner
target_org="trailhead"

sf data export tree \
  --target-org="${target_org}" \
  --plan \
  --query="data/${project_dir}/query.soql" \
  --output-dir="data/${project_dir}"
```

## Importing Data

Prefer to use the `sf data import tree` command to import data.

For example:

```shell
project_dir="" # For example: dev/beginner
target_org="trailhead"

plan_file=$(find "data/${project_dir}" -name "*-plan.json" -print -quit)

sf data import tree \
  --target-org="${target_org}" \
  --plan="${plan_file}"
```
