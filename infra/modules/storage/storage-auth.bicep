targetScope = 'resourceGroup'

/*
AVD Deployment / FSLogix Storage Auth

Scope:
- Resource Group

Deploys:
- Storage File Data SMB Share Contributor assignments for AVD user groups
- Storage File Data SMB Share Elevated Contributor assignments for AVD admin groups

Does not deploy:
- Storage accounts
- File shares
- AVD service objects
- Session host virtual machines
*/

// Imports

import {
  roleDefinitionIds
} from '../../shared/config.bicep'

// Parameters

@description('Name of the existing FSLogix storage account.')
param storageAccountName string

@description('Name of the existing FSLogix profile file share.')
param fslogixShareName string = 'profiles'

@description('Microsoft Entra group object IDs that receive Storage File Data SMB Share Contributor on the FSLogix share.')
param avdUserGroupObjectIds array

@description('Microsoft Entra group object IDs that receive Storage File Data SMB Share Elevated Contributor on the FSLogix share.')
param avdAdminGroupObjectIds array

// Variables

var storageFileDataSmbShareContributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  roleDefinitionIds.storage.fileDataSmbShareContributor
)

var storageFileDataSmbShareElevatedContributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  roleDefinitionIds.storage.fileDataSmbShareElevatedContributor
)

// Existing Resources

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' existing = {
  name: storageAccountName
}

resource defaultFileService 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' existing = {
  name: 'default'
  parent: storageAccount
}

resource fslogixShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-01-01' existing = {
  name: fslogixShareName
  parent: defaultFileService
}

// Role Assignments

// Assignments are scoped to the profile share so AVD groups do not receive broader storage account access.
resource avdUsersShareContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for groupObjectId in avdUserGroupObjectIds: {
    name: guid(fslogixShare.id, groupObjectId, storageFileDataSmbShareContributorRoleDefinitionId)
    scope: fslogixShare
    properties: {
      principalId: groupObjectId
      principalType: 'Group'
      roleDefinitionId: storageFileDataSmbShareContributorRoleDefinitionId
    }
  }
]

resource avdAdminsShareElevatedContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for groupObjectId in avdAdminGroupObjectIds: {
    name: guid(fslogixShare.id, groupObjectId, storageFileDataSmbShareElevatedContributorRoleDefinitionId)
    scope: fslogixShare
    properties: {
      principalId: groupObjectId
      principalType: 'Group'
      roleDefinitionId: storageFileDataSmbShareElevatedContributorRoleDefinitionId
    }
  }
]

// Outputs

@description('Resource IDs of the Storage File Data SMB Share Contributor role assignments created for AVD user groups.')
output avdUsersShareContributorRoleAssignmentIds array = [
  for index in range(0, length(avdUserGroupObjectIds)): avdUsersShareContributor[index].id
]

@description('Resource IDs of the Storage File Data SMB Share Elevated Contributor role assignments created for AVD admin groups.')
output avdAdminsShareElevatedContributorRoleAssignmentIds array = [
  for index in range(0, length(avdAdminGroupObjectIds)): avdAdminsShareElevatedContributor[index].id
]
