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
  EnvironmentName
  LocationName
} from '../../shared/types.bicep'

import {
  baseTags
  commonConfig
  environmentConfigMap
  resourceGroupPurpose
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

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

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

var sharedResourcesResourceGroupName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.sharedResources,
  environmentConfig.shortName
)

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

module sharedResources './resources.bicep' = {
  name: 'deploy-${sharedResourcesResourceGroupName}-resources'
  scope: resourceGroup(sharedResourcesResourceGroupName)
  dependsOn: [
    sharedResourcesResourceGroup
  ]
  params: {
    location: location
    tags: tags
    namePrefix: commonConfig.namePrefix
    workloadName: commonConfig.workloadName
    environmentShortName: environmentConfig.shortName

    galleryDescription: galleryDescription

    automationAccountSkuName: automationAccountSkuName
    automationAccountPublicNetworkAccess: automationAccountPublicNetworkAccess

    imageBuilderVmSize: imageBuilderVmSize
    imageBuilderOsDiskSizeGB: imageBuilderOsDiskSizeGB
    imageBuildTimeoutInMinutes: imageBuildTimeoutInMinutes
    imageReplicationRegions: imageReplicationRegions

    imageTemplateAutoRunState: imageTemplateAutoRunState
    imageTemplateSource: imageTemplateSource
    imageTemplateCustomizers: imageTemplateCustomizers

    imageDefinitions: imageDefinitions
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
