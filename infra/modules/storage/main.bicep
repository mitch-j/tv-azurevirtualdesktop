targetScope = 'subscription'

/*
AVD Deployment / Storage

Scope:
- Subscription

Deploys:
- Storage resource group
- FSLogix storage account
- FSLogix profile file share
- FSLogix profile share RBAC assignments

Does not deploy:
- AVD host pools, desktop application groups, or workspaces
- Session host virtual machines
- Network resources
- Private endpoints
*/

// Imports

import {
  EnvironmentName
  LocationName
  StorageAccountSkuName
} from '../../shared/types.bicep'

import {
  baseTags
  commonConfig
  environmentConfigMap
  fslogixConfig
  locationConfigMap
  resourceDefaults
  resourceGroupPurpose
  resourcePurpose
  resourceType
} from '../../shared/config.bicep'

import {
  storageAccountNameWithLocation
  resourceGroupNameWithLocation
  resourceNameWithPurposeAndLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment.')
param environment EnvironmentName

@description('Azure region where storage resources are deployed.')
param location LocationName

@description('FSLogix profile file share name. Leave blank to use the shared FSLogix configuration default.')
param fslogixShareName string = ''

@description('Provisioned size of the FSLogix profile file share in GiB.')
param fslogixShareQuotaGiB int = 1024

@description('SKU for the FSLogix storage account.')
param storageAccountSkuName StorageAccountSkuName = 'Premium_LRS'

@description('Deploy FSLogix storage RBAC assignments.')
param deployStorageAuth bool = true

@description('Microsoft Entra group object IDs that receive standard FSLogix profile share access.')
param avdUserGroupObjectIds array = []

@description('Microsoft Entra group object IDs that receive elevated FSLogix profile share access.')
param avdAdminGroupObjectIds array = []

@description('Resource ID of the subnet used for storage private endpoints.')
param privateEndpointSubnetResourceId string

@description('Resource ID of the Azure Files private DNS zone.')
param filePrivateDnsZoneResourceId string

// Variables

var effectiveFslogixShareName = empty(fslogixShareName) ? fslogixConfig.shareName : fslogixShareName
var environmentConfig = environmentConfigMap[environment]
var locationConfig = locationConfigMap[location]

var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

var storageFilePrivateEndpointName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.privateEndpoint,
  resourcePurpose.fslogix,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Resource Names

var storageResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.storage,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var storageResourceGroupResourceId = subscriptionResourceId(
  'Microsoft.Resources/resourceGroups',
  storageResourceGroupName
)

// Location is included in the storage account hash input so regional deployments produce distinct deterministic names.
var fslogixStorageAccountName = storageAccountNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  locationConfig.shortCode,
  environmentConfig.shortName,
  storageResourceGroupResourceId
)

// Modules

module storageResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${deployment().name}-${locationConfig.shortCode}-storage-rg'
  params: {
    name: storageResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module fslogixStorage './storage-account.bicep' = {
  name: '${deployment().name}-${locationConfig.shortCode}-fslogix-storage'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    location: location
    tags: tags
    storageAccountName: fslogixStorageAccountName
    storageAccountSkuName: storageAccountSkuName
    publicNetworkAccess: resourceDefaults.publicNetworkAccess
    fslogixShareName: effectiveFslogixShareName
    fslogixShareQuotaGiB: fslogixShareQuotaGiB
  }
  dependsOn: [
    storageResourceGroup
  ]
}

module fslogixStorageAuth './storage-auth.bicep' = if (deployStorageAuth) {
  name: '${deployment().name}-${locationConfig.shortCode}-fslogix-auth'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    storageAccountName: fslogixStorage.outputs.storageAccountName
    fslogixShareName: fslogixStorage.outputs.fslogixShareName
    avdUserGroupObjectIds: avdUserGroupObjectIds
    avdAdminGroupObjectIds: avdAdminGroupObjectIds
  }
}

module storageFilePrivateEndpoint './private-endpoint.bicep' = {
  name: '${deployment().name}-${locationConfig.shortCode}-storage-file-pe'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    location: location
    tags: tags
    privateEndpointName: storageFilePrivateEndpointName
    privateEndpointSubnetResourceId: privateEndpointSubnetResourceId
    filePrivateDnsZoneResourceId: filePrivateDnsZoneResourceId
    storageAccountName: fslogixStorage.outputs.storageAccountName
  }
}


// Outputs

@description('Name of the resource group containing the FSLogix storage account.')
output storageResourceGroupName string = storageResourceGroupName

@description('Resource ID of the resource group containing the FSLogix storage account.')
output storageResourceGroupResourceId string = storageResourceGroupResourceId

@description('Name of the FSLogix storage account.')
output fslogixStorageAccountName string = fslogixStorage.outputs.storageAccountName

@description('Resource ID of the FSLogix storage account.')
output fslogixStorageAccountResourceId string = fslogixStorage.outputs.storageAccountResourceId

@description('Name of the FSLogix profile file share.')
output fslogixShareName string = fslogixStorage.outputs.fslogixShareName

@description('Resource ID of the FSLogix profile file share.')
output fslogixShareResourceId string = fslogixStorage.outputs.fslogixShareResourceId

@description('Resource IDs of the Storage File Data SMB Share Contributor role assignments created for AVD user groups.')
output avdUsersShareContributorRoleAssignmentIds array = deployStorageAuth ? fslogixStorageAuth!.outputs.avdUsersShareContributorRoleAssignmentIds : []

@description('Resource IDs of the Storage File Data SMB Share Elevated Contributor role assignments created for AVD admin groups.')
output avdAdminsShareElevatedContributorRoleAssignmentIds array = deployStorageAuth ? fslogixStorageAuth!.outputs.avdAdminsShareElevatedContributorRoleAssignmentIds : []
