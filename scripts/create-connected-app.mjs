import { Org } from '@salesforce/core';
import fs from 'fs';
import path from 'path';
import os from 'os';
import { execSync } from 'child_process';
import archiver from 'archiver';
import crypto from 'crypto';
import { Octokit } from '@octokit/rest';
import sodium from 'libsodium-wrappers';

// TODO: checklist
//  - get auth to work - having trouble providing expected inputs
//  - create permission set with connected app metadata
//  - assign permission set to user
//  - verify connected app auth settings (IP restrictions, etc.) work

// Configuration
const config = {
  connectedAppName: 'GitHubConnectedApp',
  description: 'Connected App for GitHub Actions Integration',
  contactEmail: 'contact@yourdomain.dev',
  callbackUrl: 'http://localhost',
  oauthScopes: ['Api', 'RefreshToken'],
  consumerKey: '', // Dynamically populated
  certDir: path.join(os.homedir(), '.sf', 'certificates'),
  certValidityDays: 365,
  githubRepo: 'test', // Replace with your GitHub repository name
  githubOwner: 'truehands' // Replace with your GitHub username or org
};

// Certificate and key paths
const keyPath = path.join(config.certDir, 'server.key');
const certPath = path.join(config.certDir, 'server.crt');

// Metadata paths
const metadataDir = path.join(process.cwd(), 'metadata');
const connectedAppDir = path.join(metadataDir, 'connectedApps');
const connectedAppFile = path.join(
  connectedAppDir,
  `${config.connectedAppName}.connectedApp-meta.xml`
);

// Helper: Generate GitHub PAT using `gh`
function getGithubToken() {
  try {
    return execSync('gh auth token', { encoding: 'utf-8' }).trim();
  } catch (error) {
    throw new Error(
      'Failed to retrieve a GitHub token. Make sure you are logged in with `gh auth login`.'
    );
  }
}

// Helper: Create/Update GitHub Repository Secret
async function createGithubSecret(secretName, secretValue) {
  const octokit = new Octokit({ auth: getGithubToken() });

  // Fetch the public repository key
  const { data: publicKey } = await octokit.actions.getRepoPublicKey({
    owner: config.githubOwner,
    repo: config.githubRepo
  });

  // Encrypt the secret using the repository's public key
  await sodium.ready;
  const encryptedSecret = sodium.to_base64(
    sodium.crypto_box_seal(
      sodium.from_string(secretValue),
      sodium.from_base64(publicKey.key, sodium.base64_variants.ORIGINAL)
    ),
    sodium.base64_variants.ORIGINAL
  );

  // Save/Update the repository secret
  await octokit.actions.createOrUpdateRepoSecret({
    owner: config.githubOwner,
    repo: config.githubRepo,
    secret_name: secretName,
    encrypted_value: encryptedSecret,
    key_id: publicKey.key_id
  });

  console.log(`Successfully set secret: ${secretName}`);
}

async function generateCertificate() {
  console.log('Generating certificate and private key.');

  // Create certificate directory
  if (!fs.existsSync(config.certDir)) {
    fs.mkdirSync(config.certDir, { recursive: true });
  }

  // prettier-ignore
  const openSslCommand = [
    'req', '-new', '-newkey', 'rsa:2048', '-sha256',
    '-days', config.certValidityDays,
    '-nodes',
    '-x509',
    '-keyout', keyPath,
    '-out', certPath,
    '-subj', '/C=US/ST=State/L=City/O=Organization/OU=Unit/CN=yourdomain.dev'
  ];

  try {
    execSync(`openssl ${openSslCommand.join(' ')} > /dev/null 2>&1`);
    console.log('Certificate and private key created successfully.');

    // Adjust file permissions on Unix/Linux
    if (process.platform !== 'win32') {
      fs.chmodSync(keyPath, '600');
      fs.chmodSync(certPath, '644');
    }

    return true;
  } catch (error) {
    console.error('Error generating certificate:', error.message);
    return false;
  }
}

function generateConsumerKey(orgId) {
  const cleanOrgId = orgId.replace(/[^a-zA-Z0-9]/g, '');
  const randomBytes = crypto.randomBytes(16).toString('hex');
  const timestamp = Date.now().toString(16);
  return `${cleanOrgId}${timestamp}${randomBytes}`.slice(0, 256);
}

function createZipMetadata(xmlContent, packageXmlContent) {
  return new Promise((resolve, reject) => {
    const archive = archiver('zip', { zlib: { level: 9 } });
    const chunks = [];

    archive.on('data', (chunk) => chunks.push(chunk));
    archive.on('end', () => resolve(Buffer.concat(chunks)));
    archive.on('error', (err) => reject(err));

    archive.append(xmlContent, {
      name: `connectedApps/${config.connectedAppName}.connectedApp-meta.xml`
    });
    archive.append(packageXmlContent, { name: 'package.xml' });
    archive.finalize();
  });
}

async function createConnectedApp() {
  try {
    // Step 1: Generate certificate
    const certGenerated = await generateCertificate();
    if (!certGenerated) {
      throw new Error('Failed to generate certificate.');
    }

    const certificateContents = fs.readFileSync(certPath, 'utf-8');

    // Step 2: Authenticate with Salesforce
    const org = await Org.create({ aliasOrUsername: 'example--scratch' });
    const conn = org.getConnection();
    config.consumerKey = generateConsumerKey(org.getOrgId());
    console.log('start');
    console.log(`generated: ${config.consumerKey}`);
    console.log('end');

    // Step 3: Prepare Connected App Metadata XML
    const connectedAppXml = `
<?xml version="1.0" encoding="UTF-8"?>
<ConnectedApp xmlns="http://soap.sforce.com/2006/04/metadata">
  <label>${config.connectedAppName}</label>
  <description>${config.description}</description>
  <contactEmail>${config.contactEmail}</contactEmail>
  <oauthConfig>
    <callbackUrl>${config.callbackUrl}</callbackUrl>
    <consumerKey>${config.consumerKey}</consumerKey>
    ${config.oauthScopes.map((scope) => `<scopes>${scope}</scopes>`).join('\n    ')}
    <certificate>${certificateContents.trim()}</certificate>
  </oauthConfig>
</ConnectedApp>
`.trim();

    fs.mkdirSync(connectedAppDir, { recursive: true });
    fs.writeFileSync(connectedAppFile, connectedAppXml, 'utf-8');

    // Step 4: Prepare Package.xml
    const packageXml = `
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types>
    <members>${config.connectedAppName}</members>
    <name>ConnectedApp</name>
  </types>
  <version>52.0</version>
</Package>
`.trim();
    const packageXmlPath = path.join(metadataDir, 'package.xml');
    fs.writeFileSync(packageXmlPath, packageXml, 'utf-8');

    // Step 5: Create deployment package
    console.log('Creating deployment package...');
    const zipBuffer = await createZipMetadata(connectedAppXml, packageXml);

    // Step 6: Deploy Metadata
    console.log('Deploying Connected App metadata...');
    const deployResult = await conn.metadata.deploy(zipBuffer, {
      singlePackage: true,
      checkOnly: false
    });

    let isDone = false;
    let errorMessage = '';
    while (!isDone) {
      const deployStatus = await conn.metadata.checkDeployStatus(
        deployResult.id,
        true
      );
      isDone = deployStatus.done;
      errorMessage = deployStatus.errorMessage;
    }

    if (errorMessage) {
      throw new Error(`Deployment failed: ${errorMessage}`);
    }

    console.log(
      `Connected App "${config.connectedAppName}" deployed successfully!`
    );

    // Step 7: Store Secrets in GitHub
    await createGithubSecret(
      'SFDC_CONSUMER_KEY',
      config.consumerKey
        .trim() // Remove leading/trailing whitespace
        .replace(/\r\n/g, '\n') // Normalize line endings to \n
    );
    await createGithubSecret(
      'SFDC_SERVER_KEY',
      fs
        .readFileSync(keyPath, 'utf-8')
        .trim() // Remove leading/trailing whitespace
        .replace(/\r\n/g, '\n') // Normalize line endings to \n
    );
    await createGithubSecret('SFDC_USERNAME', org.getUsername());
    await createGithubSecret('SFDC_INSTANCE_URL', conn.instanceUrl);

    console.log('GitHub secrets set successfully.');
  } catch (error) {
    console.error('Error:', error.message);
    process.exit(1);
  }
}

// Run the script
createConnectedApp();
