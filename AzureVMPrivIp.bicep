// az deployment group create --template-file AzureVM.bicep --resource-group "test_group"
// az bicep build --file .\AzureVM.bicep --outfile .\AzureVM.json

@description('The name of the new virtual machine')
param vmName string = 'mockGroundstation'

// Type of authentication to use on the Virtual Machine. SSH key is recommended.

@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH key or password for the Virtual Machine. SSH key is recommended.')
param adminPassword string

var ubuntuOSVersion = '18.04-LTS'

// Location for all resources.
//var location = resourceGroup().location
@allowed([
  'East US'
  'East US 2'
  'South Central US'
  'West US 2'
  'West US 3'
  'Australia East'
  'Southeast Asia'
  'North Europe'
  'Sweden Central'
  'UK South'
  'West Europe'
  'Central US'
  'North Central US'
  'West US'
  'South Africa North'
  'Central India'
  'East Asia'
  'Japan East'
  'Jio India West'
  'Korea Central'
  'Canada Central'
  'France Central'
  'Germany West Central'
  'Norway East'
  'Switzerland North'
  'UAE North'
  'Brazil South'
  'Central US (Stage)'
  'East US (Stage)'
  'East US 2 (Stage)'
  'North Central US (Stage)'
  'South Central US (Stage)'
  'West US (Stage)'
  'West US 2 (Stage)'
  'Asia'
  'Asia Pacific'
  'Australia'
  'Brazil'
  'Canada'
  'Europe'
  'Global'
  'India'
  'Japan'
  'United Kingdom'
  'United States'
  'East Asia (Stage)'
  'Southeast Asia (Stage)'
  'Central US EUAP'
  'East US 2 EUAP'
  'West Central US'
  'South Africa West'
  'Australia Central'
  'Australia Central 2'
  'Australia Southeast'
  'Japan West'
  'Jio India Central'
  'Korea South'
  'South India'
  'West India'
  'Canada East'
  'France South'
  'Germany North'
  'Norway West'
  'Sweden South'
  'Switzerland West'
  'UK West'
  'UAE Central'
  'Brazil Southeast'  
])
@description('Azure Data region to deploy the VM to')
param targetRegion string = 'East US 2'

// The size of the VM.
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

@description('The Virtual Network name (new or existing) for the GroundStation VM')
param virtualNetworkName string = 'spacestation-vnet'

@description('The Virtual Subnet name (new or existing) for the GroundStation VM')
param subnetName string = 'spacestation-subnet'

// Name of the Network Security Group.
@description('The Network Security Name (new or existing) for the GroundStation VM')
param networkSecurityGroupName string = 'spacestationNSG'

var adminUsername = 'azureuser'
var networkInterfacePrivateIPName = '${vmName}PrivNetInt'
var osDiskType = 'Standard_LRS'

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPassword
      }
    ]
  }
}

resource nicWithPrivateIP 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfacePrivateIPName
  location: targetRegion
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          privateIPAllocationMethod: 'Dynamic'         
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId(resourceGroup().name, 'Microsoft.Network/networkSecurityGroups', networkSecurityGroupName)
    }
  }
  dependsOn: [
    nsg
  ]
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' existing = {
  name: networkSecurityGroupName
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: virtualNetworkName  
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: targetRegion
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
          id: nicWithPrivateIP.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: any(authenticationType == 'password' ? null : linuxConfiguration) // TODO: workaround for https://github.com/Azure/bicep/issues/449
      customData: loadFileAsBase64('./.devcontainer/library-scripts/BareVMSetup.sh')
    }
  }
  dependsOn:[
    nicWithPrivateIP
  ]
}

resource shutdownComputeVm 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: targetRegion
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
output hostname string = vmName
