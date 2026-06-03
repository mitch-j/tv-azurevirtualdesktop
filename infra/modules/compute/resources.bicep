targetScope = 'resourceGroup'

/*
AVD Deployment / Compute Resources

Scope:
- Resource Group

Deploys:
- Nothing when deploySessionHosts is false
- Session host resources will be added here after the scaffold validates

Does not deploy:
- Resource groups
- Virtual networks or subnets
- AVD host pools, workspaces, or application groups
- FSLogix storage accounts or file shares
*/

// Types

@sealed()
type PlannedSessionHostGroup = {
  @description('Stable workload key for this session host group.')
  name: string

  @description('Resource group name targeted by this deployment.')
  resourceGroupName: string

  @description('Existing AVD host pool name for this workload.')
  hostPoolName: string

  @description('Windows computer name prefix.')
  vmNamePrefix: string

  @minValue(0)
  @description('Number of session hosts to plan for this workload.')
  vmCount: int

  @description('Azure VM SKU for this workload.')
  vmSize: string

  @description('OS disk settings for this workload.')
  osDisk: {
    @description('Managed disk storage type.')
    storageAccountType: 'Premium_LRS' | 'StandardSSD_LRS' | 'Standard_LRS'

    @minValue(64)
    @description('Managed OS disk size in GB.')
    diskSizeGB: int
  }
}

// Parameters

@description('Azure region for session host resources.')
param location string

@description('Standard tags applied to session host resources.')
param tags object

@description('When false, this file validates configuration and produces planned outputs without creating session host resources.')
param deploySessionHosts bool = false

@description('Session host workload configuration for this resource group.')
param sessionHostGroup PlannedSessionHostGroup

// Variables

var plannedSessionHosts = [for sessionHostNumber in range(1, sessionHostGroup.vmCount): {
  name: toLower('${sessionHostGroup.vmNamePrefix}${padLeft(string(sessionHostNumber), 2, '0')}')
  location: location
  resourceGroupName: resourceGroup().name
  hostPoolName: sessionHostGroup.hostPoolName
  vmSize: sessionHostGroup.vmSize
  osDisk: sessionHostGroup.osDisk
  tags: tags
}]

// Resources

/*
Session host resources are intentionally omitted for the first pipeline pass.

Next additions:
- Network interfaces
- Virtual machines
- AD DS domain join extension
- AVD registration extension
- FSLogix configuration extension
*/

// Outputs

@description('Whether this deployment is configured to create session host resources.')
output deploySessionHosts bool = deploySessionHosts

@description('Session hosts planned for this workload.')
output plannedSessionHosts array = plannedSessionHosts
