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

var controlPlaneResourceGroupName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  'controlplane',
  environmentConfigMap[environment].shortName
)

resource controlPlaneRg 'Microsoft.Resources/resourceGroups@2024-11-01' existing = {
  name: controlPlaneResourceGroupName
}

module controlPlaneResources './resources.bicep' = {
  name: 'deploy-avd-controlplane-${environmentConfig.shortName}'
  scope: controlPlaneRg
  params: {
    environment: environment
    tags: tags

    hostPools: hostPools
    workspaces: workspaces
  }
}

output workspaceNames array = controlPlaneResources.outputs.workspaceNames
output workspaceIds array = controlPlaneResources.outputs.workspaceIds
output hostPools array = controlPlaneResources.outputs.hostPools
output hostPoolIds array = controlPlaneResources.outputs.hostPoolIds
output desktopApplicationGroupIds array = controlPlaneResources.outputs.desktopApplicationGroupIds
