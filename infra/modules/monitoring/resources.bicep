targetScope = 'resourceGroup'

/*
AVD Deployment / Monitoring Resources

Scope:
- Resource group

Deploys:
- Log Analytics workspace
- Data Collection Rules for AVD session host guest telemetry
- Monitoring outputs consumed or reconstructed by downstream modules

Does not deploy:
- Monitoring resource group
- Subscription activity log diagnostic settings
- AVD host pools, workspaces, or application groups
- Session host virtual machines
- Azure Monitor Agent extensions
- Data Collection Rule associations to session hosts
*/

// Imports

import {
  EnvironmentName
  LocationName
} from '../../shared/types.bicep'

import {
  baseTags
  commonConfig
  environmentConfigMap
  locationConfigMap
  resourcePurpose
  resourceType
} from '../../shared/config.bicep'

import {
  resourceNameWithPurposeAndLocation
} from '../../shared/naming.bicep'

// Parameters

@description('Deployment environment.')
param environment EnvironmentName

@description('Azure region where resources are deployed.')
param location LocationName

@description('Daily ingestion quota in GB for the Log Analytics workspace.')
param dailyQuotaGb int = 2

@description('Deploy alert action group for AVD monitoring alerts.')
param deployAlertActionGroup bool = true

@description('Email receivers for AVD monitoring alerts.')
param alertEmailReceivers array = []

@description('Deploy AVD scheduled query alerts.')
param deployScheduledQueryAlerts bool = true

@description('Enable AVD scheduled query alert rules after data ingestion has been validated.')
param scheduledQueryAlertsEnabled bool = false

@description('Trigger an alert when we are at 75% of the daily quota. Warning, this rounds down, so 75% of 2GB = 1 GB')
param dailyQuotaThresholdGb int = dailyQuotaGb * 75 / 100

@description('Resource IDs of existing action groups invoked when alert rules fire.')
param actionGroupResourceIds string[] = []

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

var scheduledQueryAlerts = [
  {
    name: 'avd-errors'
    displayName: 'AVD errors detected'
    description: 'Detects recent Azure Virtual Desktop errors in WVDErrors.'
    severity: avdPlatformAlertSeverity
    evaluationFrequency: scheduledQueryAlertEvaluationFrequency
    windowSize: scheduledQueryShortWindowSize
    queryTimeRange: scheduledQueryShortWindowSize
    operator: 'GreaterThan'
    threshold: avdErrorsAlertThreshold
    timeAggregation: 'Total'
    query: '''
WVDErrors
| where TimeGenerated > ago(15m)
| summarize AggregatedValue = count()
'''
  }
  {
    name: 'avd-failed-connections'
    displayName: 'AVD failed connections detected'
    description: 'Detects failed or errored AVD connection attempts. Adjust threshold if too noisy.'
    severity: avdPlatformAlertSeverity
    evaluationFrequency: scheduledQueryAlertEvaluationFrequency
    windowSize: scheduledQueryShortWindowSize
    queryTimeRange: scheduledQueryShortWindowSize
    operator: 'GreaterThan'
    threshold: failedConnectionsAlertThreshold
    timeAggregation: 'Total'
    query: '''
WVDConnections
| where TimeGenerated > ago(15m)
| where State in~ ("Failed", "Error")
| summarize AggregatedValue = count()
'''
  }
  {
    name: 'avd-fslogix-errors'
    displayName: 'AVD FSLogix errors detected'
    description: 'Detects FSLogix warning and error events from session hosts. Adjust level to error only if noisy.'
    severity: fslogixAlertSeverity
    evaluationFrequency: scheduledQueryAlertEvaluationFrequency
    windowSize: scheduledQueryShortWindowSize
    queryTimeRange: scheduledQueryShortWindowSize
    operator: 'GreaterThan'
    threshold: fslogixErrorsAlertThreshold
    timeAggregation: 'Total'
    query: '''
Event
| where TimeGenerated > ago(15m)
| where EventLog contains "FSLogix" or Source contains "FSLogix"
| where EventLevelName in ("Error", "Warning")
| summarize AggregatedValue = count()
'''
  }
  {
    name: 'avd-low-disk'
    displayName: 'AVD session host low disk space'
    description: 'Detects session host disks with less than the configured free-space percentage.'
    severity: sessionHostCapacityAlertSeverity
    evaluationFrequency: scheduledQueryAlertEvaluationFrequency
    windowSize: scheduledQueryShortWindowSize
    queryTimeRange: scheduledQueryShortWindowSize
    operator: 'GreaterThan'
    threshold: 0
    timeAggregation: 'Total'
    query: format('''
Perf
| where TimeGenerated > ago(15m)
| where ObjectName == "LogicalDisk"
| where CounterName == "% Free Space"
| where InstanceName matches regex @"^[A-Z]:$"
| summarize MinFreePercent = min(CounterValue) by Computer, InstanceName
| where MinFreePercent < {0}
| summarize AggregatedValue = count()
''', lowDiskFreePercentThreshold)
  }
  {
    name: 'avd-high-cpu'
    displayName: 'AVD session host high CPU'
    description: 'Detects session hosts averaging more than 90 percent CPU over 30 minutes.'
    severity: sessionHostCapacityAlertSeverity
    evaluationFrequency: scheduledQueryAlertEvaluationFrequency
    windowSize: scheduledQueryLongWindowSize
    queryTimeRange: scheduledQueryLongWindowSize
    operator: 'GreaterThan'
    threshold: 0
    timeAggregation: 'Total'
    query: format('''
Perf
| where TimeGenerated > ago(30m)
| where ObjectName == "Processor"
| where CounterName == "% Processor Time"
| summarize AvgCpu = avg(CounterValue) by Computer
| where AvgCpu > {0}
| summarize AggregatedValue = count()
''', highCpuPercentThreshold)
  }
  {
    name: 'avd-low-memory'
    displayName: 'AVD session host low memory'
    description: 'Detects session hosts with less than 2048 MB available memory over 30 minutes.'
    severity: sessionHostCapacityAlertSeverity
    evaluationFrequency: scheduledQueryAlertEvaluationFrequency
    windowSize: scheduledQueryLongWindowSize
    queryTimeRange: scheduledQueryLongWindowSize
    operator: 'GreaterThan'
    threshold: 0
    timeAggregation: 'Total'
    query: format('''
Perf
| where TimeGenerated > ago(30m)
| where ObjectName == "Memory"
| where CounterName == "Available MBytes"
| summarize AvgAvailableMB = avg(CounterValue) by Computer
| where AvgAvailableMB < {0}
| summarize AggregatedValue = count()
''', lowMemoryAvailableMbThreshold)  }
  {
    name: 'avd-log-ingestion'
    displayName: 'AVD Log Analytics ingestion nearing quota'
    description: 'Detects when Log Analytics ingestion approaches the configured daily quota.'
    severity: avdPlatformAlertSeverity
    evaluationFrequency: 'PT1H'
    windowSize: 'PT24H'
    queryTimeRange: 'PT24H'
    operator: 'GreaterThan'
    threshold: dailyQuotaThresholdGb
    timeAggregation: 'Total'
    query: '''
Usage
| where TimeGenerated > ago(24h)
| summarize AggregatedValue = sum(Quantity) / 1024
'''
  }
]

// Environment-specific naming and tagging values.
var environmentConfig = environmentConfigMap[environment]

// Location configuration for the selected Azure region.
var locationConfig = locationConfigMap[location]

// Tags to add to resources deployed by this module.
var tags = union(baseTags, {
  Environment: environmentConfig.tagName
})

var logAnalyticsWorkspaceName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.logAnalyticsWorkspace,
  resourcePurpose.logs,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var avdSessionHostDcrName = resourceNameWithPurposeAndLocation(
  commonConfig.namePrefix,
  commonConfig.workloadName,
  resourceType.dataCollectionRule,
  resourcePurpose.sessionHosts,
  locationConfig.shortCode,
  environmentConfig.shortName
)

var createdActionGroupResourceIds = deployAlertActionGroup
  ? [
      avdActionGroup!.outputs.resourceId
    ]
  : []

var effectiveActionGroupResourceIds = union(
  actionGroupResourceIds,
  createdActionGroupResourceIds
)

// Modules

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.15.1' = {
  name: '${deployment().name}-log'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags

    dailyQuotaGb: string(dailyQuotaGb)

    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }

    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module avdSessionHostDcr 'br/public:avm/res/insights/data-collection-rule:0.11.0' = {
  name: 'avd-dcr-avdsh'
  params: {
    name: avdSessionHostDcrName
    location: location
    tags: tags
    enableTelemetry: false
    dataCollectionRuleProperties: {
      kind: 'Windows'
      description: 'Collect Windows event logs and performance counters from AVD session hosts.'
      dataSources: {
        windowsEventLogs: [
          {
            name: 'windows-event-logs'
            streams: [
              'Microsoft-Event'
            ]
            xPathQueries: [
              'Application!*[System[(Level=1 or Level=2 or Level=3)]]'
              'System!*[System[(Level=1 or Level=2 or Level=3)]]'
              'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational!*'
              'Microsoft-Windows-TerminalServices-RemoteConnectionManager/Operational!*'
              'Microsoft-Windows-FSLogix-Apps/Operational!*'
            ]
          }
        ]
        performanceCounters: [
          {
            name: 'avd-performance-counters'
            streams: [
              'Microsoft-Perf'
            ]
            samplingFrequencyInSeconds: 60
            counterSpecifiers: [
              '\\Processor(_Total)\\% Processor Time'
              '\\Memory\\Available MBytes'
              '\\Memory\\Committed Bytes'
              '\\LogicalDisk(_Total)\\% Free Space'
              '\\LogicalDisk(_Total)\\Avg. Disk sec/Read'
              '\\LogicalDisk(_Total)\\Avg. Disk sec/Write'
              '\\LogicalDisk(_Total)\\Disk Reads/sec'
              '\\LogicalDisk(_Total)\\Disk Writes/sec'
              '\\Network Interface(*)\\Bytes Total/sec'
              '\\RemoteFX Network(*)\\Current TCP RTT'
              '\\RemoteFX Network(*)\\Current UDP Bandwidth'
              '\\Terminal Services(*)\\Active Sessions'
              '\\Terminal Services(*)\\Inactive Sessions'
            ]
          }
        ]
      }
      destinations: {
        logAnalytics: [
          {
            name: 'log-analytics'
            workspaceResourceId: logAnalyticsWorkspace.outputs.resourceId
          }
        ]
      }
      dataFlows: [
        {
          streams: [
            'Microsoft-Event'
            'Microsoft-Perf'
          ]
          destinations: [
            'log-analytics'
          ]
        }
      ]
    }
  }
}

module avdActionGroup 'br/public:avm/res/insights/action-group:0.8.0' = if (deployAlertActionGroup) {
    name: 'avd-ag'
    params: {
      name: 'ag-avd-${environmentConfig.shortName}'
      location: 'global'
      tags: tags
      groupShortName: 'avd-${environmentConfig.shortName}'
      enabled: true
      emailReceivers: [
        for receiver in alertEmailReceivers: {
          name: receiver.name
          emailAddress: receiver.emailAddress
          useCommonAlertSchema: true
        }
      ]
    }
}

module scheduledQueryRules 'br/public:avm/res/insights/scheduled-query-rule:0.6.0' = [
  for alert in scheduledQueryAlerts: if (deployScheduledQueryAlerts) {
    name: 'sqr-${alert.name}'
    params: {
      name: 'sqr-${alert.name}'
      location: location
      tags: tags
      enableTelemetry: false

      enabled: scheduledQueryAlertsEnabled
      kind: 'LogAlert'
      alertDisplayName: alert.displayName
      alertDescription: alert.description
      severity: alert.severity
      evaluationFrequency: alert.evaluationFrequency
      windowSize: alert.windowSize
      queryTimeRange: alert.queryTimeRange
      autoMitigate: true
      scopes: [
        logAnalyticsWorkspace.outputs.resourceId
      ]
      actions: {
        actionGroupResourceIds: effectiveActionGroupResourceIds
      }
      criterias: {
        allOf: [
          {
            query: alert.query
            metricMeasureColumn: 'AggregatedValue'
            operator: alert.operator
            threshold: alert.threshold
            timeAggregation: alert.timeAggregation
            failingPeriods: {
              numberOfEvaluationPeriods: 1
              minFailingPeriodsToAlert: 1
            }
          }
        ]
      }
    }
  }
]

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name
output avdSessionHostDataCollectionRuleResourceId string = avdSessionHostDcr.outputs.resourceId
@description('Name of the Data Collection Rule used by AVD session hosts.')
output avdSessionHostDataCollectionRuleName string = avdSessionHostDcr.outputs.name
