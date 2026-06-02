targetScope = 'subscription'

// AVD-Deployment
// This instance is the central entrypoint for the AVD deployment and orchestrates the deployment of all required resources and modules.

@description('Optional short organization or platform prefix used in resource names.')
param namePrefix string

@description('Controls public network access for AVD control plane resources.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Host pool definitions to create for this AVD environment.')
param hostPools array

@description('List of resource groups for session hosts.')
var sessionHostResourceGroups = [
  for hostPool in hostPools: '${normalizedPrefix}-${normalizedWorkload}-rg-${toLower(hostPool.name)}-sessionhosts-${normalizedEnvironment}'
]

@description('Descriptors for the base resource groups to be created for this AVD environment.')
var resourceGroupTypes array

@description('Short technical name for the deployable workload. Used in Azure resource names.')
param workloadName string

var environmentConfig = environmentConfigMap[environmentName]

@description('Tags')
param tags StandardTags

var resourceNamePrefix = '${workloadName}-'
var resourceNameSuffix = '${environmentConfig.shortName}'


var coreResourceGroupName = resourceGroupName('core')
var workspaceName = '${normalizedPrefix}-${normalizedWorkload}-vdws-${normalizedEnvironment}'
var workspaceFriendlyName = 'True Value AVD ${toUpper(normalizedEnvironment)} Workspace'

var desktopApplicationGroups = [
  for hostPoolItem in hostPools: {
    sourceHostPoolName: hostPoolItem.name
    name: '${normalizedPrefix}-${normalizedWorkload}-vdag-${toLower(hostPoolItem.name)}-${normalizedEnvironment}'
    friendlyName: '${hostPoolItem.friendlyName} Desktop'
    description: 'Desktop application group for ${hostPoolItem.friendlyName}.'
    hostPoolName: '${normalizedPrefix}-${normalizedWorkload}-vdpool-${toLower(hostPoolItem.name)}-${normalizedEnvironment}'
    hostPoolResourceId: resourceId(subscription().subscriptionId, coreResourceGroupName, 'Microsoft.DesktopVirtualization/hostPools', '${normalizedPrefix}-${normalizedWorkload}-vdpool-${toLower(hostPoolItem.name)}-${normalizedEnvironment}')
    resourceId: resourceId(subscription().subscriptionId, coreResourceGroupName, 'Microsoft.DesktopVirtualization/applicationGroups', '${normalizedPrefix}-${normalizedWorkload}-vdag-${toLower(hostPoolItem.name)}-${normalizedEnvironment}')
  }
]

module avdSessionHostsResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = [for rgName in sessionHostResourceGroups: {
  name: 'deploy-${rgName}'
  params: {
    name: rgName
    location: location
    tags: tags
    lock: {
      kind: 'CanNotDelete'
    }
  }
}]

module avdResourceGroups 'br/public:avm/res/resources/resource-group:0.4.3' = [for rgType in resourceGroupTypes: {
  name: 'deploy-${resourceGroupName(rgType)}'
  params: {
    name: resourceGroupName(rgType)
    location: location
    tags: tags
    lock: {
      kind: 'CanNotDelete'
    }
  }
}]

module hostPool 'br/public:avm/res/desktop-virtualization/host-pool:0.8.1' = [
  for hostPoolItem in hostPools: {
    name: 'deploy-${normalizedPrefix}-${normalizedWorkload}-vdpool-${toLower(hostPoolItem.name)}-${normalizedEnvironment}'
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

var baseResourceGroupDetails = [
  for rgType in resourceGroupTypes: {
    type: rgType
    name: resourceGroupName(rgType)
    location: location
    resourceId: subscriptionResourceId('Microsoft.Resources/resourceGroups', resourceGroupName(rgType))
  }
]

var sessionHostResourceGroupDetails = [
  for i in range(0, length(sessionHostResourceGroups)): {
    type: 'sessionhosts'
    sourceHostPoolName: hostPools[i].name
    name: sessionHostResourceGroups[i]
    location: location
    resourceId: subscriptionResourceId('Microsoft.Resources/resourceGroups', sessionHostResourceGroups[i])
  }
]

var createdResourceGroups = concat(baseResourceGroupDetails, sessionHostResourceGroupDetails)

var createdHostPools = [
  for hostPoolItem in hostPools: {
    sourceName: hostPoolItem.name
    name: '${normalizedPrefix}-${normalizedWorkload}-vdpool-${toLower(hostPoolItem.name)}-${normalizedEnvironment}'
    location: location
    resourceGroupName: coreResourceGroupName
    resourceId: resourceId(subscription().subscriptionId, coreResourceGroupName, 'Microsoft.DesktopVirtualization/hostPools', '${normalizedPrefix}-${normalizedWorkload}-vdpool-${toLower(hostPoolItem.name)}-${normalizedEnvironment}')
  }
]

output resourceGroups array = createdResourceGroups

output resourceGroupNames array = [
  for rg in createdResourceGroups: rg.name
]

output resourceGroupResourceIds array = [
  for rg in createdResourceGroups: rg.resourceId
]

output hostPoolDetails array = createdHostPools

output hostPoolNames array = [
  for pool in createdHostPools: pool.name
]

output hostPoolResourceIds array = [
  for pool in createdHostPools: pool.resourceId
]

output workspaceName string = workspace.outputs.name
output workspaceResourceId string = workspace.outputs.resourceId

output desktopApplicationGroups array = [
  for appGroup in desktopApplicationGroups: {
    name: appGroup.name
    resourceId: appGroup.resourceId
    hostPoolName: appGroup.hostPoolName
    hostPoolResourceId: appGroup.hostPoolResourceId
  }
]

output resourcePrefix string = resourceNamePrefix
output resourceSuffix string = resourceNameSuffix
output logRetentionDays int = environmentConfig.logRetentionDays
output resourceDefaults object = deploymentDefaults

output sourceRepositoryName string = repositoryName
output deploymentEnvironment string = environmentName
output deploymentLocation string = location
output appliedTags object = tags
