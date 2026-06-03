targetScope = 'resourceGroup'

/*
AVD Deployment / VNet Peering

Scope:
- Resource Group

Deploys:
- Peering from the local/spoke VNet to a remote hub VNet
- This creates only the spoke-to-hub side

Does not deploy:
- Hub virtual network
- Hub-to-spoke peering
*/

// Parameters

@description('Name of the local AVD spoke virtual network.')
param localVirtualNetworkName string

@description('Resource ID of the remote hub virtual network.')
param remoteVirtualNetworkResourceId string

@description('Name of the peering from the AVD spoke VNet to the hub VNet.')
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
  name: 'deploy-${peeringName}'
  params: {
    name: peeringName
    remoteVirtualNetworkResourceId: remoteVirtualNetworkResourceId
    localVnetName: localVirtualNetworkName
    allowVirtualNetworkAccess: allowVirtualNetworkAccess
    allowForwardedTraffic: allowForwardedTraffic
    allowGatewayTransit: allowGatewayTransit
    useRemoteGateways: useRemoteGateways
  }
}

// Outputs

@description('Resource ID of the spoke-to-hub virtual network peering.')
output peeringResourceId string = localToRemotePeering.outputs.resourceId

@description('Resource name of the spoke-to-hub virtual network peering.')
output peeringResourceName string = localToRemotePeering.outputs.name

