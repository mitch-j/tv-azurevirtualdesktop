metadata name = 'Naming Helpers'
metadata description = 'Reusable naming functions for Azure Virtual Desktop IaC deployments.'

import {
  resourceAbbreviationMap
} from './config.bicep'

import {
  ResourceTypeName
} from './types.bicep'

@description('Builds a standard resource group name.')
@export()
func resourceGroupName(
  namePrefix string,
  workloadName string,
  resourceGroupType string,
  environmentShortName string
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.resourceGroup}-${resourceGroupType}-${environmentShortName}')

@description('Builds a standard Azure resource name using the pattern: prefix-workload-abbreviation-environment.')
@export()
func resourceName(
  resourceType ResourceTypeName,
  namePrefix string,
  workloadName string,
  environmentShortName string
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${environmentShortName}')

@description('Builds a standard Azure resource name using the pattern: prefix-workload-abbreviation-purpose-environment.')
@export()
func resourceNameWithPurpose(
  resourceType ResourceTypeName,
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap[resourceType]}-${purpose}-${environmentShortName}')

@description('Builds a compact name for resources with stricter naming limits.')
@export()
func compactName(
  abbreviation string,
  namePrefix string,
  workloadName string,
  environmentShortName string
) string => toLower('${namePrefix}${workloadName}${abbreviation}${environmentShortName}')

@description('Builds a compact name for resources with stricter naming limits.')
@export()
func compactNameWithPurpose(
  abbreviation string,
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('${namePrefix}${workloadName}${abbreviation}${purpose}${environmentShortName}')

@description('Builds a storage account name. Storage account names must be lowercase alphanumeric and 3-24 characters.')
@export()
func storageAccountName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => take(toLower(replace('${namePrefix}${workloadName}st${purpose}${environmentShortName}', '-', '')), 24)

@description('Builds a Key Vault name. Key Vault names must be 3-24 characters and may contain only alphanumeric characters and hyphens.')
@export()
func keyVaultName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => take(toLower('${namePrefix}-${workloadName}-kv-${purpose}-${environmentShortName}'), 24)

@description('Builds an Azure Compute Gallery name. Gallery names may contain letters, numbers, dots, and underscores. Hyphens are avoided.')
@export()
func computeGalleryName(
  namePrefix string,
  workloadName string,
  purpose string
) string => toLower('${namePrefix}_${workloadName}_gal_${purpose}')
