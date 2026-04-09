// Azure IoT Hub with configurable consumer groups
param name string
param location string

@description('Number of consumer groups to create (named team1, team2, etc.)')
param consumerGroupCount int = 2

resource iotHub 'Microsoft.Devices/IotHubs@2023-06-30' = {
  name: name
  location: location
  sku: {
    name: 'S1'
    capacity: 1
  }
  properties: {
    disableLocalAuth: false
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 4
      }
    }
    routing: {
      fallbackRoute: {
        name: '$fallback'
        source: 'DeviceMessages'
        condition: 'true'
        endpointNames: [
          'events'
        ]
        isEnabled: true
      }
    }
  }
}

// Create numbered consumer groups (team1, team2, etc.)
resource consumerGroups 'Microsoft.Devices/IotHubs/eventHubEndpoints/ConsumerGroups@2023-06-30' = [
  for i in range(1, consumerGroupCount): {
    name: '${iotHub.name}/events/team${i}'
    properties: {
      name: 'team${i}'
    }
  }
]

output name string = iotHub.name
output hostname string = iotHub.properties.hostName
output eventHubCompatibleEndpoint string = iotHub.properties.eventHubEndpoints.events.endpoint
output eventHubCompatiblePath string = iotHub.properties.eventHubEndpoints.events.path
