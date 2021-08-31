#!/bin/bash
#
# shellcheck disable=SC2207
# SC2207: Prefer mapfile or read -a to split command output (or quote to avoid splitting).
#         Disabled because we want to split on newlines from deployment output
#
# getConnections.sh - retrieves output from a mockSpacestation.bicep deployment
#   and grants the current user the 'get list' KeyVault secrets access policies
#   and writes the private key to a local file
#   and prints SSH commands to connect to the virtual machines

set -e

error_log() {
  local message="$1"
  echo "ERROR: $1!" 1>&2;
}

info_log() {
  local message="$1"
  echo "INFO: $message..."
}

# Check for Azure CLI
if ! command -v az &> /dev/null; then
    error_log "az could not be found. This script requires the Azure CLI."
    info_log "see https://docs.microsoft.com/en-us/cli/azure/install-azure-cli for installation instructions."
    exit 1
fi

# parse arguments
if [[ "$#" -lt 2 ]]; then
   echo "getConnections.sh: retrieves output from a mockSpacestation.bicep deployment and grants the current user the 'get list' KeyVault secrets access policies, writes the private key to a local file, and prints SSH commands to connect to the virtual machines"
   echo "usage: getConnections.sh <resourceGroupName> <deploymentName>"
   exit 1
fi

resourceGroupName="$1"
deploymentName="$2"

privateKeyFileName="mockSpacestationPrivateKey"
userObjectId=$(az ad signed-in-user show --query objectId --output tsv)

# get deployment output
info_log "Querying outputs from deployment $deploymentName into resource group $resourceGroupName"
outputs=($(az deployment group show \
  --name "$deploymentName" \
  --resource-group "$resourceGroupName" \
  --query \
    "[ \
      properties.outputs.groundstationAdminUsername.value, \
      properties.outputs.groundstationHostName.value, \
      properties.outputs.keyvaultName.value, \
      properties.outputs.privateKeySecretName.value, \
      properties.outputs.spacestationAdminUsername.value, \
      properties.outputs.spacestationHostName.value \
    ]" \
  --output "tsv"))

# assign values from outputs
groundstationAdminUsername=${outputs[0]}
groundstationHostName=${outputs[1]}
keyvaultName=${outputs[2]}
privateKeySecretName=${outputs[3]}
spacestationAdminUsername=${outputs[4]}
spacestationHostName=${outputs[5]}

# add the secret permissions for the user
info_log "Adding secret policies for current user $userObjectId"
az keyvault set-policy \
  --name "$keyvaultName" \
  --secret-permissions get list \
  --object-id "$userObjectId" \
  --only-show-errors \
  --output "none"

# write the private key to the specified file
info_log "Writing $privateKeySecretName to file $privateKeyFileName"
rm -f "$privateKeyFileName"
az keyvault secret show \
  --vault-name "$keyvaultName" \
  --name "$privateKeySecretName" \
  --query "value" \
  --output "tsv" >> "$privateKeyFileName"

# set the perms on the private key
info_log "Setting permissions on $privateKeySecretName to allow SSH"
chmod 600 "$privateKeyFileName"
  
# echo out the SSH command
info_log "Success! Private key written to ./$privateKeyFileName. Run these commands to SSH into your machines"
echo "ssh -i $privateKeyFileName $groundstationAdminUsername@$groundstationHostName"
echo "ssh -i $privateKeyFileName $spacestationAdminUsername@$spacestationHostName"
