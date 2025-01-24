#!/usr/bin/env node
/* eslint-env node */
'use strict';

/**
 * Validates a JSON file against a specified schema file.
 *
 * Usage:
 *   validate-json.mjs <schema-file> <data-file>
 *
 * @param {string} schemaFile - Path to the JSON schema file.
 * @param {string} dataFile - Path to the JSON data file to be validated.
 */

import fs from 'fs';
import Ajv from 'ajv';

const ajv = new Ajv();
const [schemaFileArg, dataFileArg] = process.argv.slice(2);

if (!schemaFileArg || !dataFileArg) {
  console.error('Usage: validate-json.mjs <schema-file> <data-file>');
  process.exit(1);
}

const validateJson = (schemaFile, dataFile) => {
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
    console.error(`Error: ${error.message}`);
    process.exit(1);
  }
};

validateJson(schemaFileArg, dataFileArg);
