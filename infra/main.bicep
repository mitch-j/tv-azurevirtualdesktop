targetScope = 'resourceGroup'

// AVD-Deployment
// This instance is the central entrypoint for the AVD deployment and orchestrates the deployment of all required resources and modules.

import {
  DeploymentEnvironmentName
  StandardTags
} from './shared/types.bicep'

import {
  environmentConfigMap
  deploymentDefaults
} from './shared/config.bicep'

@description('Short deployment environment name used by pipelines and parameter files.')
param environmentName DeploymentEnvironmentName

@description('Azure region for deployed resources.')
param location string = resourceGroup().location

@description('Repository name or source location for traceability.')
param repositoryName string

@description('Controls public network access for AVD control plane resources.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Enabled'

@description('Host pool definitions to create for this AVD environment.')
param hostPools array

@description('Short technical name for the deployable workload. Used in Azure resource names.')
param workloadName string

var environmentConfig = environmentConfigMap[environmentName]

@description('Tags')
param tags StandardTags

var resourceNamePrefix = '${workloadName}-'
var resourceNameSuffix = '-${environmentConfig.shortName}'

module hostPool 'modules/avd-core/host-pool.bicep' = {
  name: 'Host-Pool-$${environmentName}'
  params: {
    environmentName: environmentName
    namePrefix: resourceNamePrefix
    location: location
    workloadName: workloadName
    tags: tags
    publicNetworkAccess: publicNetworkAccess
    hostPools: hostPools
  }
}

output hostPoolNames array = hostPool.outputs.hostPoolNames
output hostPoolResourceIds array = hostPool.outputs.hostPoolResourceIds

output resourcePrefix string = resourceNamePrefix
output resourceSuffix string = resourceNameSuffix
output logRetentionDays int = environmentConfig.logRetentionDays
output resourceDefaults object = deploymentDefaults

output sourceRepositoryName string = repositoryName
output deploymentEnvironment string = environmentName
output deploymentLocation string = location
output appliedTags object = tags
