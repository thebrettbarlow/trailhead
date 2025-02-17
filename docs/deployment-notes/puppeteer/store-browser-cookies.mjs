#!/usr/bin/env node
/* eslint-env node */

'use strict';

import puppeteer from 'puppeteer';
import fs from 'node:fs/promises';
import { Org, SfProject } from '@salesforce/core';
import path from 'path';

/**
 * Stores browser cookies for the given Salesforce org.
 *
 * Usage:
 *   node store-browser-cookies.mjs <orgAlias>
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

    const browser = await puppeteer.launch({
      headless: false,
      userDataDir: './browser-user-data'
    });
    const page = await browser.newPage();

    await page.goto(conn.instanceUrl);

    // Waiting for the Home tab to load. This has it wait until we log in manually
    await page.waitForSelector('a[title="Home"]', {
      timeout: 1000 * 60 * 10 // 10 minutes (takes a while for the verification code sometimes)
    });
    console.log('Logged in to Salesforce successfully.');

    await fs.writeFile(
      path.join(project.getPath(), 'browser-user-data', 'cookies.json'),
      JSON.stringify(await browser.cookies(), null, 2)
    );
    console.log('Cookies saved.');

    await browser.close();
  } catch (error) {
    console.error('Error:', error);
  }
})(process.argv[2]);
