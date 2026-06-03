targetScope = 'subscription'

/*
AVD Deployment / Network

Scope:
- Subscription

Deploys:
- AVD spoke virtual network
- Session host subnet
- Private endpoint subnet
- Session host network security group
- Optional spoke-to-hub virtual network peering

Does not deploy:
- Network resource group
- AVD host pools, desktop application groups, or workspaces
- Storage accounts or FSLogix shares
- Session host virtual machines
- Hub virtual network
- Hub-to-spoke peering
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

// Name of the network security group associated with the session host subnet.
var sessionHostNetworkSecurityGroupName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.networkSecurityGroup,
  resourcePurpose.sessionHosts,
  environmentConfig.shortName
)

// Name of the optional spoke-to-hub virtual network peering.
var spokeToHubPeeringName = resourceNameWithPurpose(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.virtualNetworkPeering,
  resourcePurpose.network,
  environmentConfig.shortName
)

// Modules

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
    privateEndpointSubnetName: privateEndpointSubnetName
    privateEndpointSubnetAddressPrefix: privateEndpointSubnetAddressPrefix
    sessionHostNetworkSecurityGroupName: sessionHostNetworkSecurityGroupName
    dnsServers: dnsServers
  }
}

module spokePeering './spoke-to-hub-peering.bicep' = if (!empty(hubVirtualNetworkResourceId)) {
  name: '${deployment().name}-s2h-peer'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    localVirtualNetworkName: virtualNetworkName
    remoteVirtualNetworkResourceId: hubVirtualNetworkResourceId
    peeringName: spokeToHubPeeringName
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
  dependsOn: [
    spokeVnet
  ]
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

@description('Resource ID of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringResourceId string = !empty(hubVirtualNetworkResourceId) ? spokePeering!.outputs.peeringResourceId : ''

@description('Resource name of the spoke-to-hub virtual network peering, or empty when peering is not deployed.')
output spokeToHubPeeringResourceName string = !empty(hubVirtualNetworkResourceId) ? spokePeering!.outputs.peeringResourceName : ''
