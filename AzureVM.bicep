// The name of your Virtual Machine.
// az deployment group create --template-file AzureVM.bicep --resource-group "test_group"
// az bicep build --file .\AzureVM.bicep --outfile .\AzureVM.json
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
var dnsLabelPrefix = toLower('${vmName}-${uniqueString(resourceGroup().id)}')

var ubuntuOSVersion = '18.04-LTS'

// Location for all resources.
var location  = resourceGroup().location

// The size of the VM.
@allowed([
  'Standard_A2'
  'Standard_A3'
  'Standard_A5'
  'Standard_A7'
  'Standard_D2s_v3'
  'Standard_D4s_v3'
  'Standard_D8s_v3'
  'Standard_D16s_v3'
  'Standard_D32s_v3'
])
param vmSize string = 'Standard_D8s_v3'

// Name of the VNET.
var virtualNetworkName = 'spacestation-vnet'

// Name of the subnet in the virtual network.
var subnetName = 'spacestation-subnet'

// Name of the Network Security Group.
var networkSecurityGroupName = 'spacestationNSG'

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
      customData: 'IyEvdXNyL2Jpbi9lbnYgYmFzaAojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojIENvcHlyaWdodCAoYykgTWljcm9zb2Z0IENvcnBvcmF0aW9uLiBBbGwgcmlnaHRzIHJlc2VydmVkLgojIExpY2Vuc2VkIHVuZGVyIHRoZSBNSVQgTGljZW5zZS4gU2VlIGh0dHBzOi8vZ28ubWljcm9zb2Z0LmNvbS9md2xpbmsvP2xpbmtpZD0yMDkwMzE2IGZvciBsaWNlbnNlIGluZm9ybWF0aW9uLgojLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLQojCiMgVXNlZCBvbiBhIGJsYW5rIFZNIFNldHMgdXAgdGhlIGxvY2FsIGVudmlyb25tZW50IHRvIGVtdWxhdGUgY29ubmVjdGl2aXR5IHRvIHRoZSBTcGFjZSBTdGF0aW9uLiAgVGhpcyBpcyBzbGlwc3RyZWFtZWQgaW50byB0aGUgQXp1cmVWTS5iaWNlcCBmaWxlIHRvIGJlIHJhbiB3aGVuIHRoZSBWTSBpcyBwcm92aXNpb25lZAojIFN5bnRheDogLi9CYXJlVk1TZXR1cC5zaAoKClVTRVI9ImF6dXJldXNlciIKU1BBQ0VfTkVUV09SS19OQU1FPSJzcGFjZWRldi12bmV0LXNwYWNlc3RhdGlvbiIKU1RBVElPTl9TU0hfS0VZPSIvaG9tZS8ke1VTRVJ9Ly5zc2gvaWRfcnNhX3NwYWNlU3RhdGlvbiIKU1RBVElPTl9DT05UQUlORVJfTkFNRT0ic3BhY2VkZXYtc3BhY2VzdGF0aW9uIgpTVEFUSU9OX0RPQ0tFUl9GSUxFPSIvdG1wL2xpYnJhcnktc2NyaXB0cy9Eb2NrZXJmaWxlLlNwYWNlU3RhdGlvbiIKR1JPVU5EX1NUQVRJT05fRElSPSIvaG9tZS8ke1VTRVJ9L2dyb3VuZHN0YXRpb24iCkxPR19ESVI9Ii9ob21lLyR7VVNFUn0vbG9ncyIKU1BBQ0VfU1RBVElPTl9ESVI9Ii9ob21lLyR7VVNFUn0vc3BhY2VzdGF0aW9uIgpWRVJTSU9OPSIwLjEiCkxPR0ZJTEU9Ii9ob21lLyR7VVNFUn0vbW9ja3NwYWNlc3RhdGlvbi1wcm92aXNpb25pbmcubG9nIgpHSVRIVUJfU1JDPSJodHRwczovL3Jhdy5naXRodWJ1c2VyY29udGVudC5jb20vYmlndGFsbGNhbXBiZWxsL21vY2stc3BhY2VzdGF0aW9uL21haW4iCgplY2hvICJTdGFydGluZyBNb2NrIFNwYWNlIFN0YXRpb24gQ29uZmlndXJhdGlvbiAodiAkVkVSU0lPTikiID4gJExPR0ZJTEUKZWNobyAiLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0iID4+ICRMT0dGSUxFCmVjaG8gIiQoZGF0ZSk6IFdvcmtpbmcgRGlyOiAke1BXRH0iID4+ICRMT0dGSUxFCmVjaG8gIiQoZGF0ZSk6IEluc3RhbGxpbmcgbGlicmFyaWVzIiA+PiAkTE9HRklMRQojRG93bmxvYWQgdGhlIGZpbGUgcHJlcmVxdWlzaXRlcwphcHQtZ2V0IHVwZGF0ZSAmJiBhcHQtZ2V0IGluc3RhbGwgLXkgXAogICAgYXB0LXRyYW5zcG9ydC1odHRwcyBcCiAgICBjYS1jZXJ0aWZpY2F0ZXMgXAogICAgY3VybCBcCiAgICBnbnVwZyBcCiAgICBsc2ItcmVsZWFzZSBcCiAgICBpcHV0aWxzLXBpbmcgXAogICAgdHJpY2tsZSBcCiAgICBjcm9uCgojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwojU1RBUlQ6IERvY2tlciBTZXR1cAojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwplY2hvICIkKGRhdGUpOiBEb2NrZXIgU2V0dXAgU3RhcnQiID4+ICRMT0dGSUxFCmN1cmwgLWZzU0wgaHR0cHM6Ly9kb3dubG9hZC5kb2NrZXIuY29tL2xpbnV4L3VidW50dS9ncGcgfCBzdWRvIGdwZyAtLWRlYXJtb3IgLW8gL3Vzci9zaGFyZS9rZXlyaW5ncy9kb2NrZXItYXJjaGl2ZS1rZXlyaW5nLmdwZwpjdXJsIC1mc1NMIGh0dHBzOi8vZ2V0LmRvY2tlci5jb20gLW8gZ2V0LWRvY2tlci5zaApzaCBnZXQtZG9ja2VyLnNoCnN1ZG8gZ3JvdXBhZGQgZG9ja2VyCnN1ZG8gdXNlcm1vZCAtYUcgZG9ja2VyICR7VVNFUn0Kc3VkbyBzZXRmYWNsIC1tIHVzZXI6JHtVU0VSfTpydyAvdmFyL3J1bi9kb2NrZXIuc29jawplY2hvICIkKGRhdGUpOiBEb2NrZXIgU2V0dXAgQ29tcGxldGUiID4+ICRMT0dGSUxFCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNFTkQ6IERvY2tlciBTZXR1cAojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwoKCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNTVEFSVDogR3JvdW5kIFN0YXRpb24gT1MgU2V0dXAKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKZWNobyAiJChkYXRlKTogR3JvdW5kIFN0YXRpb24gT1MgU2V0dXAgU3RhcnQiID4+ICRMT0dGSUxFCm1rZGlyIC1wICR7R1JPVU5EX1NUQVRJT05fRElSfQpta2RpciAtcCAke0xPR19ESVJ9Cm1rZGlyIC1wICR7U1BBQ0VfU1RBVElPTl9ESVJ9Cm1rZGlyIC1wIC9ob21lLyR7VVNFUn0vLnNzaApta2RpciAtcCAvdG1wL2xpYnJhcnktc2NyaXB0cwpjaG1vZCAxNzc3IC90bXAvbGlicmFyeS1zY3JpcHRzCgojQ2hlY2sgaWYgd2UgaGF2ZSBzc2gga2V5cyBhbHJlYWR5IGdlbm5lZC4gIElmIG5vdCwgY3JlYXRlIHRoZW0KaWYgW1sgISAtZiAiJHtTVEFUSU9OX1NTSF9LRVl9IiBdXTsgdGhlbgogICAgZWNobyAiR2VuZXJhdGluZyBkZXZlbG9wbWVudCBTU0gga2V5cy4uLiIKICAgIHNzaC1rZXlnZW4gLXQgcnNhIC1iIDQwOTYgLWYgJFNUQVRJT05fU1NIX0tFWSAgLXEgLU4gIiIgICAgCiAgICBlY2hvICJEb25lIgpmaQoKY2htb2QgNjAwICR7U1RBVElPTl9TU0hfS0VZfSAmJiBcCmNobW9kIDYwMCAke1NUQVRJT05fU1NIX0tFWX0ucHViICYmIFwKY2htb2QgMTc3NyAvaG9tZS8ke1VTRVJ9L2dyb3VuZHN0YXRpb24gJiYgXApjaG1vZCAxNzc3IC9ob21lLyR7VVNFUn0vc3BhY2VzdGF0aW9uICYmIFwKY2F0ICR7U1RBVElPTl9TU0hfS0VZfS5wdWIgPj4gL2hvbWUvJHtVU0VSfS8uc3NoL2F1dGhvcml6ZWRfa2V5cyAmJiBcCmNob3duICR7VVNFUn0gJHtTVEFUSU9OX1NTSF9LRVl9ICYmIFwKY2hvd24gJHtVU0VSfSAke1NUQVRJT05fU1NIX0tFWX0ucHViICYmIFwKY2hvd24gJHtVU0VSfSAvaG9tZS8ke1VTRVJ9Ly5zc2gvYXV0aG9yaXplZF9rZXlzCgoKCmVjaG8gIiQoZGF0ZSk6IEdyb3VuZCBTdGF0aW9uIE9TIFNldHVwIENvbXBsZXRlIiA+PiAkTE9HRklMRQojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwojRU5EOiBHcm91bmQgU3RhdGlvbiBPUyBTZXR1cAojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwoKCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCiNTVEFSVDogR3JvdW5kIFN0YXRpb24gRG9ja2VyIFNldHVwCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCmVjaG8gIiQoZGF0ZSk6IERvY2tlciBjb25maWd1cmF0aW9uIFN0YXJ0IiA+PiAkTE9HRklMRQojQ2hlY2sgaWYgdGhlIHByaXZhdGUgU3BhY2UgU3RhdGlvbiB2bmV0IGV4aXN0cyBhbmQgaWYgbm90LCBjcmVhdGUgaXQKQVBQTkVUV09SSz0kKGRvY2tlciBuZXR3b3JrIGxzIC0tZm9ybWF0ICd7ey5OYW1lfX0nIHwgZ3JlcCAiJHtTUEFDRV9ORVRXT1JLX05BTUV9IikKaWYgWyAteiAiJHtBUFBORVRXT1JLfSIgXTsgdGhlbgogICAgZWNobyAiQ3JlYXRpbmcgcHJpdmF0ZSBkb2NrZXIgbmV0d29yayAnJHtTUEFDRV9ORVRXT1JLX05BTUV9Jy4uLiIKICAgIGRvY2tlciBuZXR3b3JrIGNyZWF0ZSAtLWRyaXZlciBicmlkZ2UgLS1pbnRlcm5hbCAiJHtTUEFDRV9ORVRXT1JLX05BTUV9IgogICAgZWNobyAiTmV0d29yayBjcmVhdGVkIgplbHNlCiAgICBlY2hvICJQcml2YXRlIGRvY2tlciBuZXR3b3JrICcke1NQQUNFX05FVFdPUktfTkFNRX0nIGV4aXN0cyIKZmkKCgplY2hvICIkKGRhdGUpOiBEb3dubG9hZGluZyBMaWJyYXJ5IFNjcmlwdHMgU3RhcnQiID4+ICRMT0dGSUxFCmN1cmwgIiR7R0lUSFVCX1NSQ30vLmRldmNvbnRhaW5lci9saWJyYXJ5LXNjcmlwdHMvRG9ja2VyZmlsZS5TcGFjZVN0YXRpb24iIC1vICRTVEFUSU9OX0RPQ0tFUl9GSUxFIC0tc2lsZW50CmN1cmwgIiR7R0lUSFVCX1NSQ30vLmRldmNvbnRhaW5lci9saWJyYXJ5LXNjcmlwdHMvZG9ja2VyLWluLWRvY2tlci5zaCIgLW8gL3RtcC9saWJyYXJ5LXNjcmlwdHMvZG9ja2VyLWluLWRvY2tlci5zaCAtLXNpbGVudApjaG1vZCAxNzc3IC90bXAvbGlicmFyeS1zY3JpcHRzL0RvY2tlcmZpbGUuU3BhY2VTdGF0aW9uX0JhcmVWTQpjaG1vZCAxNzc3IC90bXAvbGlicmFyeS1zY3JpcHRzL2RvY2tlci1pbi1kb2NrZXIuc2gKZWNobyAiJChkYXRlKTogRG93bmxvYWRpbmcgTGlicmFyeSBTY3JpcHRzIENvbXBsZXRlIiA+PiAkTE9HRklMRQoKCgplY2hvICIkKGRhdGUpOiBTcGFjZVN0YXRpb24gQ29udGFpbmVyIEJ1aWxkIFN0YXJ0IiA+PiAkTE9HRklMRQpkb2NrZXIgYnVpbGQgLXQgJFNUQVRJT05fQ09OVEFJTkVSX05BTUUtaW1nIC0tbm8tY2FjaGUgLS1idWlsZC1hcmcgUFJJVl9LRVk9IiQoY2F0ICRTVEFUSU9OX1NTSF9LRVkpIiAtLWJ1aWxkLWFyZyBQVUJfS0VZPSIkKGNhdCAkU1RBVElPTl9TU0hfS0VZLnB1YikiIC0tZmlsZSAkU1RBVElPTl9ET0NLRVJfRklMRSAvdG1wL2xpYnJhcnktc2NyaXB0cy8KZWNobyAiJChkYXRlKTogU3BhY2VTdGF0aW9uIENvbnRhaW5lciBCdWlsZCBDb21wbGV0ZSIgPj4gJExPR0ZJTEUKCmVjaG8gIiQoZGF0ZSk6IFNwYWNlU3RhdGlvbiBDb250YWluZXIgU3RhcnQiID4+ICRMT0dGSUxFCmRvY2tlciBydW4gLWRpdCAtLXByaXZpbGVnZWQgLS1ob3N0bmFtZSAibW9ja1NwYWNlc3RhdGlvbiIgLS1uYW1lICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FIC0tbmV0d29yayAkU1BBQ0VfTkVUV09SS19OQU1FICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FLWltZwplY2hvICIkKGRhdGUpOiBTcGFjZVN0YXRpb24gQ29udGFpbmVyIENvbXBsZXRlIiA+PiAkTE9HRklMRQoKaWYgW1sgISAtZiAiL3RtcC9zcGFjZXN0YXRpb24tc3luYy5zaCIgXV07IHRoZW4KICAgIGVjaG8gIkJ1aWxkaW5nIHNwYWNlc3RhdGlvbi1zeW5jIiAgICAKICAgICNSZWdpc3RlciBjcm9uCgojQnVpbGQgdGhlIHN5bmMgc2NyaXB0IHRvIGRvIDIgMS13YXkgUlNZTkMgKFB1c2gsIHRoZW4gcHVsbCkuICBVc2UgdHJpY2tsZSB0byBrZWVwIGJhbmR3aWR0aCBAIDI1MEtCL3MKY2F0ID4gIi90bXAvc3BhY2VzdGF0aW9uLXN5bmMuc2giIDw8IEVPRgojIS9iaW4vYmFzaAppZiBbIC1lICIvdG1wL3N5bmMtcnVubmluZyIgXTsgdGhlbiAKICAgIGVjaG8gIlN5bmMgaXMgYWxyZWFkeSBydW5uaW5nLiAgTm8gd29yayB0byBkbyIKICAgZXhpdAplbHNlICAgCiAgIHRvdWNoICIvdG1wL3N5bmMtcnVubmluZyIKICAgY2htb2QgMTc3NyAiL3RtcC9zeW5jLXJ1bm5pbmciICAgCiAgIGVjaG8gIlN0YXJ0aW5nIHB1c2ggZnJvbSBHcm91bmQgU3RhdGlvbiB0byBTcGFjZSBTdGF0aW9uLi4uIgogICByc3luYyAtLXJzaD0idHJpY2tsZSAtZCAyNTBLaUIgLXUgMjUwS2lCICAtTCA0MDAgc3NoIC1vIFN0cmljdEhvc3RLZXlDaGVja2luZz1ubyAtbyBVc2VyS25vd25Ib3N0c0ZpbGU9L2Rldi9udWxsIC1pICRTVEFUSU9OX1NTSF9LRVkiIC0tdmVyYm9zZSAtLXByb2dyZXNzICRHUk9VTkRfU1RBVElPTl9ESVIvKiAkVVNFUkAxNzIuMTguMC4yOn4vZ3JvdW5kc3RhdGlvbiAgCiAgIGVjaG8gIiIKICAgZWNobyAiIgogICBlY2hvICJTdGFydGluZyBwdWxsIGZyb20gU3BhY2UgU3RhdGlvbiB0byBHcm91bmQgU3RhdGlvbiIKICAgcnN5bmMgLS1yc2g9InRyaWNrbGUgLWQgMjUwS2lCIC11IDI1MEtpQiAgLUwgNDAwIHNzaCAtbyBTdHJpY3RIb3N0S2V5Q2hlY2tpbmc9bm8gLW8gVXNlcktub3duSG9zdHNGaWxlPS9kZXYvbnVsbCAtaSAkU1RBVElPTl9TU0hfS0VZIiAtLXZlcmJvc2UgLS1wcm9ncmVzcyAkVVNFUkAxNzIuMTguMC4yOn4vc3BhY2VzdGF0aW9uLyogJFNQQUNFX1NUQVRJT05fRElSLyAgCiAgIHJtICIvdG1wL3N5bmMtcnVubmluZyIKICAgZWNobyAiLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLSIKICAgZWNobyAiIgogICBlY2hvICIiCmZpCgpFT0YKICAgIGVjaG8gIkRvbmUiCmZpCgpjaG1vZCAxNzc3IC90bXAvc3BhY2VzdGF0aW9uLXN5bmMuc2gKCgoKaWYgW1sgISAtZiAiL3RtcC9zcGFjZXN0YXRpb24tc3luYy1ub3Rocm90dGxlLnNoIiBdXTsgdGhlbgogICAgZWNobyAiQnVpbGRpbmcgc3BhY2VzdGF0aW9uLW5vdGhyb3R0bGUiICAgIAogICAgI1JlZ2lzdGVyIGNyb24KCiNCdWlsZCB0aGUgY2hlYXRlciBzeW5jIHNjcmlwdCB0byBkbyAyIDEtd2F5IFJTWU5DIChQdXNoLCB0aGVuIHB1bGwpLiAgTm8gYmFuZHdpZHRoIGxpbWl0YXRpb25zCmNhdCA+ICIvdG1wL3NwYWNlc3RhdGlvbi1zeW5jLW5vdGhyb3R0bGUuc2giIDw8IEVPRgojIS9iaW4vYmFzaAplY2hvICJUaGlzIGlzIHVzZWQgdG8gc3luY2hyb25pemUgd2l0aG91dCB0aGUgYmFuZHdpZHRoIHRocm90dGxlLiAgSXQgZG9lcyBOT1QgYWNjdXJhdGVseSByZXByZXNlbnQgdGhlIHByb2R1Y3Rpb24gZXhwZXJpZW5jZS4gIFVzZSB3aXRoIGNhdXRpb24gLSBpdCdzIGNoZWF0aW5nIgp0b3VjaGZpbGUgIi90bXAvc3luYy1ydW5uaW5nIgplY2hvICJTdGFydGluZyBwdXNoIGZyb20gR3JvdW5kIHRvIFNwYWNlIFN0YXRpb24uLi4iCmRvY2tlciBjcCAkR1JPVU5EX1NUQVRJT05fRElSLy4gJFNUQVRJT05fQ09OVEFJTkVSX05BTUU6L2hvbWUvYXp1cmV1c2VyL2dyb3VuZHN0YXRpb24vCmVjaG8gIlN0YXJ0aW5nIHB1bGwgZnJvbSBTcGFjZSBTdGF0aW9uIHRvIEdyb3VuZC4uLiIKZG9ja2VyIGNwICRTVEFUSU9OX0NPTlRBSU5FUl9OQU1FOi9ob21lL2F6dXJldXNlci9zcGFjZXN0YXRpb24vLiAkU1BBQ0VfU1RBVElPTl9ESVIvCnJtICIvdG1wL3N5bmMtcnVubmluZyIKZWNobyAiRG9uZSIKRU9GCiAgICBlY2hvICJEb25lIgpmaQoKY2htb2QgMTc3NyAvdG1wL3NwYWNlc3RhdGlvbi1zeW5jLW5vdGhyb3R0bGUuc2gKCgoKaWYgW1sgISAtZiAiL3RtcC9zcGFjZVN0YXRpb25TeW5jSm9iIiBdXTsgdGhlbgogICAgZWNobyAiQnVpbGRpbmcgcnN5bmMgY3JvbiBqb2IiICAgIAogICAgI1JlZ2lzdGVyIGNyb24KICAgIGVjaG8gIiogKiAqICogKiAvdG1wL3NwYWNlc3RhdGlvbi1zeW5jLnNoID4+ICRMT0dfRElSL3NwYWNlc3RhdGlvbi1zeW5jLmxvZyAyPiYxIiA+IC90bXAvc3BhY2VTdGF0aW9uU3luY0pvYgogICAgY3JvbnRhYiAvdG1wL3NwYWNlU3RhdGlvblN5bmNKb2IKICAgIHN1ZG8gc2VydmljZSBjcm9uIHN0YXJ0CiAgICAjY3JvbnRhYiAtbCAjbGlzdCBjcm9uIGpvYnMKICAgICNjcm9udGFiIC1yICNyZW1vdmUgY3JvbiBqb2JzCiAgICBlY2hvICJEb25lIgpmaQoKCgppZiBbWyAhIC1mICIvaG9tZS8ke1VTRVJ9L3NzaC10by1zcGFjZXN0YXRpb24uc2giIF1dOyB0aGVuCiAgICAKI0J1aWxkIHRoZSBzeW5jIHNjcmlwdCB0byBkbyAyIDEtd2F5IFJTWU5DIChQdXNoLCB0aGVuIHB1bGwpLiAgVXNlIHRyaWNrbGUgdG8ga2VlcCBiYW5kd2lkdGggQCAyNTBLQi9zCmNhdCA+ICIvaG9tZS8ke1VTRVJ9L3NzaC10by1zcGFjZXN0YXRpb24uc2giIDw8IEVPRgogICAgdHJpY2tsZSAtcyAtZCA1IC11IDUgLUwgNDAwIHNzaCAtbyBTdHJpY3RIb3N0S2V5Q2hlY2tpbmc9bm8gLW8gVXNlcktub3duSG9zdHNGaWxlPS9kZXYvbnVsbCAtaSAkU1RBVElPTl9TU0hfS0VZICRVU0VSQDE3Mi4xOC4wLjIKRU9GCiAgICBlY2hvICJEb25lIgpmaQoKY2htb2QgK3ggIi9ob21lLyR7VVNFUn0vc3NoLXRvLXNwYWNlc3RhdGlvbi5zaCIKCmVjaG8gIiQoZGF0ZSk6IERvY2tlciBjb25maWd1cmF0aW9uIEVuZCIgPj4gJExPR0ZJTEUKCgojIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIwojU1RBUlQ6IEZpbmFsaXplCiMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjCmVjaG8gIi0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tLS0tIiA+PiAkTE9HRklMRQplY2hvICIkKGRhdGUpOiBNb2NrIFNwYWNlIFN0YXRpb24gQ29uZmlndXJhdGlvbiAodiAkVkVSU0lPTikgQ29tcGxldGUuIiA+PiAkTE9HRklMRQoKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMKI0VORDogRmluYWxpemUKIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMK'
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
