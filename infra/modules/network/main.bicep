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

@description('Deployment environment.')
param environment EnvironmentName

@description('Azure region where storage resources are deployed.')
param location LocationName

@description('Virtual network address prefixes.')
param virtualNetworkAddressPrefixes array

@description('Session host subnet definitions.')
param sessionHostSubnets SubnetConfig[]

@description('Private endpoint subnet definition.')
param privateEndpointSubnet SubnetConfig

@description('Optional custom DNS servers for the virtual network. Leave empty to use Azure-provided DNS.')
param dnsServers array = []

/*
@description('Optional management subnet definition.')
param managementSubnet SubnetConfig?
*/

@description('Deploy diagnostic settings for resources created by this module.')
param deployDiagnosticSettings bool = true

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
var filePrivateDnsZoneName = 'privatelink.file.${az.environment().suffixes.storage}'

var filePrivateDnsZoneVirtualNetworkLinkName = toLower('${virtualNetworkName}-file-dns-link')

// Diagnostics and Monitoring resources deterministically resolved
var monitoringResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.monitoring,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var logAnalyticsWorkspaceName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.logAnalyticsWorkspace,
  resourcePurpose.logs,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Resources

// Existing Log Analytics workspace used as the diagnostics target for resources.
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(monitoringResourceGroupName)
}

var logAnalyticsWorkspaceResourceId = logAnalyticsWorkspace.id

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
    logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResourceId
    deployDiagnosticSettings: deployDiagnosticSettings
  }
  dependsOn: [
    networkResourceGroup
  ]
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

@description('Resource ID of the Azure Files private DNS zone.')
output filePrivateDnsZoneResourceId string = filePrivateDnsZone.outputs.privateDnsZoneResourceId

@description('Name of the Azure Files private DNS zone.')
output filePrivateDnsZoneName string = filePrivateDnsZoneName

@description('DNS servers configured on the AVD spoke virtual network.')
output dnsServers array = dnsServers
