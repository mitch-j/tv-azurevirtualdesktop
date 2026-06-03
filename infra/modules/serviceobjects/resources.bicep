targetScope = 'resourceGroup'

/*
AVD Deployment / Service Objects Resources

Scope:
- Resource Group

Deploys:
- AVD host pools using AVM
- One desktop application group per host pool
- One or more workspaces
- Workspace publishing for desktop application groups
- Desktop Virtualization User RBAC assignments on application groups

Does not deploy:
- Resource groups
- Virtual networks or subnets
- Storage accounts or FSLogix shares
- Session host virtual machines
*/

// Imports

import {
  EnvironmentName
  WorkspaceConfig
  HostPoolConfig
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  resourceType
} from '../../shared/config.bicep'

import {
  resourceNameWithPurpose
} from '../../shared/naming.bicep'

// Parameters

@description('Tags applied to deployed AVD service object resources.')
param tags object

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Workspace configurations to deploy in the target resource group.')
param workspaces WorkspaceConfig[]

@description('Host pool configurations to deploy in the target resource group.')
param hostPools HostPoolConfig[]

// Variables

@description('Shared environment configuration for the selected deployment environment.')
var environmentConfig = environmentConfigMap[environment]

@description('Azure resource names generated for each configured AVD host pool.')
var hostPoolNames = [
  for hostPoolItem in hostPools: resourceNameWithPurpose(
    commonConfig.namePrefix,
    commonConfig.workloadName,
    resourceType.hostPool,
    hostPoolItem.name,
    environmentConfig.shortName
  )
]

@description('Desktop application group deployment objects derived from each host pool configuration.')
var desktopApplicationGroups = [
  for (hostPoolItem, i) in hostPools: {
    name: resourceNameWithPurpose(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.desktopApplicationGroup,
      hostPoolItem.desktopApplicationGroup.name,
      environmentConfig.shortName
    )
    id: resourceId(
      'Microsoft.DesktopVirtualization/applicationGroups',
      resourceNameWithPurpose(
        commonConfig.namePrefix,
        commonConfig.workloadName,
        resourceType.desktopApplicationGroup,
        hostPoolItem.desktopApplicationGroup.name,
        environmentConfig.shortName
      )
    )
    hostPoolName: hostPoolNames[i]
    workspaceName: resourceNameWithPurpose(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.workspace,
      hostPoolItem.desktopApplicationGroup.workspaceName,
      environmentConfig.shortName
    )
    workspaceConfigName: hostPoolItem.desktopApplicationGroup.workspaceName
    friendlyName: hostPoolItem.desktopApplicationGroup.?friendlyName
    description: hostPoolItem.desktopApplicationGroup.?description
    rbacAssignments: hostPoolItem.desktopApplicationGroup.?rbacAssignments ?? []
  }
]

@description('Workspace deployment objects derived from the workspace parameter configuration.')
var workspaceDeployments = [
  for workspaceItem in workspaces: {
    name: resourceNameWithPurpose(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.workspace,
      workspaceItem.name,
      environmentConfig.shortName
    )
    configName: workspaceItem.name
    friendlyName: workspaceItem.?friendlyName
    description: workspaceItem.?description
    publicNetworkAccess: workspaceItem.?publicNetworkAccess
  }
]

// Modules

module hostPool 'br/public:avm/res/desktop-virtualization/host-pool:0.8.1' = [
  for (hostPoolItem, i) in hostPools: {
    name: '${deployment().name}-${hostPoolNames[i]}'
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
        kind: commonConfig.lockKind
      }

      enableTelemetry: false
    }
  }
]

module desktopApplicationGroup 'br/public:avm/res/desktop-virtualization/application-group:0.4.2' = [
  for (appGroup, i) in desktopApplicationGroups: {
    name: '${deployment().name}-${appGroup.name}'
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
        kind: commonConfig.lockKind
      }

      enableTelemetry: false
    }
  }
]

module workspace 'br/public:avm/res/desktop-virtualization/workspace:0.9.2' = [
  for (workspaceDeployment, i) in workspaceDeployments: {
    name: '${deployment().name}-${workspaceDeployment.name}'
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

      applicationGroupReferences: map(
        filter(
          desktopApplicationGroups,
          appGroup => appGroup.workspaceConfigName == workspaceDeployment.configName
        ),
        appGroup => appGroup.id
      )

      lock: {
        kind: commonConfig.lockKind
      }

      enableTelemetry: false
    }
  }
]

// Outputs

@description('Names of the deployed AVD workspaces.')
output workspaceNames array = [
  for i in range(0, length(workspaceDeployments)): workspace[i].outputs.name
]

@description('Resource IDs of the deployed AVD workspaces.')
output workspaceIds array = [
  for i in range(0, length(workspaceDeployments)): workspace[i].outputs.resourceId
]

@description('Resource IDs of the deployed AVD host pools.')
output hostPoolIds array = [
  for i in range(0, length(hostPools)): hostPool[i].outputs.resourceId
]

@description('Deployment output objects for the deployed AVD host pools and their desktop application groups.')
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

@description('Resource IDs of the deployed desktop application groups.')
output desktopApplicationGroupIds array = [
  for i in range(0, length(desktopApplicationGroups)): desktopApplicationGroup[i].outputs.resourceId
]
