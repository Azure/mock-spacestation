// az deployment group create --template-file AzureVM.bicep --resource-group "test_group"
// az bicep build --file .\AzureVM.bicep --outfile .\AzureVM.json

@description('The name of the Virtual Machine')
param vmName string = 'mockGroundstation'

@description('The authentication type for the Virtual Machine (SSH Key is recommended)')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH key or password for the Virtual Machine (SSH key is recommended)')
param adminPasswordOrKey string

@description('Create a Public IP Address for the Virtual Machine?')
param includePublicIP bool = true

@description('The size of the Virtual Machine')
@allowed([
  'Standard_B2s'
  'Standard_B4ms'
  'Standard_B8ms'
  'Standard_B16ms'
  'Standard_B20ms'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
])
param vmSize string = 'Standard_D8s_v3'

@description('Reuse an existing virtual network?')
param useExistingNetwork bool = false

@description('The Virtual Network name for the Virtual Machine (e.g. groundstation-vnet)')
param virtualNetworkName string

@description('The Virtual Subnet name for the Virtual Machine (e.g. groundstation-subnet)')
param subnetName string

@description('The Network Security Name Group (new or existing) for the Virtual Machine (e.g. groundstation-nsg)')
param networkSecurityGroupName string

var location = resourceGroup().location

var adminUsername = 'azureuser'

var publicIPAddressName = '${vmName}PublicIP'

var networkInterfacePublicIPName = '${vmName}PubNetInt'

var networkInterfacePrivateIPName = '${vmName}PrivNetInt'

var osDiskType = 'Standard_LRS'

var virtualNetworkAddressPrefix = '10.1.0.0/16'

var subnetAddressPrefix = '10.1.0.0/24'

var dnsLabelPrefix = toLower('${vmName}-${uniqueString(resourceGroup().id)}')

var ubuntuOSVersion = '18.04-LTS'

// workaround for https://github.com/Azure/bicep/issues/449
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' existing = if(useExistingNetwork) {
  name: virtualNetworkName
}

resource existingSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' existing = if(useExistingNetwork) {
  parent: existingVirtualNetwork
  name: subnetName
}

resource existingNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-06-01' existing = if(useExistingNetwork) {
  name: networkSecurityGroupName
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-06-01' = if(!useExistingNetwork) {
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

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = if(!useExistingNetwork) {
  parent: virtualNetwork
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2020-06-01' = if(!useExistingNetwork) {
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

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = if (includePublicIP) {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

resource nicWithPublicIP 'Microsoft.Network/networkInterfaces@2020-06-01' = if (includePublicIP) {
  name: networkInterfacePublicIPName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: (useExistingNetwork) ? existingSubnet.id : subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: (useExistingNetwork) ? existingNetworkSecurityGroup.id : networkSecurityGroup.id
    }
  }
}

resource nicWithPrivateIP 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfacePrivateIPName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: (useExistingNetwork) ? existingSubnet.id : subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: (useExistingNetwork) ? existingNetworkSecurityGroup.id : networkSecurityGroup.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
        diskSizeGB: 120
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
          id: (includePublicIP) ? nicWithPublicIP.id : nicWithPrivateIP.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: any(authenticationType == 'password' ? null : linuxConfiguration)
      customData: loadFileAsBase64('./.devcontainer/library-scripts/BareVMSetup.sh')
    }
  }
}

resource shutdownComputeVm 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '23:00'
    }
    timeZoneId: 'Eastern Standard time'
    targetResourceId: vm.id
  }
}

output administratorUsername string = adminUsername
output hostname string = includePublicIP ? publicIP.properties.dnsSettings.fqdn : vmName
output sshCommand string = includePublicIP ? 'ssh ${adminUsername}@${publicIP.properties.dnsSettings.fqdn}' : 'ssh ${adminUsername}@${nicWithPrivateIP.properties.ipConfigurations[0].properties.privateIPAddress}'
