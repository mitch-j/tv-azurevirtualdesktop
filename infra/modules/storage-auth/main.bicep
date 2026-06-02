targetScope = 'subscription'

import {
  EnvironmentName
} from '../../shared/types.bicep'

@description('Deployment environment.')
param environment EnvironmentName

@description('Resource group containing the FSLogix storage account.')
param storageResourceGroupName string

@description('FSLogix storage account name.')
param storageAccountName string

@description('FSLogix file share name.')
param fslogixShareName string = 'profiles'

@description('Object ID of the AD/Azure group containing AVD users.')
param avdUserGroupObjectIds array

@description('Object ID of the AD/Azure group containing AVD admins.')
param avdAdminGroupObjectIds array

module storageAuthResources './resources.bicep' = {
  name: 'deploy-avd-storage-auth-${environment}'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    storageAccountName: storageAccountName
    fslogixShareName: fslogixShareName
    avdUserGroupObjectIds: avdUserGroupObjectIds
    avdAdminGroupObjectIds: avdAdminGroupObjectIds
  }
}
