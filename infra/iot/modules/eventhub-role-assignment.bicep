// Assigns IoT Hub Data Contributor role to a principal
param iotHubName string
param principalId string

// IoT Hub Data Contributor built-in role
var iotHubDataContributorRoleId = '4fc6c259-987e-4a07-842e-c321cc9d413f'

resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' existing = {
  name: iotHubName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(iotHub.id, principalId, iotHubDataContributorRoleId)
  scope: iotHub
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', iotHubDataContributorRoleId)
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}
