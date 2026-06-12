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
param dailyQuotaGb int = 2

@description('Deploy alert action group for AVD monitoring alerts.')
param deployAlertActionGroup bool = true

@description('Resource IDs of existing action groups invoked when alert rules fire.')
param actionGroupResourceIds string[] = []

@description('Email receivers for AVD monitoring alerts.')
param alertEmailReceivers array = []

@description('Deploy AVD scheduled query alert rules.')
param deployScheduledQueryAlerts bool = true

@description('Enable AVD scheduled query alert rules after data ingestion has been validated.')
param scheduledQueryAlertsEnabled bool = false

@description('Trigger an alert when we are at 75% of the daily quota. Warning, this rounds down, so 75% of 2GB = 1 GB')
param dailyQuotaThresholdGb int = dailyQuotaGb * 75 / 100

@description('Number of AVD errors allowed in the evaluation window before alerting.')
param avdErrorsAlertThreshold int = 0

@description('Number of failed AVD connections allowed in the evaluation window before alerting.')
param failedConnectionsAlertThreshold int = 0

@description('Number of FSLogix errors allowed in the evaluation window before alerting.')
param fslogixErrorsAlertThreshold int = 0

@description('Minimum free disk percentage before low disk alerts fire.')
param lowDiskFreePercentThreshold int = 15

@description('Average CPU percentage before high CPU alerts fire.')
param highCpuPercentThreshold int = 85

@description('Average available memory in MB before low memory alerts fire.')
param lowMemoryAvailableMbThreshold int = 2048

@description('Severity for AVD platform/control-plane alerts.')
param avdPlatformAlertSeverity int = 2

@description('Severity for session host capacity alerts.')
param sessionHostCapacityAlertSeverity int = 3

@description('Severity for FSLogix profile alerts.')
param fslogixAlertSeverity int = 2

@description('Default evaluation frequency for scheduled query alerts.')
param scheduledQueryAlertEvaluationFrequency string = 'PT15M'

@description('Default short query window for AVD alert rules.')
param scheduledQueryShortWindowSize string = 'PT15M'

@description('Default long query window for capacity alert rules.')
param scheduledQueryLongWindowSize string = 'PT30M'

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
  name:  'mon-res'
  scope: resourceGroup(monitoringResourceGroupName)
  params: {
    location: location
    environment: environment
    dailyQuotaGb: dailyQuotaGb
    deployAlertActionGroup: deployAlertActionGroup
    alertEmailReceivers: alertEmailReceivers
    deployScheduledQueryAlerts: deployScheduledQueryAlerts
    scheduledQueryAlertsEnabled: scheduledQueryAlertsEnabled
    dailyQuotaThresholdGb: dailyQuotaThresholdGb
    actionGroupResourceIds: actionGroupResourceIds
    avdErrorsAlertThreshold: avdErrorsAlertThreshold
    failedConnectionsAlertThreshold: failedConnectionsAlertThreshold
    fslogixErrorsAlertThreshold: fslogixErrorsAlertThreshold
    lowDiskFreePercentThreshold: lowDiskFreePercentThreshold
    highCpuPercentThreshold: highCpuPercentThreshold
    lowMemoryAvailableMbThreshold: lowMemoryAvailableMbThreshold
    avdPlatformAlertSeverity: avdPlatformAlertSeverity
    sessionHostCapacityAlertSeverity: sessionHostCapacityAlertSeverity
    fslogixAlertSeverity: fslogixAlertSeverity
    scheduledQueryAlertEvaluationFrequency: scheduledQueryAlertEvaluationFrequency
    scheduledQueryShortWindowSize: scheduledQueryShortWindowSize
    scheduledQueryLongWindowSize: scheduledQueryLongWindowSize
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

@description('Resource ID of the Log Analytics workspace used for AVD monitoring and diagnostics.')
output logAnalyticsWorkspaceResourceId string = resources.outputs.logAnalyticsWorkspaceResourceId

@description('Name of the Log Analytics workspace used for AVD monitoring and diagnostics.')
output logAnalyticsWorkspaceName string = resources.outputs.logAnalyticsWorkspaceName

@description('Resource ID of the Data Collection Rule used by AVD session hosts.')
output avdSessionHostDataCollectionRuleResourceId string = resources.outputs.avdSessionHostDataCollectionRuleResourceId

@description('Name of the Data Collection Rule used by AVD session hosts.')
output avdSessionHostDataCollectionRuleName string = resources.outputs.avdSessionHostDataCollectionRuleName
