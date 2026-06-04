targetScope = 'subscription'

/*
AVD Deployment / Compute

Scope:
- Subscription

Deploys:
- Session host resource groups
- Resource group scoped compute workload deployments
- Network interfaces for planned session hosts when enabled

Does not deploy:
- Virtual networks or subnets
- AVD host pools, workspaces, or application groups
- FSLogix storage accounts or file shares
- Session host virtual machines
*/

// Imports

import {
  EnvironmentName
  SessionHostGroupConfig
} from '../../shared/types.bicep'

import {
  StandardTags
  commonConfig
  environmentConfigMap
  resourcePurpose
  resourceType
} from '../../shared/config.bicep'

import {
  resourceGroupName
  resourceNameWithPurpose
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('When true, this module creates network interfaces for planned session hosts.')
param deployNetworkInterfaces bool = false

@description('Session host workload configuration.')
param sessionHostGroups SessionHostGroupConfig[]

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Tags to add to resources deployed by this module.
var tags = union(StandardTags, {
  Environment: environmentConfig.tagEnvironment
})

// Existing network resources used by all session host groups.
var networkResourceGroupName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.network,
  environmentConfig.shortName
)

var virtualNetworkName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.virtualNetwork,
  resourcePurpose.primary,
  environmentConfig.shortName
)

// Enriched session host group model passed to the resource-group-scoped child module.
var plannedSessionHostGroups = [
  for sessionHostGroup in sessionHostGroups: {
    purpose: sessionHostGroup.purpose
    resourceGroupName: resourceGroupName(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      sessionHostGroup.purpose,
      environmentConfig.shortName
    )
    hostPoolName: resourceNameWithPurpose(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.hostPool,
      sessionHostGroup.purpose,
      environmentConfig.shortName
    )
    networkResourceGroupName: networkResourceGroupName
    virtualNetworkName: virtualNetworkName
    subnetName: resourceNameWithPurpose(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.subnet,
      sessionHostGroup.purpose,
      environmentConfig.shortName
    )
    vmNamePrefix: sessionHostGroup.vmNamePrefix
    vmCount: sessionHostGroup.vmCount
    vmSize: sessionHostGroup.vmSize
    osDisk: sessionHostGroup.osDisk
  }
]

// Resources

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

// Modules

module sessionHostWorkload './resources.bicep' = [
  for (sessionHostGroup, index) in plannedSessionHostGroups: {
    name: '${deployment().name}-compute-${toLower(sessionHostGroup.purpose)}'
    scope: resourceGroup(sessionHostGroup.resourceGroupName)
    params: {
      location: commonConfig.location
      tags: tags
      deployNetworkInterfaces: deployNetworkInterfaces
      sessionHostGroup: sessionHostGroup
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
