targetScope = 'resourceGroup'

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

// Modules

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.15.1' = {
  name: '${deployment().name}-log'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags

    dailyQuotaGb: dailyQuotaGb

    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }

    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

module avdSessionHostDcr 'br/public:avm/res/insights/data-collection-rule:0.11.0' = {
  name: '${deployment().name}-avd-sessionhost-dcr'
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

output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspace.outputs.resourceId
output logAnalyticsWorkspaceName string = logAnalyticsWorkspace.outputs.name
output avdSessionHostDataCollectionRuleResourceId string = avdSessionHostDcr.outputs.resourceId
@description('Name of the Data Collection Rule used by AVD session hosts.')
output avdSessionHostDataCollectionRuleName string = avdSessionHostDcr.outputs.name
