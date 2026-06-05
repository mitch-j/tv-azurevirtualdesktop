targetScope = 'subscription'

/*
AVD Deployment / Storage-Auth

Scope:
- Subscription

Deploys:
- FSLogix storage account RBAC assignments for AVD user groups
- FSLogix storage account RBAC assignments for AVD admin groups

Does not deploy:
- AVD Service Objects
  - Hostpools
  - Desktop Application Groups
  - Workspaces
- Storage accounts or FSLogix shares
- Session host virtual machines
*/

// Imports

import {
  EnvironmentName
  LocationName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourceGroupPurpose
  resourcePurpose
} from '../../shared/config.bicep'

import {
  resourceGroupNameWithLocation
  storageAccountNameWithLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for service object resources.')
param location LocationName

@description('Name of the FSLogix profile file share.')
param fslogixShareName string = 'profiles'

@description('Microsoft Entra group object IDs that receive standard FSLogix profile share access.')
param avdUserGroupObjectIds array

@description('Microsoft Entra group object IDs that receive elevated FSLogix profile share access.')
param avdAdminGroupObjectIds array

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Location configuration for the selected Azure region.
var locationConfig = locationConfigMap[location]

// Resource Names

// Storage-auth must use the same location-aware names as the storage module so RBAC targets the existing FSLogix account.
var storageResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.storage,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var storageResourceGroupId = subscriptionResourceId(
  'Microsoft.Resources/resourceGroups',
  storageResourceGroupName
)

var fslogixAccountName = storageAccountNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  locationConfig.shortCode,
  environmentConfig.shortName,
  resourceGroup().id
)

// Modules

module storageAuthResources './resources.bicep' = {
  name: '${deployment().name}-${locationConfig.shortCode}-stor-auth'
  scope: resourceGroup(storageRGName)
  params: {
    storageAccountName: fslogixAccountName
    fslogixShareName: fslogixShareName
    avdUserGroupObjectIds: avdUserGroupObjectIds
    avdAdminGroupObjectIds: avdAdminGroupObjectIds
  }
}

// Outputs

@description('Name of the resource group containing the FSLogix storage account.')
output storageResourceGroupName string = storageRGName

@description('Name of the FSLogix storage account that received RBAC assignments.')
output storageAccountName string = fslogixAccountName

@description('Name of the FSLogix profile file share that received RBAC assignments.')
output fslogixShareName string = fslogixShareName

@description('Resource IDs of the Storage File Data SMB Share Contributor role assignments created for AVD user groups.')
output avdUsersShareContributorRoleAssignmentIds array = storageAuthResources.outputs.avdUsersShareContributorRoleAssignmentIds

@description('Resource IDs of the Storage File Data SMB Share Elevated Contributor role assignments created for AVD admin groups.')
output avdAdminsShareElevatedContributorRoleAssignmentIds array = storageAuthResources.outputs.avdAdminsShareElevatedContributorRoleAssignmentIds
