#!/usr/bin/env node
/* eslint-env node */

'use strict';

/**
 * Lists Apex test classes based on a given package.xml.
 *
 * Usage:
 *   node list-apex-tests.mjs <packageXmlPath> <orgAlias> <outputFormat>
 *
 * @param {string} packageXmlPath - Path to the package.xml file.
 * @param {string} orgAlias - Alias for the Salesforce organization.
 * @param {string} outputFormat - Format for the output: "comma-separated" or "script-flags".
 */

import { Org } from '@salesforce/core';
import fs from 'fs';
import xml2js from 'xml2js';

const parsePackageXml = async (packageXmlPath) => {
  if (!fs.existsSync(packageXmlPath)) {
    throw new Error(`The file ${packageXmlPath} does not exist.`);
  }

  const packageContent = fs.readFileSync(packageXmlPath, { encoding: 'utf8' });
  try {
    return await xml2js.parseStringPromise(packageContent);
  } catch (err) {
    throw new Error(`Failed to parse package.xml: ${err.message}`);
  }
};

const getApexClassNames = (packageJson) => {
  const types = packageJson.Package.types || [];
  const apexClassesType = Array.isArray(types)
    ? types.find((t) => t.name && t.name[0] === 'ApexClass')
    : types;

  return Array.isArray(apexClassesType?.members)
    ? apexClassesType.members.map((member) => member.toString())
    : apexClassesType?.members
      ? [apexClassesType.members.toString()]
      : [];
};

const getSalesforceConnection = async (orgAlias) => {
  const org = await Org.create({ aliasOrUsername: orgAlias });
  return org.getConnection();
};

const getApexClasses = async (conn, apexClassNames) => {
  const query = `SELECT Name, SymbolTable FROM ApexClass WHERE Name IN ('${apexClassNames.join("','")}')`;
  const result = await conn.tooling.query(query);
  return result.records;
};

const isTestClass = (symbolTable) => {
  return symbolTable?.methods?.some((method) =>
    method.annotations?.some((ann) => ann.name === 'IsTest')
  );
};

const findTestClasses = (apexClasses) => {
  return apexClasses
    .filter((apexClass) => isTestClass(apexClass.SymbolTable))
    .map((apexClass) => apexClass.Name);
};

const formatOutput = (testClasses, outputFormat) => {
  if (outputFormat === 'comma-separated') {
    return testClasses.join(',');
  } else if (outputFormat === 'script-flags') {
    return testClasses.map((testClass) => `--tests=${testClass}`).join(' ');
  }
  throw new Error(`Unsupported output format: ${outputFormat}`);
};

const identifyTestClasses = async (packageXmlPath, orgAlias, outputFormat) => {
  const packageJson = await parsePackageXml(packageXmlPath);
  const apexClassNames = getApexClassNames(packageJson);

  const conn = await getSalesforceConnection(orgAlias);
  const apexClasses = await getApexClasses(conn, apexClassNames);

  const testClasses = findTestClasses(apexClasses);
  console.log(formatOutput(testClasses, outputFormat));
};

// Main execution
(async () => {
  try {
    const args = process.argv.slice(2);
    if (args.length < 3) {
      console.error(
        'Usage: node list-apex-tests.mjs <packageXmlPath> <orgAlias> <outputFormat>'
      );
      console.error(
        'Supported output formats: "comma-separated", "script-flags"'
      );
      process.exit(1);
    }

    const [packageXmlPath, orgAlias, outputFormat] = args;
    await identifyTestClasses(packageXmlPath, orgAlias, outputFormat);
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
})();
