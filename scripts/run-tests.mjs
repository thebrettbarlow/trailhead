#!/usr/bin/env node
/* eslint-env node */

'use strict';

import { exec } from 'child_process';
import util from 'util';
import { ScriptPaths } from './utils/ScriptPaths.mjs';

const execPromise = util.promisify(exec);

/**
 * Runs all tests in all modules.
 *
 * Usage:
 *   node run-tests.mjs <target-org>
 */

const usage = () => {
  console.log('Usage: node run-tests.mjs <target-org>');
  process.exit(1);
};

const validateParams = (targetOrg) => {
  if (!targetOrg) {
    console.error("Error: First parameter 'target-org' is required.");
    usage();
  }
};

(async () => {
  const args = process.argv.slice(2);
  if (args.length < 1) {
    usage();
  }
  const targetOrg = args[0];
  validateParams(targetOrg);

  const apexTestOperatorScript = await ScriptPaths.apexTestOperator();
  const modules = ['common', 'force-app'];
  let hasFailures = false;

  await Promise.all(
    modules.map(async (module) => {
      console.log(`Running tests in ${module}...`);

      try {
        const { stdout, stderr } = await execPromise(
          `${apexTestOperatorScript} ${targetOrg} ${module} run`
        );

        console.log(stdout);
        if (stderr) {
          console.error(stderr);
        }

        // Check if test output contains failure indicators
        // Parsing the error string so that we can still display the table from
        // `sf apex test run`
        if (
          stdout.includes('Outcome              Failed') ||
          stdout.includes('Fail     ')
        ) {
          hasFailures = true;
        }

        console.log(`Tests in ${module} completed.`);
      } catch (error) {
        hasFailures = true;
        console.error(`Error running tests in ${module}:`);
        if (error.stdout) console.log(error.stdout);
        if (error.stderr) console.error(error.stderr);
      }
    })
  );

  if (hasFailures) {
    console.error('Test run failed.');
    process.exit(1);
  }
})().catch((err) => {
  console.error('Error running tests:', err);
  process.exit(1);
});
