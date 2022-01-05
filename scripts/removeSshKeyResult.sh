#!/bin/bash
#
# removeSshKeyResult.sh - run by a custom script deployment to
#   1. uses the Azure CLI to delete a Deployment Script resource
#   *. use Bicep's replace() function to
#        inject values wherever resourceGroupNameDefaultValue appears
#        inject values wherever generateSshKeyScriptNameDefaultValue appears

az deployment-scripts delete \
  --resource-group "resourceGroupNameDefaultValue" \
  --name "generateSshKeyScriptName" \
  --yes
  