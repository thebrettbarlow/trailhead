#!/usr/bin/env node
/* eslint-env node */

const Ajv = require('ajv');
const fs = require('fs');

const ajv = new Ajv();
const schemaFile = process.argv[2];
const dataFile = process.argv[3];

if (!schemaFile || !dataFile) {
  console.error('Usage: validate-json.js <schema-file> <data-file>');
  process.exit(1);
}

try {
  const schema = JSON.parse(fs.readFileSync(schemaFile, 'utf8'));
  const data = JSON.parse(fs.readFileSync(dataFile, 'utf8'));

  const validate = ajv.compile(schema);
  const valid = validate(data);

  if (!valid) {
    console.error('Validation failed:', validate.errors);
    process.exit(1);
  }
  console.log('Validation successful');
} catch (error) {
  console.error('Error:', error.message);
  process.exit(1);
}
