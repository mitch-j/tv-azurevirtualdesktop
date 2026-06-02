targetScope = 'subscription'

/*
AVD Deployment / Storage Deployment

Deploys:
- Resource group for storage resources
- Premium Azure Files storage account
- SMB file share for FSLogix profile containers
*/

import {
  EnvironmentName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  standardTags
  resourcePurpose
} from '../../shared/config.bicep'

import {
  resourceGroupName
} from '../../shared/naming.bicep'

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

var environmentConfig = environmentConfigMap[environment]

var tags = union(standardTags, {
  Environment: environmentConfig.tagEnvironment
})

var storageRGName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.storage,
  environmentConfig.shortName
)

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

output resourceGroupName string = storageRGName
output storageAccountName string = storageResources.outputs.storageAccountName
output storageAccountResourceId string = storageResources.outputs.storageAccountResourceId
output fileShareNames array = storageResources.outputs.fileShareNames
output fileSharePaths array = storageResources.outputs.fileSharePaths
output fslogixProfilePath string = storageResources.outputs.fslogixProfilePath
