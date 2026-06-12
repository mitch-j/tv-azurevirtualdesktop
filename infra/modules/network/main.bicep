targetScope = 'subscription'

/*
AVD Deployment / Network

Scope:
- Subscription

Deploys:
- Network resource group
- AVD spoke virtual network
- Session host subnets
- Private endpoint subnet
- Session host network security group
- Private endpoint network security group
- Azure Files private DNS zone
- Private DNS zone VNet link to the AVD spoke virtual network

Does not deploy:
- Hub virtual network
- Virtual network peering
- AVD host pools, desktop application groups, or workspaces
- Storage accounts or FSLogix shares
- Session host virtual machines
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
param virtualNetworkAddressPrefixes string[]

@description('Session host subnet definitions.')
param sessionHostSubnets SubnetConfig[]

@description('Private endpoint subnet definition.')
param privateEndpointSubnet SubnetConfig

@description('Optional custom DNS servers for the virtual network. Leave empty to use Azure-provided DNS.')
param dnsServers string[] = []

/*
@description('Optional management subnet definition.')
param managementSubnet SubnetConfig?
*/

@description('Deploy diagnostic settings for resources created by this module.')
param deployDiagnosticSettings bool = true

@description('Optional resource ID of the Log Analytics workspace that receives diagnostic logs. If empty, the module resolves the workspace from the deterministic monitoring resource group and workspace name.')
param logAnalyticsWorkspaceResourceId string = ''

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Location configuration for the selected Azure region.
var locationConfig = locationConfigMap[location]

// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

var sessionHostSubnetResources = [
  for sessionHostSubnet in sessionHostSubnetDefinitions: {
    addressPrefix: sessionHostSubnet.addressPrefix
    name: sessionHostSubnet.name
    networkSecurityGroupResourceId: sessionHostNetworkSecurityGroupResourceId
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
]

var privateEndpointSubnetResource = {
  addressPrefix: privateEndpointSubnetDefinition.addressPrefix
  name: privateEndpointSubnetDefinition.name
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

// Resource IDs

resource sessionHostNetworkSecurityGroupExisting 'Microsoft.Network/networkSecurityGroups@2025-07-01' existing = {
  name: sessionHostNetworkSecurityGroupName
  scope: resourceGroup(networkResourceGroupName)
}

resource privateEndpointNetworkSecurityGroupExisting 'Microsoft.Network/networkSecurityGroups@2025-07-01' existing = {
  name: privateEndpointNetworkSecurityGroupName
  scope: resourceGroup(networkResourceGroupName)
}

var sessionHostNetworkSecurityGroupResourceId = sessionHostNetworkSecurityGroupExisting.id
var privateEndpointNetworkSecurityGroupResourceId = privateEndpointNetworkSecurityGroupExisting.id

// Resources

// Existing Log Analytics workspace used as the diagnostics target for resources.
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(monitoringResourceGroupName)
}

var effectiveLogAnalyticsWorkspaceResourceId = empty(logAnalyticsWorkspaceResourceId)
  ? logAnalyticsWorkspace.id
  : logAnalyticsWorkspaceResourceId

var diagnosticsEnabled = deployDiagnosticSettings && !empty(logAnalyticsWorkspaceResourceId)

var sessionHostNetworkSecurityGroupDiagnosticSettings = diagnosticsEnabled
  ? [
      {
        name: 'diag-network-nsg-session-hosts'
        workspaceResourceId: effectiveLogAnalyticsWorkspaceResourceId
        logCategoriesAndGroups: [
          {
            category: 'NetworkSecurityGroupEvent'
            enabled: true
          }
          {
            category: 'NetworkSecurityGroupRuleCounter'
            enabled: true
          }
        ]
      }
    ]
  : []

var privateEndpointNetworkSecurityGroupDiagnosticSettings = diagnosticsEnabled
  ? [
      {
        name: 'diag-network-nsg-session-hosts'
        workspaceResourceId: effectiveLogAnalyticsWorkspaceResourceId
        logCategoriesAndGroups: [
          {
            category: 'NetworkSecurityGroupEvent'
            enabled: true
          }
          {
            category: 'NetworkSecurityGroupRuleCounter'
            enabled: true
          }
        ]
      }
    ]
  : []

var virtualNetworkDiagnosticSettings = diagnosticsEnabled
  ? [
      {
        name: 'diag-network-vnet-primary'
        workspaceResourceId: effectiveLogAnalyticsWorkspaceResourceId
        logCategoriesAndGroups: [
          {
            categoryGroup: 'allLogs'
            enabled: true
          }
        ]
        metricCategories: [
          {
            category: 'AllMetrics'
            enabled: true
          }
        ]
      }
    ]
  : []

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

module sessionHostNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: '${deployment().name}-${locationConfig.shortCode}-vdsh-nsg'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    name: sessionHostNetworkSecurityGroupName
    location: location
    tags: tags
    securityRules: []
    diagnosticSettings: sessionHostNetworkSecurityGroupDiagnosticSettings
  }
  dependsOn: [
    networkResourceGroup
  ]
}

module privateEndpointNetworkSecurityGroup 'br/public:avm/res/network/network-security-group:0.5.3' = {
  name: '${deployment().name}-${locationConfig.shortCode}-pe-nsg'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    name: privateEndpointNetworkSecurityGroupName
    location: location
    tags: tags
    securityRules: []
    diagnosticSettings: privateEndpointNetworkSecurityGroupDiagnosticSettings
  }
  dependsOn: [
    networkResourceGroup
  ]
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.9.0' = {
  name: '${deployment().name}-${locationConfig.shortCode}-vnet'
  scope: resourceGroup(networkResourceGroupName)
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
    diagnosticSettings: virtualNetworkDiagnosticSettings
  }
  dependsOn: [
    sessionHostNetworkSecurityGroup
    privateEndpointNetworkSecurityGroup
  ]
}

// Network owns the Azure Files private DNS zone because storage private endpoints depend on spoke VNet DNS resolution.
module filePrivateDnsZone 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  name: '${deployment().name}-${locationConfig.shortCode}-file-dns'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    name: filePrivateDnsZoneName
    location: 'global'
    tags: tags
    virtualNetworkLinks: [
      {
        name: filePrivateDnsZoneVirtualNetworkLinkName
        virtualNetworkResourceId: virtualNetwork.outputs.resourceId
        location: 'global'
        registrationEnabled: false
        tags: tags
      }
    ]
  }
}

// Outputs

@description('Resource Name of the deployed AVD spoke virtual network.')
output networkResourceGroupName string = networkResourceGroupName

@description('Name of the deployed AVD spoke virtual network.')
output virtualNetworkName string = virtualNetworkName

@description('Resource ID of the deployed AVD spoke virtual network.')
output virtualNetworkResourceId string = virtualNetwork.outputs.resourceId

@description('Names of the subnets created in the AVD spoke virtual network.')
output virtualNetworkSubnetNames array = virtualNetwork.outputs.subnetNames

@description('Names of the session host subnets.')
output sessionHostSubnetNames array = [
  for sessionHostSubnet in sessionHostSubnetDefinitions: sessionHostSubnet.name
]

resource virtualNetworkReference 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(networkResourceGroupName)
}

@description('Resource IDs of the session host subnets.')
output sessionHostSubnetResourceIds array = [
  for sessionHostSubnet in sessionHostSubnetDefinitions: '${virtualNetworkReference.id}/subnets/${sessionHostSubnet.name}'
]

@description('Resource ID of the private endpoint subnet.')
output privateEndpointSubnetResourceId string = '${virtualNetworkReference.id}/subnets/${privateEndpointSubnetDefinition.name}'

@description('Name of the network security group associated with the session host subnet.')
output sessionHostNetworkSecurityGroupName string = sessionHostNetworkSecurityGroupName

@description('Resource ID of the network security group associated with the session host subnets.')
output sessionHostNetworkSecurityGroupResourceId string = sessionHostNetworkSecurityGroup.outputs.resourceId

@description('Name of the subnet used by private endpoints.')
output privateEndpointSubnetName string = privateEndpointSubnetDefinition.name

@description('Name of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupName string = privateEndpointNetworkSecurityGroupName

@description('Resource ID of the network security group associated with the private endpoint subnet.')
output privateEndpointNetworkSecurityGroupResourceId string = privateEndpointNetworkSecurityGroup.outputs.resourceId

@description('Resource ID of the Azure Files private DNS zone.')
output filePrivateDnsZoneResourceId string = filePrivateDnsZone.outputs.resourceId

@description('Name of the Azure Files private DNS zone.')
output filePrivateDnsZoneName string = filePrivateDnsZoneName

@description('DNS servers configured on the AVD spoke virtual network.')
output dnsServers array = dnsServers
