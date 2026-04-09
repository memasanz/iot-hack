// Azure AI Multi-Service Account (Vision, Speech, Language, Decision, etc.)
param name string
param location string

resource aiMultiService 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: name
  location: location
  kind: 'CognitiveServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: name
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
  }
}

output name string = aiMultiService.name
output endpoint string = aiMultiService.properties.endpoint
output principalId string = aiMultiService.identity.principalId
