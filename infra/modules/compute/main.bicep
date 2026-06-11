targetScope = 'subscription'

/*
AVD Deployment / Compute

Scope:
- Subscription

Deploys:
- Session host resource groups
- Resource group scoped compute workload deployments
- Network interfaces for planned session hosts
- Session host virtual machines
- Optional AD DS domain join extension

Does not deploy:
- Virtual networks or subnets
- AVD host pools, workspaces, or application groups
- FSLogix storage accounts or file shares
- Session host virtual machines
*/

// Imports

import {
  EnvironmentName
  LocationName
  SessionHostGroupConfig
} from '../../shared/types.bicep'

import {
  baseTags
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourceGroupPurpose
  resourcePurpose
  resourceType
} from '../../shared/config.bicep'

import {
  resourceGroupNameWithLocation
  resourceNameWithPurposeAndLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment.')
param environment EnvironmentName

@description('Azure region where storage resources are deployed.')
param location LocationName

@description('Session host workload configuration.')
param sessionHostGroups SessionHostGroupConfig[]

@description('Azure Compute Gallery image version resource ID used for session host VMs.')
param sessionHostImageVersionResourceId string

@description('VM local administrator username.')
param localAdminUsername string

@description('Local Administrative Account password')
@secure()
param localAdminPassword string

param enableTrustedLaunch bool = true

param secureBootEnabled bool = true

param vTpmEnabled bool = true

@description('Azure Hybrid Benefit / Windows license type for the session host VM.')
param licenseType string = 'Windows_Client'

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

@description('Optional Log Analytics workspace resource ID for Key Vault diagnostics.')
param logAnalyticsWorkspaceResourceId string = ''


// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]
var locationConfig = locationConfigMap[location]


// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

// Existing network resources used by all session host groups.
var networkResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.network,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var virtualNetworkName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.virtualNetwork,
  resourcePurpose.primary,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Enriched session host group model passed to the resource-group-scoped child module.
var plannedSessionHostGroups = [
  for sessionHostGroup in sessionHostGroups: {
    purpose: sessionHostGroup.purpose
    resourceGroupName: toLower('${commonConfig.namePrefix}-${commonConfig.workloadName}-rg-${sessionHostGroup.purpose}-${locationConfig.shortCode}-${environmentConfig.shortName}')
    hostPoolName: resourceNameWithPurposeAndLocation(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.hostPool,
      sessionHostGroup.purpose,
      locationConfig.shortCode,
      environmentConfig.shortName
    )
    networkResourceGroupName: networkResourceGroupName
    virtualNetworkName: virtualNetworkName
    subnetName: resourceNameWithPurposeAndLocation(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.subnet,
      sessionHostGroup.purpose,
      locationConfig.shortCode,
      environmentConfig.shortName
    )

    // Keep the generated session host name under the 15-character Windows computer name limit.
    // Pattern: namePrefix + workloadName + code + sessionHostRoleCode + 2-digit sequence.
    sessionHostNamePrefix: toLower('${commonConfig.namePrefix}${commonConfig.workloadName}${environmentConfig.code}${locationConfig.code}${sessionHostGroup.sessionHostRoleCode}')
    vmCount: sessionHostGroup.vmCount
    vmSize: sessionHostGroup.vmSize
    osDisk: sessionHostGroup.osDisk
  }
]

// Modules

@description('Create resource groups for each session host workload.')
module avdResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (sessionHostGroup, index) in plannedSessionHostGroups: {
    name: 'rg-${index}-${environment}'
    params: {
      name: sessionHostGroup.resourceGroupName
      location: commonConfig.location
      tags: tags
      lock: {
        kind: commonConfig.lockKind
      }
    }
  }
]

module sessionHostWorkload './resources.bicep' = [
  for (sessionHostGroup, index) in plannedSessionHostGroups: {
    name: '${environmentConfig.shortName}-cmp-${index}'
    scope: resourceGroup(sessionHostGroup.resourceGroupName)
    params: {
      location: commonConfig.location
      tags: tags
      sessionHostGroup: sessionHostGroup

      sessionHostImageVersionResourceId: sessionHostImageVersionResourceId
      localAdminUsername: localAdminUsername
      localAdminPassword: localAdminPassword
      enableTrustedLaunch: enableTrustedLaunch
      secureBootEnabled: secureBootEnabled
      vTpmEnabled: vTpmEnabled
      licenseType: licenseType
      patchMode: patchMode

      deployDomainJoinExtension: deployDomainJoinExtension
      domainName: domainName
      domainJoinUserName: domainJoinUserName
      domainJoinPassword: domainJoinPassword
      domainJoinOuPath: domainJoinOuPath
      domainJoinOptions: domainJoinOptions
      restartAfterDomainJoin: restartAfterDomainJoin

      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    }
    dependsOn: [
      avdResourceGroups
    ]
  }
]

// Outputs

@description('Session host resource groups created or updated by this deployment.')
output sessionHostResourceGroups array = [
  for sessionHostGroup in plannedSessionHostGroups: {
    purpose: sessionHostGroup.purpose
    name: sessionHostGroup.resourceGroupName
    resourceId: subscriptionResourceId('Microsoft.Resources/resourceGroups', sessionHostGroup.resourceGroupName)
  }
]

@description('Session host groups planned by this deployment.')
output plannedSessionHostGroups array = plannedSessionHostGroups

@description('Planned session hosts returned by each resource group scoped deployment.')
output plannedSessionHosts array = [
  for (sessionHostGroup, index) in plannedSessionHostGroups: {
    purpose: sessionHostGroup.purpose
    resourceGroupName: sessionHostGroup.resourceGroupName
    sessionHosts: sessionHostWorkload[index].outputs.plannedSessionHosts
  }
]

@description('Session host virtual machines returned by each resource group scoped deployment.')
output sessionHostVirtualMachines array = [
  for (sessionHostGroup, index) in plannedSessionHostGroups: {
    purpose: sessionHostGroup.purpose
    resourceGroupName: sessionHostGroup.resourceGroupName
    virtualMachines: sessionHostWorkload[index].outputs.sessionHostVirtualMachines
  }
]

@description('Domain join extension targets returned by each resource group scoped deployment.')
output domainJoinTargets array = [
  for (sessionHostGroup, index) in plannedSessionHostGroups: {
    purpose: sessionHostGroup.purpose
    resourceGroupName: sessionHostGroup.resourceGroupName
    targets: sessionHostWorkload[index].outputs.domainJoinTargets
  }
]
