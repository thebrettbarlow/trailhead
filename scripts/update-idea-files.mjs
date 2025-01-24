#!/usr/bin/env node
/* eslint-env node */
'use strict';

/**
 * Updates .idea project files for a new project.
 *
 * This script updates the `<module>` entry in `.idea/modules.xml` and creates a new `.iml` file
 * for the specified new project name.
 *
 * Usage:
 *   node update-idea-files.js <new-project-name>
 *
 * @param {string} newProjectName - The new project name to update the .idea files with.
 */

import fs from 'fs';
import path from 'path';
import { parseStringPromise, Builder } from 'xml2js';

const updateIdeaFiles = async (newProjectName) => {
  const projectDir = process.cwd();
  const modulesXmlPath = path.join(projectDir, '.idea', 'modules.xml');
  const existingImlFilePath = path.join(projectDir, '.idea', 'salesforce.iml');
  const newImlFilePath = path.join(
    projectDir,
    '.idea',
    `${newProjectName}.iml`
  );

  // Update .idea/modules.xml
  if (fs.existsSync(modulesXmlPath)) {
    const modulesXmlContent = fs.readFileSync(modulesXmlPath, 'utf-8');

    try {
      let modulesXml = await parseStringPromise(modulesXmlContent);
      modulesXml.project.component[0].modules[0].module[0].$.fileurl = `file://$PROJECT_DIR$/.idea/${newProjectName}.iml`;
      modulesXml.project.component[0].modules[0].module[0].$.filepath = `$PROJECT_DIR$/.idea/${newProjectName}.iml`;

      const builder = new Builder();
      const updatedModulesXml = builder.buildObject(modulesXml);
      fs.writeFileSync(modulesXmlPath, updatedModulesXml, 'utf-8');
      console.log(`Updated ${modulesXmlPath}`);
    } catch (error) {
      console.error(`Error parsing XML: ${error.message}`);
    }
  } else {
    console.error(`File not found: ${modulesXmlPath}`);
  }

  // Create a new .iml file with the new project name by copying the existing .iml content
  if (fs.existsSync(existingImlFilePath)) {
    const imlContent = fs.readFileSync(existingImlFilePath, 'utf-8');
    fs.writeFileSync(newImlFilePath, imlContent, 'utf-8');
    console.log(`Created new ${newImlFilePath}`);

    fs.unlinkSync(existingImlFilePath);
    console.log(`Removed existing ${existingImlFilePath}`);
  } else {
    console.error(`File not found: ${existingImlFilePath}`);
  }
};

// Main execution
(async () => {
  try {
    const newProjectName = process.argv[2];
    if (!newProjectName) {
      console.error(
        'Error: Please provide the new project name as a parameter.'
      );
      process.exit(1);
    }

    await updateIdeaFiles(newProjectName);
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
})();
