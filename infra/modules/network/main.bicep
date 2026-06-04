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
  PurposeName
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

// Types

@sealed()
type SubnetConfig = {
  @description('Purpose key used to calculate the subnet name.')
  purpose: PurposeName

  @description('CIDR block assigned to the subnet.')
  addressPrefix: string
}

// Parameters

@description('Deployment environment key used to select shared environment configuration.')
param environment EnvironmentName

@description('Azure region for network resources.')
param location string = deployment().location

@description('Virtual network address prefixes.')
param virtualNetworkAddressPrefixes array

@description('Session host subnet definitions.')
param sessionHostSubnets SubnetConfig[]

@description('Private endpoint subnet definition.')
param privateEndpointSubnet SubnetConfig

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

// Session host subnet names and address prefixes.
var sessionHostSubnetDefinitions = [
  for sessionHostSubnet in sessionHostSubnets: {
    name: resourceNameWithPurpose(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.subnet,
      sessionHostSubnet.purpose,
      environmentConfig.shortName
    )
    addressPrefix: sessionHostSubnet.addressPrefix
  }
]

// Private endpoint subnet name and address prefix.
var privateEndpointSubnetDefinition = {
  name: resourceNameWithPurpose(
    commonConfig.namePrefix,
    commonConfig.workloadName,
    resourceType.subnet,
    privateEndpointSubnet.purpose,
    environmentConfig.shortName
  )
  addressPrefix: privateEndpointSubnet.addressPrefix
}

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

var hubVirtualNetworkResourceIdSegments = split(hubVirtualNetworkResourceId, '/')

var hubVirtualNetworkSubscriptionIdFromId = empty(hubVirtualNetworkResourceId) ? '' : hubVirtualNetworkResourceIdSegments[2]

var hubVirtualNetworkResourceGroupNameFromId = empty(hubVirtualNetworkResourceId) ? '' : hubVirtualNetworkResourceIdSegments[4]

var hubVirtualNetworkNameFromId = empty(hubVirtualNetworkResourceId) ? '' : hubVirtualNetworkResourceIdSegments[lastIndexOf(hubVirtualNetworkResourceIdSegments, 'virtualNetworks') + 1]

var effectiveHubSubscriptionId = empty(hubSubscriptionId) ? hubVirtualNetworkSubscriptionIdFromId : hubSubscriptionId

var effectiveHubResourceGroupName = empty(hubResourceGroupName) ? hubVirtualNetworkResourceGroupNameFromId : hubResourceGroupName

var effectiveHubVirtualNetworkName = empty(hubVirtualNetworkName) ? hubVirtualNetworkNameFromId : hubVirtualNetworkName

var deploySpokeToHubPeering = !empty(hubVirtualNetworkResourceId)

var deployHubToSpokePeering = !empty(hubVirtualNetworkResourceId) && !empty(effectiveHubSubscriptionId) && !empty(effectiveHubResourceGroupName) && !empty(effectiveHubVirtualNetworkName)

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
    sessionHostSubnets: sessionHostSubnetDefinitions
    privateEndpointNetworkSecurityGroupName: privateEndpointNetworkSecurityGroupName
    privateEndpointSubnet: privateEndpointSubnetDefinition
    sessionHostNetworkSecurityGroupName: sessionHostNetworkSecurityGroupName
    dnsServers: dnsServers
  }
  dependsOn: [
    networkResourceGroup
  ]
}

module spokeToHubPeering './vnet-peering.bicep' = if (deploySpokeToHubPeering) {
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

module hubToSpokePeering './vnet-peering.bicep' = if (deployHubToSpokePeering) {
  name: '${deployment().name}-h2s-peer'
  scope: resourceGroup(effectiveHubSubscriptionId, effectiveHubResourceGroupName)
  params: {
    localVirtualNetworkName: effectiveHubVirtualNetworkName
    remoteVirtualNetworkResourceId: spokeVnet.outputs.virtualNetworkResourceId
    peeringName: hubToSpokePeeringName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Outputs

@description('Resource Name of the deployed AVD spoke virtual network.')
output networkResourceGroupName string = networkResourceGroupName

@description('Name of the deployed AVD spoke virtual network.')
output virtualNetworkName string = virtualNetworkName

@description('Resource ID of the deployed AVD spoke virtual network.')
output virtualNetworkResourceId string = spokeVnet.outputs.virtualNetworkResourceId

@description('Names of the subnets created in the AVD spoke virtual network.')
output virtualNetworkSubnetNames array = spokeVnet.outputs.virtualNetworkSubnetNames

@description('Names of the session host subnets.')
output sessionHostSubnetNames array = [
  for sessionHostSubnet in sessionHostSubnetDefinitions: sessionHostSubnet.name
]

@description('Resource IDs of the session host subnets.')
output sessionHostSubnetResourceIds array = spokeVnet.outputs.sessionHostSubnetResourceIds

@description('Name of the network security group associated with the session host subnet.')
output sessionHostNetworkSecurityGroupName string = sessionHostNetworkSecurityGroupName

@description('Resource ID of the network security group associated with the session host subnet.')
output sessionHostNetworkSecurityGroupResourceId string = spokeVnet.outputs.sessionHostNetworkSecurityGroupResourceId

@description('Name of the subnet used by private endpoints.')
output privateEndpointSubnetName string = privateEndpointSubnetDefinition.name

@description('Resource ID of the subnet used by private endpoints.')
output privateEndpointSubnetResourceId string = spokeVnet.outputs.privateEndpointSubnetResourceId

@description('Name of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupName string = privateEndpointNetworkSecurityGroupName

@description('Resource ID of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupResourceId string = spokeVnet.outputs.privateEndpointNetworkSecurityGroupResourceId

@description('Resource name of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringResourceName string = deploySpokeToHubPeering ? spokeToHubPeering!.outputs.peeringResourceName : ''

@description('Resource ID of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringResourceId string = deploySpokeToHubPeering ? spokeToHubPeering!.outputs.peeringResourceId : ''

@description('Name of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringName string = deploySpokeToHubPeering ? spokeToHubPeeringName : ''

@description('Resource name of the hub-to-spoke virtual network peering, or empty when peering is not deployed.')
output hubToSpokePeeringResourceName string = deployHubToSpokePeering ? hubToSpokePeering!.outputs.peeringResourceName : ''

@description('Resource ID of the hub-to-spoke virtual network peering, or empty when peering is not deployed.')
output hubToSpokePeeringResourceId string = deployHubToSpokePeering ? hubToSpokePeering!.outputs.peeringResourceId : ''

@description('Name of the hub-to-spoke virtual network peering, or empty when peering is not deployed.')
output hubToSpokePeeringName string = deployHubToSpokePeering ? hubToSpokePeeringName : ''
