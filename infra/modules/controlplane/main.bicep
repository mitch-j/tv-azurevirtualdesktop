targetScope = resourceGroup()

/* AVD Deployment - Control Plane Module
This module is responsible for building the control plane components of the AVD environment,
including host pools, application groups, and workspaces. It is designed to be deployed after
the bootstrap module has created the necessary resource groups and foundational infrastructure.
The control plane module focuses on deploying the AVD-specific resources that enable virtual desktop
and application delivery to end users.
*/

import {
  commonConfig
  environmentConfigMap
} from '../../shared/config.bicep'

import {
  EnvironmentName
} from '../../shared/types.bicep'

import {
  hostPoolName
  applicationGroupName
  workspaceName
} from '../../shared/naming.bicep'

param environment EnvironmentName
param hostPoolShortName string = 'pooled'

var environmentConfig = environmentConfigMap[environment]

@description('Host pool definitions to create for this AVD environment.')
param hostPools array


var avdDesktopAppGroupName = applicationGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  '${hostPoolShortName}-desktop',
  environmentConfig.shortName
)

var avdWorkspaceName = workspaceName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  'main',
  environmentConfig.shortName
)

module hostPool 'br/public:avm/res/desktop-virtualization/host-pool:0.8.1' = [
  for hostPoolItem in hostPools: {
    name: 'deploy-$'
    scope: resourceGroup(coreResourceGroupName)
    dependsOn: [
      avdResourceGroups
    ]
    params: {
      name: '${normalizedPrefix}-${normalizedWorkload}-vdpool-${toLower(hostPoolItem.name)}-${normalizedEnvironment}'
      location: location
      tags: tags

      friendlyName: hostPoolItem.friendlyName
      description: hostPoolItem.description
      hostPoolType: hostPoolItem.hostPoolType
      loadBalancerType: hostPoolItem.loadBalancerType
      preferredAppGroupType: hostPoolItem.preferredAppGroupType
      maxSessionLimit: hostPoolItem.maxSessionLimit
      validationEnvironment: hostPoolItem.validationEnvironment
      startVMOnConnect: hostPoolItem.startVMOnConnect
      customRdpProperty: hostPoolItem.customRdpProperty
      publicNetworkAccess: publicNetworkAccess

      lock: {
        kind: 'CanNotDelete'
      }
    }
  }
]

module desktopApplicationGroup 'br/public:avm/res/desktop-virtualization/application-group:0.4.2' = [
  for appGroup in desktopApplicationGroups: {
    name: 'deploy-${appGroup.name}'
    scope: resourceGroup(coreResourceGroupName)
    dependsOn: [
      hostPool
    ]
    params: {
      name: appGroup.name
      location: location
      tags: tags

      applicationGroupType: 'Desktop'
      hostpoolName: appGroup.hostPoolName

      friendlyName: appGroup.friendlyName
      description: appGroup.description
      showInFeed: true

      lock: {
        kind: 'CanNotDelete'
      }

      enableTelemetry: false
    }
  }
]

module workspace 'br/public:avm/res/desktop-virtualization/workspace:0.9.2' = {
  name: 'deploy-${workspaceName}'
  scope: resourceGroup(coreResourceGroupName)
  dependsOn: [
    desktopApplicationGroup
  ]
  params: {
    name: workspaceName
    location: location
    tags: tags

    friendlyName: workspaceFriendlyName
    description: 'Azure Virtual Desktop workspace for ${workspaceFriendlyName}.'
    publicNetworkAccess: publicNetworkAccess

    applicationGroupReferences: [
      for appGroup in desktopApplicationGroups: appGroup.resourceId
    ]

    lock: {
      kind: 'CanNotDelete'
    }

    enableTelemetry: false
  }
}
