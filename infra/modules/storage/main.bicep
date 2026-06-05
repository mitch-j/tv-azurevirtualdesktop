targetScope = 'subscription'

/*
AVD Deployment / Storage

Scope:
- Subscription

Deploys:
- Location-aware resource group for storage resources
- Premium Azure Files storage account
- SMB file share for FSLogix profile containers

Does not deploy:
- Storage account RBAC
- AVD Service Objects
  - Hostpools
  - Desktop Application Groups
  - Workspaces
- Session host virtual machines
- Virtual networks or subnets
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
  locationConfigMap
  resourceGroupPurpose
} from '../../shared/config.bicep'

import {
  resourceGroupNameWithLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for service object resources.')
param location LocationName

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

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Location configuration for the selected Azure region.
var locationConfig = locationConfigMap[location]

// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

// Resource Names

// Name of the resource group that contains AVD storage resources.
var storageResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.storage,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Modules

module storageResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${deployment().name}-service-objects-rg'
  params: {
    name: storageResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module storageResources './resources.bicep' = {
  name: '${deployment().name}-stor-res'
  scope: resourceGroup(storageResourceGroupName)
  dependsOn: [
    storageResourceGroup
  ]
  params: {
    environment: environment
    tags: tags
    location: location
    fslogixShareName: fslogixShareName
    fslogixShareQuotaGiB: fslogixShareQuotaGiB
    enablePublicNetworkAccess: enablePublicNetworkAccess
    privateEndpointSubnetResourceId: privateEndpointSubnetResourceId
    filePrivateDnsZoneResourceId: filePrivateDnsZoneResourceId
  }
}

// Outputs

@description('Name of the resource group containing the storage resources.')
output storageResourceGroupName string = storageResourceGroupName

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
