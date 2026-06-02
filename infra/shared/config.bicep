metadata name = 'Configuration Values'
metadata description = 'This Bicep file defines standard configuration values used across the IaC templates. It includes environment settings, resource type abbreviations, and default behavior flags for consistent deployment practices.'

import {
  EnvironmentConfigMap
} from './types.bicep'

@description('Standard environment settings used across deployment templates.')
@export()
var environmentConfigMap EnvironmentConfigMap = {
  dev: {
    shortName: 'dev'
    tagEnvironment: 'Development'
    logRetentionDays: 30
  }
  test: {
    shortName: 'test'
    tagEnvironment: 'Stage'
    logRetentionDays: 30
  }
  prod: {
    shortName: 'prod'
    tagEnvironment: 'Production'
    logRetentionDays: 90
    supportEmail: 'operations@doitbest.com'
  }
  e2e: {
    shortName: 'e2e'
    tagEnvironment: 'End to End'
    logRetentionDays: 30
  }
  poc: {
    shortName: 'poc'
    tagEnvironment: 'Proof of Concept'
    logRetentionDays: 30
  }
}

@description('Standard Azure resource type abbreviations used for naming.')
@export()
var resourceAbbreviationMap = {
  appService: 'app'
  appServicePlan: 'asp'
  applicationInsights: 'appi'
  containerRegistry: 'acr'
  functionApp: 'func'
  keyVault: 'kv'
  logAnalyticsWorkspace: 'log'
  managedIdentity: 'id'
  privateEndpoint: 'pe'
  privateDnsZone: 'pdnsz'
  resourceGroup: 'rg'
  storageAccount: 'st'
  subnet: 'snet'
  virtualNetwork: 'vnet'
  hostPool: 'vdpool'
  desktopApplicationGroup: 'vdag'
  workspace: 'vdws'
  scalingPlan: 'vdscaling'
}

@description('Default module behavior flags. Override in parameters or module inputs when needed.')
@export()
var deploymentDefaults = {
  enableDiagnosticSettings: true
  enablePrivateEndpoints: true
  enablePublicNetworkAccess: false
  enablePurgeProtection: true
  enableSoftDelete: true
}

@description('Default diagnostic categories by general resource pattern. Resource-specific modules may override these.')
@export()
var diagnosticDefaults = {
  metrics: [
    'AllMetrics'
  ]
  logs: []
}

@description('Common placeholder values used by the repo template. Replace these in real workload repos.')
@export()
var commonConfig = {
  namePrefix: 'tv'
  location: 'eastus'
  workloadName: 'avd'
  repositoryName: 'tv-azurevirtualdesktop'
  product: 'Azure Virtual Desktop'
  division: 'Information Technology'
  resourceGroupTypes: [
    'controlplane'
    'network'
    'profiles'
    'secrets'
  ]
}

@description('Standard tags applied to all resources. Extend or override in specific modules as needed.')
@export()
var standardTags = {
  Division: commonConfig.division
  Product: commonConfig.product
}
