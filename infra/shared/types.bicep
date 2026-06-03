metadata name = 'Type Definitions'
metadata description = 'This Bicep file defines shared types used across the IaC templates. It includes standard tag values, environment configurations, and resource reference types for consistent deployment practices.'

// Environment Types

@description('Short deployment environment names used by repo pipelines and parameter files.')
@export()
type EnvironmentName = 'dev' | 'test' | 'prod' | 'e2e' | 'poc'

@description('Azure policy-compliant Environment tag values.')
@export()
type TagEnvironmentName =
  | 'Development'
  | 'Dev/Stage'
  | 'Stage'
  | 'Production'
  | 'Proof of Concept'
  | 'End to End'

@description('Standard environment configuration used by shared repo templates.')
@export()
type EnvironmentConfig = {
  @description('Short environment name used in resource names.')
  shortName: EnvironmentName

  @description('Azure policy-compliant Environment tag value.')
  tagEnvironment: TagEnvironmentName

  @description('Default diagnostic log retention in days.')
  logRetentionDays: int

  @description('Optional support email address for this environment.')
  supportEmail: string?
}

@description('Map of supported deployment environments to standard settings.')
@export()
type EnvironmentConfigMap = {
  dev: EnvironmentConfig
  test: EnvironmentConfig
  prod: EnvironmentConfig
  e2e: EnvironmentConfig
  poc: EnvironmentConfig
}

// Tag Types

@description('Azure policy-compliant Division tag values.')
@export()
type DivisionName =
  | 'Information Technology'
  | 'Finance'
  | 'Marketing'
  | 'Ecommerce'
  | 'Sales and Business Development'
  | 'Lumber and Building Materials'
  | 'Administration'
  | 'Logistics'
  | 'Merchandising'
  | 'Shared'

@description('Required standard Azure resource tags.')
@export()
type StandardTags = {
  Environment: TagEnvironmentName
  Division: DivisionName
  Product: string
}

// Naming Types

@description('Supported Azure resource type keys for standard naming.')
@export()
type ResourceTypeName =
  | 'appService'
  | 'appServicePlan'
  | 'applicationInsights'
  | 'containerRegistry'
  | 'functionApp'
  | 'keyVault'
  | 'logAnalyticsWorkspace'
  | 'managedIdentity'
  | 'privateEndpoint'
  | 'privateDnsZone'
  | 'resourceGroup'
  | 'storageAccount'
  | 'subnet'
  | 'virtualNetwork'
  | 'hostPool'
  | 'desktopApplicationGroup'
  | 'workspace'
  | 'scalingPlan'
  | 'computeGallery'
  | 'imageTemplate'
  | 'sessionHost'

@description('Supported purpose keys for standard naming.')
@export()
type PurposeName =
  | 'serviceObjects'
  | 'storage'
  | 'network'
  | 'compute'
  | 'sessionHosts'
  | 'opsPooled'
  | 'devPooled'
  | 'devPersonal'
  | 'opsPooledDesktop'
  | 'opsPersonalDesktop'
  | 'devPooledDesktop'
  | 'devPersonalDesktop'
  | 'primary'
  | 'diagnostics'
  | 'bootDiagnostics'
  | 'images'
  | 'logs'
  | 'fslogix'

// Existing Resource References

@description('Generic reference to an existing Azure resource.')
@export()
type ExistingResourceRef = {
  @description('Resource name.')
  name: string

  @description('Resource group name.')
  resourceGroupName: string

  @description('Subscription ID.')
  subscriptionId: string
}

@description('Generic reference to an existing virtual network.')
@export()
type ExistingVnetRef = {
  @description('Resource name.')
  name: string

  @description('Resource group name.')
  resourceGroupName: string

  @description('Subscription ID.')
  subscriptionId: string

  @description('Optional full resource ID. Use this when the VNet is easier to pass directly.')
  resourceId: string?
}

// Network Types

@description('Subnet configuration for virtual network modules.')
@export()
type SubnetConfig = {
  @description('Short purpose to include in the subnet name.')
  purpose: string?

  @description('Subnet address prefix.')
  addressPrefix: string

  @description('Enable or disable network policies for private endpoints.')
  privateEndpointNetworkPolicies: 'Enabled' | 'Disabled'?

  @description('Enable or disable network policies for private link services.')
  privateLinkServiceNetworkPolicies: 'Enabled' | 'Disabled'?
}

@description('Virtual network peering configuration.')
@export()
type PeeringConfig = {
  @description('Optional peering name override.')
  name: string?

  @description('Allow traffic between the two virtual networks.')
  allowVirtualNetworkAccess: bool?

  @description('Allow forwarded traffic from network virtual appliances or gateways.')
  allowForwardedTraffic: bool?

  @description('Allow this VNet to share its VPN or ExpressRoute gateway.')
  allowGatewayTransit: bool?

  @description('Allow this VNet to use the remote VNet gateway.')
  useRemoteGateways: bool?
}

// Private DNS Zone Types

@description('Additional private DNS virtual network link configuration.')
@export()
type AdditionalPrivateDnsVnetLinkConfig = {
  @description('Private DNS virtual network link name.')
  linkName: string

  @description('Whether auto-registration is enabled for the linked virtual network.')
  registrationEnabled: bool?

  @description('DNS resolution policy for the virtual network link.')
  resolutionPolicy: 'NxDomainRedirect' | 'Default'?

  @description('Resource ID of the linked virtual network.')
  virtualNetworkId: string
}

@description('Private DNS zone configuration.')
@export()
type PrivateDnsZoneConfig = {
  @description('Private DNS zone name.')
  name: string

  @description('Whether to create a link to the resolver virtual network.')
  createResolverVnetLink: bool?

  @description('Whether auto-registration is enabled on the resolver VNet link.')
  resolverAutoRegistrationEnabled: bool?

  @description('Whether internet fallback is enabled where supported.')
  enableInternetFallback: bool?

  @description('Additional VNet links to create for this private DNS zone.')
  additionalLinks: AdditionalPrivateDnsVnetLinkConfig[]?
}

// Private DNS Resolver Types

@description('Private DNS resolver reference.')
@export()
type PrivateDnsResolverConfig = {
  @description('Resource name.')
  name: string

  @description('Resource group name.')
  resourceGroupName: string

  @description('Subscription ID.')
  subscriptionId: string

  @description('Private DNS resolver virtual network resource ID.')
  vnetId: string
}

@description('Target DNS server configuration for DNS forwarding rules.')
@sealed()
@export()
type TargetDnsServerConfig = {
  @description('Target DNS server IP address.')
  ipAddress: string

  @description('Target DNS server port.')
  port: int?
}

@description('Private DNS resolver forwarding rule configuration.')
@sealed()
@export()
type ForwardingRuleConfig = {
  @description('Forwarding rule name.')
  name: string

  @description('Domain suffix to forward. Example: corp.local.')
  domainName: string

  @description('Whether this rule is enabled.')
  enabled: bool?

  @description('Target DNS servers for this rule.')
  targetDnsServers: TargetDnsServerConfig[]
}

@description('Private DNS forwarding ruleset virtual network link configuration.')
@sealed()
@export()
type ForwardingRulesetLinkConfig = {
  @description('Ruleset virtual network link name.')
  name: string

  @description('Resource ID of the linked virtual network.')
  virtualNetworkId: string
}

@description('Private DNS forwarding ruleset configuration.')
@sealed()
@export()
type ForwardingRulesetManagedConfig = {
  @description('Forwarding ruleset name.')
  name: string

  @description('Optional outbound endpoint resource IDs. Defaults should be handled by the consuming module.')
  outboundEndpointIds: string[]?

  @description('Forwarding rules to create in this ruleset.')
  rules: ForwardingRuleConfig[]?

  @description('Virtual networks to link to this ruleset.')
  vnetLinks: ForwardingRulesetLinkConfig[]?
}

// RBAC Types

@description('Role assignment configuration.')
@export()
type RoleAssignmentConfig = {
  @description('Microsoft Entra principal object ID.')
  principalId: string

  @description('Principal type.')
  principalType: 'User' | 'Group' | 'ServicePrincipal' | 'ForeignGroup'

  @description('Role definition ID GUID.')
  roleDefinitionId: string
}

// Azure Virtual Desktop Types

@description('Azure Virtual Desktop workspace configuration.')
@export()
type WorkspaceConfig = {
  @description('Short name used in the generated workspace name.')
  name: PurposeName

  @description('Friendly display name.')
  friendlyName: string?

  @description('Description.')
  description: string?

  @description('Public network access setting.')
  publicNetworkAccess: 'Enabled' | 'Disabled'?
}

@description('Azure Virtual Desktop desktop application group configuration.')
@export()
type DesktopApplicationGroupConfig = {
  @description('Short name used in the generated desktop application group name.')
  name: PurposeName

  @description('Friendly display name.')
  friendlyName: string?

  @description('Description.')
  description: string?

  @description('Short workspace name where this app group should be published.')
  workspaceName: PurposeName

  @description('RBAC assignments scoped to the application group.')
  rbacAssignments: RoleAssignmentConfig[]?
}

@description('Azure Virtual Desktop host pool configuration.')
@export()
type HostPoolConfig = {
  @description('Short name used in the generated host pool name.')
  name: PurposeName

  @description('Friendly display name.')
  friendlyName: string?

  @description('Description.')
  description: string?

  @description('Host pool type.')
  hostPoolType: 'Pooled' | 'Personal'

  @description('Load balancer type.')
  loadBalancerType: 'BreadthFirst' | 'DepthFirst' | 'Persistent'

  @description('Preferred app group type.')
  preferredAppGroupType: 'Desktop' | 'RailApplications' | 'None'

  @description('Maximum session limit.')
  maxSessionLimit: int?

  @description('Whether validation environment is enabled.')
  validationEnvironment: bool?

  @description('Start VM on connect.')
  startVMOnConnect: bool?

  @description('Custom RDP properties.')
  customRdpProperty: string?

  @description('Public network access setting.')
  publicNetworkAccess: 'Enabled' | 'Disabled'?

  @description('Desktop application group for this host pool.')
  desktopApplicationGroup: DesktopApplicationGroupConfig
}
