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

param dailyQuotaGb = '2'
