targetScope = 'resourceGroup'

/*
AVD Deployment - Control Plane Resources

Deploys:
- AVD host pools using AVM
- One desktop application group per host pool
- One or more workspaces
- Workspace publishing for desktop application groups
- Desktop Virtualization User RBAC assignments on application groups
*/

import {
  EnvironmentName
  WorkspaceConfig
  HostPoolConfig
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
} from '../../shared/config.bicep'

import {
  resourceNameWithPurpose
} from '../../shared/naming.bicep'

@description('Tags applied to deployed resources.')
param tags object

param environment EnvironmentName
param workspaces WorkspaceConfig[]
param hostPools HostPoolConfig[]

var environmentConfig = environmentConfigMap[environment]

var hostPoolNames = [
  for hostPoolItem in hostPools: resourceNameWithPurpose(
    'hostPool',
    commonConfig.namePrefix,
    commonConfig.workloadName,
    hostPoolItem.name,
    environmentConfig.shortName
  )
]

var desktopApplicationGroups = [
  for (hostPoolItem, i) in hostPools: {
    name: resourceNameWithPurpose(
      'desktopApplicationGroup',
      commonConfig.namePrefix,
      commonConfig.workloadName,
      hostPoolItem.desktopApplicationGroup.name,
      environmentConfig.shortName
    )
    id: resourceId(
      'Microsoft.DesktopVirtualization/applicationGroups',
      resourceNameWithPurpose(
        'desktopApplicationGroup',
        commonConfig.namePrefix,
        commonConfig.workloadName,
        hostPoolItem.desktopApplicationGroup.name,
        environmentConfig.shortName
      )
    )
    hostPoolName: hostPoolNames[i]
    workspaceName: resourceNameWithPurpose(
      'workspace',
      commonConfig.namePrefix,
      commonConfig.workloadName,
      hostPoolItem.desktopApplicationGroup.workspaceName,
      environmentConfig.shortName
    )
    workspaceConfigName: hostPoolItem.desktopApplicationGroup.workspaceName
    friendlyName: hostPoolItem.desktopApplicationGroup.?friendlyName
    description: hostPoolItem.desktopApplicationGroup.?description
    rbacAssignments: hostPoolItem.desktopApplicationGroup.?rbacAssignments ?? []
  }
]

var workspaceDeployments = [
  for workspaceItem in workspaces: {
    name: resourceNameWithPurpose(
      'workspace',
      commonConfig.namePrefix,
      commonConfig.workloadName,
      workspaceItem.name,
      environmentConfig.shortName
    )
    configName: workspaceItem.name
    friendlyName: workspaceItem.?friendlyName
    description: workspaceItem.?description
    publicNetworkAccess: workspaceItem.?publicNetworkAccess
  }
]

module hostPool 'br/public:avm/res/desktop-virtualization/host-pool:0.8.1' = [
  for (hostPoolItem, i) in hostPools: {
    name: 'deploy-${hostPoolNames[i]}'
    params: {
      name: hostPoolNames[i]
      location: commonConfig.location
      tags: tags

      friendlyName: hostPoolItem.?friendlyName ?? hostPoolNames[i]
      description: hostPoolItem.?description ?? ''
      hostPoolType: hostPoolItem.hostPoolType
      loadBalancerType: hostPoolItem.loadBalancerType
      preferredAppGroupType: hostPoolItem.preferredAppGroupType
      maxSessionLimit: hostPoolItem.?maxSessionLimit ?? 10
      validationEnvironment: hostPoolItem.?validationEnvironment ?? false
      startVMOnConnect: hostPoolItem.?startVMOnConnect ?? false
      customRdpProperty: hostPoolItem.?customRdpProperty ?? ''
      publicNetworkAccess: hostPoolItem.?publicNetworkAccess ?? 'Disabled'

      lock: {
        kind: 'CanNotDelete'
      }

      enableTelemetry: false
    }
  }
]

module desktopApplicationGroup 'br/public:avm/res/desktop-virtualization/application-group:0.4.2' = [
  for (appGroup, i) in desktopApplicationGroups: {
    name: 'deploy-${appGroup.name}'
    dependsOn: [
      hostPool
    ]
    params: {
      name: appGroup.name
      location: commonConfig.location
      tags: tags

      applicationGroupType: 'Desktop'
      hostpoolName: appGroup.hostPoolName

      friendlyName: appGroup.?friendlyName ?? appGroup.name
      description: appGroup.?description ?? ''
      showInFeed: true

      roleAssignments: [
        for rbacAssignment in appGroup.rbacAssignments: {
          principalId: rbacAssignment.principalId
          principalType: rbacAssignment.principalType
          roleDefinitionIdOrName: rbacAssignment.roleDefinitionId
        }
      ]

      lock: {
        kind: 'CanNotDelete'
      }

      enableTelemetry: false
    }
  }
]

module workspace 'br/public:avm/res/desktop-virtualization/workspace:0.9.2' = [
  for (workspaceDeployment, i) in workspaceDeployments: {
    name: 'deploy-${workspaceDeployment.name}'
    dependsOn: [
      desktopApplicationGroup
    ]
    params: {
      name: workspaceDeployment.name
      location: commonConfig.location
      tags: tags

      friendlyName: workspaceDeployment.?friendlyName ?? workspaceDeployment.name
      description: workspaceDeployment.?description ?? ''
      publicNetworkAccess: workspaceDeployment.?publicNetworkAccess ?? 'Disabled'

      lock: {
        kind: 'CanNotDelete'
      }

      enableTelemetry: false
    }
  }
]

resource workspaceApplicationGroupAssociations 'Microsoft.DesktopVirtualization/workspaces/applicationGroupReferences@2025-10-10' = [
  for appGroup in desktopApplicationGroups: {
    name: '${appGroup.workspaceName}/${appGroup.name}'
    dependsOn: [
      workspace
      desktopApplicationGroup
    ]
    properties: {
      applicationGroupPath: resourceId('Microsoft.DesktopVirtualization/applicationGroups', appGroup.name)
    }
  }
]

output workspaceNames array = [
  for i in range(0, length(workspaceDeployments)): workspace[i].outputs.name
]

output workspaceIds array = [
  for i in range(0, length(workspaceDeployments)): workspace[i].outputs.resourceId
]

output hostPoolIds array = [
  for i in range(0, length(hostPools)): hostPool[i].outputs.resourceId
]

output hostPools array = [
  for i in range(0, length(hostPools)): {
    name: hostPool[i].outputs.name
    id: hostPool[i].outputs.resourceId
    resourceGroupName: hostPool[i].outputs.resourceGroupName
    location: hostPool[i].outputs.location
    desktopApplicationGroupName: desktopApplicationGroups[i].name
    desktopApplicationGroupId: desktopApplicationGroup[i].outputs.resourceId
  }
]

output desktopApplicationGroupIds array = [
  for i in range(0, length(desktopApplicationGroups)): desktopApplicationGroup[i].outputs.resourceId
]
