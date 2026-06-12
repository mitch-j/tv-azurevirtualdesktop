targetScope = 'resourceGroup'

// CURRENTLY NOT USED. Retained for future possible implementation.

// Diagnostic logging is handled in each individual resource module.



import {
  ExistingResourceRef
} from '../../shared/types.bicep'


@description('Resource ID of the Azure resource receiving diagnostic settings.')
param targetResourceId string

@description('Reference to an existing Log Analytics workspace.')
param existingLogAnalyticsWorkspace ExistingResourceRef



resource existingWorkspace 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: existingLogAnalyticsWorkspace!.name
  scope: resourceGroup(
    existingLogAnalyticsWorkspace!.subscriptionId,
    existingLogAnalyticsWorkspace!.resourceGroupName
  )
}

resource storageDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diag-log'
  scope: storageAccount
  properties: {
    workspaceId: existingWorkspace
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}
