// The name of your Virtual Machine.
// az deployment group create --template-file AzureVM.bicep --resource-group "test_group" --parameters '{ "bareVMSetupContents": {"value":"username"}, "adminPassword": {"value":""}}'
param vmName string = 'mockGroundstation'

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
      customData: 'IyEvdXNyL2Jpbi9lbnYgYmFzaAojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIENvcHlyaWdodCAoYykgTWljcm9zb2Z0IENvcnBvcmF0aW9uLiBBbGwgcmlnaHRzIHJlc2VydmVkLgojIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgTGljZW5zZS4gU2VlIGh0dHBzOi8vZ28ubWljcm9zb2Z0LmNvbS9md2xpbmsvP2xpbmtpZD0yMDkwMzE2IGZvciBsaWNlbnNlIGluZm9ybWF0aW9uLgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojCiMgVXNlZCBvbiBhIGJsYW5rIFZNIFNldHMgdXAgdGhlIGxvY2FsIGVudmlyb25tZW50IHRvIGVtdWxhdGUgY29ubmVjdGl2aXR5IHRvIHRoZSBTcGFjZSBTdGF0aW9uLiAgVGhpcyBpcyBzbGlwc3RyZWFtZWQgaW50byB0aGUgQXp1cmVWTS5iaWNlcCBmaWxlIHRvIGJlIHJhbiB3aGVuIHRoZSBWTSBpcyBwcm92aXNpb25lZAojIFN5bnRheDogLi9CYXJlVk1TZXR1cC5zaAoKClVTRVI9ImF6dXJldXNlciIKU1BBQ0VfTkVUV09SS19OQU1FPSJzcGFjZWRldi12bmV0LXNwYWNlc3RhdGlvbiIKU1RBVElPTl9TU0hfS0VZPSIvaG9tZS8ke1VTRVJ9Ly5zc2gvaWRfcnNhX3NwYWNlU3RhdGlvbiIKU1RBVElPTl9DT05UQUlORVJfTkFNRT0ic3BhY2VkZXYtc3BhY2VzdGF0aW9uIgpTVEFUSU9OX0RPQ0tFUl9GSUxFPSIvdG1wL2xpYnJhcnktc2NyaXB0cy9Eb2NrZXJmaWxlLlNwYWNlU3RhdGlvbiIKR1JPVU5EX1NUQVRJT05fRElSPSIvaG9tZS8ke1VTRVJ9L2dyb3VuZHN0YXRpb24iCkxPR19ESVI9Ii9ob21lLyR7VVNFUn0vbG9ncyIKU1BBQ0VfU1RBVElPTl9ESVI9Ii9ob21lLyR7VVNFUn0vc3BhY2VzdGF0aW9uIgpWRVJTSU9OPSIwLjEiCkxPR0ZJTEU9Ii9ob21lLyR7VVNFUn0vbW9ja3NwYWNlc3RhdGlvbi1wcm92aXNpb25pbmcubG9nIgpHSVRIVUJfU1JDPSJodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vYmlndGFsbGNhbXBiZWxsL21vY2stc3BhY2VzdGF0aW9uL21haW4iCgplY2hvICJTdGFydGluZyBNb2NrIFNwYWNlIFN0YXRpb24gQ29uZmlndXJhdGlvbiAodiAkVkVSU0lPTikiID4gJExPR0ZJTEUKZWNobyAiLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0iID4+ICRMT0dGSUxFCmVjaG8gIiQoZGF0ZSk6IFdvcmtpbmcgRGlyOiAke1BXRH0iID4+ICRMT0dGSUxFCmVjaG8gIiQoZGF0ZSk6IEluc3RhbGxpbmcgbGlicmFyaWVzIiA+PiAkTE9HRklMRQojRG93bmxvYWQgdGhlIGZpbGUgcHJlcmVxdWlzaXRlcwphcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3RhbGwgLXkgXAogICAgYXB0LXRyYW5zcG9ydC1odHRwcyBcCiAgICBjYS1jZXJ0aWZpY2F0ZXMgXAogICAgY3VybCBcCiAgICBnbnVwZyBcCiAgICBsc2ItcmVsZWFzZSBcCiAgICBpcHV0aWxzLXBpbmcgXAogICAgdHJpY2tsZSBcCiAgICBjcm9uCgojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwojU1RBUlQ6IERvY2tlciBTZXR1cAojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwplY2hvICIkKGRhdGUpOiBEb2NrZXIgU2V0dXAgU3RhcnQiID4+ICRMT0dGSUxFCmN1cmwgLWZzU0wgaHR0cHM6Ly9kb3dubG9hZC5kb2NrZXIuY29tL2xpbnV4L3VidW50dS9ncGcgfCBzdWRvIGdwZyAtLWRlYXJtb3IgLW8gL3Vzci9zaGFyZS9rZXlyaW5ncy9kb2NrZXItYXJjaGl2ZS1rZXlyaW5nLmdwZwpjdXJsIC1mc1NMIGh0dHBzOi8vZ2V0LmRvY2tlci5jb20gLW8gZ2V0LWRvY2tlci5zaApzaCBnZXQtZG9ja2VyLnNoCnN1ZG8gZ3JvdXBhZGQgZG9ja2VyCnN1ZG8gdXNlcm1vZCAtYUcgZG9ja2VyICR7VVNFUn0Kc3VkbyBzZXRmYWNsIC1tIHVzZXI6JHtVU0VSfTpydyAvdmFyL3J1bi9kb2NrZXIuc29jawplY2hvICIkKGRhdGUpOiBEb2NrZXIgU2V0dXAgQ29tcGxldGUiID4+ICRMT0dGSUxFCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNFTkQ6IERvY2tlciBTZXR1cAojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwoKCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNTVEFSVDogR3JvdW5kIFN0YXRpb24gT1MgU2V0dXAKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKZWNobyAiJChkYXRlKTogR3JvdW5kIFN0YXRpb24gT1MgU2V0dXAgU3RhcnQiID4+ICRMT0dGSUxFCm1rZGlyIC1wICR7R1JPVU5EX1NUQVRJT05fRElSfQpta2RpciAtcCAke0xPR19ESVJ9Cm1rZGlyIC1wICR7U1BBQ0VfU1RBVElPTl9ESVJ9Cm1rZGlyIC1wIC9ob21lLyR7VVNFUn0vLnNzaApta2RpciAtcCAvdG1wL2xpYnJhcnktc2NyaXB0cwpjaG1vZCAxNzc3IC90bXAvbGlicmFyeS1zY3JpcHRzCgojQ2hlY2sgaWYgd2UgaGF2ZSBzc2gga2V5cyBhbHJlYWR5IGdlbm5lZC4gIElmIG5vdCwgY3JlYXRlIHRoZW0KaWYgW1sgISAtZiAiJHtTVEFUSU9OX1NTSF9LRVl9IiBdXTsgdGhlbgogICAgZWNobyAiR2VuZXJhdGluZyBkZXZlbG9wbWVudCBTU0gga2V5cy4uLiIKICAgIHNzaC1rZXlnZW4gLXQgcnNhIC1iIDQwOTYgLWYgJFNUQVRJT05fU1NIX0tFWSAgLXEgLU4gIiIgICAgCiAgICBlY2hvICJEb25lIgpmaQoKY2htb2QgNjAwICR7U1RBVElPTl9TU0hfS0VZfSAmJiBcCmNobW9kIDYwMCAke1NUQVRJT05fU1NIX0tFWX0ucHViICYmIFwKY2htb2QgMTc3NyAvaG9tZS8ke1VTRVJ9L2dyb3VuZHN0YXRpb24gJiYgXApjaG1vZCAxNzc3IC9ob21lLyR7VVNFUn0vc3BhY2VzdGF0aW9uICYmIFwKY2F0ICR7U1RBVElPTl9TU0hfS0VZfS5wdWIgPj4gL2hvbWUvJHtVU0VSfS8uc3NoL2F1dGhvcml6ZWRfa2V5cyAmJiBcCmNob3duICR7VVNFUn0gJHtTVEFUSU9OX1NTSF9LRVl9ICYmIFwKY2hvd24gJHtVU0VSfSAke1NUQVRJT05fU1NIX0tFWX0ucHViICYmIFwKY2hvd24gJHtVU0VSfSAvaG9tZS8ke1VTRVJ9Ly5zc2gvYXV0aG9yaXplZF9rZXlzCgoKCmVjaG8gIiQoZGF0ZSk6IEdyb3VuZCBTdGF0aW9uIE9TIFNldHVwIENvbXBsZXRlIiA+PiAkTE9HRklMRQojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwojRU5EOiBHcm91bmQgU3RhdGlvbiBPUyBTZXR1cAojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwoKCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNTVEFSVDogR3JvdW5kIFN0YXRpb24gRG9ja2VyIFNldHVwCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCmVjaG8gIiQoZGF0ZSk6IERvY2tlciBjb25maWd1cmF0aW9uIFN0YXJ0IiA+PiAkTE9HRklMRQojQ2hlY2sgaWYgdGhlIHByaXZhdGUgU3BhY2UgU3RhdGlvbiB2bmV0IGV4aXN0cyBhbmQgaWYgbm90LCBjcmVhdGUgaXQKQVBQTkVUV09SSz0kKGRvY2tlciBuZXR3b3JrIGxzIC0tZm9ybWF0ICd7ey5OYW1lfX0nIHwgZ3JlcCAiJHtTUEFDRV9ORVRXT1JLX05BTUV9IikKaWYgWyAteiAiJHtBUFBORVRXT1JLfSIgXTsgdGhlbgogICAgZWNobyAiQ3JlYXRpbmcgcHJpdmF0ZSBkb2NrZXIgbmV0d29yayAnJHtTUEFDRV9ORVRXT1JLX05BTUV9Jy4uLiIKICAgIGRvY2tlciBuZXR3b3JrIGNyZWF0ZSAtLWRyaXZlciBicmlkZ2UgLS1pbnRlcm5hbCAiJHtTUEFDRV9ORVRXT1JLX05BTUV9IgogICAgZWNobyAiTmV0d29yayBjcmVhdGVkIgplbHNlCiAgICBlY2hvICJQcml2YXRlIGRvY2tlciBuZXR3b3JrICcke1NQQUNFX05FVFdPUktfTkFNRX0nIGV4aXN0cyIKZmkKCgplY2hvICIkKGRhdGUpOiBEb3dubG9hZGluZyBMaWJyYXJ5IFNjcmlwdHMgU3RhcnQiID4+ICRMT0dGSUxFCmN1cmwgIiR7R0lUSFVCX1NSQ30vLmRldmNvbnRhaW5lci9saWJyYXJ5LXNjcmlwdHMvRG9ja2VyZmlsZS5TcGFjZVN0YXRpb24iIC1vICRTVEFUSU9OX0RPQ0tFUl9GSUxFIC0tc2lsZW50CmN1cmwgIiR7R0lUSFVCX1NSQ30vLmRldmNvbnRhaW5lci9saWJyYXJ5LXNjcmlwdHMvZG9ja2VyLWluLWRvY2tlci5zaCIgLW8gL3RtcC9saWJyYXJ5LXNjcmlwdHMvZG9ja2VyLWluLWRvY2tlci5zaCAtLXNpbGVudApjaG1vZCAxNzc3IC90bXAvbGlicmFyeS1zY3JpcHRzL0RvY2tlcmZpbGUuU3BhY2VTdGF0aW9uX0JhcmVWTQpjaG1vZCAxNzc3IC90bXAvbGlicmFyeS1zY3JpcHRzL2RvY2tlci1pbi1kb2NrZXIuc2gKZWNobyAiJChkYXRlKTogRG93bmxvYWRpbmcgTGlicmFyeSBTY3JpcHRzIENvbXBsZXRlIiA+PiAkTE9HRklMRQoKCgplY2hvICIkKGRhdGUpOiBTcGFjZVN0YXRpb24gQ29udGFpbmVyIEJ1aWxkIFN0YXJ0IiA+PiAkTE9HRklMRQpkb2NrZXIgYnVpbGQgLXQgJFNUQVRJT05fQ09OVEFJTkVSX05BTUUtaW1nIC0tbm8tY2FjaGUgLS1idWlsZC1hcmcgUFJJVl9LRVk9IiQoY2F0ICRTVEFUSU9OX1NTSF9LRVkpIiAtLWJ1aWxkLWFyZyBQVUJfS0VZPSIkKGNhdCAkU1RBVElPTl9TU0hfS0VZLnB1YikiIC0tZmlsZSAkU1RBVElPTl9ET0NLRVJfRklMRSAvdG1wL2xpYnJhcnktc2NyaXB0cy8KZWNobyAiJChkYXRlKTogU3BhY2VTdGF0aW9uIENvbnRhaW5lciBCdWlsZCBDb21wbGV0ZSIgPj4gJExPR0ZJTEUKCmVjaG8gIiQoZGF0ZSk6IFNwYWNlU3RhdGlvbiBDb250YWluZXIgU3RhcnQiID4+ICRMT0dGSUxFCmRvY2tlciBydW4gLWRpdCAtLXByaXZpbGVnZWQgLS1ob3N0bmFtZSAibW9ja1NwYWNlc3RhdGlvbiIgLS1uYW1lICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FIC0tbmV0d29yayAkU1BBQ0VfTkVUV09SS19OQU1FICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FLWltZwplY2hvICIkKGRhdGUpOiBTcGFjZVN0YXRpb24gQ29udGFpbmVyIENvbXBsZXRlIiA+PiAkTE9HRklMRQoKaWYgW1sgISAtZiAiL3RtcC9zcGFjZXN0YXRpb24tc3luYy5zaCIgXV07IHRoZW4KICAgIGVjaG8gIkJ1aWxkaW5nIHNwYWNlc3RhdGlvbi1zeW5jIiAgICAKICAgICNSZWdpc3RlciBjcm9uCgojQnVpbGQgdGhlIHN5bmMgc2NyaXB0IHRvIGRvIDIgMS13YXkgUlNZTkMgKFB1c2gsIHRoZW4gcHVsbCkuICBVc2UgdHJpY2tsZSB0byBrZWVwIGJhbmR3aWR0aCBAIDI1MEtCL3MKY2F0ID4gIi90bXAvc3BhY2VzdGF0aW9uLXN5bmMuc2giIDw8IEVPRgojIS9iaW4vYmFzaAppZiBbIC1lICIkR1JPVU5EX1NUQVRJT05fRElSL3N5bmMtcnVubmluZyIgXTsgdGhlbiAKICAgIGVjaG8gIlN5bmMgaXMgYWxyZWFkeSBydW5uaW5nLiAgTm8gd29yayB0byBkbyIKICAgZXhpdAplbHNlICAgCiAgIHRvdWNoICIkR1JPVU5EX1NUQVRJT05fRElSL3N5bmMtcnVubmluZyIKICAgY2htb2QgMTc3NyAiJEdST1VORF9TVEFUSU9OX0RJUi9zeW5jLXJ1bm5pbmciCiAgIGVjaG8gIlN0YXJ0aW5nIFN5bmMiCiAgIHJzeW5jIC0tcnNoPSJ0cmlja2xlIC1kIDI1MEtpQiAtdSAyNTBLaUIgIC1MIDQwMCBzc2ggLW8gU3RyaWN0SG9zdEtleUNoZWNraW5nPW5vIC1vIFVzZXJLbm93bkhvc3RzRmlsZT0vZGV2L251bGwgLWkgJFNUQVRJT05fU1NIX0tFWSIgLS12ZXJib3NlIC0tcHJvZ3Jlc3MgJEdST1VORF9TVEFUSU9OX0RJUi8qICRVU0VSQCQxNzIuMTguMC4yOn4vZ3JvdW5kc3RhdGlvbiAgCiAgIHJzeW5jIC0tcnNoPSJ0cmlja2xlIC1kIDI1MEtpQiAtdSAyNTBLaUIgIC1MIDQwMCBzc2ggLW8gU3RyaWN0SG9zdEtleUNoZWNraW5nPW5vIC1vIFVzZXJLbm93bkhvc3RzRmlsZT0vZGV2L251bGwgLWkgJFNUQVRJT05fU1NIX0tFWSIgLS12ZXJib3NlIC0tcHJvZ3Jlc3MgJFVTRVJAJDE3Mi4xOC4wLjI6fi9zcGFjZXN0YXRpb24vKiAkU1BBQ0VfU1RBVElPTl9ESVIvICAKICAgcm0gIiRHUk9VTkRfU1RBVElPTl9ESVIvc3luYy1ydW5uaW5nIgpmaQoKRU9GCiAgICBlY2hvICJEb25lIgpmaQoKY2htb2QgMTc3NyAvdG1wL3NwYWNlc3RhdGlvbi1zeW5jLnNoCgoKCmlmIFtbICEgLWYgIi90bXAvc3BhY2VzdGF0aW9uLXN5bmMtbm90aHJvdHRsZS5zaCIgXV07IHRoZW4KICAgIGVjaG8gIkJ1aWxkaW5nIHNwYWNlc3RhdGlvbi1ub3Rocm90dGxlIiAgICAKICAgICNSZWdpc3RlciBjcm9uCgojQnVpbGQgdGhlIGNoZWF0ZXIgc3luYyBzY3JpcHQgdG8gZG8gMiAxLXdheSBSU1lOQyAoUHVzaCwgdGhlbiBwdWxsKS4gIE5vIGJhbmR3aWR0aCBsaW1pdGF0aW9ucwpjYXQgPiAiL3RtcC9zcGFjZXN0YXRpb24tc3luYy1ub3Rocm90dGxlLnNoIiA8PCBFT0YKIyEvYmluL2Jhc2gKZWNobyAiVGhpcyBpcyB1c2VkIHRvIHN5bmNocm9uaXplIHdpdGhvdXQgdGhlIGJhbmR3aWR0aCB0aHJvdHRsZS4gIEl0IGRvZXMgTk9UIGFjY3VyYXRlbHkgcmVwcmVzZW50IHRoZSBwcm9kdWN0aW9uIGV4cGVyaWVuY2UuICBVc2Ugd2l0aCBjYXV0aW9uIC0gaXQncyBjaGVhdGluZyIKdG91Y2hmaWxlICIkR1JPVU5EX1NUQVRJT05fRElSL3N5bmMtcnVubmluZyIKZWNobyAiU3RhcnRpbmcgcHVzaCBmcm9tIEdyb3VuZCB0byBTcGFjZSBTdGF0aW9uLi4uIgpkb2NrZXIgY3AgJEdST1VORF9TVEFUSU9OX0RJUi8uICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FOi9ob21lL2F6dXJldXNlci9ncm91bmRzdGF0aW9uLwplY2hvICJTdGFydGluZyBwdWxsIGZyb20gU3BhY2UgU3RhdGlvbiB0byBHcm91bmQuLi4iCmRvY2tlciBjcCAkU1RBVElPTl9DT05UQUlORVJfTkFNRTovaG9tZS9henVyZXVzZXIvc3BhY2VzdGF0aW9uLy4gJFNQQUNFX1NUQVRJT05fRElSLwpybSAiJEdST1VORF9TVEFUSU9OX0RJUi9zeW5jLXJ1bm5pbmciCmVjaG8gIkRvbmUiCkVPRgogICAgZWNobyAiRG9uZSIKZmkKCmNobW9kIDE3NzcgL3RtcC9zcGFjZXN0YXRpb24tc3luYy1ub3Rocm90dGxlLnNoCgoKCmlmIFtbICEgLWYgIi90bXAvc3BhY2VTdGF0aW9uU3luY0pvYiIgXV07IHRoZW4KICAgIGVjaG8gIkJ1aWxkaW5nIHJzeW5jIGNyb24gam9iIiAgICAKICAgICNSZWdpc3RlciBjcm9uCiAgICBlY2hvICIqICogKiAqICogL3RtcC9zcGFjZXN0YXRpb24tc3luYy5zaCA+PiAkTE9HX0RJUi9zcGFjZXN0YXRpb24tc3luYy5sb2cgMj4mMSIgPiAvdG1wL3NwYWNlU3RhdGlvblN5bmNKb2IKICAgIGNyb250YWIgL3RtcC9zcGFjZVN0YXRpb25TeW5jSm9iCiAgICBzdWRvIHNlcnZpY2UgY3JvbiBzdGFydAogICAgI2Nyb250YWIgLWwgI2xpc3QgY3JvbiBqb2JzCiAgICAjY3JvbnRhYiAtciAjcmVtb3ZlIGNyb24gam9icwogICAgZWNobyAiRG9uZSIKZmkKCgoKaWYgW1sgISAtZiAiL2hvbWUvJHtVU0VSfS9zc2gtdG8tc3BhY2VzdGF0aW9uLnNoIiBdXTsgdGhlbgogICAgCiNCdWlsZCB0aGUgc3luYyBzY3JpcHQgdG8gZG8gMiAxLXdheSBSU1lOQyAoUHVzaCwgdGhlbiBwdWxsKS4gIFVzZSB0cmlja2xlIHRvIGtlZXAgYmFuZHdpZHRoIEAgMjUwS0IvcwpjYXQgPiAiL2hvbWUvJHtVU0VSfS9zc2gtdG8tc3BhY2VzdGF0aW9uLnNoIiA8PCBFT0YKICAgIHRyaWNrbGUgLXMgLWQgNSAtdSA1IC1MIDQwMCBzc2ggLW8gU3RyaWN0SG9zdEtleUNoZWNraW5nPW5vIC1vIFVzZXJLbm93bkhvc3RzRmlsZT0vZGV2L251bGwgLWkgJFNUQVRJT05fU1NIX0tFWSAkVVNFUkAxNzIuMTguMC4yCkVPRgogICAgZWNobyAiRG9uZSIKZmkKCmNobW9kICt4ICIvaG9tZS8ke1VTRVJ9L3NzaC10by1zcGFjZXN0YXRpb24uc2giCgplY2hvICIkKGRhdGUpOiBEb2NrZXIgY29uZmlndXJhdGlvbiBFbmQiID4+ICRMT0dGSUxFCgoKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKI1NUQVJUOiBGaW5hbGl6ZQojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwplY2hvICItLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSIgPj4gJExPR0ZJTEUKZWNobyAiJChkYXRlKTogTW9jayBTcGFjZSBTdGF0aW9uIENvbmZpZ3VyYXRpb24gKHYgJFZFUlNJT04pIENvbXBsZXRlLiIgPj4gJExPR0ZJTEUKCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNFTkQ6IEZpbmFsaXplCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCg=='
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
