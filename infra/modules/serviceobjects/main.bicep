targetScope = 'subscription'

/*
AVD Deployment / Service Objects Deployment

Deploys:
- Service Objects resource group
- AVD host pools
- One desktop application group per host pool
- One or more workspaces
- Workspace publishing for desktop application groups
- Desktop Virtualization User RBAC assignments on application groups
*/

import {
  EnvironmentName
  WorkspaceConfig
  HostPoolConfig
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  standardTags
  resourcePurpose
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

@description('Environment to deploy.')
param environment EnvironmentName

@description('Configuration for workspaces to deploy.')
param workspaces WorkspaceConfig[]

@description('Configuration for host pools to deploy.')
param hostPools HostPoolConfig[]

var environmentConfig = environmentConfigMap[environment]

@description('Tags to add to resources deployed by this module.')
var tags = union(standardTags, {
  Environment: environmentConfig.tagEnvironment
})

var serviceObjectsRGName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.serviceObjects,
  environmentConfig.shortName
)

module serviceObjectsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'deploy-${serviceObjectsRGName}'
  params: {
    name: serviceObjectsRGName
    location: commonConfig.location
    tags: tags
    lock: {
      kind: 'CanNotDelete'
    }
  }
}

module serviceObjectsResources './resources.bicep' = {
  name: 'deploy-avd-serviceobjects-${environmentConfig.shortName}'
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

output resourceGroupName string = serviceObjectsRGName
output workspaceNames array = serviceObjectsResources.outputs.workspaceNames
output workspaceIds array = serviceObjectsResources.outputs.workspaceIds
output hostPools array = serviceObjectsResources.outputs.hostPools
output hostPoolIds array = serviceObjectsResources.outputs.hostPoolIds
output desktopApplicationGroupIds array = serviceObjectsResources.outputs.desktopApplicationGroupIds
