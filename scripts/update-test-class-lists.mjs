#!/usr/bin/env node
/* eslint-env node */

'use strict';

/**
 * Updates the lists of test classes for all modules.
 *
 * This is needed because we identify tests classes by querying for their SymbolTable and checking if
 * it contains `@IsTest` annotated methods. During a deployment, these will not be present in the
 * target org until the deployment has completed. We use this to keep an up-to-date list of test
 * classes that can be used during deployments.
 *
 * This works because we can list test classes based on the metadata in the org we were developing in.
 *
 * Usage:
 *   update-test-class-lists.mjs <target-org>
 */

import util from 'util';
import { exec } from 'child_process';
import { ScriptPaths } from './utils/ScriptPaths.mjs';
import { PackageDirectories } from './utils/PackageDirectories.mjs';
import { SfProject } from '@salesforce/core';
import fs from 'fs';
import pLimit from 'p-limit';

const execPromise = util.promisify(exec);

const usage = () => {
  console.error('Usage: node update-test-class-lists.mjs <target-org>');
  process.exit(1);
};

(async () => {
  try {
    const args = process.argv.slice(2);
    if (args.length !== 1) {
      usage();
    }

    const targetOrg = args[0];
    const project = await SfProject.resolve();
    const rootDir = project.getPath();

    const packageDirs = await PackageDirectories.listPackageXmls();
    const listApexTestsScript = await ScriptPaths.listApexTests();

    // TODO: debug and see if we can run these in parallel
    // Each time we try to make calls to the tooling api in parallel, some query
    // results return empty and others return the list of classes
    const limit = pLimit(1);

    const promises = packageDirs.map((directory) =>
      limit(async () => {
        try {
          console.log(`Updating test class list for ${directory}...`);

          const manifestPath = `${rootDir}/${directory}/package.xml`;
          const outputPath = `${rootDir}/${directory}/test-classes.json`;

          const { stdout, stderr } = await execPromise(
            `node ${listApexTestsScript} ${manifestPath} ${targetOrg} json`
          );

          if (stderr) {
            console.error(`stderr: ${stderr}`);
            return;
          }

          fs.writeFileSync(outputPath, stdout);
        } catch (error) {
          console.error(
            `Error updating test class list for ${directory}: ${error.message}`
          );
        }
      })
    );

    await Promise.all(promises);

    console.log('Running prettier...');
    await execPromise('npx prettier --write "**/test-classes.json"');
    console.log('Test class lists updated successfully.');
  } catch (error) {
    console.error('Error updating test class lists:', error.message);
    process.exit(1);
  }
})();
