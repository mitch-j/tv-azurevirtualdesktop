targetScope = 'resourceGroup'

/*
AVD Deployment / Spoke VNet

Scope:
- Resource Group

Deploys:
- Spoke virtual network
- Session host subnets
- Private endpoint subnet
- Session host network security group
- Private endpoint network security group

Does not deploy:
- Network resource group
- Hub virtual network
- Virtual network peering
- Storage accounts or private endpoints
- Session host virtual machines
*/

// Imports

import {
  LocationName
} from '../../shared/types.bicep'

import {
  commonConfig
} from '../../shared/config.bicep'

// Types

@sealed()
type SubnetDefinition = {
  @description('Subnet name.')
  name: string

  @description('CIDR block assigned to the subnet.')
  addressPrefix: string
}

// Parameters

@description('Tags applied to deployed AVD resources.')
param tags object

@description('Azure region for deployed resources.')
param location LocationName

@description('Name of the AVD spoke virtual network.')
param virtualNetworkName string

@description('Virtual network address prefixes.')
param virtualNetworkAddressPrefixes array

@description('Session host subnet definitions.')
param sessionHostSubnets SubnetDefinition[]

@description('Name of the network security group for the private endpoint subnet.')
param privateEndpointNetworkSecurityGroupName string

@description('Private endpoint subnet definition.')
param privateEndpointSubnet SubnetDefinition

@description('Name of the network security group for AVD session hosts.')
param sessionHostNetworkSecurityGroupName string

@description('Optional custom DNS servers for the virtual network. Leave empty to use Azure-provided DNS.')
param dnsServers array = []

// Variables

var sessionHostNetworkSecurityGroupResourceId = resourceId(
  'Microsoft.Network/networkSecurityGroups',
  sessionHostNetworkSecurityGroupName
)

var privateEndpointNetworkSecurityGroupResourceId = resourceId(
  'Microsoft.Network/networkSecurityGroups',
  privateEndpointNetworkSecurityGroupName
)

var sessionHostSubnetResources = [
  for sessionHostSubnet in sessionHostSubnets: {
    addressPrefix: sessionHostSubnet.addressPrefix
    name: sessionHostSubnet.name
    networkSecurityGroupResourceId: sessionHostNetworkSecurityGroupResourceId
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
]

var privateEndpointSubnetResource = {
  addressPrefix: privateEndpointSubnet.addressPrefix
  name: privateEndpointSubnet.name
  networkSecurityGroupResourceId: privateEndpointNetworkSecurityGroupResourceId
  privateEndpointNetworkPolicies: 'Disabled'
  privateLinkServiceNetworkPolicies: 'Enabled'
}

var virtualNetworkSubnets = concat(
  sessionHostSubnetResources,
  [
    privateEndpointSubnetResource
  ]
)

// Modules

module sessionHostNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: '${deployment().name}-vdsh-nsg'
  params: {
    name: sessionHostNetworkSecurityGroupName
    location: location
    tags: tags
    securityRules: []
  }
}

module privateEndpointNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: '${deployment().name}-pe-nsg'
  params: {
    name: privateEndpointNetworkSecurityGroupName
    location: location
    tags: tags
    securityRules: []
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.9.0' = {
  name: '${deployment().name}-vnet'
  params: {
    name: virtualNetworkName
    location: location
    tags: tags
    addressPrefixes: virtualNetworkAddressPrefixes
    dnsServers: dnsServers
    lock: {
      kind: commonConfig.lockKind
    }
    subnets: virtualNetworkSubnets
  }
  dependsOn: [
    sessionHostNetworkSecurityGroup
    privateEndpointNetworkSecurityGroup
  ]
}

// Outputs

@description('Resource ID of the deployed AVD spoke virtual network.')
output virtualNetworkResourceId string = virtualNetwork.outputs.resourceId

@description('Names of the subnets created in the AVD spoke virtual network.')
output virtualNetworkSubnetNames array = virtualNetwork.outputs.subnetNames

@description('Resource IDs of the session host subnets.')
output sessionHostSubnetResourceIds array = [
  for sessionHostSubnet in sessionHostSubnets: resourceId(
    'Microsoft.Network/virtualNetworks/subnets',
    virtualNetworkName,
    sessionHostSubnet.name
  )
]

@description('Resource ID of the private endpoint subnet.')
output privateEndpointSubnetResourceId string = resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  virtualNetworkName,
  privateEndpointSubnet.name
)

@description('Resource ID of the network security group associated with the session host subnets.')
output sessionHostNetworkSecurityGroupResourceId string = sessionHostNetworkSecurityGroup.outputs.resourceId

@description('Resource ID of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupResourceId string = privateEndpointNetworkSecurityGroup.outputs.resourceId
