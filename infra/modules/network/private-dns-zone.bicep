targetScope = 'resourceGroup'

/*
AVD Deployment / Private DNS Zone

Scope:
- Resource Group

Deploys:
- Private DNS zone
- VNet link from the private DNS zone to the AVD spoke VNet

Does not deploy:
- Virtual networks
- Private endpoints
- Storage accounts or file shares
*/

// Parameters

@description('Tags applied to deployed AVD resources.')
param tags object

@description('Name of the private DNS zone.')
param privateDnsZoneName string

@description('Name of the private DNS zone virtual network link.')
param virtualNetworkLinkName string

@description('Resource ID of the virtual network linked to the private DNS zone.')
param virtualNetworkResourceId string

// Modules

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  name: '${deployment().name}-pdnsz'
  params: {
    name: privateDnsZoneName
    location: 'global'
    tags: tags
    virtualNetworkLinks: [
      {
        name: virtualNetworkLinkName
        virtualNetworkResourceId: virtualNetworkResourceId
        location: 'global'
        registrationEnabled: false
        tags: tags
      }
    ]
  }
}

// Outputs

@description('Resource ID of the private DNS zone.')
output privateDnsZoneResourceId string = privateDnsZone.outputs.resourceId

@description('Name of the private DNS zone.')
output privateDnsZoneName string = privateDnsZone.outputs.name
