using '../main.bicep'

/* This parameter file configures the deployment for the proof-of-concept environment. */

param environmentName = 'poc'
param location = 'useast'
param repositoryName = 'tv-azurevirtualdesktop'

param tags = {
  Division: 'Information Technology'
  Product: 'AVD'
  Environment: 'Proof of Concept'
}

param workloadName = 'avd'

// param workspaceFriendlyName = 'True Value AVD POC Workspace'
param publicNetworkAccess = 'Enabled'

param hostPools = [
  {
    name: 'ops-pooled'
    friendlyName: 'True Value AVD POC Ops Pooled'
    description: 'Pooled AVD host pool for Ops users.'
    hostPoolType: 'Pooled'
    loadBalancerType: 'DepthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 10
    validationEnvironment: false
    startVMOnConnect: true
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;'
  }
  {
    name: 'dev-pooled'
    friendlyName: 'True Value AVD POC Dev Pooled'
    description: 'Pooled AVD host pool for Dev users.'
    hostPoolType: 'Pooled'
    loadBalancerType: 'DepthFirst'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 10
    validationEnvironment: false
    startVMOnConnect: false
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;'
  }
  {
    name: 'dev-personal'
    friendlyName: 'True Value AVD POC Dev Personal'
    description: 'Personal AVD host pool for Dev users.'
    hostPoolType: 'Personal'
    loadBalancerType: 'Persistent'
    preferredAppGroupType: 'Desktop'
    maxSessionLimit: 1
    validationEnvironment: false
    startVMOnConnect: false
    customRdpProperty: 'drivestoredirect:s:;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:0;devicestoredirect:s:;redirectcomports:i:0;redirectsmartcards:i:0;usbdevicestoredirect:s:;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;'
  }
]
