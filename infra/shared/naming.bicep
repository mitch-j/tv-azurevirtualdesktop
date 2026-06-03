metadata name = 'Naming Helpers'
metadata description = 'Reusable naming functions for Azure Virtual Desktop IaC deployments.'

// Imports

import {
  resourceAbbreviationMap
  resourcePurposeMap
  resourcePurpose
} from './config.bicep'

import {
  PurposeName
  ResourceTypeName
} from './types.bicep'

// Standard Resource Names

@description('Builds a standard Azure resource name using the pattern: prefix-workload-abbreviation-environment.')
@export()
func resourceName(
  namePrefix string,
  workloadName string,
  resourceType ResourceTypeName,
  environmentShortName string
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${environmentShortName}')

@description('Builds a standard Azure resource name using the pattern: prefix-workload-abbreviation-purpose-environment.')
@export()
func resourceNameWithPurpose(
  namePrefix string,
  workloadName string,
  resourceType ResourceTypeName,
  purpose PurposeName,
  environmentShortName string
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${resourcePurposeMap[purpose]}-${environmentShortName}')

@description('Builds a standard resource group name using the pattern: prefix-workload-rg-purpose-environment.')
@export()
func resourceGroupName(
  namePrefix string,
  workloadName string,
  purpose PurposeName,
  environmentShortName string
) string => resourceNameWithPurpose(
  namePrefix,
  workloadName,
  'resourceGroup',
  purpose,
  environmentShortName
)

// Compact Resource Names

@description('Builds a compact resource name using the pattern: prefixworkloadabbreviationenvironment.')
@export()
func compactName(
  namePrefix string,
  workloadName string,
  resourceType ResourceTypeName,
  environmentShortName string
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${environmentShortName}')

@description('Builds a compact resource name with purpose using the pattern: prefixworkloadabbreviationpurposeenvironment.')
@export()
func compactNameWithPurpose(
  namePrefix string,
  workloadName string,
  resourceType ResourceTypeName,
  purpose PurposeName,
  environmentShortName string
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${replace(resourcePurposeMap[purpose], '-', '')}${environmentShortName}')

// Storage Account Names

/*
Storage account names must be globally unique and meet strict naming limits.

Recommended pattern:
1. Generate a deterministic suffix with stable inputs.
2. Pass the suffix into storageAccountName().
3. Let the helper build a compact, lower-case storage account name.

Example:

var storageUniqueSuffix = uniqueString(
  subscription().id,
  resourceGroup().id,
  commonConfig.namePrefix,
  commonConfig.workloadName,
  purpose.diagnostics,
  environmentConfigMap[environment].shortName
)

var diagnosticsStorageAccountName = storageAccountName(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  purpose.diagnostics,
  environmentConfigMap[environment].shortName,
  storageUniqueSuffix
)
*/

@description('Builds a deterministic globally unique storage account name from a compact base and precomputed suffix.')
@export()
func storageAccountName(
  namePrefix string,
  workloadName string,
  purpose PurposeName,
  environmentShortName string,
  uniqueSuffix string
) string => '${take(toLower(replace('${namePrefix}${workloadName}${resourceAbbreviationMap.storageAccount}${replace(resourcePurposeMap[purpose], '-', '')}${environmentShortName}', '-', '')), 11)}${uniqueSuffix}'

@description('Builds a directional virtual network peering name.')
@export()
func virtualNetworkPeeringName(
  namePrefix string,
  workloadName string,
  sourceName string,
  targetName string
) string => '${toLower(namePrefix)}-${toLower(workloadName)}-${resourceAbbreviationMap.virtualNetworkPeering}-${toLower(sourceName)}-to-${toLower(targetName)}'

// This is a helper for FSLogix naming.
@description('Builds a deterministic name for the FSLogix storage account')
@export()
func fslogixStorageAccountName(
  namePrefix string,
  workloadName string,
  environmentShortName string,
  storageResourceGroupId string
) string => storageAccountName(
  namePrefix,
  workloadName,
  resourcePurpose.fslogix,
  environmentShortName,
  uniqueString(
    subscription().id,
    storageResourceGroupId,
    namePrefix,
    workloadName,
    resourcePurpose.fslogix,
    environmentShortName
  )
)

// Service-Specific Resource Names

@description('Builds a Key Vault name. Key Vault names must be 3-24 characters and may contain only alphanumeric characters and hyphens.')
@export()
func keyVaultName(
  namePrefix string,
  workloadName string,
  purpose PurposeName,
  environmentShortName string
) string => take(toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.keyVault}-${resourcePurposeMap[purpose]}-${environmentShortName}'), 24)

@description('Builds an Azure Compute Gallery name. Gallery names may contain letters, numbers, dots, and underscores. Hyphens are avoided.')
@export()
func computeGalleryName(
  namePrefix string,
  workloadName string,
  purpose PurposeName
) string => toLower('${namePrefix}_${workloadName}_${resourceAbbreviationMap.computeGallery}_${replace(resourcePurposeMap[purpose], '-', '_')}')
