metadata name = 'Configuration Values'
metadata description = 'Standard configuration values used across the Azure Virtual Desktop IaC templates.'

// Imports

import {
  AvdRdpPropertyPresets
  BaseTags
  CommonConfig
  DeploymentDefaults
  DiagnosticDefaults
  EnvironmentConfigMap
  FslogixConfig
  LocationConfigMap
  ResourceAbbreviationMap
  ResourceDefaults
  ResourceGroupPurposeConfigMap
  ResourceGroupPurposeSegmentMap
  ResourcePurposeConfigMap
  ResourcePurposeSegmentMap
  ResourceTypeConfigMap
  RoleDefinitionIds
} from './types.bicep'

// Environment Configuration

@description('Standard environment settings used across deployment templates.')
@export()
var environmentConfigMap EnvironmentConfigMap = {
  dev: {
    shortName: 'dev'
    code: 'd'
    tagName: 'Development'
    logRetentionDays: 30
  }
  test: {
    shortName: 'test'
    code: 't'
    tagName: 'Stage'
    logRetentionDays: 30
  }
  prod: {
    shortName: 'prod'
    code: 'p'
    tagName: 'Production'
    logRetentionDays: 90
    supportEmail: 'operations@doitbest.com'
  }
  e2e: {
    shortName: 'e2e'
    code: 'e'
    tagName: 'End to End'
    logRetentionDays: 30
  }
  poc: {
    shortName: 'poc'
    code: 'x'
    tagName: 'Proof of Concept'
    logRetentionDays: 30
  }
  dr: {
    shortName: 'dr'
    code: 'r'
    tagName: 'Disaster Recovery'
    logRetentionDays: 90
  }
}

@description('Standard location settings used across deployment templates.')
@export()
var locationConfigMap LocationConfigMap = {
  eastus: {
    name: 'eastus'
    shortCode: 'eus'
    code: 'e'
  }
  eastus2: {
    name: 'eastus2'
    shortCode: 'eus2'
    code: '2'
  }
  centralus: {
    name: 'centralus'
    shortCode: 'cus'
    code: 'c'
  }
  northcentralus: {
    name: 'northcentralus'
    shortCode: 'ncus'
    code: 'n'
  }
  southcentralus: {
    name: 'southcentralus'
    shortCode: 'scus'
    code: 's'
  }
  westcentralus: {
    name: 'westcentralus'
    shortCode: 'wcus'
    code: 'w'
  }
  westus: {
    name: 'westus'
    shortCode: 'wus'
    code: 'u'
  }
  westus2: {
    name: 'westus2'
    shortCode: 'wus2'
    code: 'v'
  }
  westus3: {
    name: 'westus3'
    shortCode: 'wus3'
    code: 'z'
  }
}

// Repository Defaults

@description('Shared repository and workload configuration values used across modules.')
@export()
var commonConfig CommonConfig = {
  namePrefix: 'tv'
  location: 'eastus'
  workloadName: 'avd'
  repositoryName: 'tv-azurevirtualdesktop'
  product: 'Azure Virtual Desktop'
  division: 'Information Technology'
  lockKind: 'None'
}

@description('Base tags applied to all resources. Environment is added by each deployment module.')
@export()
var baseTags BaseTags = {
  Division: commonConfig.division
  Product: commonConfig.product
}

// Deployment Defaults

@description('Default module behavior flags. Override in parameters or module inputs when needed.')
@export()
var deploymentDefaults DeploymentDefaults = {
  enableDiagnosticSettings: true
  enablePrivateEndpoints: true
  enablePurgeProtection: true
  enableSoftDelete: true
}

@description('Default Azure resource property values. Override in modules when a resource requires different behavior.')
@export()
var resourceDefaults ResourceDefaults = {
  publicNetworkAccess: 'Disabled'
}

@description('Default diagnostic categories by general resource pattern. Resource-specific modules may override these.')
@export()
var diagnosticDefaults DiagnosticDefaults = {
  metrics: [
    'AllMetrics'
  ]
  logs: []
}

// Storage and FSLogix Defaults

@description('Standard FSLogix profile container settings.')
@export()
var fslogixConfig FslogixConfig = {
  shareName: 'profiles'
}

// Azure Virtual Desktop Defaults

@description('Standard Azure Virtual Desktop RDP property presets.')
@export()
var avdRdpPropertyPresets AvdRdpPropertyPresets = {
  defaultSecure: 'audiocapturemode:i:1;audiomode:i:0;targetisaadjoined:i:1;drivestoredirect:s:;redirectclipboard:i:1;redirectcomports:i:0;redirectprinters:i:1;redirectsmartcards:i:1;screen mode id:i:2;use multimon:i:1;'
}

// Resource Type Naming

@description('Standard Azure resource type keys used for naming.')
@export()
var resourceType ResourceTypeConfigMap = {
  appService: 'appService'
  appServicePlan: 'appServicePlan'
  applicationInsights: 'applicationInsights'
  automationAccount: 'automationAccount'
  computeGallery: 'computeGallery'
  containerRegistry: 'containerRegistry'
  desktopApplicationGroup: 'desktopApplicationGroup'
  functionApp: 'functionApp'
  galleryImageDefinition: 'galleryImageDefinition'
  hostPool: 'hostPool'
  imageTemplate: 'imageTemplate'
  keyVault: 'keyVault'
  logAnalyticsWorkspace: 'logAnalyticsWorkspace'
  managedIdentity: 'managedIdentity'
  networkSecurityGroup: 'networkSecurityGroup'
  privateDnsZone: 'privateDnsZone'
  privateEndpoint: 'privateEndpoint'
  resourceGroup: 'resourceGroup'
  scalingPlan: 'scalingPlan'
  sessionHost: 'sessionHost'
  storageAccount: 'storageAccount'
  subnet: 'subnet'
  virtualNetwork: 'virtualNetwork'
  virtualNetworkPeering: 'virtualNetworkPeering'
  vmImageDefinition: 'vmImageDefinition'
  workspace: 'workspace'
  actionGroup: 'actionGroup'
}

@description('Standard Azure resource type abbreviations used for naming.')
@export()
var resourceAbbreviationMap ResourceAbbreviationMap = {
  appService: 'app'
  appServicePlan: 'asp'
  applicationInsights: 'appi'
  automationAccount: 'aa'
  computeGallery: 'gal'
  containerRegistry: 'acr'
  desktopApplicationGroup: 'vdag'
  functionApp: 'func'
  galleryImageDefinition: 'galimg'
  hostPool: 'vdpool'
  imageTemplate: 'it'
  keyVault: 'kv'
  logAnalyticsWorkspace: 'log'
  managedIdentity: 'id'
  networkSecurityGroup: 'nsg'
  privateDnsZone: 'pdnsz'
  privateEndpoint: 'pe'
  resourceGroup: 'rg'
  scalingPlan: 'vdscaling'
  sessionHost: 'vdsh'
  storageAccount: 'st'
  subnet: 'snet'
  virtualNetwork: 'vnet'
  virtualNetworkPeering: 'peer'
  vmImageDefinition: 'imgdef'
  workspace: 'vdws'
  actionGroup: 'ag'
}

// Resource Purpose Naming

@description('Standard resource group purpose keys used for naming.')
@export()
var resourceGroupPurpose ResourceGroupPurposeConfigMap = {
  serviceObjects: 'serviceObjects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sharedResources: 'sharedResources'
}

@description('Standard resource group purpose name segments used in resource group names.')
@export()
var resourceGroupPurposeMap ResourceGroupPurposeSegmentMap = {
  serviceObjects: 'service-objects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sharedResources: 'shared'
}

@description('Standard resource purpose keys used for naming.')
@export()
var resourcePurpose ResourcePurposeConfigMap = {
  serviceObjects: 'serviceObjects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sharedResources: 'sharedResources'
  sessionHosts: 'sessionHosts'
  privateEndpoints: 'privateEndpoints'
  opsPooled: 'opsPooled'
  opsPersonal: 'opsPersonal'
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

@description('Standard resource purpose name segments used in resource names.')
@export()
var resourcePurposeMap ResourcePurposeSegmentMap = {
  serviceObjects: 'service-objects'
  storage: 'storage'
  network: 'network'
  compute: 'compute'
  sharedResources: 'shared'
  sessionHosts: 'sessionhosts'
  privateEndpoints: 'private-endpoints'
  opsPooled: 'ops-pooled'
  opsPersonal: 'ops-personal'
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
  avdToHub: 'avd2hub'
  hubToAvd: 'hub2avd'
}

// Role Definition IDs

@description('Azure built-in role definition IDs used across Azure Virtual Desktop deployments.')
@export()
var roleDefinitionIds RoleDefinitionIds = {
  avd: {
    desktopVirtualizationUser: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
  }
  storage: {
    fileDataSmbShareContributor: '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
    fileDataSmbShareElevatedContributor: 'a7264617-510b-434b-a828-9731dc254ea7'
  }
}
