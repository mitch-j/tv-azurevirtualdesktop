using 'main.bicep'

/*
AVD Deployment / Monitoring PoC Parameters

Scope:
- Subscription

Configures:
- PoC monitoring deployment parameters
- Monitoring location
- Log Analytics workspace daily ingestion quota
- Environment-specific monitoring values

Does not configure:
- Session host virtual machine settings
- Azure Monitor Agent installation
- Data Collection Rule associations
- AVD host pool diagnostic categories
- FSLogix storage diagnostic categories
*/

param environment = 'poc'

param location = 'eastus'

param dailyQuotaGb = 2

param deployAlertActionGroup = true
param alertEmailReceivers = [
  {
    name: 'systems-engineering'
    emailAddress: 'mitch.jurisch@doitbest.com'
  }
]

param deployScheduledQueryAlerts = true

param scheduledQueryAlertsEnabled = false


param avdErrorsAlertThreshold = 0
param failedConnectionsAlertThreshold = 0
param fslogixErrorsAlertThreshold = 0
param lowDiskFreePercentThreshold = 15
param highCpuPercentThreshold = 85
param lowMemoryAvailableMbThreshold = 2048
param dailyQuotaThresholdGb = dailyQuotaGb * 75 / 100
param avdPlatformAlertSeverity = 2
param sessionHostCapacityAlertSeverity = 3
param fslogixAlertSeverity = 2
param scheduledQueryAlertEvaluationFrequency = 'PT15M'
param scheduledQueryShortWindowSize = 'PT15M'
param scheduledQueryLongWindowSize = 'PT30M'
