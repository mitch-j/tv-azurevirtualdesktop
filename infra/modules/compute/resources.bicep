targetScope = 'resourceGroup'

/*
AVD Deployment / Compute Resources

Scope:
- Resource Group

Deploys:
- Network interfaces for planned session hosts
- Session host virtual machines
- Optional AD DS domain join extension

Does not deploy:
- Resource groups
- Virtual networks or subnets
- AVD host pools, workspaces, or application groups
- FSLogix storage accounts or file shares
- Session host virtual machines
*/

import {
  LocationName
} from '../../shared/types.bicep'

// Types

@sealed()
type PlannedSessionHostGroup = {
  @description('Purpose key used to identify the session host workload.')
  purpose: string

  @description('Resource group name targeted by this deployment.')
  resourceGroupName: string

  @description('Existing AVD host pool name for this workload.')
  hostPoolName: string

  @description('Existing virtual network resource group name.')
  networkResourceGroupName: string

  @description('Existing virtual network name.')
  virtualNetworkName: string

  @description('Existing session host subnet name.')
  subnetName: string

  @description('Session Host name prefix.')
  sessionHostNamePrefix: string

  @minValue(0)
  @description('Number of session hosts to plan for this workload.')
  vmCount: int

  @description('Azure VM SKU for this workload.')
  vmSize: string

  @description('OS disk settings for this workload.')
  osDisk: {
    @description('Managed disk storage type.')
    storageAccountType: 'Premium_LRS' | 'Premium_ZRS' | 'StandardSSD_LRS' | 'Standard_LRS'

    @minValue(64)
    @description('Managed OS disk size in GB.')
    diskSizeGB: int
  }
}

// Parameters

@description('Tags applied to deployed AVD resources.')
param tags object

@description('Azure region for deployed resources.')
param location LocationName

@description('Session host workload configuration for this resource group.')
param sessionHostGroup PlannedSessionHostGroup

@description('Azure Compute Gallery image version resource ID used for session host VMs.')
param sessionHostImageVersionResourceId string

@description('VM local administrator username.')
param localAdminUsername string

@description('VM local administrator password.')
@secure()
param localAdminPassword string

@description('When true, deploys the VM using Trusted Launch security type.')
param enableTrustedLaunch bool = true

@description('When true, enables Secure Boot on the VM.')
param secureBootEnabled bool = true

@description('When true, enables vTPM on the VM.')
param vTpmEnabled bool = true

@description('Windows license type for the session host VM.')
param licenseType string = 'Windows_Client'

@description('VM patch mode.')
param patchMode string = 'AutomaticByOS'

@description('When true, deploys the AD DS domain join extension to session host VMs.')
param deployDomainJoinExtension bool = false

@description('Active Directory domain DNS name used for session host domain join.')
param domainName string = 'TV.local'

@description('Active Directory domain join username. Use either user@domain or DOMAIN\\user format.')
param domainJoinUserName string

@description('Active Directory domain join account password.')
@secure()
param domainJoinPassword string

@description('Optional OU distinguished name where session host computer objects should be created.')
param domainJoinOuPath string = ''

@description('Domain join extension options. 3 = join domain and create computer account if needed.')
param domainJoinOptions int = 3

@description('Whether the domain join extension should restart the VM after joining the domain.')
param restartAfterDomainJoin bool = true

@description('')
param logAnalyticsWorkspaceResourceId string

// Variables

var plannedSessionHosts = [
  for sessionHostNumber in range(1, sessionHostGroup.vmCount): {
    sessionHostName: toLower('${sessionHostGroup.sessionHostNamePrefix}${padLeft(string(sessionHostNumber), 2, '0')}')
    purpose: sessionHostGroup.purpose
    nicName: toLower('${sessionHostGroup.sessionHostNamePrefix}${padLeft(string(sessionHostNumber), 2, '0')}-nic')
    location: location
    resourceGroupName: resourceGroup().name
    hostPoolName: sessionHostGroup.hostPoolName
    vmSize: sessionHostGroup.vmSize
    osDisk: sessionHostGroup.osDisk
    vmResourceId: resourceId('Microsoft.Compute/virtualMachines', toLower('${sessionHostGroup.sessionHostNamePrefix}${padLeft(string(sessionHostNumber), 2, '0')}'))
    subnetResourceId: resourceId(
      sessionHostGroup.networkResourceGroupName,
      'Microsoft.Network/virtualNetworks/subnets',
      sessionHostGroup.virtualNetworkName,
      sessionHostGroup.subnetName
    )
    tags: tags
  }
]

// Modules

@description('Create NICs for each planned session host.')
module sessionHostNetworkInterfaces 'br/public:avm/res/network/network-interface:0.5.3' = [
  for (sessionHost, index) in plannedSessionHosts: {
    name: '${deployment().name}-nic-${index}'
    params: {
      name: sessionHost.nicName
      location: location
      tags: tags
      ipConfigurations: [
        {
          name: 'ipconfig01'
          subnetResourceId: sessionHost.subnetResourceId
          privateIPAllocationMethod: 'Dynamic'
        }
      ]
    }
  }
]

@description('Create session host virtual machines.')
resource sessionHostVirtualMachines 'Microsoft.Compute/virtualMachines@2024-07-01' = [
  for (sessionHost, index) in plannedSessionHosts: {
    name: sessionHost.sessionHostName
    location: location
    tags: tags
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      hardwareProfile: {
        vmSize: sessionHost.vmSize
      }
      storageProfile: {
        imageReference: {
          id: sessionHostImageVersionResourceId
        }
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: sessionHost.osDisk.storageAccountType
          }
          diskSizeGB: sessionHost.osDisk.diskSizeGB
        }
      }
      osProfile: {
        computerName: sessionHost.sessionHostName
        adminUsername: localAdminUsername
        adminPassword: localAdminPassword
        windowsConfiguration: {
          provisionVMAgent: true
          enableAutomaticUpdates: true
          patchSettings: {
            patchMode: patchMode
          }
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: resourceId('Microsoft.Network/networkInterfaces', sessionHost.nicName)
            properties: {
              primary: true
            }
          }
        ]
      }
      licenseType: licenseType
      securityProfile: enableTrustedLaunch ? {
        securityType: 'TrustedLaunch'
        uefiSettings: {
          secureBootEnabled: secureBootEnabled
          vTpmEnabled: vTpmEnabled
        }
      } : null
    }
    dependsOn: [
      sessionHostNetworkInterfaces
    ]
  }
]

@description('Join session host virtual machines to Active Directory Domain Services.')
resource domainJoinExtensions 'Microsoft.Compute/virtualMachines/extensions@2024-07-01' = [
  for (sessionHost, index) in plannedSessionHosts: if (deployDomainJoinExtension) {
    parent: sessionHostVirtualMachines[index]
    name: 'joindomain'
    location: location
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'JsonADDomainExtension'
      typeHandlerVersion: '1.3'
      autoUpgradeMinorVersion: true
      settings: {
        Name: domainName
        OUPath: domainJoinOuPath
        User: domainJoinUserName
        Restart: string(restartAfterDomainJoin)
        Options: domainJoinOptions
      }
      protectedSettings: {
        Password: domainJoinPassword
      }
    }
  }
]

// Outputs

@description('Session hosts planned for this workload.')
output plannedSessionHosts array = plannedSessionHosts

@description('Network interfaces created or planned for this workload.')
output sessionHostNetworkInterfaces array = [
  for sessionHost in plannedSessionHosts: {
    name: sessionHost.nicName
    resourceId: resourceId('Microsoft.Network/networkInterfaces', sessionHost.nicName)
    subnetResourceId: sessionHost.subnetResourceId
  }
]

@description('Session host virtual machines deployed or planned for this workload.')
output sessionHostVirtualMachines array = [
  for sessionHost in plannedSessionHosts: {
    name: sessionHost.sessionHostName
    resourceId: resourceId('Microsoft.Compute/virtualMachines', sessionHost.sessionHostName)
    resourceGroupName: resourceGroup().name
    hostPoolName: sessionHost.hostPoolName
    nicResourceId: resourceId('Microsoft.Network/networkInterfaces', sessionHost.nicName)
    subnetResourceId: sessionHost.subnetResourceId
  }
]

@description('Domain join extension deployment targets.')
output domainJoinTargets array = [
  for sessionHost in plannedSessionHosts: {
    sessionHostName: sessionHost.sessionHostName
    domainName: domainName
    ouPath: domainJoinOuPath
    extensionName: 'joindomain'
    extensionResourceId: resourceId(
      'Microsoft.Compute/virtualMachines/extensions',
      sessionHost.sessionHostName,
      'joindomain'
    )
  }
]

// Output

@description('')
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspaceResourceId
