#!/usr/bin/env node
/* eslint-env node */

'use strict';

import util from 'util';
import { exec } from 'child_process';
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

  // TODO: add modules here
  const modules = ['common', 'force-app'];

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

        console.log(`Tests in ${module} completed.`);
      } catch (error) {
        console.error(`Error running tests in ${module}:`, error);
      }
    })
  );
})().catch((err) => {
  console.error('Error running tests:', err);
  process.exit(1);
});
