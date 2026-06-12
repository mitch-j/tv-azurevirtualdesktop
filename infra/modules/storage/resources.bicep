targetScope = 'resourceGroup'

/*
AVD Deployment / Storage Account

Scope:
- Resource Group

Deploys:
- FSLogix storage account
- FSLogix profile file share

Does not deploy:
- Storage RBAC assignments
- Private endpoints
- Private DNS records
- Session host virtual machines
*/

// Imports

import {
  PublicNetworkAccess
  StandardTags
  StorageAccountSkuName
} from '../../shared/types.bicep'

import {
  roleDefinitionIds
} from '../../shared/config.bicep'

// Types

@description('Supported storage account kind values for this module.')
type StorageAccountKind =
  | 'FileStorage'
  | 'StorageV2'

// Parameters

@description('Azure region where the storage account is deployed.')
param location string

@description('Tags applied to storage resources.')
param tags StandardTags

@description('Name of the FSLogix storage account.')
param storageAccountName string

@description('SKU for the FSLogix storage account.')
param storageAccountSkuName StorageAccountSkuName = 'Premium_LRS'

@description('Storage account kind. FileStorage is recommended for Premium Azure Files.')
param storageAccountKind StorageAccountKind = 'FileStorage'

@description('Public network access setting for the storage account.')
param publicNetworkAccess PublicNetworkAccess = 'Disabled'

@description('FSLogix profile file share name.')
param fslogixShareName string = 'profiles'

@description('Provisioned size of the FSLogix profile file share in GiB.')
param fslogixShareQuotaGiB int = 1024

@description('Deploy FSLogix profile share RBAC assignments.')
param deployStorageAuth bool = true

@description('Microsoft Entra group object IDs that receive Storage File Data SMB Share Contributor on the FSLogix share.')
param avdUserGroupObjectIds array = []

@description('Microsoft Entra group object IDs that receive Storage File Data SMB Share Elevated Contributor on the FSLogix share.')
param avdAdminGroupObjectIds array = []

@description('Name of the Azure Files private endpoint.')
param privateEndpointName string

@description('Resource ID of the subnet used for the storage private endpoint.')
param privateEndpointSubnetResourceId string

@description('Name of the private DNS zone group attached to the private endpoint.')
param privateDnsZoneGroupName string = 'default'

@description('Resource ID of the Azure Files private DNS zone.')
param filePrivateDnsZoneResourceId string

@description('Resource ID of the Log Analytics workspace used for diagnostics.')
param logAnalyticsWorkspaceResourceId string = ''

@description('Deploy diagnostic settings for resources created by this module.')
param deployDiagnosticSettings bool = true

// Variables

var fslogixShareResourceId = resourceId(
  'Microsoft.Storage/storageAccounts/fileServices/shares',
  storageAccountName,
  'default',
  fslogixShareName
)

// AVM's file share role assignment implementation uses /fileshares/ for the RBAC extension scope.
// The actual file share resource ID remains /shares/.
var fslogixShareRoleAssignmentScopeResourceId = replace(
  fslogixShareResourceId,
  '/shares/',
  '/fileshares/'
)

var storageFileDataSmbShareContributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  roleDefinitionIds.storage.fileDataSmbShareContributor
)

var storageFileDataSmbShareElevatedContributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  roleDefinitionIds.storage.fileDataSmbShareElevatedContributor
)

var avdUserGroupObjectIdsForShareRoleAssignments = deployStorageAuth ? avdUserGroupObjectIds : []
var avdAdminGroupObjectIdsForShareRoleAssignments = deployStorageAuth ? avdAdminGroupObjectIds : []

var avdUserShareRoleAssignments = [
  for groupObjectId in avdUserGroupObjectIdsForShareRoleAssignments: {
    name: guid(fslogixShareResourceId, groupObjectId, storageFileDataSmbShareContributorRoleDefinitionId)
    principalId: groupObjectId
    principalType: 'Group'
    roleDefinitionIdOrName: storageFileDataSmbShareContributorRoleDefinitionId
  }
]

var avdAdminShareRoleAssignments = [
  for groupObjectId in avdAdminGroupObjectIdsForShareRoleAssignments: {
    name: guid(fslogixShareResourceId, groupObjectId, storageFileDataSmbShareElevatedContributorRoleDefinitionId)
    principalId: groupObjectId
    principalType: 'Group'
    roleDefinitionIdOrName: storageFileDataSmbShareElevatedContributorRoleDefinitionId
  }
]

var fslogixShareRoleAssignments = concat(
  avdUserShareRoleAssignments,
  avdAdminShareRoleAssignments
)

var avdUsersShareContributorRoleAssignmentIds = [
  for groupObjectId in avdUserGroupObjectIdsForShareRoleAssignments: extensionResourceId(
    fslogixShareRoleAssignmentScopeResourceId,
    'Microsoft.Authorization/roleAssignments',
    guid(fslogixShareResourceId, groupObjectId, storageFileDataSmbShareContributorRoleDefinitionId)
  )
]

var avdAdminsShareElevatedContributorRoleAssignmentIds = [
  for groupObjectId in avdAdminGroupObjectIdsForShareRoleAssignments: extensionResourceId(
    fslogixShareRoleAssignmentScopeResourceId,
    'Microsoft.Authorization/roleAssignments',
    guid(fslogixShareResourceId, groupObjectId, storageFileDataSmbShareElevatedContributorRoleDefinitionId)
  )
]

var storageAccountDiagnosticSettings = deployDiagnosticSettings && !empty(logAnalyticsWorkspaceResourceId)
  ? [
      {
        name: 'diag-storage-account'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ]
  : []

var fileServiceDiagnosticSettings = deployDiagnosticSettings && !empty(logAnalyticsWorkspaceResourceId)
  ? [
      {
        name: 'diag-file-service'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ]
  : []

// Resources

module fslogixStorageAccount 'br/public:avm/res/storage/storage-account:0.32.1' = {
  name: '${deployment().name}-sa'
  params: {
    name: storageAccountName
    location: location
    tags: tags

    skuName: storageAccountSkuName
    kind: storageAccountKind

    allowBlobPublicAccess: false
    allowCrossTenantReplication: false

    // Keep this true for now unless/until storage account key usage is fully removed from your setup process.
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false

    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: true

    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }

    diagnosticSettings: storageAccountDiagnosticSettings

    fileServices: {
      shareDeleteRetentionPolicy: {
        enabled: true
        days: 7
      }
      diagnosticSettings: fileServiceDiagnosticSettings
      shares: [
        {
          name: fslogixShareName
          accessTier: storageAccountKind == 'FileStorage' ? 'Premium' : 'TransactionOptimized'
          enabledProtocols: 'SMB'
          shareQuota: fslogixShareQuotaGiB
          roleAssignments: fslogixShareRoleAssignments
        }
      ]
    }

    privateEndpoints: [
      {
        name: privateEndpointName
        service: 'file'
        subnetResourceId: privateEndpointSubnetResourceId
        privateDnsZoneGroup: {
          name: privateDnsZoneGroupName
          privateDnsZoneGroupConfigs: [
            {
              name: 'file'
              privateDnsZoneResourceId: filePrivateDnsZoneResourceId
            }
          ]
        }
        tags: tags
      }
    ]
  }
}

// Outputs

@description('Name of the FSLogix storage account.')
output storageAccountName string = fslogixStorageAccount.outputs.name

@description('Resource ID of the FSLogix storage account.')
output storageAccountResourceId string = fslogixStorageAccount.outputs.resourceId

@description('Name of the FSLogix profile file share.')
output fslogixShareName string = fslogixShareName

@description('Resource ID of the FSLogix profile file share.')
output fslogixShareResourceId string = fslogixShareResourceId

@description('Role assignment scope Resource ID used for FSLogix profile share RBAC.')
output fslogixShareRoleAssignmentScopeResourceId string = fslogixShareRoleAssignmentScopeResourceId

var fslogixShareUncPath = '\\\\${fslogixStorageAccount.outputs.name}.file.${environment().suffixes.storage}\\${fslogixShareName}'

@description('UNC path for the FSLogix profile file share.')
output fslogixShareUncPath string = fslogixShareUncPath

@description('Primary service endpoints for the FSLogix storage account.')
output storageAccountServiceEndpoints object = fslogixStorageAccount.outputs.serviceEndpoints

@description('Primary Azure Files endpoint for the FSLogix storage account.')
output fileEndpoint string = fslogixStorageAccount.outputs.serviceEndpoints.?file ?? ''

@description('Name of the Azure Files private endpoint.')
output privateEndpointName string = length(fslogixStorageAccount.outputs.privateEndpoints) > 0
  ? fslogixStorageAccount.outputs.privateEndpoints[0].name
  : ''

@description('Resource ID of the Azure Files private endpoint.')
output privateEndpointResourceId string = length(fslogixStorageAccount.outputs.privateEndpoints) > 0
  ? fslogixStorageAccount.outputs.privateEndpoints[0].resourceId
  : ''

@description('Network interface resource IDs created for the Azure Files private endpoint.')
output privateEndpointNetworkInterfaceResourceIds array = length(fslogixStorageAccount.outputs.privateEndpoints) > 0
  ? fslogixStorageAccount.outputs.privateEndpoints[0].networkInterfaceResourceIds
  : []

@description('Resource IDs of the Storage File Data SMB Share Contributor role assignments created for AVD user groups.')
output avdUsersShareContributorRoleAssignmentIds array = avdUsersShareContributorRoleAssignmentIds

@description('Resource IDs of the Storage File Data SMB Share Elevated Contributor role assignments created for AVD admin groups.')
output avdAdminsShareElevatedContributorRoleAssignmentIds array = avdAdminsShareElevatedContributorRoleAssignmentIds
