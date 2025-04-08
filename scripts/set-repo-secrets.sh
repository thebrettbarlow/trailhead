#!/usr/bin/env bash

# Configuration
repo="truehands/platform"
cert_dir="/etc/ssl/private"
key_path="${cert_dir}/server.key"
cert_path="${cert_dir}/server.crt"
xml_file_path="force-app/github/connectedApps/GitHub_Actions_Integration.connectedApp-meta.xml"

# Ensure the script is run as root
if [[ "$EUID" -ne 0 ]]; then
  echo "This script must be run as root. Please use sudo."
  exit 1
fi

# Check if the gh CLI is installed
if ! command -v gh &> /dev/null; then
  echo "The gh CLI is not installed. Please install it from https://cli.github.com/."
  exit 1
fi

# Function to clean up generated files
cleanup() {
  echo "Cleaning up generated files..."
  sudo rm -f "${key_path}" "${cert_path}"
  echo "Cleanup complete."
}

# Ensure the cleanup function is called on exit
trap cleanup EXIT

# Create certificate directory if it doesn't exist
if [[ ! -d "${cert_dir}" ]]; then
  sudo mkdir -p "${cert_dir}"
  sudo chmod 700 "${cert_dir}"
  echo "Created certificate directory ${cert_dir}"
fi

# OpenSSL command to generate certificate and private key
openssl_cmd="openssl req -new -newkey rsa:2048 -sha256 \
  -days 365 \
  -nodes \
  -x509 \
  -keyout ${key_path} \
  -out ${cert_path} \
  -subj /C=US/ST=State/L=City/O=Organization/OU=Unit/CN=yourdomain.dev"

# Execute the OpenSSL command and suppress output
if eval "sudo ${openssl_cmd} > /dev/null 2>&1"; then
  echo "Certificate and private key created successfully."
else
  echo "Error generating certificate."
  exit 1
fi

# Adjust file permissions
sudo chmod 600 "${key_path}"
sudo chmod 644 "${cert_path}"

# Verify file creation
if [[ -f "${key_path}" && -f "${cert_path}" ]]; then
  echo "Private key path: ${key_path}"
  echo "Certificate path: ${cert_path}"
else
  echo "Error: Certificate or key file not created."
  exit 1
fi

# Read the server.key file
server_key=$(sudo cat "${key_path}")

# Update the certificate in the XML file
certificate_content=$(sudo sed -e '/^-----BEGIN CERTIFICATE-----$/d' -e '/^-----END CERTIFICATE-----$/d' "${cert_path}" | tr -d '\n')

# Determine the root directory of the git repository
root_dir=$(git rev-parse --show-toplevel)

# Ensure the root_dir command succeeded
if [[ $? -ne 0 ]]; then
  echo "Error: Not a git repository."
  exit 1
fi

# Construct the full path to the XML file
xml_file="${root_dir}/${xml_file_path}"

# Check if the XML file exists
if [[ ! -f "${xml_file}" ]]; then
  echo "Error: XML file not found at ${xml_file}."
  exit 1
fi

# Update the certificate in the XML file using awk for better multiline support
sudo awk -v cert="${certificate_content}" '
BEGIN { cert_block = "<certificate>" cert "</certificate>" }
/<certificate>.*<\/certificate>/ {
    sub(/<certificate>.*<\/certificate>/, cert_block)
}
{ print }
' "${xml_file}" > "${xml_file}.tmp" && sudo mv "${xml_file}.tmp" "${xml_file}"

# Change the file ownership to the current user
sudo chown "$(whoami)" "${xml_file}"

# Change the file permissions to allow manual editing
chmod u+w "${xml_file}"

echo "Updated certificate in ${xml_file}"
echo "Permissions updated to allow manual editing."

# Function to set a GitHub secret
set_secret() {
  local secret_name=$1
  local secret_value=$2
  echo "${secret_value}" | gh secret set "${secret_name}" -R "${repo}"
  if [[ $? -ne 0 ]]; then
    echo "Failed to set secret ${secret_name}"
    exit 1
  else
    echo "Secret ${secret_name} set successfully"
  fi
}

# Set the secrets
set_secret "SFDC_CLIENT_ID" "3MVG9FINO1nsxRuBoEuWPUQeBe1Du7fvvl6nBFBX4LIxAp2CQ0go451OHAtRcJh7NHeEQ9PiRoH555ILqmkQm"
set_secret "SFDC_SERVER_KEY" "${server_key}"
set_secret "SFDC_USERNAME" "github@truehands.dev"
set_secret "SFDC_INSTANCE_URL" "https://truehands.my.salesforce.com"

echo "All secrets have been set successfully."
