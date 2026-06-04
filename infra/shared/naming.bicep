metadata name = 'Naming Helpers'
metadata description = 'Reusable naming functions for Azure Virtual Desktop IaC deployments.'

// Imports

import {
  resourceAbbreviationMap
  resourceGroupPurposeMap
  resourcePurpose
  resourcePurposeMap
} from './config.bicep'

import {
  EnvironmentCode
  EnvironmentShortName
  LocationCode
  LocationShortCode
  NamePrefix
  PurposeName
  ResourceGroupPurposeName
  ResourceTypeName
  SessionHostRoleCode
  WorkloadName
} from './types.bicep'

// Standard Resource Names

@description('Builds a standard Azure resource name using the pattern: prefix-workload-abbreviation-environment.')
@export()
func resourceName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${environmentShortName}')

@description('Builds a standard Azure resource name using the pattern: prefix-workload-abbreviation-location-environment.')
@export()
func resourceNameWithLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${locationShortCode}-${environmentShortName}')

@description('Builds a standard Azure resource name using the pattern: prefix-workload-abbreviation-purpose-environment.')
@export()
func resourceNameWithPurpose(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  purpose PurposeName,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${resourcePurposeMap[purpose]}-${environmentShortName}')

@description('Builds a location-aware Azure resource name using the pattern: prefix-workload-abbreviation-purpose-location-environment.')
@export()
func resourceNameWithPurposeAndLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  purpose PurposeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${resourcePurposeMap[purpose]}-${locationShortCode}-${environmentShortName}')

@description('Builds a standard resource group name using the pattern: prefix-workload-rg-purpose-environment.')
@export()
func resourceGroupName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose ResourceGroupPurposeName,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.resourceGroup}-${resourceGroupPurposeMap[purpose]}-${environmentShortName}')

@description('Builds a location-aware resource group name using the pattern: prefix-workload-rg-purpose-location-environment.')
@export()
func resourceGroupNameWithLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose ResourceGroupPurposeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.resourceGroup}-${resourceGroupPurposeMap[purpose]}-${locationShortCode}-${environmentShortName}')

// Compact Resource Names

@description('Builds a compact resource name using the pattern: prefixworkloadabbreviationenvironment.')
@export()
func compactName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${environmentShortName}')

@description('Builds a location-aware compact resource name using the pattern: prefixworkloadabbreviationlocationenvironment.')
@export()
func compactNameWithLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${locationShortCode}${environmentShortName}')

@description('Builds a compact resource name with purpose using the pattern: prefixworkloadabbreviationpurposeenvironment.')
@export()
func compactNameWithPurpose(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  purpose PurposeName,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${replace(resourcePurposeMap[purpose], '-', '')}${environmentShortName}')

@description('Builds a location-aware compact resource name with purpose using the pattern: prefixworkloadabbreviationpurposelocationenvironment.')
@export()
func compactNameWithPurposeAndLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  resourceType ResourceTypeName,
  purpose PurposeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${replace(resourcePurposeMap[purpose], '-', '')}${locationShortCode}${environmentShortName}')

// Storage Account Names

/*
Storage account names must be globally unique and follow strict Azure naming rules.

Rules:
- 3 to 24 characters
- Lowercase letters and numbers only
- Globally unique

Pattern:
- Build a compact deterministic base.
- Truncate the base to leave room for a unique suffix.
- Append a stable unique suffix generated by the caller or helper.

The unique suffix should be generated from stable deployment inputs, not random values.
*/

@description('Builds a deterministic globally unique storage account name from a compact base and precomputed suffix.')
@export()
func storageAccountName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  environmentShortName EnvironmentShortName,
  uniqueSuffix string
) string => '${take(toLower(replace('${namePrefix}${workloadName}${resourceAbbreviationMap.storageAccount}${replace(resourcePurposeMap[purpose], '-', '')}${environmentShortName}', '-', '')), 11)}${take(uniqueSuffix, 13)}'

@description('Builds a deterministic globally unique location-aware storage account name from a compact base and precomputed suffix.')
@export()
func storageAccountNameWithLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName,
  uniqueSuffix string
) string => '${take(toLower(replace('${namePrefix}${workloadName}${resourceAbbreviationMap.storageAccount}${replace(resourcePurposeMap[purpose], '-', '')}${locationShortCode}${environmentShortName}', '-', '')), 11)}${take(uniqueSuffix, 13)}'

@description('Builds a deterministic unique suffix for storage account names.')
@export()
func storageAccountUniqueSuffix(
  storageResourceGroupId string,
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  environmentShortName EnvironmentShortName
) string => uniqueString(
  subscription().id,
  storageResourceGroupId,
  namePrefix,
  workloadName,
  purpose,
  environmentShortName
)

@description('Builds a deterministic location-aware unique suffix for storage account names.')
@export()
func storageAccountUniqueSuffixWithLocation(
  storageResourceGroupId string,
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName
) string => uniqueString(
  subscription().id,
  storageResourceGroupId,
  namePrefix,
  workloadName,
  purpose,
  locationShortCode,
  environmentShortName
)

@description('Builds a deterministic FSLogix storage account name.')
@export()
func fslogixStorageAccountName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  environmentShortName EnvironmentShortName,
  storageResourceGroupId string
) string => storageAccountName(
  namePrefix,
  workloadName,
  resourcePurpose.fslogix,
  environmentShortName,
  storageAccountUniqueSuffix(
    storageResourceGroupId,
    namePrefix,
    workloadName,
    resourcePurpose.fslogix,
    environmentShortName
  )
)

@description('Builds a deterministic location-aware FSLogix storage account name.')
@export()
func fslogixStorageAccountNameWithLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName,
  storageResourceGroupId string
) string => storageAccountNameWithLocation(
  namePrefix,
  workloadName,
  resourcePurpose.fslogix,
  locationShortCode,
  environmentShortName,
  storageAccountUniqueSuffixWithLocation(
    storageResourceGroupId,
    namePrefix,
    workloadName,
    resourcePurpose.fslogix,
    locationShortCode,
    environmentShortName
  )
)

// Network Resource Names

@description('Builds a directional virtual network peering name using the pattern: prefix-workload-peer-purpose-source-to-target.')
@export()
func virtualNetworkPeeringName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  sourceName string,
  targetName string
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.virtualNetworkPeering}-${resourcePurposeMap[purpose]}-${sourceName}-to-${targetName}')

// Service-Specific Resource Names

@description('Builds a Key Vault name. Key Vault names must be 3-24 characters and may contain only alphanumeric characters and hyphens.')
@export()
func keyVaultName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  environmentShortName EnvironmentShortName
) string => take(toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.keyVault}-${resourcePurposeMap[purpose]}-${environmentShortName}'), 24)

@description('Builds a location-aware Key Vault name. Key Vault names must be 3-24 characters and may contain only alphanumeric characters and hyphens.')
@export()
func keyVaultNameWithLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  locationShortCode LocationShortCode,
  environmentShortName EnvironmentShortName
) string => take(toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.keyVault}-${resourcePurposeMap[purpose]}-${locationShortCode}-${environmentShortName}'), 24)

@description('Builds an Azure Compute Gallery name. Gallery names may contain letters, numbers, dots, and underscores. Hyphens are avoided.')
@export()
func computeGalleryName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName
) string => toLower('${namePrefix}_${workloadName}_${resourceAbbreviationMap.computeGallery}_${replace(resourcePurposeMap[purpose], '-', '_')}')

@description('Builds a location-aware Azure Compute Gallery name. Gallery names may contain letters, numbers, dots, and underscores. Hyphens are avoided.')
@export()
func computeGalleryNameWithLocation(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  purpose PurposeName,
  locationShortCode LocationShortCode
) string => toLower('${namePrefix}_${workloadName}_${resourceAbbreviationMap.computeGallery}_${replace(resourcePurposeMap[purpose], '-', '_')}_${locationShortCode}')

// Session Host Names

@description('Builds a session host computer name using the pattern: prefix + workload + role code + environment code + location code + sequence number.')
@export()
func sessionHostName(
  namePrefix NamePrefix,
  workloadName WorkloadName,
  roleCode SessionHostRoleCode,
  environmentCode EnvironmentCode,
  locationCode LocationCode,
  sequenceNumber int
) string => toLower('${namePrefix}${workloadName}${roleCode}${environmentCode}${locationCode}${padLeft(string(sequenceNumber), 3, '0')}')
