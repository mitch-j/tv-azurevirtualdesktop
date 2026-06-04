metadata name = 'Type Definitions'
metadata description = 'Shared Bicep type contracts used across the Azure Virtual Desktop IaC templates.'

// Name Types

@description('Supported organization or company prefixes used in resource names.')
@export()
type NamePrefix =
  | 'dib'
  | 'tv'

@description('Supported workload names used in resource names.')
@export()
type WorkloadName =
  | 'avd'
  | 'connectivity'
  | 'security'
  | 'management'
  | 'identity'

// Environment Types

@description('Short deployment environment names used by repo pipelines and parameter files.')
@export()
type EnvironmentName =
  | 'dev'
  | 'test'
  | 'prod'
  | 'e2e'
  | 'poc'
  | 'dr'

@description('Short deployment environment names used in resource names.')
@export()
type EnvironmentShortName =
  | 'dev'
  | 'test'
  | 'prod'
  | 'e2e'
  | 'poc'
  | 'dr'

@description('Single-character environment codes used where compact names are required.')
@export()
type EnvironmentCode =
  | 'd'
  | 't'
  | 'p'
  | 'e'
  | 'x'
  | 'r'

@description('Azure policy-compliant Environment tag values.')
@export()
type EnvironmentTagName =
  | 'Development'
  | 'Dev/Stage'
  | 'Stage'
  | 'Production'
  | 'Proof of Concept'
  | 'End to End'
  | 'Disaster Recovery'

@description('Standard environment configuration used by shared repo templates.')
@sealed()
@export()
type EnvironmentConfig = {
  @description('Short environment name used in resource names.')
  shortName: EnvironmentShortName

  @description('Single-character environment code used where compact names are required.')
  code: EnvironmentCode

  @description('Azure policy-compliant Environment tag value.')
  tagName: EnvironmentTagName

  @description('Default diagnostic log retention in days.')
  logRetentionDays: int

  @description('Optional support email address for this environment.')
  supportEmail: string?
}

@description('Map of supported deployment environments to standard settings.')
@sealed()
@export()
type EnvironmentConfigMap = {
  dev: EnvironmentConfig
  test: EnvironmentConfig
  prod: EnvironmentConfig
  e2e: EnvironmentConfig
  poc: EnvironmentConfig
  dr: EnvironmentConfig
}

// Location Types

@description('Supported Azure region names.')
@export()
type LocationName =
  | 'eastus'
  | 'eastus2'
  | 'centralus'
  | 'northcentralus'
  | 'southcentralus'
  | 'westcentralus'
  | 'westus'
  | 'westus2'
  | 'westus3'

@description('Supported Azure region short codes used in resource names.')
@export()
type LocationShortCode =
  | 'eus'
  | 'eus2'
  | 'cus'
  | 'ncus'
  | 'scus'
  | 'wcus'
  | 'wus'
  | 'wus2'
  | 'wus3'

@description('Supported single-character Azure region codes used where compact names are required.')
@export()
type LocationCode =
  | 'e'
  | '2'
  | 'c'
  | 'n'
  | 's'
  | 'w'
  | 'u'
  | 'v'
  | 'z'

@description('Supported Azure region configuration.')
@sealed()
@export()
type LocationConfig = {
  @description('Azure region name.')
  name: LocationName

  @description('Short code used in resource names.')
  shortCode: LocationShortCode

  @description('Single-character code used where very short names are required.')
  code: LocationCode
}

@description('Map of supported Azure regions to standard settings.')
@sealed()
@export()
type LocationConfigMap = {
  eastus: LocationConfig
  eastus2: LocationConfig
  centralus: LocationConfig
  northcentralus: LocationConfig
  southcentralus: LocationConfig
  westcentralus: LocationConfig
  westus: LocationConfig
  westus2: LocationConfig
  westus3: LocationConfig
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

@description('Base Azure resource tags shared by all resources before environment-specific tags are added.')
@sealed()
@export()
type BaseTags = {
  @description('Azure policy-compliant division tag value.')
  Division: DivisionName

  @description('Business product or service associated with the resource.')
  Product: string
}

@description('Required standard Azure resource tags.')
@sealed()
@export()
type StandardTags = {
  @description('Azure policy-compliant deployment environment tag value.')
  Environment: EnvironmentTagName

  @description('Azure policy-compliant division tag value.')
  Division: DivisionName

  @description('Business product or service associated with the resource.')
  Product: string
}

// Shared Value Types

@description('Supported Azure resource lock kinds.')
@export()
type LockKind =
  | 'None'
  | 'CanNotDelete'
  | 'ReadOnly'

@description('Public network access setting.')
@export()
type PublicNetworkAccess =
  | 'Enabled'
  | 'Disabled'

@description('Subnet network policy state.')
@export()
type NetworkPolicyState =
  | 'Enabled'
  | 'Disabled'

@description('DNS resolution policy for private DNS virtual network links.')
@export()
type DnsResolutionPolicy =
  | 'NxDomainRedirect'
  | 'Default'

@description('Supported Microsoft Entra principal types for role assignments.')
@export()
type PrincipalType =
  | 'User'
  | 'Group'
  | 'ServicePrincipal'
  | 'ForeignGroup'

@description('Supported storage account SKU names.')
@export()
type StorageAccountSkuName =
  | 'Standard_LRS'
  | 'Standard_GRS'
  | 'Standard_RAGRS'
  | 'Standard_ZRS'
  | 'Standard_GZRS'
  | 'Standard_RAGZRS'
  | 'Premium_LRS'
  | 'Premium_ZRS'

@description('Supported managed disk SKU names.')
@export()
type ManagedDiskSkuName =
  | 'Standard_LRS'
  | 'StandardSSD_LRS'
  | 'Premium_LRS'
  | 'Premium_ZRS'

// Repository Configuration Types

@description('Shared repository and workload configuration values used across modules.')
@sealed()
@export()
type CommonConfig = {
  @description('Standard resource name prefix.')
  namePrefix: NamePrefix

  @description('Default Azure region for deployments.')
  location: LocationName

  @description('Technical workload name used in resource naming.')
  workloadName: WorkloadName

  @description('Repository name.')
  repositoryName: string

  @description('Business product or service associated with deployed resources.')
  product: string

  @description('Azure policy-compliant division tag value.')
  division: DivisionName

  @description('Default resource lock behavior.')
  lockKind: LockKind
}

// Default Configuration Types

@description('Default deployment feature flags used across modules.')
@sealed()
@export()
type DeploymentDefaults = {
  @description('Whether diagnostic settings are enabled by default.')
  enableDiagnosticSettings: bool

  @description('Whether private endpoints are enabled by default.')
  enablePrivateEndpoints: bool

  @description('Whether purge protection is enabled by default where supported.')
  enablePurgeProtection: bool

  @description('Whether soft delete is enabled by default where supported.')
  enableSoftDelete: bool
}

@description('Default Azure resource property values used across modules.')
@sealed()
@export()
type ResourceDefaults = {
  @description('Default public network access setting for supported resources.')
  publicNetworkAccess: PublicNetworkAccess
}

@description('Default diagnostic settings configuration.')
@sealed()
@export()
type DiagnosticDefaults = {
  @description('Default diagnostic metric categories.')
  metrics: string[]

  @description('Default diagnostic log categories.')
  logs: string[]
}

@description('Standard FSLogix profile container configuration.')
@sealed()
@export()
type FslogixConfig = {
  @description('Azure Files share name used for FSLogix profiles.')
  shareName: string
}

@description('Standard Azure Virtual Desktop RDP property presets.')
@sealed()
@export()
type AvdRdpPropertyPresets = {
  @description('Default secure RDP property baseline.')
  defaultSecure: string
}

// Naming Types

@description('Supported Azure resource type keys for standard naming.')
@export()
type ResourceTypeName =
  | 'appService'
  | 'appServicePlan'
  | 'applicationInsights'
  | 'automationAccount'
  | 'computeGallery'
  | 'containerRegistry'
  | 'desktopApplicationGroup'
  | 'functionApp'
  | 'galleryImageDefinition'
  | 'hostPool'
  | 'imageTemplate'
  | 'keyVault'
  | 'logAnalyticsWorkspace'
  | 'managedIdentity'
  | 'networkSecurityGroup'
  | 'privateDnsZone'
  | 'privateEndpoint'
  | 'resourceGroup'
  | 'scalingPlan'
  | 'sessionHost'
  | 'storageAccount'
  | 'subnet'
  | 'virtualNetwork'
  | 'virtualNetworkPeering'
  | 'vmImageDefinition'
  | 'workspace'

@description('Standard resource type keys used for naming.')
@sealed()
@export()
type ResourceTypeConfigMap = {
  appService: ResourceTypeName
  appServicePlan: ResourceTypeName
  applicationInsights: ResourceTypeName
  automationAccount: ResourceTypeName
  computeGallery: ResourceTypeName
  containerRegistry: ResourceTypeName
  desktopApplicationGroup: ResourceTypeName
  functionApp: ResourceTypeName
  galleryImageDefinition: ResourceTypeName
  hostPool: ResourceTypeName
  imageTemplate: ResourceTypeName
  keyVault: ResourceTypeName
  logAnalyticsWorkspace: ResourceTypeName
  managedIdentity: ResourceTypeName
  networkSecurityGroup: ResourceTypeName
  privateDnsZone: ResourceTypeName
  privateEndpoint: ResourceTypeName
  resourceGroup: ResourceTypeName
  scalingPlan: ResourceTypeName
  sessionHost: ResourceTypeName
  storageAccount: ResourceTypeName
  subnet: ResourceTypeName
  virtualNetwork: ResourceTypeName
  virtualNetworkPeering: ResourceTypeName
  vmImageDefinition: ResourceTypeName
  workspace: ResourceTypeName
}

@description('Resource type abbreviation map used by naming functions.')
@sealed()
@export()
type ResourceAbbreviationMap = {
  appService: string
  appServicePlan: string
  applicationInsights: string
  automationAccount: string
  computeGallery: string
  containerRegistry: string
  desktopApplicationGroup: string
  functionApp: string
  galleryImageDefinition: string
  hostPool: string
  imageTemplate: string
  keyVault: string
  logAnalyticsWorkspace: string
  managedIdentity: string
  networkSecurityGroup: string
  privateDnsZone: string
  privateEndpoint: string
  resourceGroup: string
  scalingPlan: string
  sessionHost: string
  storageAccount: string
  subnet: string
  virtualNetwork: string
  virtualNetworkPeering: string
  vmImageDefinition: string
  workspace: string
}

@description('Supported resource group purpose keys for standard naming.')
@export()
type ResourceGroupPurposeName =
  | 'serviceObjects'
  | 'storage'
  | 'network'
  | 'compute'
  | 'sharedResources'

@description('Standard resource group purpose keys used for naming.')
@sealed()
@export()
type ResourceGroupPurposeConfigMap = {
  serviceObjects: ResourceGroupPurposeName
  storage: ResourceGroupPurposeName
  network: ResourceGroupPurposeName
  compute: ResourceGroupPurposeName
  sharedResources: ResourceGroupPurposeName
}

@description('Resource group purpose name segment map used by naming functions.')
@sealed()
@export()
type ResourceGroupPurposeSegmentMap = {
  serviceObjects: string
  storage: string
  network: string
  compute: string
  sharedResources: string
}

@description('Supported general resource purpose keys for standard naming.')
@export()
type PurposeName =
  | 'serviceObjects'
  | 'storage'
  | 'network'
  | 'compute'
  | 'sharedResources'
  | 'sessionHosts'
  | 'privateEndpoints'
  | 'opsPooled'
  | 'opsPersonal'
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
  | 'avdToHub'
  | 'hubToAvd'

@description('Standard resource purpose keys used for naming.')
@sealed()
@export()
type ResourcePurposeConfigMap = {
  serviceObjects: PurposeName
  storage: PurposeName
  network: PurposeName
  compute: PurposeName
  sharedResources: PurposeName
  sessionHosts: PurposeName
  privateEndpoints: PurposeName
  opsPooled: PurposeName
  opsPersonal: PurposeName
  devPooled: PurposeName
  devPersonal: PurposeName
  opsPooledDesktop: PurposeName
  opsPersonalDesktop: PurposeName
  devPooledDesktop: PurposeName
  devPersonalDesktop: PurposeName
  primary: PurposeName
  diagnostics: PurposeName
  bootDiagnostics: PurposeName
  images: PurposeName
  logs: PurposeName
  fslogix: PurposeName
  avdToHub: PurposeName
  hubToAvd: PurposeName
}

@description('Resource purpose name segment map used by naming functions.')
@sealed()
@export()
type ResourcePurposeSegmentMap = {
  serviceObjects: string
  storage: string
  network: string
  compute: string
  sharedResources: string
  sessionHosts: string
  privateEndpoints: string
  opsPooled: string
  opsPersonal: string
  devPooled: string
  devPersonal: string
  opsPooledDesktop: string
  opsPersonalDesktop: string
  devPooledDesktop: string
  devPersonalDesktop: string
  primary: string
  diagnostics: string
  bootDiagnostics: string
  images: string
  logs: string
  fslogix: string
  avdToHub: string
  hubToAvd: string
}

// Existing Resource References

@description('Generic reference to an existing Azure resource.')
@sealed()
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
@sealed()
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
@sealed()
@export()
type SubnetConfig = {
  @description('Short purpose to include in the subnet name.')
  purpose: PurposeName?

  @description('Subnet address prefix.')
  addressPrefix: string

  @description('Enable or disable network policies for private endpoints.')
  privateEndpointNetworkPolicies: NetworkPolicyState?

  @description('Enable or disable network policies for private link services.')
  privateLinkServiceNetworkPolicies: NetworkPolicyState?
}

@description('Virtual network peering configuration.')
@sealed()
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
@sealed()
@export()
type AdditionalPrivateDnsVnetLinkConfig = {
  @description('Private DNS virtual network link name.')
  linkName: string

  @description('Whether auto-registration is enabled for the linked virtual network.')
  registrationEnabled: bool?

  @description('DNS resolution policy for the virtual network link.')
  resolutionPolicy: DnsResolutionPolicy?

  @description('Resource ID of the linked virtual network.')
  virtualNetworkId: string
}

@description('Private DNS zone configuration.')
@sealed()
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
@sealed()
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
@sealed()
@export()
type RoleAssignmentConfig = {
  @description('Microsoft Entra principal object ID.')
  principalId: string

  @description('Principal type.')
  principalType: PrincipalType

  @description('Role definition ID GUID.')
  roleDefinitionId: string
}

@description('Azure Virtual Desktop role definition IDs.')
@sealed()
@export()
type AvdRoleDefinitionIds = {
  @description('Desktop Virtualization User role definition ID.')
  desktopVirtualizationUser: string
}

@description('Azure Storage role definition IDs.')
@sealed()
@export()
type StorageRoleDefinitionIds = {
  @description('Storage File Data SMB Share Contributor role definition ID.')
  fileDataSmbShareContributor: string

  @description('Storage File Data SMB Share Elevated Contributor role definition ID.')
  fileDataSmbShareElevatedContributor: string
}

@description('Standard Azure built-in role definition IDs used across AVD deployments.')
@sealed()
@export()
type RoleDefinitionIds = {
  @description('Azure Virtual Desktop role definition IDs.')
  avd: AvdRoleDefinitionIds

  @description('Azure Storage role definition IDs.')
  storage: StorageRoleDefinitionIds
}

// Azure Virtual Desktop Value Types

@description('Supported Azure Virtual Desktop host pool types.')
@export()
type HostPoolType =
  | 'Pooled'
  | 'Personal'

@description('Supported Azure Virtual Desktop load balancing modes.')
@export()
type HostPoolLoadBalancerType =
  | 'BreadthFirst'
  | 'DepthFirst'
  | 'Persistent'

@description('Supported Azure Virtual Desktop preferred application group types.')
@export()
type PreferredAppGroupType =
  | 'Desktop'
  | 'RailApplications'
  | 'None'

@description('Supported session host role codes used in VM naming.')
@export()
type SessionHostRoleCode =
  | 'ops'
  | 'dev'
  | 'op'
  | 'dp'
  | 'dv'

// Azure Virtual Desktop Types

@description('Azure Virtual Desktop workspace configuration.')
@sealed()
@export()
type WorkspaceConfig = {
  @description('Short name used in the generated workspace name.')
  name: PurposeName

  @description('Friendly display name.')
  friendlyName: string?

  @description('Description.')
  description: string?

  @description('Public network access setting.')
  publicNetworkAccess: PublicNetworkAccess?
}

@description('Azure Virtual Desktop desktop application group configuration.')
@sealed()
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
@sealed()
@export()
type HostPoolConfig = {
  @description('Short name used in the generated host pool name.')
  name: PurposeName

  @description('Friendly display name.')
  friendlyName: string?

  @description('Description.')
  description: string?

  @description('Host pool type.')
  hostPoolType: HostPoolType

  @description('Load balancer type.')
  loadBalancerType: HostPoolLoadBalancerType

  @description('Preferred app group type.')
  preferredAppGroupType: PreferredAppGroupType

  @description('Maximum session limit.')
  maxSessionLimit: int?

  @description('Whether validation environment is enabled.')
  validationEnvironment: bool?

  @description('Start VM on connect.')
  startVMOnConnect: bool?

  @description('Custom RDP properties.')
  customRdpProperty: string?

  @description('Public network access setting.')
  publicNetworkAccess: PublicNetworkAccess?

  @description('Desktop application group for this host pool.')
  desktopApplicationGroup: DesktopApplicationGroupConfig
}

@description('Session host OS disk configuration.')
@sealed()
@export()
type SessionHostOsDiskConfig = {
  @description('Managed disk SKU for the session host OS disk.')
  storageAccountType: ManagedDiskSkuName

  @minValue(64)
  @description('Managed OS disk size in GB.')
  diskSizeGB: int
}

@description('Azure Virtual Desktop session host group configuration.')
@sealed()
@export()
type SessionHostGroupConfig = {
  @description('Purpose key used to identify the session host workload.')
  purpose: PurposeName

  @description('Windows computer name role code. Keep this short enough for the final name to stay within the 15-character NetBIOS limit.')
  sessionHostRoleCode: SessionHostRoleCode

  @minValue(0)
  @description('Number of session hosts to plan for this workload.')
  vmCount: int

  @description('Azure VM SKU for this workload.')
  vmSize: string

  @description('OS disk settings for this workload.')
  osDisk: SessionHostOsDiskConfig
}
