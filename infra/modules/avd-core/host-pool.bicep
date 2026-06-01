import {
  DeploymentEnvironmentName
  StandardTags
} from '../../shared/types.bicep'

@description('Short deployment environment name used by pipelines and parameter files.')
param environmentName DeploymentEnvironmentName

@description('Optional short organization or platform prefix used in resource names.')
param namePrefix string

@description('Azure region for deployed resources.')
param location string = resourceGroup().location

@description('Workload short name used in resource names.')
param workloadName string

@description('Tags')
param tags StandardTags

@description('Controls public network access for AVD control plane resources.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string

@description('Host pool definitions to create for this AVD environment.')
param hostPools array

var normalizedPrefix = toLower(namePrefix)
var normalizedEnvironment = toLower(environmentName)
var normalizedWorkload = toLower(workloadName)

resource hostPoolResources 'Microsoft.DesktopVirtualization/hostPools@2026-01-01-preview' = [
  for hostPool in hostPools: {
    name: '${normalizedPrefix}-${normalizedWorkload}-hp-${toLower(hostPool.name)}-${normalizedEnvironment}'
    location: location
    tags: tags
    properties: {
      friendlyName: hostPool.friendlyName
      description: hostPool.description
      hostPoolType: hostPool.hostPoolType
      loadBalancerType: hostPool.loadBalancerType
      preferredAppGroupType: hostPool.preferredAppGroupType
      maxSessionLimit: hostPool.maxSessionLimit
      validationEnvironment: hostPool.validationEnvironment
      startVMOnConnect: hostPool.startVMOnConnect
      customRdpProperty: hostPool.customRdpProperty
      publicNetworkAccess: publicNetworkAccess
    }
  }
]

output hostPoolNames array = [
  for i in range(0, length(hostPools)): hostPoolResources[i].name
]

output hostPoolResourceIds array = [
  for i in range(0, length(hostPools)): hostPoolResources[i].id
]
