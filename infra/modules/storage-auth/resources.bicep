targetScope = 'resourceGroup'

/*
AVD Deployment / Storage Auth Resources

Scope:
- Resource Group

Deploys:
- Storage File Data SMB Share Contributor assignments for AVD user groups
- Storage File Data SMB Share Elevated Contributor assignments for AVD admin groups

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
  storageRoleDefinitionIds
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

// Existing Resources

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: storageAccountName
}

resource fslogixShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-08-01' existing = {
  name: '${storageAccount.name}/default/${fslogixShareName}'
}

// Role Assignments

// Grants standard FSLogix profile share access to AVD user groups.
resource avdUsersShareContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for groupObjectId in avdUserGroupObjectIds: {
    name: guid(fslogixShare.id, groupObjectId, 'Storage File Data SMB Share Contributor')
    scope: fslogixShare
    properties: {
      principalId: groupObjectId
      principalType: 'Group'
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        storageRoleDefinitionIds.fileDataSmbShareContributor
      )
    }
  }
]

// Grants elevated FSLogix profile share access to AVD admin groups.
resource avdAdminsShareElevatedContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for groupObjectId in avdAdminGroupObjectIds: {
    name: guid(fslogixShare.id, groupObjectId, 'Storage File Data SMB Share Elevated Contributor')
    scope: fslogixShare
    properties: {
      principalId: groupObjectId
      principalType: 'Group'
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        storageRoleDefinitionIds.fileDataSmbShareElevatedContributor
      )
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
