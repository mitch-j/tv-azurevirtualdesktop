using 'main.bicep'

param environment = 'poc'

param workspaces = [
  {
    name: 'primary'
    friendlyName: 'True Value AVD POC'
    description: 'Primary Azure Virtual Desktop workspace for the POC environment.'
    publicNetworkAccess: 'Disabled'
  }
]

param hostPools = [
  {
    name: 'opsPooled'
    friendlyName: 'True Value AVD POC Ops Pooled'
    description: 'Pooled AVD host pool for Ops users.'
    hostPoolType: 'Pooled'
    loadBalancerType: 'DepthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 10
    validationEnvironment: false
    startVMOnConnect: true
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;'
    publicNetworkAccess: 'Disabled'
    desktopApplicationGroup: {
      name: 'opsPooledDesktop'
      friendlyName: 'True Value AVD POC Ops Desktop'
      description: 'Desktop application group for Ops pooled users.'
      workspaceName: 'primary'
      rbacAssignments: [
        {
          principalId: 'aa09d144-a544-4cc9-b0bc-ff053061445c'
          principalType: 'Group'
          roleDefinitionId: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
        }
      ]
    }
  }
  {
    name: 'devPooled'
    friendlyName: 'True Value AVD POC Dev Pooled'
    description: 'Pooled AVD host pool for Dev users.'
    hostPoolType: 'Pooled'
    loadBalancerType: 'DepthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 10
    validationEnvironment: false
    startVMOnConnect: false
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;'
    publicNetworkAccess: 'Disabled'
    desktopApplicationGroup: {
      name: 'devPooledDesktop'
      friendlyName: 'True Value AVD POC Dev Pooled Desktop'
      description: 'Desktop application group for Dev pooled users.'
      workspaceName: 'primary'
      rbacAssignments: [
        {
          principalId: 'aa09d144-a544-4cc9-b0bc-ff053061445c'
          principalType: 'Group'
          roleDefinitionId: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
        }
      ]
    }
  }
  {
    name: 'devPersonal'
    friendlyName: 'True Value AVD POC Dev Personal'
    description: 'Personal AVD host pool for Dev users.'
    hostPoolType: 'Personal'
    loadBalancerType: 'Persistent'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 1
    validationEnvironment: false
    startVMOnConnect: false
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;'
    publicNetworkAccess: 'Disabled'
    desktopApplicationGroup: {
      name: 'devPersonalDesktop'
      friendlyName: 'True Value AVD POC Dev Personal Desktop'
      description: 'Desktop application group for Dev personal desktops.'
      workspaceName: 'primary'
      rbacAssignments: [
        {
          principalId: 'ebdf4719-7e5e-4b65-89a5-2a7d24627f75'
          principalType: 'Group'
          roleDefinitionId: '1d18fff3-a72a-46b5-b4a9-0b38a3cd7e63'
        }
      ]
    }
  }
]
