using 'peering.bicep'

/*
AVD Deployment / Network Peering Parameters

Environment:
- poc

Used by:
- infra/modules/network/peering.bicep

Notes:
- This deployment creates hub/spoke virtual network peering only.
- The spoke VNet must already exist before this deployment runs.
- The service connection running this deployment must have peering permissions on both the hub and spoke virtual networks.
- Do not store secrets, credentials, private keys, or certificate material in this file.
*/

param environment = 'poc'
param location = 'eastus'

param hubVirtualNetworkResourceId = '/subscriptions/3cea8964-57d2-44c4-9c10-0c10866165c8/resourceGroups/networkvpn-rg-prod/providers/Microsoft.Network/virtualNetworks/hub-vnet-prod'
param spokeVirtualNetworkResourceId ='/subscriptions/b908e3b2-448e-4a3f-9d79-996703913a99/resourceGroups/tv-avd-rg-network-eus-poc/providers/Microsoft.Network/virtualNetworks/tv-avd-vnet-pri-eus-poc'

param hubPeeringAlias = 'hub-prod'

param spokeToHubAllowVirtualNetworkAccess = true
param spokeToHubAllowForwardedTraffic = true
param spokeToHubAllowGatewayTransit = false
param spokeToHubUseRemoteGateways = true

param hubToSpokeAllowVirtualNetworkAccess = true
param hubToSpokeAllowForwardedTraffic = true
param hubToSpokeAllowGatewayTransit = true
param hubToSpokeUseRemoteGateways = false
