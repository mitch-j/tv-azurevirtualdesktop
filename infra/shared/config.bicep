metadata name = 'Configuration Values'
metadata description = 'This Bicep file defines standard configuration values used across the IaC templates. It includes environment settings, resource type abbreviations, and default behavior flags for consistent deployment practices.'

// Imports

import {
  EnvironmentConfigMap
} from './types.bicep'

// Environment Configuration

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

@description('FSLogix file share')
@export()
var fslogixConfig = {
  shareName: 'profiles'
}

// Repository Defaults

@description('Shared repository and workload configuration values used across modules.')
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

@description('Standard tags applied to all resources. Extend or override in specific modules as needed.')
@export()
var StandardTags = {
  Division: commonConfig.division
  Product: commonConfig.product
}

// Deployment Defaults

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

// Resource Type Naming

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
  networkSecurityGroup: 'networkSecurityGroup'
  privateEndpoint: 'privateEndpoint'
  privateDnsZone: 'privateDnsZone'
  resourceGroup: 'resourceGroup'
  storageAccount: 'storageAccount'
  subnet: 'subnet'
  virtualNetwork: 'virtualNetwork'
  virtualNetworkPeering: 'virtualNetworkPeering'
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
  networkSecurityGroup: 'nsg'
  privateEndpoint: 'pe'
  privateDnsZone: 'pdnsz'
  resourceGroup: 'rg'
  storageAccount: 'st'
  subnet: 'snet'
  virtualNetwork: 'vnet'
  virtualNetworkPeering: 'peer'
  hostPool: 'vdpool'
  desktopApplicationGroup: 'vdag'
  workspace: 'vdws'
  scalingPlan: 'vdscaling'
  computeGallery: 'gal'
  imageTemplate: 'it'
  sessionHost: 'vdsh'
}

// Resource Purpose Naming

@description('Standard purpose keys used for naming.')
@export()
var resourcePurpose = {
  serviceObjects: 'serviceObjects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sessionHosts: 'sessionHosts'
  privateEndpoints: 'privateEndpoints'
  opsPooled: 'opsPooled'
  devPooled: 'devPooled'
  devPersonal: 'devPersonal'
  opsPooledDesktop: 'opsPooledDesktop'
  opsPersonalDesktop: 'opsPersonalDesktop'
  devPooledDesktop: 'devPooledDesktop'
  devPersonalDesktop: 'devPersonalDesktop'
  primary: 'primary'
  diagnostics: 'diagnostics'
  bootDiagnostics: 'bootDiagnostics'
  images: 'images'
  logs: 'logs'
  fslogix: 'fslogix'
  avdToHub: 'avdToHub'
  hubToAvd: 'hubToAvd'
}

@description('Standard purpose name segments used in resource names.')
@export()
var resourcePurposeMap = {
  serviceObjects: 'serviceobjects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sessionHosts: 'sessionhosts'
  privateEndpoints: 'private-endpoints'
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
  fslogix: 'fslogix'
  avdToHub: 'avd-poc-to-hub-prod'
  hubToAvd: 'hub-prod-to-avd-poc'
}

// Azure Virtual Desktop Defaults

@description('Default Azure Virtual Desktop settings reused across host pools.')
@export()
var avdDefaults = {
  customRdpProperty: 'audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:0;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;use multimon:i:1;'
}

// Role Definition IDs

@description('Azure role definition IDs used by Azure Virtual Desktop service object deployments.')
@export()
var avdRoleDefinitionIds = {
  desktopVirtualizationUser: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
}

@description('Azure role definition IDs used by Storage Auth deployments.')
@export()
var storageRoleDefinitionIds = {
  fileDataSmbShareContributor: '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
  fileDataSmbShareElevatedContributor: 'a7264617-510b-434b-a828-9731dc254ea7'
}
