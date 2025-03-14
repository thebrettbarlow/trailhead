#!/usr/bin/env node
/* eslint-env node */

'use strict';

import puppeteer from 'puppeteer';
import fs from 'fs-extra';
import path from 'path';
import { Org, SfProject } from '@salesforce/core';

/**
 * Configures page layout assignments for the given Salesforce org.
 *
 * Usage:
 *   node configure-page-layout-assignments.mjs <orgAlias>
 *
 * @param {string} orgAlias - The alias of the Salesforce org.
 */
(async (orgAlias) => {
  if (!orgAlias) {
    throw new Error(
      'Org alias is required. Please pass it as a command-line argument.'
    );
  }

  try {
    const org = await Org.create({ aliasOrUsername: orgAlias });
    const conn = await org.getConnection();
    const project = await SfProject.resolve();

    const timeout = 1000 * 60 * 5; // 5 minutes (slow internet, etc.)
    const browser = await puppeteer.launch({
      headless: false,
      userDataDir: './browser-user-data',
      defaultViewport: null,
      timeout,
      slowMo: 100
    });

    const cookies = await fs.readJson(
      path.join(project.getPath(), 'browser-user-data', 'cookies.json')
    );
    await browser.setCookie(...cookies);

    const page = await browser.newPage();
    page.setDefaultTimeout(timeout);
    page.setDefaultNavigationTimeout(timeout);

    console.log('Opening Salesforce...');
    const frontdoor = `${conn.instanceUrl}/secur/frontdoor.jsp?sid=${conn.accessToken}`;
    await page.goto(frontdoor, { waitUntil: 'networkidle2' });

    // TODO: get the sobject name from a config
    const sobjectName = 'SF_Doc__c';
    const query = `SELECT Id
                   FROM CustomObject
                   WHERE DeveloperName = '${sobjectName.replace('__c', '')}'`;
    const result = await conn.tooling.query(query);
    const sobjectId = result.records[0].Id;

    // Waiting for the Home tab to load
    await page.waitForSelector('a[title="Home"]');

    console.log('Editing Page Layout Assignments...');
    const pageLayoutUrl = `${conn.instanceUrl}/lightning/setup/ObjectManager/${sobjectId}/PageLayouts/view`;
    await page.goto(pageLayoutUrl, { waitUntil: 'networkidle2' });

    const buttonSelector = 'div.slds-button-group button:nth-child(2)';
    await page.waitForSelector(buttonSelector, { visible: true });
    await page.click(buttonSelector);

    const frameElement = await page.waitForSelector('iframe', {
      timeout
    });
    const frame = frameElement ? await frameElement.contentFrame() : null;

    if (!frame) {
      console.error(
        'Failed to switch to iframe context in the Page Layout Assignments page.'
      );
      process.exit(1);
    }

    const editButtonSelector = 'input[title="Edit Assignment"]';
    await frame.waitForSelector(editButtonSelector, {
      visible: true,
      timeout
    });
    await frame.click(editButtonSelector);

    // TODO: get the record type name from a config
    const recordTypeName = 'Revision';
    const tableHeaderSelector = `th div[title="${recordTypeName}"]`;
    await frame.waitForSelector(tableHeaderSelector, {
      visible: true,
      timeout
    });

    // <span class="plaSelector" id="pageLayoutSelectorSpan">
    // <select id="pageLayoutSelector" name="pageLayoutSelector" onchange="layoutMapping.onChangePLA(this);">
    // <option selected="selected" value="000000000000000">-- Select Page Layout --</option>
    // <option value="00hRK0000086n4m">Primary Layout</option>
    // <option value="00hRK0000086n4n">Revision Layout</option>
    // </select>
    // </span>

    // TODO: get the page layout name from a config
    const pageLayoutName = 'Revision Layout';
    const dropdownSelector = '#pageLayoutSelector';
    const dropdown = await frame.waitForSelector(dropdownSelector, {
      visible: true,
      timeout
    });

    // Find the option element with the matching text content
    const option = await frame.$(`option[value][text="${pageLayoutName}"]`);

    // If the option is found, set the dropdown value directly
    if (option) {
      await frame.evaluate(
        (d, o) => {
          d.value = o.value;
          d.dispatchEvent(new Event('change'));
        },
        dropdown,
        option
      );
    } else {
      console.error(`Option with text "${pageLayoutName}" not found.`);
    }

    const saveButtonSelector = 'input[title="Save"]';
    console.log('Saving Page Layout Assignments...');
    await frame.waitForSelector(saveButtonSelector, { visible: true });
    await frame.click(saveButtonSelector);

    console.log('Done.');
    await browser.close();
  } catch (error) {
    console.error('Error:', error);
  }
})(process.argv[2]);
