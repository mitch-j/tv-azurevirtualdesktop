targetScope = 'resourceGroup'

/*
AVD Deployment / Storage Private Endpoint

Scope:
- Resource Group

Deploys:
- Private endpoint for Azure Files on the FSLogix storage account
- Private DNS zone group for Azure Files private DNS registration

Does not deploy:
- Storage account
- File share
- Virtual network or subnets
- Private DNS zone
- Private DNS virtual network links
*/

// Parameters

@description('Azure region for the private endpoint.')
param location string

@description('Tags applied to the private endpoint.')
param tags object

@description('Name of the private endpoint.')
param privateEndpointName string

@description('Resource ID of the subnet used for the private endpoint.')
param privateEndpointSubnetResourceId string

@description('Name of the private DNS zone group attached to the private endpoint.')
param privateDnsZoneGroupName string = 'default'

@description('Resource ID of the Azure Files private DNS zone.')
param filePrivateDnsZoneResourceId string

@description('Name of the existing storage account.')
param storageAccountName string

// Existing Resources

resource storageAccount 'Microsoft.Storage/storageAccounts@2026-04-01' existing = {
  name: storageAccountName
}

module storageFilePrivateEndpoint 'br/public:avm/res/network/private-endpoint:0.12.1' = {
  name: '${deployment().name}-pep'
  params: {
    name: privateEndpointName
    tags: tags
    location: location
    subnetResourceId: privateEndpointSubnetResourceId
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-file'
        properties: {
          groupIds: [
            'file'
          ]
          privateLinkServiceId: storageAccount.id
        }
      }
    ]
    privateDnsZoneGroup: {
      name: privateDnsZoneGroupName
      privateDnsZoneGroupConfigs: [
        {
          privateDnsZoneResourceId: filePrivateDnsZoneResourceId
          name: 'file'
        }
      ]
    }
  }
}

// Outputs

@description('Resource ID of the Azure Files private endpoint.')
output privateEndpointResourceId string = storageFilePrivateEndpoint.outputs.resourceId

@description('Name of the Azure Files private endpoint.')
output privateEndpointName string = storageFilePrivateEndpoint.name

@description('Resource ID of the private DNS zone group attached to the Azure Files private endpoint.')
output privateDnsZoneGroupResourceId string = storageFilePrivateEndpoint.outputs.resourceGroupName
