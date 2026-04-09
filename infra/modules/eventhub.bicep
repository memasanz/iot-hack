// Event Hub Namespace + Event Hub with a send/listen policy
param namespaceName string
param eventHubName string
param location string

resource namespace 'Microsoft.EventHub/namespaces@2024-01-01' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Standard'
    capacity: 1
  }
}

resource eventHub 'Microsoft.EventHub/namespaces/eventhubs@2024-01-01' = {
  parent: namespace
  name: eventHubName
  properties: {
    partitionCount: 4
    messageRetentionInDays: 1
  }
}

resource sendListenPolicy 'Microsoft.EventHub/namespaces/eventhubs/authorizationRules@2024-01-01' = {
  parent: eventHub
  name: 'simulatorPolicy'
  properties: {
    rights: [
      'Send'
      'Listen'
    ]
  }
}

output namespaceName string = namespace.name
output eventHubName string = eventHub.name
output connectionString string = sendListenPolicy.listKeys().primaryConnectionString
