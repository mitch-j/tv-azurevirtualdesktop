targetScope = 'resourceGroup'

/*
AVD Deployment / Storage

Scope:
- Resource Group

Deploys:
- Premium Azure Files storage account for FSLogix profiles
- SMB file share for FSLogix profile containers

Does not deploy:
- Storage Account RBAC
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
  resourcePurpose
} from '../../shared/config.bicep'

import {
  storageAccountName
} from '../../shared/naming.bicep'

// Parameters

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

// Variables

// Storage endpoint suffix for the current Azure cloud.
var storageSuffix = az.environment().suffixes.storage

// Azure Files endpoint suffix used to build UNC paths.
var fileEndpointSuffix = 'file.${storageSuffix}'

// Environment-specific naming values.
var environmentConfig = environmentConfigMap[environment]

// Generate a deterministic suffix from stable inputs to help keep the storage account name globally unique.
var storageUniqueSuffix = uniqueString(
  subscription().id,
  resourceGroup().id,
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfig.shortName
)

// Build the storage account name using the shared naming helper.
var fslogixStorageAccountName = storageAccountName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfig.shortName,
  storageUniqueSuffix
)

// Enables private endpoint deployment when a subnet resource ID is provided.
var enablePrivateEndpoint = !empty(privateEndpointSubnetResourceId)

// Modules

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

// Outputs

@description('Name of the deployed FSLogix storage account.')
output storageAccountName string = fslogixStorage.outputs.name

@description('Resource ID of the deployed FSLogix storage account.')
output storageAccountResourceId string = fslogixStorage.outputs.resourceId

@description('Names of the deployed Azure Files shares.')
output fileShareNames array = [
  fslogixShareName
]

@description('UNC paths for the deployed Azure Files shares.')
output fileSharePaths array = [
  '\\\\${fslogixStorage.outputs.name}.${fileEndpointSuffix}\\${fslogixShareName}'
]

@description('UNC path used for FSLogix profile containers.')
output fslogixProfilePath string = '\\\\${fslogixStorage.outputs.name}.${fileEndpointSuffix}\\${fslogixShareName}'
