#!/usr/bin/env node
/* eslint-env node */

'use strict';

import { exec } from 'child_process';
import util from 'util';
import { PackageDirectories } from './utils/PackageDirectories.mjs';
import { ScriptPaths } from './utils/ScriptPaths.mjs';

const execPromise = util.promisify(exec);

/**
 * Updates the manifests for all modules.
 *
 * Usage:
 *   node update-manifests.mjs
 */
(async () => {
  try {
    const packageDirs = await PackageDirectories.listPackageXmls();

    const updateManifestScript = await ScriptPaths.updateManifest();
    const promises = [];
    for (const directory of packageDirs) {
      try {
        console.log(`Updating manifest for ${directory}...`);
        promises.push(execPromise(`${updateManifestScript} ${directory}`));
      } catch (error) {
        console.error(
          `Failed to update manifest for ${directory}: ${error.message}`
        );
      }
    }

    await Promise.all(promises);

    console.log('Running prettier...');
    await execPromise('npx prettier --write "**/package.xml"');
    console.log('Manifests updated successfully.');
  } catch (error) {
    console.error('Error updating manifests:', error.message);
    process.exit(1);
  }
})();
