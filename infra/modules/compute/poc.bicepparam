using 'main.bicep'

/*
AVD Deployment / Compute Parameters

Environment:
- poc

Used by:
- infra/modules/compute/main.bicep

Notes:
- This pass creates network interfaces for planned session hosts.
- Session host virtual machines are not deployed yet.
- Do not store secrets, credentials, private keys, registration tokens, or certificate material in this file.
*/

param environment = 'poc'
param location = 'eastus'

param deployNetworkInterfaces = true

param sessionHostGroups = [
  {
    purpose: 'opsPooled'
    sessionHostRoleCode: 'ops'
    vmCount: 1
    vmSize: 'Standard_E16as_v5'
    osDisk: {
      storageAccountType: 'Premium_LRS'
      diskSizeGB: 128
    }
  }
  {
    purpose: 'devPersonal'
    sessionHostRoleCode: 'dvp'
    vmCount: 1
    vmSize: 'Standard_D8als_v6'
    osDisk: {
      storageAccountType: 'Premium_LRS'
      diskSizeGB: 256
    }
  }
  {
    purpose: 'devPooled'
    sessionHostRoleCode: 'dvs'
    vmCount: 1
    vmSize: 'Standard_D8as_v7'
    osDisk: {
      storageAccountType: 'Premium_LRS'
      diskSizeGB: 256
    }
  }
]

param enableTrustedLaunch = true
param secureBootEnabled = true
param vTpmEnabled = true

param licenseType = 'Windows_Client'
param patchMode = 'AutomaticByOS'

param sessionHostImageVersionResourceId = '/subscriptions/f70559ab-d7c3-453e-98c5-bea562d2a102/resourceGroups/tv-avd-rg-shared/providers/Microsoft.Compute/galleries/tv_avd_gal_img/images/win11-25h2-avd-m365/versions/0.0.1'
param deployDomainJoinExtension = false

param domainName = 'TV.local'
// param domainJoinOuPath = 'placeholder,OU=Session Hosts,OU=AVD,OU=Azure,DC=TV,DC=local'
param domainJoinOptions = 3

param restartAfterDomainJoin = true
