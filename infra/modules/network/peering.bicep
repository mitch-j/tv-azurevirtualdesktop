targetScope = 'subscription'

/*
AVD Deployment / Network Peering

Scope:
- Subscription

Deploys:
- Spoke-to-hub virtual network peering
- Hub-to-spoke virtual network peering

Does not deploy:
- Resource groups
- Virtual networks
- Subnets
- Network security groups
- Private DNS zones

Notes:
- This deployment is intentionally separate from the network deployment so it can use a dedicated peering service connection.
*/

// Imports

import {
  EnvironmentName
  LocationName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourceGroupPurpose
  resourcePurpose
  resourceType
} from '../../shared/config.bicep'

import {
  resourceGroupNameWithLocation
  resourceNameWithPurposeAndLocation
  virtualNetworkPeeringName
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for the AVD spoke virtual network.')
param location LocationName

@description('Resource ID of the hub virtual network.')
param hubVirtualNetworkResourceId string

@description('Subscription ID containing the hub virtual network. Leave empty to derive it from hubVirtualNetworkResourceId.')
param hubSubscriptionId string = ''

@description('Resource group containing the hub virtual network. Leave empty to derive it from hubVirtualNetworkResourceId.')
param hubResourceGroupName string = ''

@description('Name of the hub virtual network. Leave empty to derive it from hubVirtualNetworkResourceId.')
param hubVirtualNetworkName string = ''

@description('Short alias used for the hub side of directional peering names.')
param hubPeeringAlias string = 'hub-prod'

@description('Whether virtual network access is allowed from the spoke VNet to the hub VNet.')
param spokeToHubAllowVirtualNetworkAccess bool = true

@description('Whether forwarded traffic is allowed from the spoke VNet to the hub VNet.')
param spokeToHubAllowForwardedTraffic bool = true

@description('Whether gateway transit is allowed from the spoke VNet.')
param spokeToHubAllowGatewayTransit bool = false

@description('Whether the spoke VNet uses gateways from the hub VNet.')
param spokeToHubUseRemoteGateways bool = false

@description('Whether virtual network access is allowed from the hub VNet to the spoke VNet.')
param hubToSpokeAllowVirtualNetworkAccess bool = true

@description('Whether forwarded traffic is allowed from the hub VNet to the spoke VNet.')
param hubToSpokeAllowForwardedTraffic bool = true

@description('Whether gateway transit is allowed from the hub VNet.')
param hubToSpokeAllowGatewayTransit bool = false

@description('Whether the hub VNet uses gateways from the spoke VNet.')
param hubToSpokeUseRemoteGateways bool = false

// Variables

var environmentConfig = environmentConfigMap[environment]
var locationConfig = locationConfigMap[location]

var networkResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.network,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var spokeVirtualNetworkName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.virtualNetwork,
  resourcePurpose.primary,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var spokeVirtualNetworkResourceId = resourceId(
  networkResourceGroupName,
  'Microsoft.Network/virtualNetworks',
  spokeVirtualNetworkName
)

var hubVnetIdSegments = split(hubVirtualNetworkResourceId, '/')

var parsedHubSubscriptionId = hubVnetIdSegments[2]
var parsedHubResourceGroupName = hubVnetIdSegments[4]
var parsedHubVnetName = hubVnetIdSegments[lastIndexOf(hubVnetIdSegments, 'virtualNetworks') + 1]

var effectiveHubSubscriptionId = empty(hubSubscriptionId) ? parsedHubSubscriptionId : hubSubscriptionId
var effectiveHubResourceGroupName = empty(hubResourceGroupName) ? parsedHubResourceGroupName : hubResourceGroupName
var effectiveHubVnetName = empty(hubVirtualNetworkName) ? parsedHubVnetName : hubVirtualNetworkName

var spokePeeringAlias = '${commonConfig.workloadName}-${locationConfig.shortCode}-${environmentConfig.shortName}'

var spokeToHubPeeringName = virtualNetworkPeeringName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  spokePeeringAlias,
  hubPeeringAlias
)

var hubToSpokePeeringName = virtualNetworkPeeringName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  hubPeeringAlias,
  spokePeeringAlias
)

// Modules

module spokeToHubPeering './vnet-peering.bicep' = {
  name: '${deployment().name}-${locationConfig.shortCode}-s2h-peer'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    localVirtualNetworkName: spokeVirtualNetworkName
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
    peeringName: spokeToHubPeeringName
    allowVirtualNetworkAccess: spokeToHubAllowVirtualNetworkAccess
    allowForwardedTraffic: spokeToHubAllowForwardedTraffic
    allowGatewayTransit: spokeToHubAllowGatewayTransit
    useRemoteGateways: spokeToHubUseRemoteGateways
  }
}

module hubToSpokePeering './vnet-peering.bicep' = {
  name: '${deployment().name}-${locationConfig.shortCode}-h2s-peer'
  scope: resourceGroup(effectiveHubSubscriptionId, effectiveHubResourceGroupName)
  params: {
    localVirtualNetworkName: effectiveHubVnetName
    remoteVirtualNetworkResourceId: spokeVirtualNetworkResourceId
    peeringName: hubToSpokePeeringName
    allowVirtualNetworkAccess: hubToSpokeAllowVirtualNetworkAccess
    allowForwardedTraffic: hubToSpokeAllowForwardedTraffic
    allowGatewayTransit: hubToSpokeAllowGatewayTransit
    useRemoteGateways: hubToSpokeUseRemoteGateways
  }
}

// Outputs

@description('Name of the AVD spoke network resource group.')
output networkResourceGroupName string = networkResourceGroupName

@description('Name of the AVD spoke virtual network.')
output spokeVirtualNetworkName string = spokeVirtualNetworkName

@description('Resource ID of the AVD spoke virtual network.')
output spokeVirtualNetworkResourceId string = spokeVirtualNetworkResourceId

@description('Name of the hub virtual network.')
output hubVirtualNetworkName string = effectiveHubVnetName

@description('Resource ID of the hub virtual network.')
output hubVirtualNetworkResourceId string = hubVirtualNetworkResourceId

@description('Name of the spoke-to-hub virtual network peering.')
output spokeToHubPeeringName string = spokeToHubPeeringName

@description('Resource ID of the spoke-to-hub virtual network peering.')
output spokeToHubPeeringResourceId string = spokeToHubPeering.outputs.peeringResourceId

@description('Name of the hub-to-spoke virtual network peering.')
output hubToSpokePeeringName string = hubToSpokePeeringName

@description('Resource ID of the hub-to-spoke virtual network peering.')
output hubToSpokePeeringResourceId string = hubToSpokePeering.outputs.peeringResourceId
