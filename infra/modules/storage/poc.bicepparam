using 'main.bicep'

param environment = 'poc'

param fslogixShareName = 'profiles'
param fslogixShareQuotaGiB = 1024

// For POC only. Flip this to false once private endpoint + DNS are wired.
param enablePublicNetworkAccess = false

param privateEndpointSubnetResourceId = ''
param filePrivateDnsZoneResourceId = ''
