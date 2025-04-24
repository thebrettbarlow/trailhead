#!/usr/bin/env node
/* eslint-env node */

'use strict';

import * as path from 'path';
import { Org, SfProject } from '@salesforce/core';
import fs from 'fs-extra';
import { glob } from 'glob';

const getJsonFiles = async (dataDir) =>
  glob(`${dataDir}/*.json`, { ignore: ['**/*-plan.json'] });

const getCurrentUserId = async (conn) => {
  const query = `SELECT Id FROM User WHERE Username = '${conn.getUsername()}'`;
  const result = await conn.query(query);
  return result.records[0].Id;
};

const makeBackup = async (file) => {
  const backupFile = `${file}.bak`;
  if (!(await fs.pathExists(backupFile))) {
    await fs.copyFile(file, backupFile);
  }
};

const replaceUserIds = async (file, currentUserId) => {
  const userIdRegex = /005[a-zA-Z0-9]{15}/g;

  const originalContent = await fs.promises.readFile(file, 'utf8');
  const updatedContent = originalContent.replace(userIdRegex, currentUserId);

  const hasReplacedUserIds = originalContent !== updatedContent;
  if (hasReplacedUserIds) {
    await makeBackup(file);
    fs.writeFileSync(file, updatedContent);
  }

  return hasReplacedUserIds;
};

const prepareRecordTypeMap = async (conn, jsonFiles) => {
  const recordTypeMap = new Map();
  const developerNames = new Set();
  for (const file of jsonFiles) {
    const content = fs.readJsonSync(file);
    const records = content.records;
    for (const record of records) {
      if (record.RecordType) {
        const sobjectType = record.RecordType.SobjectType;
        if (!recordTypeMap.has(sobjectType)) {
          recordTypeMap.set(sobjectType, new Map());
        }

        const sobjectRecordTypeMap = recordTypeMap.get(sobjectType);
        if (!sobjectRecordTypeMap.has(record.RecordType.DeveloperName)) {
          sobjectRecordTypeMap.set(record.RecordType.DeveloperName, null);
          developerNames.add(record.RecordType.DeveloperName);
        }
      }
    }
  }

  if (recordTypeMap.size === 0) {
    return recordTypeMap;
  }

  const listOfStrings = (arr) => arr.map((el) => `'${el}'`).join(',');

  const query = [
    'SELECT Id, SobjectType, DeveloperName',
    'FROM RecordType',
    `WHERE SobjectType IN (${listOfStrings(Array.from(recordTypeMap.keys()))})`,
    `AND DeveloperName IN (${listOfStrings(Array.from(developerNames.values()))})`
  ].join(' ');

  const result = await conn.query(query);
  for (const record of result.records) {
    const sobjectRecordTypeMap = recordTypeMap.get(record.SobjectType);
    sobjectRecordTypeMap.set(record.DeveloperName, record.Id);
  }

  return recordTypeMap;
};

const replaceRecordTypeIds = async (file, recordTypeMap) => {
  const content = fs.readJsonSync(file);
  const records = content.records;

  let hasReplacedRecordTypeIds = false;
  for (const record of records) {
    if (record.RecordType) {
      if (
        record.RecordType.SobjectType == null ||
        record.RecordType.DeveloperName == null
      ) {
        throw new Error(
          `Expected RecordType to contain both the SobjectType and DeveloperName properties, but it did not. Found ${JSON.stringify(record)}`
        );
      }

      const recordTypeId = recordTypeMap
        .get(record.RecordType.SobjectType)
        .get(record.RecordType.DeveloperName);
      if (recordTypeId == null) {
        throw new Error(
          `Could not find RecordType with SobjectType ${record.RecordType.SobjectType} and DeveloperName ${record.RecordType.DeveloperName}. Processing ${JSON.stringify(record)}`
        );
      }

      delete record.RecordType;
      record.RecordTypeId = recordTypeId;
      hasReplacedRecordTypeIds = true;
    }
  }

  if (hasReplacedRecordTypeIds) {
    await makeBackup(file);
    fs.writeFileSync(file, JSON.stringify(content, null, 2));
  }

  return hasReplacedRecordTypeIds;
};

const prepareDataForImport = async (targetOrg, moduleDir, outputFile) => {
  const project = await SfProject.resolve();
  const dataDir = path.join(project.getPath(), 'data', moduleDir);
  const jsonFiles = await getJsonFiles(dataDir);

  const org = await Org.create({ aliasOrUsername: targetOrg });
  const conn = await org.getConnection();

  const currentUserId = await getCurrentUserId(conn);
  const recordTypeMap = await prepareRecordTypeMap(conn, jsonFiles);

  const modifiedFiles = new Set();
  for (const file of jsonFiles) {
    // eslint-disable-next-line no-await-in-loop
    const hasReplacedUserIds = await replaceUserIds(file, currentUserId);

    // eslint-disable-next-line no-await-in-loop
    const hasReplacedRecordTypeIds = await replaceRecordTypeIds(
      file,
      recordTypeMap
    );

    if (hasReplacedUserIds || hasReplacedRecordTypeIds) {
      modifiedFiles.add(file);
    }
  }

  fs.ensureFileSync(outputFile);
  for (const file of Array.from(modifiedFiles.values())) {
    fs.appendFileSync(outputFile, `${file}\n`);
  }
};

(async () => {
  try {
    const args = process.argv.slice(2);
    if (args.length < 3) {
      console.error(
        'Usage: node prepare-data-for-import.js <target-org> <module-dir> <output-file>'
      );
      process.exit(1);
    }

    const [targetOrg, moduleDir, outputFile] = args;
    await prepareDataForImport(targetOrg, moduleDir, outputFile);
  } catch (e) {
    console.error('Error:', e);
    process.exit(1);
  }
})();
