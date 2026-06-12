targetScope = 'subscription'

/*
AVD Deployment / Monitoring

Scope:
- Subscription

Deploys:
- Monitoring resource group
- Resource-group scoped monitoring resources
- Log Analytics workspace
- Data Collection Rules for AVD telemetry
- Subscription activity log diagnostic settings

Does not deploy:
- AVD host pools, workspaces, or application groups
- Session host virtual machines
- Azure Monitor Agent extensions
- Data Collection Rule associations to session hosts
- FSLogix storage accounts or file shares
*/

// Imports

import {
  EnvironmentName
  LocationName
} from '../../shared/types.bicep'

import {
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourceGroupPurpose
  baseTags
} from '../../shared/config.bicep'

import {
  resourceGroupNameWithLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment.')
param environment EnvironmentName

@description('Azure region where storage resources are deployed.')
param location LocationName

@description('Daily ingestion quota in GB for the Log Analytics workspace.')
param dailyQuotaGb string = '2'

// Variables

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Location configuration for the selected Azure region.
var locationConfig = locationConfigMap[location]

// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

var monitoringResourceGroupName = resourceGroupNameWithLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceGroupPurpose.monitoring,
  locationConfig.shortCode,
  environmentConfig.shortName
)

// Modules

module monitoringResourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: '${deployment().name}-${locationConfig.shortCode}-monitoring-rg'
  params: {
    name: monitoringResourceGroupName
    location: location
    tags: tags
    lock: {
      kind: commonConfig.lockKind
    }
  }
}

module resources './resources.bicep' = {
  name: '${deployment().name}-monitoring-resources'
  scope: resourceGroup(monitoringResourceGroupName)
  params: {
    location: location
    environment: environment
    dailyQuotaGb: dailyQuotaGb
  }
  dependsOn: [
    monitoringResourceGroup
  ]
}

module subscriptionActivityLogDiagnostics 'br/public:avm/res/insights/diagnostic-setting:0.1.4' = {
  name: '${deployment().name}-activity-log-diag'
  scope: subscription()
  params: {
    name: 'diag-activity-log'
    workspaceResourceId: resources.outputs.logAnalyticsWorkspaceResourceId
  }
}

// Outputs

// Outputs

@description('Resource ID of the Log Analytics workspace used for AVD monitoring and diagnostics.')
output logAnalyticsWorkspaceResourceId string = resources.outputs.logAnalyticsWorkspaceResourceId

@description('Name of the Log Analytics workspace used for AVD monitoring and diagnostics.')
output logAnalyticsWorkspaceName string = resources.outputs.logAnalyticsWorkspaceName

@description('Resource ID of the Data Collection Rule used by AVD session hosts.')
output avdSessionHostDataCollectionRuleResourceId string = resources.outputs.avdSessionHostDataCollectionRuleResourceId

@description('Name of the Data Collection Rule used by AVD session hosts.')
output avdSessionHostDataCollectionRuleName string = resources.outputs.avdSessionHostDataCollectionRuleName
