metadata name = 'Naming Helpers'
metadata description = 'Reusable naming functions for Azure Virtual Desktop IaC deployments.'

import {
  resourceAbbreviationMap
} from './config.bicep'

@description('Builds a standard resource group name.')
@export()
func resourceGroupName(
  namePrefix string,
  workloadName string,
  resourceGroupType string,
  environmentShortName string
) string => toLower('${namePrefix}-${workloadName}-${resourceAbbreviationMap.resourceGroup}-${resourceGroupType}-${environmentShortName}')

@description('Builds a standard Azure resource name using the pattern: abbreviation-prefix-workload-purpose-environment.')
@export()
func resourceName(
  resourceType string,
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('${resourceAbbreviationMap[resourceType]}-${namePrefix}-${workloadName}-${purpose}-${environmentShortName}')

@description('Builds a standard Azure resource name using a custom abbreviation.')
@export()
func resourceNameWithAbbreviation(
  abbreviation string,
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('${abbreviation}-${namePrefix}-${workloadName}-${purpose}-${environmentShortName}')

@description('Builds a compact name for resources with stricter naming limits.')
@export()
func compactName(
  abbreviation string,
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('${abbreviation}${namePrefix}${workloadName}${purpose}${environmentShortName}')

@description('Builds a storage account name. Storage account names must be lowercase alphanumeric and 3-24 characters.')
@export()
func storageAccountName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => take(toLower(replace('st${namePrefix}${workloadName}${purpose}${environmentShortName}', '-', '')), 24)

@description('Builds a Key Vault name. Key Vault names must be 3-24 characters and may contain only alphanumeric characters and hyphens.')
@export()
func keyVaultName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => take(toLower('kv-${namePrefix}-${workloadName}-${purpose}-${environmentShortName}'), 24)

@description('Builds a Log Analytics workspace name.')
@export()
func logAnalyticsWorkspaceName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('log-${namePrefix}-${workloadName}-${purpose}-${environmentShortName}')

@description('Builds an Azure Compute Gallery name. Gallery names may contain letters, numbers, dots, and underscores. Hyphens are avoided.')
@export()
func computeGalleryName(
  namePrefix string,
  workloadName string,
  purpose string
) string => toLower('gal_${namePrefix}_${workloadName}_${purpose}')

@description('Builds an AVD host pool name.')
@export()
func hostPoolName(
  namePrefix string,
  workloadName string,
  poolName string,
  environmentShortName string
) string => toLower('vdpool-${namePrefix}-${workloadName}-${poolName}-${environmentShortName}')

@description('Builds an AVD application group name.')
@export()
func applicationGroupName(
  namePrefix string,
  workloadName string,
  appGroupName string,
  environmentShortName string
) string => toLower('vdag-${namePrefix}-${workloadName}-${appGroupName}-${environmentShortName}')

@description('Builds an AVD workspace name.')
@export()
func workspaceName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('vdws-${namePrefix}-${workloadName}-${purpose}-${environmentShortName}')

@description('Builds an AVD scaling plan name.')
@export()
func scalingPlanName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('vdscaling-${namePrefix}-${workloadName}-${purpose}-${environmentShortName}')

@description('Builds a private endpoint name.')
@export()
func privateEndpointName(
  namePrefix string,
  workloadName string,
  targetName string,
  environmentShortName string
) string => toLower('pep-${namePrefix}-${workloadName}-${targetName}-${environmentShortName}')

@description('Builds a managed identity name.')
@export()
func managedIdentityName(
  namePrefix string,
  workloadName string,
  purpose string,
  environmentShortName string
) string => toLower('id-${namePrefix}-${workloadName}-${purpose}-${environmentShortName}')
