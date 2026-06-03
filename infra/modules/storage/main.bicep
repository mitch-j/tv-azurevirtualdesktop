targetScope = 'subscription'

/*
AVD Deployment / Storage

Scope:
- Subscription

Deploys:
- Resource group for storage resources
- Premium Azure Files storage account
- SMB file share for FSLogix profile containers

Does not deploy:
- AVD Service Objects
  - Hostpools
  - Desktop Application Groups
  - Workspaces
- Session host virtual machines

*/

// Imports

import {
  EnvironmentName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  StandardTags
  resourcePurpose
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

// Parameters

@description('Environment to deploy.')
param environment EnvironmentName

@description('Name of the FSLogix profile file share.')
param fslogixShareName string = 'profiles'

@description('Provisioned size of the FSLogix profile share in GiB.')
@minValue(100)
param fslogixShareQuotaGiB int = 1024

@description('Enable public network access. Use false when private endpoints are configured.')
param enablePublicNetworkAccess bool = false

@description('Optional subnet resource ID for the Azure Files private endpoint.')
param privateEndpointSubnetResourceId string = ''

@description('Optional private DNS zone resource ID for privatelink.file.core.windows.net.')
param filePrivateDnsZoneResourceId string = ''

// Variables

@description('Shared environment configuration for the selected deployment environment.')
var environmentConfig = environmentConfigMap[environment]

@description('Standard tags applied to resources deployed by this module.')
var tags = union(StandardTags, {
  Environment: environmentConfig.tagEnvironment
})

@description('Name of the resource Group that will contain storage resources.')
var storageRGName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.storage,
  environmentConfig.shortName
)

// Modules

module storageResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: 'deploy-${storageRGName}'
  params: {
    name: storageRGName
    location: commonConfig.location
    tags: tags
  }
}

module storageResources './resources.bicep' = {
  name: 'deploy-${commonConfig.workloadName}-storage-${environmentConfig.shortName}'
  scope: resourceGroup(storageRGName)
  dependsOn: [
    storageResourceGroup
  ]
  params: {
    environment: environment
    tags: tags
    fslogixShareName: fslogixShareName
    fslogixShareQuotaGiB: fslogixShareQuotaGiB
    enablePublicNetworkAccess: enablePublicNetworkAccess
    privateEndpointSubnetResourceId: privateEndpointSubnetResourceId
    filePrivateDnsZoneResourceId: filePrivateDnsZoneResourceId
  }
}

// Outputs

@description('Name of the resource group containing the storage resources.')
output storageResourceGroupName string = storageRGName

@description('Name of the deployed FSLogix storage account.')
output storageAccountName string = storageResources.outputs.storageAccountName

@description('Resource ID of the deployed FSLogix storage account.')
output storageAccountResourceId string = storageResources.outputs.storageAccountResourceId

@description('Names of the deployed Azure Files shares.')
output fileShareNames array = storageResources.outputs.fileShareNames

@description('UNC paths for the deployed Azure Files shares.')
output fileSharePaths array = storageResources.outputs.fileSharePaths

@description('UNC path used for FSLogix profile containers.')
output fslogixProfilePath string = storageResources.outputs.fslogixProfilePath
