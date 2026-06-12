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
  LocationName
  WorkspaceConfig
  HostPoolConfig
  ScalingPlanConfig
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourceDefaults
  resourceType
} from '../../shared/config.bicep'

import {
  resourceNameWithPurposeAndLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Tags applied to deployed AVD resources.')
param tags object

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for deployed resources.')
param location LocationName

@description('Workspace configurations to deploy in the target resource group.')
param workspaces WorkspaceConfig[]

@description('Host pool configurations to deploy in the target resource group.')
param hostPools HostPoolConfig[]

@description('Scaling plan configurations to deploy in the target resource group.')
param scalingPlans ScalingPlanConfig[] = []

param logAnalyticsWorkspaceResourceId string

@description('Deploy diagnostic settings for resources created by this module.')
param deployDiagnosticSettings bool = true

// Variables

// Environment-specific naming values.
var environmentConfig = environmentConfigMap[environment]

@description('Azure resource names generated for each configured AVD scaling plan.')
var scalingPlanNames = [
  for scalingPlanItem in scalingPlans: resourceNameWithPurposeAndLocation(
    commonConfig.namePrefix,
    commonConfig.workloadName,
    resourceType.scalingPlan,
    scalingPlanItem.name,
    locationConfig.shortCode,
    environmentConfig.shortName
  )
]

// Shared location configuration for the selected Azure region.
var locationConfig = locationConfigMap[location]

@description('Azure resource names generated for each configured AVD host pool.')
var hostPoolNames = [
  for hostPoolItem in hostPools: resourceNameWithPurposeAndLocation(
    commonConfig.namePrefix,
    commonConfig.workloadName,
    resourceType.hostPool,
    hostPoolItem.name,
    locationConfig.shortCode,
    environmentConfig.shortName
  )
]

@description('Desktop application group deployment objects derived from each host pool configuration.')
var desktopApplicationGroups = [
  for (hostPoolItem, i) in hostPools: {
    name: resourceNameWithPurposeAndLocation(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.desktopApplicationGroup,
      hostPoolItem.desktopApplicationGroup.name,
      locationConfig.shortCode,
      environmentConfig.shortName
    )
    id: resourceId(
      'Microsoft.DesktopVirtualization/applicationGroups',
      resourceNameWithPurposeAndLocation(
        commonConfig.namePrefix,
        commonConfig.workloadName,
        resourceType.desktopApplicationGroup,
        hostPoolItem.desktopApplicationGroup.name,
        locationConfig.shortCode,
        environmentConfig.shortName
      )
    )
    hostPoolName: hostPoolNames[i]
    workspaceName: resourceNameWithPurposeAndLocation(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.workspace,
      hostPoolItem.desktopApplicationGroup.workspaceName,
      locationConfig.shortCode,
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
    name: resourceNameWithPurposeAndLocation(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.workspace,
      workspaceItem.name,
      locationConfig.shortCode,
      environmentConfig.shortName
    )
    configName: workspaceItem.name
    friendlyName: workspaceItem.?friendlyName
    description: workspaceItem.?description
    publicNetworkAccess: workspaceItem.?publicNetworkAccess ?? resourceDefaults.publicNetworkAccess
  }
]

var diagnosticSettings = deployDiagnosticSettings && !empty(logAnalyticsWorkspaceResourceId)
  ? [
      {
        name: 'diag-log'
        workspaceResourceId: logAnalyticsWorkspaceResourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ]
  : []

// Modules

module hostPool 'br/public:avm/res/desktop-virtualization/host-pool:0.8.1' = [
  for (hostPoolItem, i) in hostPools: {
    name: '${environmentConfig.shortName}-${locationConfig.shortCode}-vdpool-${i}'
    params: {
      name: hostPoolNames[i]
      location: location
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
      publicNetworkAccess: hostPoolItem.?publicNetworkAccess ?? resourceDefaults.publicNetworkAccess

      lock: {
        kind: commonConfig.lockKind
      }

      diagnosticSettings: diagnosticSettings
    }
  }
]

module desktopApplicationGroup 'br/public:avm/res/desktop-virtualization/application-group:0.4.2' = [
  for (appGroup, i) in desktopApplicationGroups: {
    name: '${environmentConfig.shortName}-${locationConfig.shortCode}-vdag-${i}'
    dependsOn: [
      hostPool
    ]
    params: {
      name: appGroup.name
      location: location
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

      diagnosticSettings: diagnosticSettings
    }
  }
]

module workspace 'br/public:avm/res/desktop-virtualization/workspace:0.9.2' = [
  for (workspaceDeployment, i) in workspaceDeployments: {
    name: '${environmentConfig.shortName}-${locationConfig.shortCode}-vdws-${i}'
    dependsOn: [
      desktopApplicationGroup
    ]
    params: {
      name: workspaceDeployment.name
      location: location
      tags: tags

      friendlyName: workspaceDeployment.?friendlyName ?? workspaceDeployment.name
      description: workspaceDeployment.?description ?? ''
      publicNetworkAccess: workspaceDeployment.publicNetworkAccess

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

      diagnosticSettings: diagnosticSettings
    }
  }
]

module scalingPlan 'br/public:avm/res/desktop-virtualization/scaling-plan:0.5.0' = [
  for (scalingPlanItem, i) in scalingPlans: {
    name: '${environmentConfig.shortName}-${locationConfig.shortCode}-vdscaling-${i}'
    dependsOn: [
      hostPool
    ]
    params: {
      name: scalingPlanNames[i]
      location: location
      tags: tags
      friendlyName: scalingPlanItem.?friendlyName ?? scalingPlanNames[i]
      description: scalingPlanItem.?description ?? ''
      hostPoolType: scalingPlanItem.hostPoolType
      timeZone: scalingPlanItem.timeZone
      exclusionTag: scalingPlanItem.?exclusionTag
      hostPoolReferences: [
        for hostPoolName in scalingPlanItem.hostPoolNames: {
          hostPoolResourceId: resourceId(
            'Microsoft.DesktopVirtualization/hostPools',
            resourceNameWithPurposeAndLocation(
              commonConfig.namePrefix,
              commonConfig.workloadName,
              resourceType.hostPool,
              hostPoolName,
              locationConfig.shortCode,
              environmentConfig.shortName
            )
          )
          scalingPlanEnabled: true
        }
      ]
      schedules: scalingPlanItem.schedules
      lock: {
        kind: commonConfig.lockKind
      }
      enableTelemetry: false
      diagnosticSettings: diagnosticSettings
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

@description('Resource IDs of the deployed AVD scaling plans.')
output scalingPlanIds array = [
  for i in range(0, length(scalingPlans)): scalingPlan[i].outputs.resourceId
]

@description('Names of the deployed AVD scaling plans.')
output scalingPlanNames array = [
  for i in range(0, length(scalingPlans)): scalingPlan[i].outputs.name
]
