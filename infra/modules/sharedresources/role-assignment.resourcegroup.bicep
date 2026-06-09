targetScope = 'resourceGroup'

/*
AVD Deployment / Shared Resources / RBAC Role Assignment

Scope:
- resourceGroup

Deploys:
- Custom role assigned to Resource Group

Does not deploy:
- AVD host pools or workspaces
- Session host virtual machines
- FSLogix storage
- Network resources
- Azure Monitor, Network Watcher, role entitlement, or policy assignments yet
*/

// Parameters

@description('Principal ID receiving the role assignment.')
param principalId string

@description('Principal type receiving the role assignment.')
param principalType string = 'ServicePrincipal'

@description('Role definition ID, not the full resource ID.')
param roleDefinitionId string

/*
module roleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  name: '${deployment().name}-rbac'
  params: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      roleDefinitionId
    )
    resourceId: guid(resourceGroup().id)
  }
}
*/

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      roleDefinitionId
    )
  }
}

