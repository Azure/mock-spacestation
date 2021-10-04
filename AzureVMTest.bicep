// az deployment group create --template-file AzureVM.bicep --resource-group "test_group"
// az bicep build --file .\AzureVM.bicep --outfile .\AzureVM.json

@description('The name of the new virtual machine')
param vmName string = 'mockGroundstation'

@description('SSH key or password for the Virtual Machine. SSH key is recommended.')
param adminPassword string

var ubuntuOSVersion = '18.04-LTS'

// Location for all resources.
var location = resourceGroup().location

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


var adminUsername = 'azureuser'

var osDiskType = 'Standard_LRS'


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
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword      
      customData: loadFileAsBase64('./.devcontainer/library-scripts/BareVMSetup.sh')
    }
  }
}


output administratorUsername string = adminUsername
output hostname string = vmName

