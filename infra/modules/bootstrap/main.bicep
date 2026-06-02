targetScope = 'subscription'

/* AVD Deployment - Bootstrap Module
This module is responsible for bootstrapping the foundational infrastructure required for the AVD environment. It
creates the core resource groups and any shared resources that need to exist before deploying the host pools and
session hosts. This module is designed to be run once per subscription/environment and sets up the necessary structure
for subsequent module deployments.
*/

import {
  EnvironmentName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  standardTags
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

@description('Short deployment environment name used by pipelines and parameter files.')
param environment EnvironmentName

var location = commonConfig.location

var environmentConfig = environmentConfigMap[environment]

@description('Tags to add to resource groups deployed by this module.')
var tags = union(standardTags, {
  Environment: environmentConfig.tagEnvironment
})

var resourceGroupNames = [
  for resourceGroupType in commonConfig.resourceGroupTypes: {
    type: resourceGroupType
    name: resourceGroupName(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceGroupType,
      environmentConfig.shortName
    )
  }
]

module avdResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (rg, i) in resourceGroupNames: {
    name: 'deploy-rg-${environmentConfig.shortName}-${i}'
    params: {
      name: rg.name
      location: location
      tags: tags
      lock: {
        kind: 'CanNotDelete'
      }
    }
  }
]

resource desktopVirtualizationProvider 'Microsoft.Resources/resourceProviders@2025-04-01' = {
  name: 'Microsoft.DesktopVirtualization'
}

resource authorizationProvider 'Microsoft.Resources/resourceProviders@2021-04-01' = {
  name: 'Microsoft.Authorization'
}

output resourceGroups array = resourceGroupNames
