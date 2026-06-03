targetScope = 'subscription'

/*
AVD Deployment / Network

Scope:
- Subscription

Deploys:
- Network resource group
- AVD spoke virtual network
- Session host subnet
- Private endpoint subnet
- Session host network security group
- Optional spoke-to-hub virtual network peering
- Hub-to-spoke peering

Does not deploy:
- AVD host pools, desktop application groups, or workspaces
- Storage accounts or FSLogix shares
- Session host virtual machines
- Hub virtual network
*/

// Imports

import {
  EnvironmentName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  StandardTags
  resourcePurpose
  resourceType
} from '../../shared/config.bicep'

import {
  resourceGroupName
  resourceNameWithPurpose
  virtualNetworkPeeringName
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for network resources.')
param location string = deployment().location

@description('Virtual network address prefixes.')
param virtualNetworkAddressPrefixes array

@description('Session host subnet address prefix.')
param sessionHostSubnetAddressPrefix string

@description('Private endpoint subnet address prefix.')
param privateEndpointSubnetAddressPrefix string

@description('Optional custom DNS servers for the virtual network. Leave empty to use Azure-provided DNS.')
param dnsServers array = []

@description('Optional remote hub VNet resource ID. Leave empty to skip peering.')
param hubVirtualNetworkResourceId string = ''

@description('Subscription ID containing the hub virtual network.')
param hubSubscriptionId string = ''

@description('Resource group containing the hub virtual network.')
param hubResourceGroupName string = ''

@description('Name of the hub virtual network.')
param hubVirtualNetworkName string = ''

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Tags to add to resources deployed by this module.
var tags = union(StandardTags, {
  Environment: environmentConfig.tagEnvironment
})

// Name of the resource group that contains Network module resources.
var networkResourceGroupName = resourceGroupName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourcePurpose.network,
  environmentConfig.shortName
)

// Name of the AVD spoke virtual network.
var virtualNetworkName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.virtualNetwork,
  resourcePurpose.network,
  environmentConfig.shortName
)

// Name of the subnet used by AVD session hosts.
var sessionHostSubnetName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.subnet,
  resourcePurpose.sessionHosts,
  environmentConfig.shortName
)

// Name of the subnet reserved for private endpoints.
var privateEndpointSubnetName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.subnet,
  resourcePurpose.privateEndpoints,
  environmentConfig.shortName
)

// Name of the network security group associated with the private endpoint subnet.
var privateEndpointNetworkSecurityGroupName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.networkSecurityGroup,
  resourcePurpose.privateEndpoints,
  environmentConfig.shortName
)

// Name of the network security group associated with the session host subnet.
var sessionHostNetworkSecurityGroupName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.networkSecurityGroup,
  resourcePurpose.sessionHosts,
  environmentConfig.shortName
)

var avdSpokePeeringAlias = '${commonConfig.workloadName}-${environmentConfig.shortName}'
var hubPeeringAlias = 'hub-prod'

var spokeToHubPeeringName = virtualNetworkPeeringName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  avdSpokePeeringAlias,
  hubPeeringAlias
)

var hubToSpokePeeringName = virtualNetworkPeeringName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  hubPeeringAlias,
  avdSpokePeeringAlias
)

// Modules

module networkResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' ={
  name: '${deployment().name}-network-rg'
  params: {
    name: networkResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module spokeVnet './spoke-vnet.bicep' = {
  name: '${deployment().name}-spoke-vnet'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location: location
    tags: tags
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressPrefixes: virtualNetworkAddressPrefixes
    sessionHostSubnetName: sessionHostSubnetName
    sessionHostSubnetAddressPrefix: sessionHostSubnetAddressPrefix
    privateEndpointNetworkSecurityGroupName: privateEndpointNetworkSecurityGroupName
    privateEndpointSubnetName: privateEndpointSubnetName
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    sessionHostNetworkSecurityGroupName: sessionHostNetworkSecurityGroupName
    dnsServers: dnsServers
  }
}

module spokeToHubPeering './spoke-to-hub-peering.bicep' = if (!empty(hubVirtualNetworkResourceId)) {
  name: '${deployment().name}-s2h-peer'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    localVirtualNetworkName: virtualNetworkName
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
    peeringName: spokeToHubPeeringName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    spokeVnet
  ]
}

module hubToSpokePeering './hub-to-spoke-peering.bicep' = if (!empty(hubVirtualNetworkResourceId)) {
  name: '${deployment().name}-h2s-peer'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    localVirtualNetworkName: hubVirtualNetworkName
    remoteVirtualNetworkResourceId: spokeVnet.outputs.virtualNetworkResourceId
    peeringName: hubToSpokePeeringName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Outputs

@description('Name of the resource group containing Network module resources.')
output networkResourceGroupName string = networkResourceGroupName

@description('Name of the deployed AVD spoke virtual network.')
output virtualNetworkName string = virtualNetworkName

@description('Resource ID of the deployed AVD spoke virtual network.')
output virtualNetworkResourceId string = spokeVnet.outputs.virtualNetworkResourceId

@description('Names of the subnets created in the AVD spoke virtual network.')
output virtualNetworkSubnetNames array = spokeVnet.outputs.virtualNetworkSubnetNames

@description('Name of the subnet used by AVD session hosts.')
output sessionHostSubnetName string = sessionHostSubnetName

@description('Resource ID of the subnet used by AVD session hosts.')
output sessionHostSubnetResourceId string = spokeVnet.outputs.sessionHostSubnetResourceId

@description('Resource ID of the subnet used by private endpoints.')
output privateEndpointSubnetResourceId string = spokeVnet.outputs.privateEndpointSubnetResourceId

@description('Name of the network security group associated with the session host subnet.')
output sessionHostNetworkSecurityGroupName string = sessionHostNetworkSecurityGroupName

@description('Resource ID of the network security group associated with the session host subnet.')
output sessionHostNetworkSecurityGroupResourceId string = spokeVnet.outputs.sessionHostNetworkSecurityGroupResourceId

@description('Name of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringName string = !empty(hubVirtualNetworkResourceId) ? spokeToHubPeeringName : ''

@description('Name of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output hubToSpokePeeringName string = !empty(hubVirtualNetworkResourceId) ? hubToSpokePeeringName : ''

@description('Resource ID of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringResourceId string = !empty(hubVirtualNetworkResourceId) ? hubToSpokePeering!.outputs.peeringResourceId : ''

@description('Resource name of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringResourceName string = !empty(hubVirtualNetworkResourceId) ? hubToSpokePeering!.outputs.peeringResourceName : ''

@description('Resource ID of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output hubToSpokePeeringResourceId string = !empty(hubVirtualNetworkResourceId) ? spokeToHubPeering!.outputs.peeringResourceId : ''

@description('Resource name of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output hubToSpokePeeringResourceName string = !empty(hubVirtualNetworkResourceId) ? spokeToHubPeering!.outputs.peeringResourceName : ''

@description('Name of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupName string = privateEndpointNetworkSecurityGroupName

@description('Resource ID of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupResourceId string = spokeVnet.outputs.privateEndpointNetworkSecurityGroupResourceId

