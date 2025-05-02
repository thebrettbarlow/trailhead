#!/usr/bin/env node
/* eslint-env node */

'use strict';

import { execSync } from 'child_process';
import path from 'path';
import fs from 'fs-extra';

/**
 * Retrieves and moves website metadata for all websites in the websites directory.
 *
 * Usage:
 *   node retrieve-websites.mjs <target-org>
 *
 * @param {string} targetOrg - The target org to retrieve metadata from.
 */

(async () => {
  try {
    const args = process.argv.slice(2);
    if (args.length < 1) {
      console.error('Usage: node retrieve-websites.mjs <target-org>');
      process.exit(1);
    }

    console.log('Retrieving websites...');
    const targetOrg = args[0];

    const rootDir = await getRootDir();
    const websiteDirs = await getWebsiteDirs(rootDir);
    console.log(`Count of websites: ${websiteDirs.length}`);

    await retrieveMetadata(targetOrg);

    const websiteArgs = websiteDirs.map((websiteDir) =>
      prepareToMove(rootDir, websiteDir)
    );

    for (const website of websiteArgs) {
      const { names, sourceDir, targetDir } = website;
      console.log(`Processing ${names.baseName}...`);
      if (sourceDir === targetDir) {
        console.log('Website is already in the target directory.');
        continue;
      }

      const existingTargetMetadataFilePath =
        // eslint-disable-next-line no-await-in-loop
        await getExistingTargetMetadataFilePath(targetDir, names);

      // eslint-disable-next-line no-await-in-loop
      await moveSourceToTarget(sourceDir, targetDir);

      if (existingTargetMetadataFilePath) {
        // eslint-disable-next-line no-await-in-loop
        await revertMetadataFile(existingTargetMetadataFilePath);
      }
    }

    execSync(
      `npx prettier --write "${path.join(rootDir, 'force-app', 'websites')}"`,
      { stdio: 'inherit' }
    );

    await cleanup();
  } catch (e) {
    console.error('Error:', e.message);
    process.exit(1);
  }
})();

async function getRootDir() {
  return execSync('git rev-parse --show-toplevel').toString().trim();
}

async function getWebsiteDirs(rootDir) {
  const websiteDirExclusions = new Set(['common']);

  const websitesPath = path.join(rootDir, 'force-app', 'websites');
  const entries = await fs.readdir(websitesPath, { withFileTypes: true });

  return entries
    .filter(
      (entry) => entry.isDirectory() && !websiteDirExclusions.has(entry.name)
    )
    .map((entry) => entry.name);
}

async function retrieveMetadata(targetOrg) {
  const command = [
    'sf project retrieve start',
    '--ignore-conflicts',
    `--target-org=${targetOrg}`,
    '--metadata=CspTrustedSite',
    '--metadata=CustomSite',
    '--metadata=DigitalExperienceBundle',
    '--metadata=DigitalExperienceConfig',
    '--metadata=ExperienceBundle',
    '--metadata=NavigationMenu',
    '--metadata=Network'
  ].join(' ');

  try {
    execSync(command, { stdio: 'inherit' });
  } catch (error) {
    console.error('Error retrieving metadata:', error.message);
    throw error;
  }
}

function prepareToMove(rootDir, websiteDir) {
  const baseName = path.basename(websiteDir);
  const pascalCase = toPascalCase(baseName);
  const pascalCaseWithUnderscores = toPascalCaseWithUnderscores(baseName);

  const forceAppMainDefault = path.join(
    rootDir,
    'force-app',
    'main',
    'default'
  );
  const forceAppExperiencesDir = path.join(forceAppMainDefault, 'experiences');
  const forceAppDigitalExperiencesDir = path.join(
    forceAppMainDefault,
    'digitalExperiences',
    'site'
  );

  const targetWebsiteDir = path.join(
    rootDir,
    'force-app',
    'websites',
    baseName
  );
  const targetExperiencesDir = path.join(targetWebsiteDir, 'experiences');
  const targetDigitalExperiencesDir = path.join(
    targetWebsiteDir,
    'digitalExperiences',
    'site'
  );

  const possibleDirs = [
    path.join(forceAppExperiencesDir, `${pascalCase}1`),
    path.join(forceAppExperiencesDir, `${pascalCaseWithUnderscores}1`),
    path.join(forceAppDigitalExperiencesDir, `${pascalCase}1`),
    path.join(forceAppDigitalExperiencesDir, `${pascalCaseWithUnderscores}1`),
    path.join(targetExperiencesDir, `${pascalCase}1`),
    path.join(targetExperiencesDir, `${pascalCaseWithUnderscores}1`),
    path.join(targetDigitalExperiencesDir, `${pascalCase}1`),
    path.join(targetDigitalExperiencesDir, `${pascalCaseWithUnderscores}1`)
  ];

  let sourceDir = null;
  for (const dir of possibleDirs) {
    if (fs.existsSync(dir)) {
      sourceDir = dir;
      break;
    }
  }

  if (!sourceDir) {
    throw new Error(`Could not find source directory for ${baseName}`);
  }

  let targetDir = null;
  if (
    sourceDir.startsWith(targetExperiencesDir) ||
    sourceDir.startsWith(targetDigitalExperiencesDir)
  ) {
    targetDir = sourceDir;
  } else {
    targetDir = path.join(
      targetWebsiteDir,
      sourceDir.slice(forceAppMainDefault.length + 1)
    );
  }

  return {
    names: { baseName, pascalCase, pascalCaseWithUnderscores },
    sourceDir,
    targetDir
  };
}

function toPascalCase(name) {
  return name
    .split('-')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join('');
}

function toPascalCaseWithUnderscores(name) {
  return name
    .split('-')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join('_');
}

async function getExistingTargetMetadataFilePath(targetDir, names) {
  const digitalExperienceXml = 'digitalExperience-meta.xml';
  const siteXml = 'site-meta.xml';

  const possibleFiles = [
    path.join(targetDir, `${names.pascalCase}1.${digitalExperienceXml}`),
    path.join(
      targetDir,
      `${names.pascalCaseWithUnderscores}1.${digitalExperienceXml}`
    ),
    path.join(targetDir, `${names.pascalCase}1.${siteXml}`),
    path.join(targetDir, `${names.pascalCaseWithUnderscores}1.${siteXml}`)
  ];

  for (const file of possibleFiles) {
    if (fs.existsSync(file)) {
      return file;
    }
  }

  return null;
}

async function moveSourceToTarget(sourceDir, targetDir) {
  // Start fresh in the target directory
  await fs.remove(targetDir);
  await fs.mkdirp(targetDir);

  // Copy everything from the source directory and then remove it
  await fs.copy(sourceDir, targetDir);
  await fs.remove(sourceDir);
}

async function revertMetadataFile(metadataFilePath) {
  try {
    await execSync(`git checkout -- ${metadataFilePath}`);
  } catch (e) {
    console.error(
      `Warning: Failed to checkout ${metadataFilePath}. This is expected the first time you retrieve metadata for a website.`
    );
  }
}

async function cleanup() {
  // Formatting these to reduce the number of files in the git diff
  await execSync('npx prettier --write "force-app/websites/**/*.{json,xml}"');

  // Removing tags that are hard to deploy
  await execSync(
    'find force-app/websites -name "*.site-meta.xml" -exec sed -i "" "/<siteAdmin>/d" {} \\;'
  );
  await execSync(
    'find force-app/websites -name "*.site-meta.xml" -exec sed -i "" "/<siteGuestRecordDefaultOwner>/d" {} \\;'
  );

  // We set this to `true` in production after deploying domains to the Salesforce CDN
  await execSync(
    'find force-app/websites -name "*.network-meta.xml" -exec sed -i "" "/<enableImageOptimizationCDN>/d" {} \\;'
  );
}
