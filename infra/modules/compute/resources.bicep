targetScope = 'resourceGroup'

/*
AVD Deployment / Compute Resources

Scope:
- Resource Group

Deploys:
- Session host virtual machines
- Network interfaces for session host virtual machines, through the AVM VM module
- Optional AD DS domain join extension, through the AVM VM module
- VM platform diagnostic settings to Log Analytics

Does not deploy:
- Resource groups
- Virtual networks or subnets
- AVD host pools, workspaces, or application groups
- FSLogix storage accounts or file shares
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
  @description('Number of session hosts to deploy for this workload.')
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

@description('Resource ID of the Log Analytics workspace that receives diagnostic logs.')
param logAnalyticsWorkspaceResourceId string

@description('Deploy diagnostic settings for resources created by this module.')
param deployDiagnosticSettings bool = true

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

var diagnosticSettingsEnabled = deployDiagnosticSettings && !empty(logAnalyticsWorkspaceResourceId)

var nicDiagnosticSettings = diagnosticSettingsEnabled
  ? [
      {
        name: 'diag-nic'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        logAnalyticsDestinationType: 'Dedicated'
        logCategoriesAndGroups: []
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ]
  : []

// Existing VM symbols used only so extension diagnostic settings can be scoped to the VMs
// created inside the AVM module. Bicep extension resources need a symbolic scope.
resource deployedSessionHostVirtualMachines 'Microsoft.Compute/virtualMachines@2024-07-01' existing = [
  for sessionHost in plannedSessionHosts: {
    name: sessionHost.sessionHostName
  }
]

// Modules

@description('Create session host virtual machines and their network interfaces.')
module sessionHostVirtualMachines 'br/public:avm/res/compute/virtual-machine:0.22.1' = [
  for (sessionHost, index) in plannedSessionHosts: {
    name: '${deployment().name}-vm-${index}'
    params: {
      name: sessionHost.sessionHostName
      computerName: sessionHost.sessionHostName
      location: location
      tags: tags

      osType: 'Windows'
      vmSize: sessionHost.vmSize
      availabilityZone: -1
      licenseType: licenseType

      imageReference: {
        id: sessionHostImageVersionResourceId
      }

      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        diskSizeGB: sessionHost.osDisk.diskSizeGB
        managedDisk: {
          storageAccountType: sessionHost.osDisk.storageAccountType
        }
      }

      adminUsername: localAdminUsername
      adminPassword: localAdminPassword
      provisionVMAgent: true
      enableAutomaticUpdates: true
      patchMode: patchMode

      securityType: enableTrustedLaunch ? 'TrustedLaunch' : null
      secureBootEnabled: enableTrustedLaunch ? secureBootEnabled : false
      vTpmEnabled: enableTrustedLaunch ? vTpmEnabled : false

      managedIdentities: {
        systemAssigned: true
      }

      bootDiagnostics: true

      nicConfigurations: [
        {
          name: sessionHost.nicName
          deleteOption: 'Delete'
          enableAcceleratedNetworking: true
          ipConfigurations: [
            {
              name: 'ipconfig01'
              subnetResourceId: sessionHost.subnetResourceId
              privateIPAllocationMethod: 'Dynamic'
            }
          ]
          diagnosticSettings: nicDiagnosticSettings
          tags: tags
        }
      ]

      extensionDomainJoinPassword: deployDomainJoinExtension ? domainJoinPassword : ''
      extensionDomainJoinConfig: deployDomainJoinExtension
        ? {
            enabled: true
            name: 'joindomain'
            domainName: domainName
            ouPath: domainJoinOuPath
            user: domainJoinUserName
            restart: string(restartAfterDomainJoin)
            options: domainJoinOptions
          }
        : {
            enabled: false
          }
    }
  }
]

@description('Send VM platform logs and metrics to Log Analytics.')
resource sessionHostVirtualMachineDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = [
  for (sessionHost, index) in plannedSessionHosts: if (diagnosticSettingsEnabled) {
    name: 'diag-vm'
    scope: deployedSessionHostVirtualMachines[index]
    properties: {
      workspaceId: logAnalyticsWorkspaceResourceId
      logAnalyticsDestinationType: 'Dedicated'
      logs: [
        {
          category: 'SoftwareUpdateProfile'
          enabled: true
        }
        {
          category: 'SoftwareUpdates'
          enabled: true
        }
      ]
      metrics: [
        {
          category: 'AllMetrics'
          enabled: true
        }
      ]
    }
    dependsOn: [
      sessionHostVirtualMachines
    ]
  }
]

// Outputs

@description('Session hosts planned for this workload.')
output plannedSessionHosts array = plannedSessionHosts

@description('Network interfaces created for this workload.')
output sessionHostNetworkInterfaces array = [
  for sessionHost in plannedSessionHosts: {
    name: sessionHost.nicName
    resourceId: resourceId('Microsoft.Network/networkInterfaces', sessionHost.nicName)
    subnetResourceId: sessionHost.subnetResourceId
  }
]

@description('Session host virtual machines deployed for this workload.')
output sessionHostVirtualMachines array = [
  for (sessionHost, index) in plannedSessionHosts: {
    name: sessionHost.sessionHostName
    resourceId: sessionHostVirtualMachines[index].outputs.resourceId
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

@description('Log Analytics workspace resource ID used by diagnostic settings.')
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspaceResourceId
