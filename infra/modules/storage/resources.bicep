targetScope = 'resourceGroup'

/*
AVD Deployment / Storage Deployment

Deploys:
- Premium Azure Files storage account for FSLogix profiles
- SMB file share for FSLogix profile containers
*/

import {
  EnvironmentName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  resourcePurpose
} from '../../shared/config.bicep'

import {
  storageAccountName
} from '../../shared/naming.bicep'

@description('Environment to deploy to')
param environment EnvironmentName

@description('Tags applied to deployed resources.')
param tags object

@description('Name of the FSLogix profile file share.')
param fslogixShareName string = 'profiles'

@description('Provisioned size of the FSLogix profile share in GiB. Premium Azure Files performance scales with provisioned capacity.')
@minValue(100)
param fslogixShareQuotaGiB int = 1024

@description('Enable public network access. Use false when private endpoints are configured.')
param enablePublicNetworkAccess bool = true

@description('Optional subnet resource ID for the Azure Files private endpoint.')
param privateEndpointSubnetResourceId string = ''

@description('Optional private DNS zone resource ID for privatelink.file.core.windows.net.')
param filePrivateDnsZoneResourceId string = ''

var environmentConfig = environmentConfigMap[environment]

// First generate a deterministic unique suffix for the storage account using the uniqueString function with stable inputs:

var storageUniqueSuffix = uniqueString(
  subscription().id,
  resourceGroup().id,
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfigMap[environment].shortName
)

// Then build the storage account name using the helper function with the precomputed suffix:
var fslogixStorageAccountName = storageAccountName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfig.shortname,
  storageUniqueSuffix
)

var enablePrivateEndpoint = !empty(privateEndpointSubnetResourceId)

module fslogixStorage 'br/public:avm/res/storage/storage-account:0.32.1' = {
  name: 'deploy-${fslogixStorageAccountName}'
  params: {
    name: fslogixStorageAccountName
    location: commonConfig.location
    tags: tags

    kind: 'FileStorage'
    skuName: 'Premium_LRS'

    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true

    publicNetworkAccess: enablePublicNetworkAccess ? 'Enabled' : 'Disabled'

    networkAcls: enablePublicNetworkAccess
      ? {
          bypass: 'AzureServices'
          defaultAction: 'Allow'
        }
      : {
          bypass: 'AzureServices'
          defaultAction: 'Deny'
        }

    fileServices: {
      shareDeleteRetentionPolicy: {
        enabled: true
        days: 14
      }
      shares: [
        {
          name: fslogixShareName
          enabledProtocols: 'SMB'
          shareQuota: fslogixShareQuotaGiB
        }
      ]
    }

    privateEndpoints: enablePrivateEndpoint
      ? [
          {
            service: 'file'
            subnetResourceId: privateEndpointSubnetResourceId
            privateDnsZoneGroup: !empty(filePrivateDnsZoneResourceId)
              ? {
                  privateDnsZoneGroupConfigs: [
                    {
                      privateDnsZoneResourceId: filePrivateDnsZoneResourceId
                    }
                  ]
                }
              : null
          }
        ]
      : []
  }
}

var storageSuffix = az.environment().suffixes.storage
var fileEndpointSuffix = 'file.${storageSuffix}'

output storageAccountName string = fslogixStorage.outputs.name
output storageAccountResourceId string = fslogixStorage.outputs.resourceId
output fileShareNames array = [
  fslogixShareName
]
output fileSharePaths array = [
  '\\\\${fslogixStorage.outputs.name}.${fileEndpointSuffix}\\${fslogixShareName}'
]
output fslogixProfilePath string = '\\\\${fslogixStorage.outputs.name}.${fileEndpointSuffix}\\${fslogixShareName}'
