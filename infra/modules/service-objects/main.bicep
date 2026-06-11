targetScope = 'subscription'

/*
AVD Deployment / Service Objects

Scope:
- Subscription

Deploys:
- Service Objects resource group
- AVD host pools
- One desktop application group per host pool
- One or more workspaces
- Workspace publishing for desktop application groups
- Desktop Virtualization User RBAC assignments on application groups

Does not deploy:
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
  baseTags
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourceGroupPurpose
  roleDefinitionIds
} from '../../shared/config.bicep'

import {
  resourceGroupNameWithLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for service object resources.')
param location LocationName

@description('Workspace configurations to deploy for the selected environment.')
param workspaces WorkspaceConfig[]

@description('Host pool configurations to deploy for the selected environment.')
param hostPools HostPoolConfig[]

@description('Scaling plan configurations to deploy for the selected environment.')
param scalingPlans ScalingPlanConfig[] = []

@description('Object ID of the Azure Virtual Desktop service principal used by autoscale.')
param avdAutoscaleServicePrincipalObjectId string = ''

@description('Deploy Azure RBAC assignments required for AVD autoscale.')
param deployAutoscaleRbac bool = true

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Location configuration for the selected Azure region.
var locationConfig = locationConfigMap[location]

// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

// Resource Names

// Name of the resource group that contains AVD service object resources.
var serviceObjectsResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.serviceObjects,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Resources

resource avdAutoscalePowerOnOffRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (deployAutoscaleRbac && !empty(avdAutoscaleServicePrincipalObjectId) && !empty(scalingPlans)) {
  name: guid(subscription().id, avdAutoscaleServicePrincipalObjectId, roleDefinitionIds.avd.desktopVirtualizationPowerOnOffContributor)
  scope: subscription()
  properties: {
    principalId: avdAutoscaleServicePrincipalObjectId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      roleDefinitionIds.avd.desktopVirtualizationPowerOnOffContributor
    )
  }
}

// Modules

module serviceObjectsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${deployment().name}-so-rg'
  params: {
    name: serviceObjectsResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module serviceObjectsResources './resources.bicep' = {
  name: '${deployment().name}-so-res'
  scope: resourceGroup(serviceObjectsResourceGroupName)
  dependsOn: [
    serviceObjectsResourceGroup
  ]
  params: {
    environment: environment
    location: location
    tags: tags
    hostPools: hostPools
    workspaces: workspaces
    scalingPlans: scalingPlans
  }
}

// Outputs

@description('Name of the Service Objects resource group.')
output serviceObjectsResourceGroupName string = serviceObjectsResourceGroupName

@description('Names of the deployed AVD workspaces.')
output workspaceNames array = serviceObjectsResources.outputs.workspaceNames

@description('Resource IDs of the deployed AVD workspaces.')
output workspaceIds array = serviceObjectsResources.outputs.workspaceIds

@description('Deployment output objects for the deployed AVD host pools.')
output hostPools array = serviceObjectsResources.outputs.hostPools

@description('Resource IDs of the deployed AVD host pools.')
output hostPoolIds array = serviceObjectsResources.outputs.hostPoolIds

@description('Resource IDs of the deployed desktop application groups.')
output desktopApplicationGroupIds array = serviceObjectsResources.outputs.desktopApplicationGroupIds

@description('Names of the deployed AVD scaling plans.')
output scalingPlanNames array = serviceObjectsResources.outputs.scalingPlanNames

@description('Resource IDs of the deployed AVD scaling plans.')
output scalingPlanIds array = serviceObjectsResources.outputs.scalingPlanIds
