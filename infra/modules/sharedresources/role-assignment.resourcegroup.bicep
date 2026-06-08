targetScope = 'resourceGroup'

@description('Principal ID receiving the role assignment.')
param principalId string

@description('Principal type receiving the role assignment.')
param principalType string = 'ServicePrincipal'

@description('Role definition ID, not the full resource ID.')
param roleDefinitionId string

@description('Stable seed used for the role assignment name.')
param roleAssignmentNameSeed string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId, roleAssignmentNameSeed)
  properties: {
    principalId: principalId
    principalType: principalType
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      roleDefinitionId
    )
  }
}
