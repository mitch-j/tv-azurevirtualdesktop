targetScope = 'subscription'

import {
  EnvironmentName
  WorkspaceConfig
  HostPoolConfig
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  standardTags
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

param environment EnvironmentName
param workspaces WorkspaceConfig[]
param hostPools HostPoolConfig[]

@description('Tags to add to resource groups deployed by this module.')
var tags = union(standardTags, {
  Environment: environmentConfig.tagEnvironment
})

var environmentConfig = environmentConfigMap[environment]

var serviceobjectsResourceGroupName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  'serviceobjects',
  environmentConfigMap[environment].shortName
)

resource serviceobjectsRg 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: serviceobjectsResourceGroupName
}

module serviceobjectsResources './resources.bicep' = {
  name: 'deploy-avd-serviceobjects-${environmentConfig.shortName}'
  scope: serviceobjectsRg
  params: {
    environment: environment
    tags: tags

    hostPools: hostPools
    workspaces: workspaces
  }
}

output workspaceNames array = serviceobjectsResources.outputs.workspaceNames
output workspaceIds array = serviceobjectsResources.outputs.workspaceIds
output hostPools array = serviceobjectsResources.outputs.hostPools
output hostPoolIds array = serviceobjectsResources.outputs.hostPoolIds
output desktopApplicationGroupIds array = serviceobjectsResources.outputs.desktopApplicationGroupIds
