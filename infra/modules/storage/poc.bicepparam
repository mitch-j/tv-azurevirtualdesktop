using 'main.bicep'

/*
AVD Deployment / Storage Parameters

Environment:
- poc

Used by:
- infra/modules/storage/main.bicep

Notes:
- Deploys the POC FSLogix storage configuration.
- Location controls the Azure region used for resource deployment and location-aware naming.
- Public network access should remain disabled when private endpoint and DNS values are configured.
- Do not store secrets, credentials, private keys, or certificate material in this file.
*/

// Environment
param environment = 'poc'
param location = 'eastus'

// FSLogix profile storage
param fslogixShareName = 'profiles'
param fslogixShareQuotaGiB = 1024

// Network access
// For POC only. Keep false once private endpoint and DNS are wired.
param enablePublicNetworkAccess = false

// Private endpoint integration
param privateEndpointSubnetResourceId = ''
param filePrivateDnsZoneResourceId = ''
