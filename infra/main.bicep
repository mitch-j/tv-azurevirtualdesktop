targetScope = 'resourceGroup'

import {
  DeploymentEnvironmentName
  DivisionName
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

@description('Azure policy-compliant Division tag value.')
param division DivisionName

@description('Azure policy-compliant Product tag value.')
param product string

@description('Repository name or source location for traceability.')
param repositoryName string = '<repository-name>'

@description('Short technical name for the deployable workload. Used in Azure resource names.')
param workloadName string

var environmentConfig = environmentConfigMap[environmentName]

var standardTags StandardTags = {
  Environment: environmentConfig.tagEnvironment
  Division: division
  Product: product
}

var resourceNamePrefix = '${workloadName}-'
var resourceNameSuffix = '-${environmentConfig.shortName}'

// Add resource declarations or module calls below.
// Example:
//
// module exampleModule './modules/example.bicep' = {
//   name: 'example-${environmentConfig.shortName}'
//   params: {
//     location: location
//     tags: standardTags
//   }
// }

output deploymentEnvironment string = environmentName
output tagEnvironment string = environmentConfig.tagEnvironment
output deploymentLocation string = location
output resourcePrefix string = resourceNamePrefix
output resourceSuffix string = resourceNameSuffix
output logRetentionDays int = environmentConfig.logRetentionDays
output resourceDefaults object = deploymentDefaults
output appliedTags object = standardTags
output sourceRepositoryName string = repositoryName
