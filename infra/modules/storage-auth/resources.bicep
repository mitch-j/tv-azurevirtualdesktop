targetScope = 'resourceGroup'

@description('FSLogix storage account name.')
param storageAccountName string

@description('FSLogix file share name.')
param fslogixShareName string = 'profiles'

@description('Object ID of the AD/Azure group containing AVD users.')
param avdUserGroupObjectIds array

@description('Object ID of the AD/Azure group containing AVD admins.')
param avdAdminGroupObjectIds array

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' existing = {
  name: storageAccountName
}

resource fslogixShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-08-01' existing = {
  name: '${storageAccount.name}/default/${fslogixShareName}'
}

resource avdUsersShareContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for groupObjectId in avdUserGroupObjectIds: {
    name: guid(fslogixShare.id, groupObjectId, 'Storage File Data SMB Share Contributor')
    scope: fslogixShare
    properties: {
      principalId: groupObjectId
      principalType: 'Group'
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '0c867c2a-1d8c-454a-a3db-ab2ea1bdc8bb'
      )
    }
  }
]

resource avdAdminsShareElevatedContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for groupObjectId in avdAdminGroupObjectIds: {
    name: guid(fslogixShare.id, groupObjectId, 'Storage File Data SMB Share Elevated Contributor')
    scope: fslogixShare
    properties: {
      principalId: groupObjectId
      principalType: 'Group'
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        'a7264617-510b-434b-a828-9731dc254ea7'
      )
    }
  }
]
