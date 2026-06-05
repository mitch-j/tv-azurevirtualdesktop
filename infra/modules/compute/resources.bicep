targetScope = 'resourceGroup'

/*
AVD Deployment / Compute Resources

Scope:
- Resource Group

Deploys:
- Network interfaces for planned session hosts when deployNetworkInterfaces is true

Does not deploy:
- Resource groups
- Virtual networks or subnets
- AVD host pools, workspaces, or application groups
- FSLogix storage accounts or file shares
- Session host virtual machines
*/

import {
  LocationName
} from '../../shared/types.bicep'

// Types

@sealed()
type PlannedSessionHostGroup = {
  @description('Purpose key used to identify the session host workload.')
  purpose: string

  @description('Resource group name targeted by this deployment.')
  resourceGroupName: string

  @description('Existing AVD host pool name for this workload.')
  hostPoolName: string

  @description('Existing virtual network resource group name.')
  networkResourceGroupName: string

  @description('Existing virtual network name.')
  virtualNetworkName: string

  @description('Existing session host subnet name.')
  subnetName: string

  @description('Session Host name prefix.')
  sessionHostNamePrefix: string

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

@description('Tags applied to deployed AVD resources.')
param tags object

@description('Azure region for deployed resources.')
param location LocationName

@description('When true, this module creates network interfaces for planned session hosts.')
param deployNetworkInterfaces bool = false

@description('Session host workload configuration for this resource group.')
param sessionHostGroup PlannedSessionHostGroup

// Variables

var plannedSessionHosts = [
  for sessionHostNumber in range(1, sessionHostGroup.vmCount): {
    sessionHostName: toLower('${sessionHostGroup.sessionHostNamePrefix}${padLeft(string(sessionHostNumber), 2, '0')}')
    purpose: sessionHostGroup.purpose
    nicName: toLower('${sessionHostGroup.sessionHostNamePrefix}${padLeft(string(sessionHostNumber), 2, '0')}-nic')
    location: location
    resourceGroupName: resourceGroup().name
    hostPoolName: sessionHostGroup.hostPoolName
    vmSize: sessionHostGroup.vmSize
    osDisk: sessionHostGroup.osDisk
    subnetResourceId: resourceId(
      sessionHostGroup.networkResourceGroupName,
      'Microsoft.Network/virtualNetworks/subnets',
      sessionHostGroup.virtualNetworkName,
      sessionHostGroup.subnetName
    )
    tags: tags
  }
]

// Modules

@description('Create NICs for each planned session host.')
module sessionHostNetworkInterfaces 'br/public:avm/res/network/network-interface:0.5.3' = [
  for (sessionHost, index) in plannedSessionHosts: if (deployNetworkInterfaces) {
    name: '${deployment().name}-nic-${index}'
    params: {
      name: sessionHost.nicName
      location: location
      tags: tags
      ipConfigurations: [
        {
          name: 'ipconfig01'
          subnetResourceId: sessionHost.subnetResourceId
          privateIPAllocationMethod: 'Dynamic'
        }
      ]
    }
  }
]

// Outputs

@description('Whether this deployment is configured to create network interfaces.')
output deployNetworkInterfaces bool = deployNetworkInterfaces

@description('Session hosts planned for this workload.')
output plannedSessionHosts array = plannedSessionHosts

@description('Network interfaces created or planned for this workload.')
output sessionHostNetworkInterfaces array = [
  for sessionHost in plannedSessionHosts: {
    name: sessionHost.nicName
    resourceId: resourceId('Microsoft.Network/networkInterfaces', sessionHost.nicName)
    subnetResourceId: sessionHost.subnetResourceId
  }
]
