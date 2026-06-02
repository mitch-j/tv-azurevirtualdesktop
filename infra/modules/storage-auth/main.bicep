targetScope = 'subscription'

/*
AVD Deployment / Storage-Auth Deployment

Deploys:
- Correct RBAC roles for the newly created Storage Account
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
  resourceGroupName
  storageAccountName
} from '../../shared/naming.bicep'

@description('Deployment environment.')
param environment EnvironmentName

@description('FSLogix file share name.')
param fslogixShareName string = 'profiles'

@description('Object IDs of the AD/Azure groups containing AVD users.')
param avdUserGroupObjectIds array

@description('Object IDs of the AD/Azure groups containing AVD admins.')
param avdAdminGroupObjectIds array

var environmentConfig = environmentConfigMap[environment]

var storageRGName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.storage,
  environmentConfig.shortName
)

var storageResourceGroupId = subscriptionResourceId(
  'Microsoft.Resources/resourceGroups',
  storageRGName
)

var storageUniqueSuffix = uniqueString(
  subscription().id,
  storageResourceGroupId,
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfig.shortName
)

var fslogixAccountName = storageAccountName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.fslogix,
  environmentConfig.shortName,
  storageUniqueSuffix
)

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

output storageResourceGroupName string = storageRGName
output storageAccountName string = fslogixAccountName
output fslogixShareName string = fslogixShareName
