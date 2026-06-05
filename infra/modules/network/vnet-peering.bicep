targetScope = 'resourceGroup'

/*
AVD Deployment / VNet Peering

Scope:
- Resource Group

Deploys:
- A virtual network peering from a remote VNet to a local VNet

Does not deploy:
- Virtual networks

Notes:
- Called twice by main.bicep with the local and remote variables reversed to deploy both sides of the peering.

*/

// Parameters

@description('Name of the local AVD virtual network.')
param localVirtualNetworkName string

@description('Resource ID of the remote virtual network.')
param remoteVirtualNetworkResourceId string

@description('Name of the virtual network peering.')
param peeringName string

@description('Whether virtual network access is allowed from the local VNet to the remote VNet.')
param allowVirtualNetworkAccess bool = true

@description('Whether forwarded traffic is allowed from the local VNet to the remote VNet.')
param allowForwardedTraffic bool = true

@description('Whether gateway transit is allowed from the local VNet.')
param allowGatewayTransit bool = false

@description('Whether the local VNet uses gateways from the remote VNet.')
param useRemoteGateways bool = false

// Modules

module localToRemotePeering 'br/public:avm/res/network/virtual-network/virtual-network-peering:0.2.0' = {
  name: '${deployment().name}-peer'
  params: {
    name: peeringName
    localVnetName: localVirtualNetworkName
    remoteVirtualNetworkResourceId: remoteVirtualNetworkResourceId

    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit

    useRemoteGateways: useRemoteGateways
  }
}

// Outputs

@description('Resource ID of the virtual network peering.')
output peeringResourceId string = localToRemotePeering.outputs.resourceId

@description('Resource name of the virtual network peering.')
output peeringResourceName string = localToRemotePeering.outputs.name

