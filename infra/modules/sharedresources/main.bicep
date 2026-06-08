targetScope = 'subscription'

/*
AVD Deployment / Shared Resources

Scope:
- Subscription

Deploys:
- Shared resources resource group
- Shared image and automation resources through the resource-group scoped resources module

Does not deploy:
- AVD host pools or workspaces
- Session host virtual machines
- FSLogix storage
- Network resources
- Key Vault, Azure Monitor, Network Watcher, role entitlement, or policy assignments yet
*/

// Imports

import {
  LocationName
} from '../../shared/types.bicep'

import {
  baseTags
  commonConfig
} from '../../shared/config.bicep'

// Parameters

@description('Name suffix used for shared resources that are environment-neutral and consumed across PoC, test, and production.')
param sharedResourcesNameSuffix string = 'shared'

@description('Azure region for network resources.')
param location LocationName

@description('Image Builder customizers. Empty by default so this module can deploy the plumbing before customization scripts exist.')
param imageTemplateCustomizers array

// passthrough params

param galleryDescription string
param automationAccountSkuName string
param automationAccountPublicNetworkAccess string
param imageBuilderVmSize string
param imageBuilderOsDiskSizeGB int
param imageBuildTimeoutInMinutes int
param imageReplicationRegions string[]
param imageTemplateAutoRunState string
param imageTemplateSource object
param imageDefinitions array

@description('Whether to deploy image build monitoring resources.')
param enableImageBuildMonitoring bool

@description('Existing Log Analytics Workspace resource ID. Leave empty to deploy a workspace in the shared resources resource group.')
param existingLogAnalyticsWorkspaceResourceId string

@description('Log Analytics workspace retention in days.')
param logAnalyticsWorkspaceRetentionInDays int

@description('Email address used for image build alert notifications. Leave empty to skip email action group receiver.')
param imageBuildAlertsEmailAddress string

@description('Whether to deploy scheduled query alerts for Image Builder automation results.')
param enableImageBuildAlerts bool

@description('Whether to deploy an Automation schedule for Image Builder runs.')
param enableImageBuildSchedule bool

@description('Image build schedule frequency.')
param imageBuildScheduleFrequency string

@description('Image build schedule interval.')
param imageBuildScheduleInterval int

@description('Time zone used by the Image Builder automation schedule.')
param imageBuildScheduleTimeZone string

@description('Optional subnet resource ID used by Azure VM Image Builder build VMs.')
param imageBuilderSubnetResourceId string

@description('Storage account type used for image versions distributed by Image Builder.')
param imageVersionStorageAccountType string

@description('Target Azure Compute Gallery image version produced by Azure VM Image Builder. Must use Major.Minor.Build format.')
param galleryImageDefinitionTargetVersion string

param imageTemplateBaseTime string

// Variables

// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: sharedResourcesNameSuffix
})

var sharedResourcesResourceGroupName = 'tv-avd-rg-shared'
var imageBuilderResourceGroupName = 'tv-avd-rg-img-shared'

// Modules

module sharedResourcesResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'deploy-${sharedResourcesResourceGroupName}'
  params: {
    name: sharedResourcesResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module imageBuilderResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'deploy-${imageBuilderResourceGroupName}'
  params: {
    name: imageBuilderResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}
module sharedResources './resources.bicep' = {
  name: 'deploy-${sharedResourcesResourceGroupName}-resources'
  scope: resourceGroup(sharedResourcesResourceGroupName)
  dependsOn: [
    sharedResourcesResourceGroup
    imageBuilderResourceGroup
  ]
  params: {
    location: location
    tags: tags
    namePrefix: commonConfig.namePrefix
    workloadName: commonConfig.workloadName
    sharedResourcesNameSuffix: sharedResourcesNameSuffix

    galleryDescription: galleryDescription

    automationAccountSkuName: automationAccountSkuName
    automationAccountPublicNetworkAccess: automationAccountPublicNetworkAccess

    imageBuilderStagingResourceGroupResourceId: subscriptionResourceId(
      'Microsoft.Resources/resourceGroups',
      imageBuilderResourceGroupName
    )

    imageBuilderVmSize: imageBuilderVmSize
    imageBuilderOsDiskSizeGB: imageBuilderOsDiskSizeGB
    imageBuildTimeoutInMinutes: imageBuildTimeoutInMinutes
    imageReplicationRegions: imageReplicationRegions

    imageTemplateAutoRunState: imageTemplateAutoRunState
    imageTemplateSource: imageTemplateSource
    imageTemplateCustomizers: imageTemplateCustomizers

    imageDefinitions: imageDefinitions
    enableImageBuildMonitoring: enableImageBuildMonitoring
    existingLogAnalyticsWorkspaceResourceId: existingLogAnalyticsWorkspaceResourceId
    logAnalyticsWorkspaceRetentionInDays: logAnalyticsWorkspaceRetentionInDays
    imageBuildAlertsEmailAddress: imageBuildAlertsEmailAddress
    enableImageBuildAlerts: enableImageBuildAlerts
    enableImageBuildSchedule: enableImageBuildSchedule
    imageBuildScheduleFrequency: imageBuildScheduleFrequency
    imageBuildScheduleInterval: imageBuildScheduleInterval
    imageBuildScheduleTimeZone: imageBuildScheduleTimeZone
    imageBuilderSubnetResourceId: imageBuilderSubnetResourceId
    imageVersionStorageAccountType: imageVersionStorageAccountType
    galleryImageDefinitionTargetVersion: galleryImageDefinitionTargetVersion
    imageTemplateBaseTime: imageTemplateBaseTime
  }
}

// Outputs

@description('Name of the shared resources resource group.')
output sharedResourcesResourceGroupName string = sharedResourcesResourceGroupName

@description('Resource ID of the shared resources resource group.')
output sharedResourcesResourceGroupResourceId string = subscriptionResourceId(
  'Microsoft.Resources/resourceGroups',
  sharedResourcesResourceGroupName
)

@description('Name of the Azure Compute Gallery.')
output computeGalleryName string = sharedResources.outputs.computeGalleryName

@description('Resource ID of the Azure Compute Gallery.')
output computeGalleryResourceId string = sharedResources.outputs.computeGalleryResourceId

@description('Resource ID of the Azure VM Image Builder managed identity.')
output imageBuilderIdentityResourceId string = sharedResources.outputs.imageBuilderIdentityResourceId

@description('Name of the Azure VM Image Builder template.')
output imageTemplateName string = sharedResources.outputs.imageTemplateName

@description('Resource ID of the Azure VM Image Builder template.')
output imageTemplateResourceId string = sharedResources.outputs.imageTemplateResourceId

@description('Name of the Automation Account.')
output automationAccountName string = sharedResources.outputs.automationAccountName

@description('Resource ID of the Automation Account.')
output automationAccountResourceId string = sharedResources.outputs.automationAccountResourceId

@description('Name of the Log Analytics workspace deployed by the shared resources module.')
output logAnalyticsWorkspaceName string = sharedResources.outputs.logAnalyticsWorkspaceName

@description('Resource ID of the Log Analytics workspace used by the shared resources module.')
output logAnalyticsWorkspaceResourceId string = sharedResources.outputs.logAnalyticsWorkspaceResourceId

@description('Name of the Image Builder alert action group.')
output imageBuildActionGroupName string = sharedResources.outputs.imageBuildActionGroupName

@description('Resource ID of the Image Builder alert action group.')
output imageBuildActionGroupResourceId string = sharedResources.outputs.imageBuildActionGroupResourceId
