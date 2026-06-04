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

param deployNetworkInterfaces = true

param sessionHostGroups = [
  {
    purpose: 'opsPooled'
    vmNamePrefix: 'tvavdops'
    vmCount: 1
    vmSize: 'Standard_E16as_v5'
    osDisk: {
      storageAccountType: 'Premium_LRS'
      diskSizeGB: 128
    }
  }
  {
    purpose: 'devPersonal'
    vmNamePrefix: 'tvavddp'
    vmCount: 1
    vmSize: 'Standard_D8als_v6'
    osDisk: {
      storageAccountType: 'Premium_LRS'
      diskSizeGB: 256
    }
  }
  {
    purpose: 'devPooled'
    vmNamePrefix: 'tvavddv'
    vmCount: 1
    vmSize: 'Standard_D8as_v5'
    osDisk: {
      storageAccountType: 'Premium_LRS'
      diskSizeGB: 256
    }
  }
]
