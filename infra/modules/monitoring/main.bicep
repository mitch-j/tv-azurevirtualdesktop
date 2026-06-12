targetScope = 'subscription'





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

@description ('Cost optimization quota for logs')
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
