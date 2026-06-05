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
- Azure Files private DNS zone
- Private DNS zone VNet link to the AVD spoke virtual network

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
  LocationName
} from '../../shared/types.bicep'

import {
  baseTags
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
param location LocationName

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

@description('Short alias used for the hub side of directional peering names.')
param hubPeeringAlias string = 'hub-prod'

/*
@description('Optional management subnet definition.')
param managementSubnet SubnetConfig?
*/

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

// Location is included so the same environment can support regional network deployments without name collisions.
var networkResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.network,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var virtualNetworkName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.virtualNetwork,
  resourcePurpose.primary,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var sessionHostSubnetDefinitions = [
  for sessionHostSubnet in sessionHostSubnets: {
    name: resourceNameWithPurposeAndLocation(
      commonConfig.namePrefix,
      commonConfig.workloadName,
      resourceType.subnet,
      sessionHostSubnet.purpose,
      locationConfig.shortCode,
      environmentConfig.shortName
    )
    addressPrefix: sessionHostSubnet.addressPrefix
  }
]

var privateEndpointSubnetDefinition = {
  name: resourceNameWithPurposeAndLocation(
    commonConfig.namePrefix,
    commonConfig.workloadName,
    resourceType.subnet,
    privateEndpointSubnet.purpose,
    locationConfig.shortCode,
    environmentConfig.shortName
  )
  addressPrefix: privateEndpointSubnet.addressPrefix
}

// Private endpoint subnet uses its own NSG so PE rules stay isolated from session host traffic.
var privateEndpointNetworkSecurityGroupName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.networkSecurityGroup,
  resourcePurpose.privateEndpoints,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Session host subnets share an NSG because the host pool network rules should be managed consistently.
var sessionHostNetworkSecurityGroupName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.networkSecurityGroup,
  resourcePurpose.sessionHosts,
  locationConfig.shortCode,
  environmentConfig.shortName
)

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

// Hub VNet ID parsing

// Break the hub VNet resource ID into path segments so subscription, resource group, and VNet name can be derived when explicit override parameters are not provided.
var hubVnetIdSegments = split(hubVirtualNetworkResourceId, '/')

// Subscription ID parsed from the hub VNet resource ID.
var parsedHubSubscriptionId = empty(hubVirtualNetworkResourceId) ? '' : hubVnetIdSegments[2]

// Resource group name parsed from the hub VNet resource ID.
var parsedHubResourceGroupName = empty(hubVirtualNetworkResourceId) ? '' : hubVnetIdSegments[4]

// VNet name parsed from the hub VNet resource ID.
var parsedHubVnetName = empty(hubVirtualNetworkResourceId) ? '' : hubVnetIdSegments[lastIndexOf(hubVnetIdSegments, 'virtualNetworks') + 1]

// Hub VNet effective values

// Hub subscription ID used for deployment. Explicit parameter value wins over the parsed resource ID value.
var effectiveHubSubscriptionId = empty(hubSubscriptionId) ? parsedHubSubscriptionId : hubSubscriptionId

// Hub resource group name used for deployment. Explicit parameter value wins over the parsed resource ID value.
var effectiveHubResourceGroupName = empty(hubResourceGroupName) ? parsedHubResourceGroupName : hubResourceGroupName

// Hub VNet name used for deployment. Explicit parameter value wins over the parsed resource ID value.
var effectiveHubVnetName = empty(hubVirtualNetworkName) ? parsedHubVnetName : hubVirtualNetworkName

// Peering deployment controls

// Deploy spoke-to-hub peering when a hub VNet resource ID is provided.
var deploySpokeToHubPeering = !empty(hubVirtualNetworkResourceId)

// Deploy hub-to-spoke peering only when all hub-side scope values can be resolved.
var deployHubToSpokePeering = !empty(hubVirtualNetworkResourceId) && !empty(effectiveHubSubscriptionId) && !empty(effectiveHubResourceGroupName) && !empty(effectiveHubVnetName)

var filePrivateDnsZoneName = 'privatelink.file.core.windows.net'

var filePrivateDnsZoneVirtualNetworkLinkName = toLower('${virtualNetworkName}-file-dns-link')

// Modules

module networkResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${deployment().name}-${locationConfig.shortCode}-network-rg'
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
  name: '${deployment().name}-${locationConfig.shortCode}-spoke-vnet'
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
  name: '${deployment().name}-${locationConfig.shortCode}-s2h-peer'
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
  name: '${deployment().name}-${locationConfig.shortCode}-h2s-peer'
  scope: resourceGroup(effectiveHubSubscriptionId, effectiveHubResourceGroupName)
  params: {
    localVirtualNetworkName: effectiveHubVnetName
    remoteVirtualNetworkResourceId: spokeVnet.outputs.virtualNetworkResourceId
    peeringName: hubToSpokePeeringName
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Network owns the Azure Files private DNS zone because storage private endpoints depend on spoke VNet DNS resolution.
module filePrivateDnsZone './private-dns-zone.bicep' = {
  name: '${deployment().name}-${locationConfig.shortCode}-file-dns'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    tags: tags
    privateDnsZoneName: filePrivateDnsZoneName
    virtualNetworkLinkName: filePrivateDnsZoneVirtualNetworkLinkName
    virtualNetworkResourceId: spokeVnet.outputs.virtualNetworkResourceId
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

@description('Resource ID of the Azure Files private DNS zone.')
output filePrivateDnsZoneResourceId string = filePrivateDnsZone.outputs.privateDnsZoneResourceId

@description('Name of the Azure Files private DNS zone.')
output filePrivateDnsZoneName string = filePrivateDnsZoneName

@description('DNS servers configured on the AVD spoke virtual network.')
output dnsServers array = dnsServers
