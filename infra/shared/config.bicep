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

@description('Standard Azure resource type keys used for naming.')
@export()
var resourceType = {
  appService: 'appService'
  appServicePlan: 'appServicePlan'
  applicationInsights: 'applicationInsights'
  containerRegistry: 'containerRegistry'
  functionApp: 'functionApp'
  keyVault: 'keyVault'
  logAnalyticsWorkspace: 'logAnalyticsWorkspace'
  managedIdentity: 'managedIdentity'
  privateEndpoint: 'privateEndpoint'
  privateDnsZone: 'privateDnsZone'
  resourceGroup: 'resourceGroup'
  storageAccount: 'storageAccount'
  subnet: 'subnet'
  virtualNetwork: 'virtualNetwork'
  hostPool: 'hostPool'
  desktopApplicationGroup: 'desktopApplicationGroup'
  workspace: 'workspace'
  scalingPlan: 'scalingPlan'
  computeGallery: 'computeGallery'
  imageTemplate: 'imageTemplate'
  sessionHost: 'sessionHost'
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
  computeGallery: 'gal'
  imageTemplate: 'it'
  sessionHost: 'vdsh'
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
  lockKind: 'None'
}

@description('Standard purpose keys used for naming.')
@export()
var resourcePurpose = {
  serviceObjects: 'serviceObjects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sessionHosts: 'sessionHosts'
  opsPooled: 'opsPooled'
  devPooled: 'devPooled'
  devPersonal: 'devPersonal'
  opsPooledDesktop: 'opsPooledDesktop'
  opsePersonalDesktop: 'opsPersonalDesktop'
  devPooledDesktop: 'devPooledDesktop'
  devPersonalDesktop: 'devPersonalDesktop'
  primary: 'primary'
  diagnostics: 'diagnostics'
  bootDiagnostics: 'bootDiagnostics'
  images: 'images'
  logs: 'logs'
  fslogix: 'fslogix'
}

@description('Standard purpose name segments used in resource names.')
@export()
var resourcePurposeMap = {
  serviceObjects: 'serviceobjects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sessionHosts: 'sessionhosts'
  opsPooled: 'ops-pooled'
  devPooled: 'dev-pooled'
  devPersonal: 'dev-personal'
  opsPooledDesktop: 'ops-pooled-desktop'
  opsPersonalDesktop: 'ops-personal-desktop'
  devPooledDesktop: 'dev-pooled-desktop'
  devPersonalDesktop: 'dev-personal-desktop'
  primary: 'pri'
  diagnostics: 'diag'
  bootDiagnostics: 'bootdiag'
  images: 'img'
  logs: 'log'
  fslogix: 'fslogiz'
}

@description('Standard tags applied to all resources. Extend or override in specific modules as needed.')
@export()
var standardTags = {
  Division: commonConfig.division
  Product: commonConfig.product
}
