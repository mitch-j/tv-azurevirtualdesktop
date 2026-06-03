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
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  resourcePurpose
} from '../../shared/config.bicep'

import {
  resourceGroupName
  storageAccountName
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment.')
param environment EnvironmentName

@description('FSLogix file share name.')
param fslogixShareName string = 'profiles'

@description('Microsoft Entra group object IDs that receive standard FSLogix profile share access.')
param avdUserGroupObjectIds array

@description('Microsoft Entra group object IDs that receive elevated FSLogix profile share access.')
param avdAdminGroupObjectIds array

// Variables

// Environment-specific naming and tagging configuration.
var environmentConfig = environmentConfigMap[environment]

// Name of the resource group containing the FSLogix storage account.
var storageRGName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.storage,
  environmentConfig.shortName
)

// Resource ID of the storage resource group used as a stable naming input.
var storageResourceGroupId = subscriptionResourceId(
  'Microsoft.Resources/resourceGroups',
  storageRGName
)

// Deterministic suffix used to derive the FSLogix storage account name.
var storageUniqueSuffix = uniqueString(
  subscription().id,
  storageResourceGroupId,
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfig.shortName
)

// Name of the FSLogix storage account that receives share-level RBAC assignments.
var fslogixAccountName = storageAccountName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfig.shortName,
  storageUniqueSuffix
)

// Modules

module storageAuthResources './resources.bicep' = {
  name: 'deploy-avd-storage-auth-${environment}'
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
