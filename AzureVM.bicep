// The name of your Virtual Machine.
// az deployment group create --template-file AzureVM.bicep --resource-group "test_group"
param vmName string = 'mockGroundstation10'

// Type of authentication to use on the Virtual Machine. SSH key is recommended.

@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

// SSH Key or password for the Virtual Machine. SSH key is recommended.
param adminPassword string

// Unique DNS Name for the Public IP used to access the Virtual Machine.
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id)}')

// The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.
@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '16.04.0-LTS'
  '18.04-LTS'  
])
param ubuntuOSVersion string = '18.04-LTS'

// Location for all resources.
param location string = resourceGroup().location

// The size of the VM.
param vmSize string = 'Standard_D8s_v3'

// Name of the VNET.
param virtualNetworkName string = 'vNet'

// Name of the subnet in the virtual network.
param subnetName string = 'Subnet'

// Name of the Network Security Group.
param networkSecurityGroupName string = 'SecGroupNet'

var adminUsername = 'azureuser'
var publicIPAddressName = '${vmName}PublicIP'
var networkInterfaceName = '${vmName}NetInt'
var subnetRef = '${vnet.id}/subnets/${subnetName}'
var osDiskType = 'Standard_LRS'
var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'
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

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
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

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
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
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: any(authenticationType == 'password' ? null : linuxConfiguration) // TODO: workaround for https://github.com/Azure/bicep/issues/449
      //This is Base64 of AzureVMsetup.sh.  Auto-genned by pipeline.  Can be genned using Convert-AzureVMsetup.ps1
      customData: 'IyEvdXNyL2Jpbi9lbnYgYmFzaAojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIENvcHlyaWdodCAoYykgTWljcm9zb2Z0IENvcnBvcmF0aW9uLiBBbGwgcmlnaHRzIHJlc2VydmVkLgojIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgTGljZW5zZS4gU2VlIGh0dHBzOi8vZ28ubWljcm9zb2Z0LmNvbS9md2xpbmsvP2xpbmtpZD0yMDkwMzE2IGZvciBsaWNlbnNlIGluZm9ybWF0aW9uLgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojCiMgVXNlZCBvbiBhIGJsYW5rIFZNIFNldHMgdXAgdGhlIGxvY2FsIGVudmlyb25tZW50IHRvIGVtdWxhdGUgY29ubmVjdGl2aXR5IHRvIHRoZSBTcGFjZSBTdGF0aW9uLiAgVGhpcyBpcyBzbGlwc3RyZWFtZWQgaW50byB0aGUgQXp1cmVWTS5iaWNlcCBmaWxlIHRvIGJlIHJhbiB3aGVuIHRoZSBWTSBpcyBwcm92aXNpb25lZAojIFN5bnRheDogLi9CYXJlVk1TZXR1cC5zaAoKClVTRVI9ImF6dXJldXNlciIKU1BBQ0VfTkVUV09SS19OQU1FPSJzcGFjZWRldi12bmV0LXNwYWNlc3RhdGlvbiIKU1RBVElPTl9TU0hfS0VZPSIvaG9tZS8ke1VTRVJ9Ly5zc2gvaWRfcnNhX3NwYWNlU3RhdGlvbiIKU1RBVElPTl9DT05UQUlORVJfTkFNRT0ic3BhY2VkZXYtc3BhY2VzdGF0aW9uIgpTVEFUSU9OX0RPQ0tFUl9GSUxFPSIvdG1wL2xpYnJhcnktc2NyaXB0cy9Eb2NrZXJmaWxlLlNwYWNlU3RhdGlvbiIKR1JPVU5EX1NUQVRJT05fRElSPSIvaG9tZS8ke1VTRVJ9L2dyb3VuZHN0YXRpb24iCkxPR19ESVI9Ii9ob21lLyR7VVNFUn0vbG9ncyIKU1BBQ0VfU1RBVElPTl9ESVI9Ii9ob21lLyR7VVNFUn0vc3BhY2VzdGF0aW9uIgpWRVJTSU9OPSIwLjEiCkxPR0ZJTEU9Ii9ob21lLyR7VVNFUn0vTW9ja1NwYWNlU3RhdGlvbi1zZXR1cC5sb2ciCkdJVEhVQl9TUkM9Imh0dHBzOi8vcmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbS9iaWd0YWxsY2FtcGJlbGwvbW9jay1zcGFjZXN0YXRpb24vbWFpbiIKCmVjaG8gIlN0YXJ0aW5nIE1vY2sgU3BhY2UgU3RhdGlvbiBDb25maWd1cmF0aW9uICh2ICRWRVJTSU9OKSIgPiAkTE9HRklMRQplY2hvICItLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSIgPj4gJExPR0ZJTEUKZWNobyAiJChkYXRlKTogV29ya2luZyBEaXI6ICR7UFdEfSIgPj4gJExPR0ZJTEUKZWNobyAiJChkYXRlKTogSW5zdGFsbGluZyBsaWJyYXJpZXMiID4+ICRMT0dGSUxFCiNEb3dubG9hZCB0aGUgZmlsZSBwcmVyZXF1aXNpdGVzCmFwdC1nZXQgdXBkYXRlICYmIGFwdC1nZXQgaW5zdGFsbCAteSBcCiAgICBhcHQtdHJhbnNwb3J0LWh0dHBzIFwKICAgIGNhLWNlcnRpZmljYXRlcyBcCiAgICBjdXJsIFwKICAgIGdudXBnIFwKICAgIGxzYi1yZWxlYXNlIFwKICAgIGlwdXRpbHMtcGluZyBcCiAgICB0cmlja2xlIFwKICAgIGNyb24KCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNTVEFSVDogRG9ja2VyIFNldHVwCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCmVjaG8gIiQoZGF0ZSk6IERvY2tlciBTZXR1cCBTdGFydCIgPj4gJExPR0ZJTEUKY3VybCAtZnNTTCBodHRwczovL2Rvd25sb2FkLmRvY2tlci5jb20vbGludXgvdWJ1bnR1L2dwZyB8IHN1ZG8gZ3BnIC0tZGVhcm1vciAtbyAvdXNyL3NoYXJlL2tleXJpbmdzL2RvY2tlci1hcmNoaXZlLWtleXJpbmcuZ3BnCmN1cmwgLWZzU0wgaHR0cHM6Ly9nZXQuZG9ja2VyLmNvbSAtbyBnZXQtZG9ja2VyLnNoCnNoIGdldC1kb2NrZXIuc2gKc3VkbyBncm91cGFkZCBkb2NrZXIKc3VkbyB1c2VybW9kIC1hRyBkb2NrZXIgJHtVU0VSfQpzdWRvIHNldGZhY2wgLW0gdXNlcjoke1VTRVJ9OnJ3IC92YXIvcnVuL2RvY2tlci5zb2NrCmVjaG8gIiQoZGF0ZSk6IERvY2tlciBTZXR1cCBDb21wbGV0ZSIgPj4gJExPR0ZJTEUKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKI0VORDogRG9ja2VyIFNldHVwCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCgoKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKI1NUQVJUOiBHcm91bmQgU3RhdGlvbiBPUyBTZXR1cAojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwplY2hvICIkKGRhdGUpOiBHcm91bmQgU3RhdGlvbiBPUyBTZXR1cCBTdGFydCIgPj4gJExPR0ZJTEUKbWtkaXIgLXAgJHtHUk9VTkRfU1RBVElPTl9ESVJ9Cm1rZGlyIC1wICR7TE9HX0RJUn0KbWtkaXIgLXAgJHtTUEFDRV9TVEFUSU9OX0RJUn0KbWtkaXIgLXAgL2hvbWUvJHtVU0VSfS8uc3NoCm1rZGlyIC1wIC5kZXZjb250YWluZXIvbGlicmFyeS1zY3JpcHRzCgojQ2hlY2sgaWYgd2UgaGF2ZSBzc2gga2V5cyBhbHJlYWR5IGdlbm5lZC4gIElmIG5vdCwgY3JlYXRlIHRoZW0KaWYgW1sgISAtZiAiJHtTVEFUSU9OX1NTSF9LRVl9IiBdXTsgdGhlbgogICAgZWNobyAiR2VuZXJhdGluZyBkZXZlbG9wbWVudCBTU0gga2V5cy4uLiIKICAgIHNzaC1rZXlnZW4gLXQgcnNhIC1iIDQwOTYgLWYgJFNUQVRJT05fU1NIX0tFWSAgLXEgLU4gIiIgICAgCiAgICBlY2hvICJEb25lIgpmaQoKZWNobyAiJChkYXRlKTogR3JvdW5kIFN0YXRpb24gT1MgU2V0dXAgQ29tcGxldGUiID4+ICRMT0dGSUxFCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNFTkQ6IEdyb3VuZCBTdGF0aW9uIE9TIFNldHVwCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCgoKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKI1NUQVJUOiBHcm91bmQgU3RhdGlvbiBEb2NrZXIgU2V0dXAKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKZWNobyAiJChkYXRlKTogRG9ja2VyIGNvbmZpZ3VyYXRpb24gU3RhcnQiID4+ICRMT0dGSUxFCiNDaGVjayBpZiB0aGUgcHJpdmF0ZSBTcGFjZSBTdGF0aW9uIHZuZXQgZXhpc3RzIGFuZCBpZiBub3QsIGNyZWF0ZSBpdApBUFBORVRXT1JLPSQoZG9ja2VyIG5ldHdvcmsgbHMgLS1mb3JtYXQgJ3t7Lk5hbWV9fScgfCBncmVwICIke1NQQUNFX05FVFdPUktfTkFNRX0iKQppZiBbIC16ICIke0FQUE5FVFdPUkt9IiBdOyB0aGVuCiAgICBlY2hvICJDcmVhdGluZyBwcml2YXRlIGRvY2tlciBuZXR3b3JrICcke1NQQUNFX05FVFdPUktfTkFNRX0nLi4uIgogICAgZG9ja2VyIG5ldHdvcmsgY3JlYXRlIC0tZHJpdmVyIGJyaWRnZSAtLWludGVybmFsICIke1NQQUNFX05FVFdPUktfTkFNRX0iCiAgICBlY2hvICJOZXR3b3JrIGNyZWF0ZWQiCmVsc2UKICAgIGVjaG8gIlByaXZhdGUgZG9ja2VyIG5ldHdvcmsgJyR7U1BBQ0VfTkVUV09SS19OQU1FfScgZXhpc3RzIgpmaQoKCmVjaG8gIiQoZGF0ZSk6IERvd25sb2FkaW5nIExpYnJhcnkgU2NyaXB0cyBTdGFydCIgPj4gJExPR0ZJTEUKY3VybCAiJHtHSVRIVUJfU1JDfS8uZGV2Y29udGFpbmVyL2xpYnJhcnktc2NyaXB0cy9Eb2NrZXJmaWxlLlNwYWNlU3RhdGlvbiAtbyAvLmRldmNvbnRhaW5lci9saWJyYXJ5LXNjcmlwdHMvRG9ja2VyZmlsZS5TcGFjZVN0YXRpb24gLXEiCmN1cmwgIiR7R0lUSFVCX1NSQ30vLmRldmNvbnRhaW5lci9saWJyYXJ5LXNjcmlwdHMvRG9ja2VyZmlsZS5TcGFjZVN0YXRpb24gLW8gLy5kZXZjb250YWluZXIvbGlicmFyeS1zY3JpcHRzL2RvY2tlci1pbi1kb2NrZXIuc2ggLXEiCmVjaG8gIiQoZGF0ZSk6IERvd25sb2FkaW5nIExpYnJhcnkgU2NyaXB0cyBDb21wbGV0ZSIgPj4gJExPR0ZJTEUKCgoKZWNobyAiJChkYXRlKTogU3BhY2VTdGF0aW9uIENvbnRhaW5lciBCdWlsZCBTdGFydCIgPj4gJExPR0ZJTEUKI3N1ZG8gZG9ja2VyIGJ1aWxkIC10ICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FLWltZyAtLW5vLWNhY2hlIC0tYnVpbGQtYXJnIFBSSVZfS0VZPSIkKGNhdCAkU1RBVElPTl9TU0hfS0VZKSIgLS1idWlsZC1hcmcgUFVCX0tFWT0iJChjYXQgJFNUQVRJT05fU1NIX0tFWS5wdWIpIiAtLWZpbGUgJFNUQVRJT05fRE9DS0VSX0ZJTEUgLgplY2hvICIkKGRhdGUpOiBTcGFjZVN0YXRpb24gQ29udGFpbmVyIEJ1aWxkIENvbXBsZXRlIiA+PiAkTE9HRklMRQoKZWNobyAiJChkYXRlKTogU3BhY2VTdGF0aW9uIENvbnRhaW5lciBTdGFydCIgPj4gJExPR0ZJTEUKI3N1ZG8gZG9ja2VyIHJ1biAtZGl0IC0tcHJpdmlsZWdlZCAtLWhvc3RuYW1lICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FIC0tbmFtZSAkU1RBVElPTl9DT05UQUlORVJfTkFNRSAtLW5ldHdvcmsgJFNQQUNFX05FVFdPUktfTkFNRSAkU1RBVElPTl9DT05UQUlORVJfTkFNRS1pbWcKZWNobyAiJChkYXRlKTogU3BhY2VTdGF0aW9uIENvbnRhaW5lciBDb21wbGV0ZSIgPj4gJExPR0ZJTEUKCmlmIFtbICEgLWYgIi90bXAvc3BhY2VzdGF0aW9uLXN5bmMuc2giIF1dOyB0aGVuCiAgICBlY2hvICJCdWlsZGluZyBzcGFjZXN0YXRpb24tc3luYyIgICAgCiAgICAjUmVnaXN0ZXIgY3JvbgoKI0J1aWxkIHRoZSBzeW5jIHNjcmlwdCB0byBkbyAyIDEtd2F5IFJTWU5DIChQdXNoLCB0aGVuIHB1bGwpLiAgVXNlIHRyaWNrbGUgdG8ga2VlcCBiYW5kd2lkdGggQCAyNTBLQi9zCmNhdCA+ICIvdG1wL3NwYWNlc3RhdGlvbi1zeW5jLnNoIiA8PCBFT0YKIyEvYmluL2Jhc2gKdG91Y2hmaWxlPS90bXAvc3luYy1ydW5uaW5nCmlmIFsgLWUgJHRvdWNoZmlsZSBdOyB0aGVuIAogICAgZWNobyAiU3luYyBpcyBhbHJlYWR5IHJ1bm5pbmcuICBObyB3b3JrIHRvIGRvIgogICBleGl0CmVsc2UgICAKICAgdG91Y2ggJHRvdWNoZmlsZQogICBlY2hvICJTdGFydGluZyBTeW5jIgogICByc3luYyAtLXJzaD0idHJpY2tsZSAtZCAyNTBLaUIgLXUgMjUwS2lCICAtTCA0MDAgc3NoIC1vIFN0cmljdEhvc3RLZXlDaGVja2luZz1ubyAtbyBVc2VyS25vd25Ib3N0c0ZpbGU9L2Rldi9udWxsIC1pICRTVEFUSU9OX1NTSF9LRVkiIC0tdmVyYm9zZSAtLXByb2dyZXNzICRHUk9VTkRfU1RBVElPTl9ESVIvKiAkU1RBVElPTl9VU0VSTkFNRUAkU1RBVElPTl9DT05UQUlORVJfTkFNRTp+L2dyb3VuZHN0YXRpb24gIAogICByc3luYyAtLXJzaD0idHJpY2tsZSAtZCAyNTBLaUIgLXUgMjUwS2lCICAtTCA0MDAgc3NoIC1vIFN0cmljdEhvc3RLZXlDaGVja2luZz1ubyAtbyBVc2VyS25vd25Ib3N0c0ZpbGU9L2Rldi9udWxsIC1pICRTVEFUSU9OX1NTSF9LRVkiIC0tdmVyYm9zZSAtLXByb2dyZXNzICRTVEFUSU9OX1VTRVJOQU1FQCRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FOn4vc3BhY2VzdGF0aW9uLyogJFNQQUNFX1NUQVRJT05fRElSLyAgCiAgIHJtICR0b3VjaGZpbGUKZmkKCkVPRgogICAgZWNobyAiRG9uZSIKZmkKCmVjaG8gIiQoZGF0ZSk6IERvY2tlciBjb25maWd1cmF0aW9uIEVuZCIgPj4gJExPR0ZJTEUKCgojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwojU1RBUlQ6IEZpbmFsaXplCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCmVjaG8gIi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIiA+PiAkTE9HRklMRQplY2hvICIkKGRhdGUpOiBNb2NrIFNwYWNlIFN0YXRpb24gQ29uZmlndXJhdGlvbiAodiAkVkVSU0lPTikgQ29tcGxldGUuIiA+PiAvaG9tZS8ke1VTRVJ9L01vY2stU3BhY2VTdGF0aW9uLUF6dXJlVm1TZXR1cC50eHQKCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNFTkQ6IEZpbmFsaXplCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCg=='
    }        
  }
}

resource shutdown_computevm_virtualMachineName 'Microsoft.DevTestLab/schedules@2018-09-15' = {
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
output hostname string = publicIP.properties.dnsSettings.fqdn
output sshCommand string = 'ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${adminUsername}@${publicIP.properties.dnsSettings.fqdn}'
