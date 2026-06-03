targetScope = 'subscription'

/*
AVD Deployment / Compute

Scope:
- Subscription

Deploys:
- Session host resource groups
- Resource group scoped compute workload deployments

Does not deploy:
- Virtual networks or subnets
- AVD host pools, workspaces, or application groups
- FSLogix storage accounts or file shares
- Session host virtual machines in the first pipeline pass
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

} from '../../shared/config.bicep'

import {
  resourceGroupName
  resourceNameWithPurpose

} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('When false, this module creates compute resource groups and validates planned session host configuration without creating VMs.')
param deploySessionHosts bool = false

@description('Session host workload configuration.')
param sessionHostGroups SessionHostGroupConfig[]

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Tags to add to resources deployed by this module.
var tags = union(StandardTags, {
  Environment: environmentConfig.tagEnvironment
})

/*
var storageResourceGroupName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.resourceGroup,
  resourcePurpose.storage,
  environmentConfig.shortName
)

var storageResourceGroupId = subscriptionResourceId(
  'Microsoft.Resources/resourceGroups',
  storageResourceGroupName
)

var fslogixAccountName = fslogixStorageAccountName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  environmentConfig.shortName,
  storageResourceGroupId
)


var fslogixShareName = fslogixConfig.shareName
var fslogixProfilePath = '\\\\${fslogixAccountName}.file.core.windows.net\\${fslogixShareName}'
*/

var plannedSessionHostGroups = [
  for sessionHostGroup in sessionHostGroups: {
  name: sessionHostGroup.name
  resourceGroupName: resourceGroupName(
    commonConfig.namePrefix,
    commonConfig.workloadName,
    sessionHostGroup.resourceGroupPurpose,
    environmentConfig.shortName
  )
  hostPoolName: resourceNameWithPurpose(
    commonConfig.namePrefix,
    commonConfig.workloadName,
    'hostPool',
    sessionHostGroup.hostPoolPurpose,
    environmentConfig.shortName
  )
  vmNamePrefix: sessionHostGroup.vmNamePrefix
  vmCount: sessionHostGroup.vmCount
  vmSize: sessionHostGroup.vmSize
  osDisk: sessionHostGroup.osDisk
}]

// Resources

@description('Create Resource Groups for each Session Host Type')
module avdResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (rg, i) in plannedSessionHostGroups: {
    name: 'rg-${i}-${environment}'
    params: {
      name: rg.resourceGroupName
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
  name: '${deployment().name}-compute-rg'
  scope: resourceGroup(plannedSessionHostGroups[index].resourceGroupName)
  params: {
    location: commonConfig.location
    tags: tags
    deploySessionHosts: deploySessionHosts
    sessionHostGroup: sessionHostGroup
  }
  dependsOn: [
    avdResourceGroups
  ]
}]

// Outputs

@description('Session host resource groups created or updated by this deployment.')
output sessionHostResourceGroups array = [for sessionHostGroup in plannedSessionHostGroups: {
  name: sessionHostGroup.resourceGroupName
  resourceId: subscriptionResourceId('Microsoft.Resources/resourceGroups', sessionHostGroup.resourceGroupName)
}]

@description('Session host groups planned by this deployment.')
output plannedSessionHostGroups array = plannedSessionHostGroups

@description('Planned session hosts returned by each resource group scoped deployment.')
output plannedSessionHosts array = [for (sessionHostGroup, index) in plannedSessionHostGroups: {
  groupName: sessionHostGroup.name
  resourceGroupName: sessionHostGroup.resourceGroupName
  sessionHosts: sessionHostWorkload[index].outputs.plannedSessionHosts
}]
