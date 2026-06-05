targetScope = 'resourceGroup'

/*
AVD Deployment / Storage Account

Scope:
- Resource Group

Deploys:
- FSLogix storage account
- FSLogix profile file share

Does not deploy:
- Storage RBAC assignments
- Private endpoints
- Private DNS records
- Session host virtual machines
*/

// Imports

import {
  PublicNetworkAccess
  StandardTags
  StorageAccountSkuName
} from '../../shared/types.bicep'

// Types

@description('Supported storage account kind values for this module.')
type StorageAccountKind =
  | 'FileStorage'
  | 'StorageV2'

// Parameters

@description('Azure region where the storage account is deployed.')
param location string

@description('Tags applied to storage resources.')
param tags StandardTags

@description('Name of the FSLogix storage account.')
param storageAccountName string

@description('SKU for the FSLogix storage account.')
param storageAccountSkuName StorageAccountSkuName = 'Premium_LRS'

@description('Storage account kind. FileStorage is recommended for Premium Azure Files.')
param storageAccountKind StorageAccountKind = 'FileStorage'

@description('Public network access setting for the storage account.')
param publicNetworkAccess PublicNetworkAccess = 'Disabled'

@description('FSLogix profile file share name.')
param fslogixShareName string = 'profiles'

@description('Provisioned size of the FSLogix profile file share in GiB.')
param fslogixShareQuotaGiB int = 1024

// Resources

resource fslogixStorageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: storageAccountSkuName
  }
  kind: storageAccountKind
  properties: {
    allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: publicNetworkAccess
    supportsHttpsTrafficOnly: true
  }
}

resource defaultFileService 'Microsoft.Storage/storageAccounts/fileServices@2025-01-01' = {
  name: 'default'
  parent: fslogixStorageAccount
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource fslogixShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2025-01-01' = {
  name: fslogixShareName
  parent: defaultFileService
  properties: {
    accessTier: 'Premium'
    enabledProtocols: 'SMB'
    shareQuota: fslogixShareQuotaGiB
  }
}

// Outputs

@description('Name of the FSLogix storage account.')
output storageAccountName string = fslogixStorageAccount.name

@description('Resource ID of the FSLogix storage account.')
output storageAccountResourceId string = fslogixStorageAccount.id

@description('Name of the FSLogix profile file share.')
output fslogixShareName string = fslogixShare.name

@description('Resource ID of the FSLogix profile file share.')
output fslogixShareResourceId string = fslogixShare.id
