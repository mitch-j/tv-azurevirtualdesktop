targetScope = 'subscription'

/*
AVD Deployment / Service Objects

Scope:
- Subscription

Deploys:
- Service Objects resource group
- AVD host pools
- One desktop application group per host pool
- One or more workspaces
- Workspace publishing for desktop application groups
- Desktop Virtualization User RBAC assignments on application groups

Does not deploy:
- Virtual networks or subnets
- Storage accounts or FSLogix shares
- Session host virtual machines
*/

// Imports

import {
  EnvironmentName
  WorkspaceConfig
  HostPoolConfig
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  StandardTags
  resourcePurpose
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Workspace configurations to deploy for the selected environment.')
param workspaces WorkspaceConfig[]

@description('Host pool configurations to deploy for the selected environment.')
param hostPools HostPoolConfig[]

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Tags to add to resources deployed by this module.
var tags = union(StandardTags, {
  Environment: environmentConfig.tagEnvironment
})

@description('Name of the resource group that contains AVD service object resources.')
var serviceObjectsRGName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.serviceObjects,
  environmentConfig.shortName
)

// Modules

module serviceObjectsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${deployment().name}-serviceObjects-rg'
  params: {
    name: serviceObjectsRGName
    location: commonConfig.location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module serviceObjectsResources './resources.bicep' = {
  name: '${deployment().name}-serviceObjects-res'
  scope: resourceGroup(serviceObjectsRGName)
  dependsOn: [
    serviceObjectsResourceGroup
  ]
  params: {
    environment: environment
    tags: tags
    hostPools: hostPools
    workspaces: workspaces
  }
}

// Outputs

@description('Name of the Service Objects resource group.')
output serviceObjectsResourceGroupName string = serviceObjectsRGName

@description('Names of the deployed AVD workspaces.')
output workspaceNames array = serviceObjectsResources.outputs.workspaceNames

@description('Resource IDs of the deployed AVD workspaces.')
output workspaceIds array = serviceObjectsResources.outputs.workspaceIds

@description('Deployment output objects for the deployed AVD host pools.')
output hostPools array = serviceObjectsResources.outputs.hostPools

@description('Resource IDs of the deployed AVD host pools.')
output hostPoolIds array = serviceObjectsResources.outputs.hostPoolIds

@description('Resource IDs of the deployed desktop application groups.')
output desktopApplicationGroupIds array = serviceObjectsResources.outputs.desktopApplicationGroupIds
