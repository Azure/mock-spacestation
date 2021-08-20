// largely inspired by
// https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.compute/virtualMachine-simple-linux/main.bicep

//////////
// CONSTS
//////////

var dnsLabelPrefix = toLower('${virtualMachineName}-${uniqueString(resourceGroup().id)}')
var virtualNetworkName = '${virtualMachineName}VirtualNetwork'
var virtualNetworkAddressPrefix = '10.1.0.0/16'
var subnetName = '${virtualMachineName}Subnet'
var subnetAddressPrefix = '10.1.0.0/24'

var networkSecurityGroupName = '${virtualMachineName}NetworkSecurityGroup'

var virtualMachineNetworkInterfaceName = '${virtualMachineName}NetworkInterface'
var virtualMachinePublicIPAddressName = '${virtualMachineName}publicIPAddress'

var destinationScript = replace(loadTextContent('../scripts/configureDestination.sh'), 'privateKeyDefaultValue', sshPrivateKey)

var sourceScriptWithDestination = replace(loadTextContent('../scripts/configureSource.sh'), 'hostToSyncDefaultValue', hostToSync)
var sourceScriptWithDestinationSource = replace(sourceScriptWithDestination, 'virtualMachineNameDefaultValue', virtualMachineName)
var sourceScriptWithDestinationSourceKey = replace(sourceScriptWithDestinationSource, 'privateKeyDefaultValue', sshPrivateKey)

//////////
// PARAMS
//////////

@description('The location to deploy your Virtual Machine')
param location string = resourceGroup().location

@description('The administrator username for your Virtual Machine')
param adminUsername string = 'azureuser'

@description('The hostname of the machine to configure rsync to')
param hostToSync string = ''

@description('The private key for SSH access to other Virtual Machines in this deployment')
@secure()
param sshPrivateKey string

@description('The public key for SSH access to this Virtual Machine')
@secure()
param sshPublicKey string

@description('The version of Ubuntu to use for your Virtual Machine')
param ubuntuOSVersion string = '18.04-LTS'

@description('The name of your Virtual Machine')
param virtualMachineName string

@description('The size of your Virtual Machine')
param virtualMachineSize string = 'Standard_B2s'

@description('The disk to use for your Virtual Machine')
param osDiskType string = 'Standard_LRS'

//////////
// MAIN
//////////

resource networkInterface 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: virtualMachineNetworkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  parent: virtualNetwork
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: virtualMachinePublicIPAddressName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: adminUsername
      adminPassword: sshPublicKey
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
    }
  }
}

resource configureDestination 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = if(empty(hostToSync)) {
  parent: virtualMachine
  name: 'configureDestination'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
       script: base64(destinationScript)
    }
  }
}

resource configureSource 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = if(!empty(hostToSync)) {
  parent: virtualMachine
  name: 'configureSource'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
       script: base64(sourceScriptWithDestinationSourceKey)
    }
  }
}

output adminUsername string = adminUsername
output hostName string = publicIPAddress.properties.dnsSettings.fqdn
output sshCommand string = 'ssh ${adminUsername}@${publicIPAddress.properties.dnsSettings.fqdn}'
