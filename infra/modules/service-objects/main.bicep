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
  LocationName
  WorkspaceConfig
  HostPoolConfig
} from '../../shared/types.bicep'

import {
  baseTags
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourceGroupPurpose
} from '../../shared/config.bicep'

import {
  resourceGroupNameWithLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for service object resources.')
param location LocationName

@description('Workspace configurations to deploy for the selected environment.')
param workspaces WorkspaceConfig[]

@description('Host pool configurations to deploy for the selected environment.')
param hostPools HostPoolConfig[]

// Variables

@description('Shared environment configuration for the selected deployment environment.')
var environmentConfig = environmentConfigMap[environment]

@description('Shared location configuration for the selected Azure region.')
var locationConfig = locationConfigMap[location]

@description('Tags to add to resources deployed by this module.')
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

@description('Name of the resource group that contains AVD service object resources.')
var serviceObjectsResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.serviceObjects,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Modules

module serviceObjectsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${deployment().name}-service-objects-rg'
  params: {
    name: serviceObjectsResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module serviceObjectsResources './resources.bicep' = {
  name: '${deployment().name}-service-objects-res'
  scope: resourceGroup(serviceObjectsResourceGroupName)
  dependsOn: [
    serviceObjectsResourceGroup
  ]
  params: {
    environment: environment
    location: location
    tags: tags
    hostPools: hostPools
    workspaces: workspaces
  }
}

// Outputs

@description('Name of the Service Objects resource group.')
output serviceObjectsResourceGroupName string = serviceObjectsResourceGroupName

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
