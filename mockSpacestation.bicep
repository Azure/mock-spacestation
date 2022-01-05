//////////
// CONSTS
//////////

// Administrator Values
var adminUsername = 'azureuser'

// User Assigned Identity Values
var userAssignedIdentityName = 'mockSpacestationIdentity'

// SSH Key Generation Script Values
var generateSshKeyScriptContent = loadTextContent('./scripts/generateSshKey.sh')
var generateSshKeyScriptName = 'generateSshKey'
var removeSshKeyGenResultScriptName = 'removeSshKeyGenResultScript'
var removeSshKeyGenResultScriptContent = loadTextContent('./scripts/removeSshKeyResult.sh')
var removeSshKeyGenScriptWithGroupName = replace(removeSshKeyGenResultScriptContent, 'resourceGroupNameDefaultValue', resourceGroup().name)
var removeSshKeyGenScriptWithGroupNameAndScriptName = replace(removeSshKeyGenScriptWithGroupName, 'generateSshKeyScriptName', generateSshKeyScriptName)

// KeyVault Values
var keyvaultName = toLower('mockisskv${uniqueString(resourceGroup().id)}')
var keyvaultTenantId = subscription().tenantId
var privateKeySecretName = 'sshPrivateKey'
var publicKeySecretName = 'sshPublicKey'

//////////
// PARAMS
//////////

// Groundstation Parameters
@description('The name of the Mock Groundstation Virtual Machine')
param groundstationVirtualMachineName string = 'mockGroundstation'
@description('The region to deploy Mock Groundstation resources into')
param groundstationLocation string = 'eastus'

// Spacestation Parameters
@description('The name of the Mock Spacestation Virtual Machine')
param spacestationVirtualMachineName string = 'mockSpacestation'
@description('The region to deploy Mock Spacestation resources into')
param spacestationLocation string = 'australiaeast'

//////////
// MAIN
//////////

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userAssignedIdentityName
  location: resourceGroup().location    
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: '${guid(resourceGroup().id, userAssignedIdentity.id)}'
  scope: resourceGroup()
  properties: {
    // The 'Contributor' RBAC role definition ID is a hardcoded value:
    // https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor
    roleDefinitionId: '${subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')}'
    principalId: userAssignedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
  dependsOn: [
    userAssignedIdentity
  ]
}

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: keyvaultName
  location: resourceGroup().location
  properties: {
    accessPolicies: []
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: keyvaultTenantId
  }
}

resource generateSshKeyScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: generateSshKeyScriptName
  location: resourceGroup().location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.25.0'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D' // retain script for 1 day
    scriptContent: generateSshKeyScriptContent
    timeout: 'PT30M' // timeout after 30 minutes
  }
}

resource publicKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyvault.name}/${publicKeySecretName}'
  properties: {
    value: generateSshKeyScript.properties.outputs.keyinfo.publicKey
  }
}

resource privateKeySecret 'Microsoft.KeyVault/vaults/secrets@2019-09-01' = {
  name: '${keyvault.name}/${privateKeySecretName}'
  properties: {
    value: generateSshKeyScript.properties.outputs.keyinfo.privateKey
  }
}

module groundstation 'modules/linuxVirtualMachine.bicep' = {
  name: 'mockGroundstationVm'
  params: {
    adminUsername: adminUsername
    location: groundstationLocation
    sshPrivateKey: generateSshKeyScript.properties.outputs.keyinfo.privateKey
    sshPublicKey: generateSshKeyScript.properties.outputs.keyinfo.publicKey
    virtualMachineName: groundstationVirtualMachineName
  }
}

module spacestation 'modules/linuxVirtualMachine.bicep' = {
  name: 'mockSpacestationVm'
  params: {
    adminUsername: adminUsername
    location: spacestationLocation
    hostToSync: groundstation.outputs.hostName
    sshPrivateKey: generateSshKeyScript.properties.outputs.keyinfo.privateKey
    sshPublicKey: generateSshKeyScript.properties.outputs.keyinfo.publicKey
    virtualMachineName: spacestationVirtualMachineName
  }
}

resource removeSshKeyGenResultScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
  name: removeSshKeyGenResultScriptName
  location: resourceGroup().location
  kind: 'AzureCLI'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentity.id}': {}
    }
  }
  properties: {
    azCliVersion: '2.25.0'
    cleanupPreference: 'OnSuccess'
    retentionInterval: 'P1D' // retain script for 1 day
    scriptContent: removeSshKeyGenScriptWithGroupNameAndScriptName
    timeout: 'PT30M' // timeout after 30 minutes
  }
  dependsOn: [ // make sure to run this last
    userAssignedIdentity
    roleAssignment
    keyvault
    generateSshKeyScript
    publicKeySecret
    privateKeySecret
    groundstation
    spacestation
  ]
}

//////////
// OUTPUT
//////////

output groundstationAdminUsername string = adminUsername
output groundstationHostName string = groundstation.outputs.hostName
output keyvaultName string = keyvault.name
output privateKeySecretName string = privateKeySecretName
output spacestationAdminUsername string = adminUsername
output spacestationHostName string = spacestation.outputs.hostName
