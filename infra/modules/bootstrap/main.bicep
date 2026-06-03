targetScope = 'subscription'

/*
AVD Deployment / Bootstrap

Scope:
- Subscription

Deploys:
- Core AVD resource groups defined in shared configuration

Does not deploy:
- Virtual networks or subnets
- Storage accounts or FSLogix shares
- AVD host pools, desktop application groups, or workspaces
- Session host virtual machines

Notes:
- Resource group ownership may move to individual modules when module-level ownership is preferred.
- Keep this module focused on subscription-level bootstrap resources only.
*/

// Imports

/*
import {
  EnvironmentName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  StandardTags
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

// Parameters

@description('Short deployment environment name used by pipelines and parameter files.')
param environment EnvironmentName

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Azure region used for bootstrap resource group deployment.
var location = commonConfig.location

// Standard tags applied to resource groups deployed by this module.
var tags = union(StandardTags, {
  Environment: environmentConfig.tagEnvironment
})

// Resource group names generated from shared resource group type configuration.
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

// Modules

module avdResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [
  for (rg, i) in resourceGroupNames: {
    name: '${deployment().name}-rg'
    params: {
      name: rg.name
      location: location
      tags: tags
      lock: {
        kind: commonConfig.lockKind
      }
    }
  }
]

// Outputs

@description('Resource group names generated and deployed by the bootstrap module.')
output resourceGroups array = resourceGroupNames
*/
