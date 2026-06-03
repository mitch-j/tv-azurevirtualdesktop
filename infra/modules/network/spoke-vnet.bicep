targetScope = 'resourceGroup'

/*
AVD Deployment / Spoke VNet

Scope:
- Resource Group

Deploys:
- Spoke virtual network
- Session host subnet
- Private endpoint subnet
- Session host network security group

Does not deploy:
- Network resource group
- Hub virtual network
- Virtual network peering
- Storage accounts or private endpoints
- Session host virtual machines
*/

// Imports
import {
  commonConfig
} from '../../shared/config.bicep'


// Parameters

@description('Azure region for network resources.')
param location string

@description('Tags applied to deployed resources.')
param tags object

@description('Name of the AVD spoke virtual network.')
param virtualNetworkName string

@description('Virtual network address prefixes.')
param virtualNetworkAddressPrefixes array

@description('Name of the subnet used by AVD session hosts.')
param sessionHostSubnetName string

@description('Session host subnet address prefix.')
param sessionHostSubnetAddressPrefix string

@description('Name of the network security group for the private endpoint subnet.')
param privateEndpointNetworkSecurityGroupName string

@description('Name of the subnet reserved for private endpoints.')
param privateEndpointSubnetName string

@description('Private endpoint subnet address prefix.')
param privateEndpointSubnetAddressPrefix string

@description('Name of the network security group for AVD session hosts.')
param sessionHostNetworkSecurityGroupName string

@description('Optional custom DNS servers for the virtual network. Leave empty to use Azure-provided DNS.')
param dnsServers array = []

// Modules

module sessionHostNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: '${deployment().name}-sh-nsg'
  params:{
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
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.9.0' = {
  name: '${deployment().name}-vnet'
  params:{
    name: virtualNetworkName
    location: location
    tags: tags
    addressPrefixes: virtualNetworkAddressPrefixes
    dnsServers: dnsServers
    lock: {
      kind: commonConfig.lockKind
    }
    subnets: [
      {
        addressPrefix: sessionHostSubnetAddressPrefix
        name: sessionHostSubnetName
        networkSecurityGroupResourceId: sessionHostNetworkSecurityGroup.outputs.resourceId
        privateEndpointNetworkPolicies: 'Enabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
      {
        addressPrefix: privateEndpointSubnetAddressPrefix
        name: privateEndpointSubnetName
        networkSecurityGroupResourceId: privateEndpointNetworkSecurityGroup.outputs.resourceId
        privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: 'Enabled'
      }
    ]
  }
}

// Outputs

@description('Resource ID of the deployed AVD spoke virtual network.')
output virtualNetworkResourceId string = virtualNetwork.outputs.resourceId

@description('Resource Name of the subnets created')
output virtualNetworkSubnetNames array = virtualNetwork.outputs.subnetNames

@description('Resource ID of the subnet used by AVD session hosts.')
output sessionHostSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[0]

@description('Resource ID of the subnet used by private endpoints.')
output privateEndpointSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[1]

@description('Resource ID of the network security group associated with the session host subnet.')
output sessionHostNetworkSecurityGroupResourceId string = sessionHostNetworkSecurityGroup.outputs.resourceId

@description('Resource ID of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupResourceId string = privateEndpointNetworkSecurityGroup.outputs.resourceId
