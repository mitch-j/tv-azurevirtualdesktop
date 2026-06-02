metadata name = 'Naming Helpers'
metadata description = 'Reusable naming functions for Azure Virtual Desktop IaC deployments.'

import {
  resourceAbbreviationMap
  resourcePurposeMap
} from './config.bicep'

import {
  ResourceTypeName
  PurposeName
} from './types.bicep'

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

@description('Builds a compact name for resources with stricter naming limits.')
@export()
func compactName(
  namePrefix string,
  workloadName string,
  resourceType ResourceTypeName,
  environmentShortName string
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${environmentShortName}')

@description('Builds a compact name for resources with stricter naming limits.')
@export()
func compactNameWithPurpose(
  namePrefix string,
  workloadName string,
  resourceType ResourceTypeName,
  purpose PurposeName,
  environmentShortName string
) string => toLower('${namePrefix}${workloadName}${resourceAbbreviationMap[resourceType]}${replace(resourcePurposeMap[purpose], '-', '')}${environmentShortName}')

/* Storage Account Naming function usage example:

First generate a deterministic unique suffix for the storage account using the uniqueString function with stable inputs:
var storageUniqueSuffix = uniqueString(
  subscription().id,
  resourceGroup().id,
  commonConfig.namePrefix,
  commonConfig.workloadName,
  purpose.diagnostics,
  environmentConfigMap[environment].shortName
)

Then build the storage account name using the helper function with the precomputed suffix:
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
