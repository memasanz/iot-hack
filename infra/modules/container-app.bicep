// Container App — IoT Telemetry Simulator
param name string
param location string
param environmentId string
param containerImage string
param acrLoginServer string
param acrName string

param iotHubHostname string
param deviceCount int
param sendIntervalSeconds int
param anomalyProbability string
param prefix string

// Reference existing ACR to retrieve credentials
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: environmentId
    configuration: {
      ingress: {
        external: true
        targetPort: 8000
        transport: 'http'
      }
      secrets: [
        {
          name: 'acr-password'
          value: acr.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: acrLoginServer
          username: acr.listCredentials().username
          passwordSecretRef: 'acr-password'
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'mbi-iot-simulator'
          image: containerImage
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'IOT_HUB_HOSTNAME'
              value: iotHubHostname
            }
            {
              name: 'DEVICE_COUNT'
              value: string(deviceCount)
            }
            {
              name: 'SEND_INTERVAL_SECONDS'
              value: string(sendIntervalSeconds)
            }
            {
              name: 'ANOMALY_PROBABILITY'
              value: anomalyProbability
            }
            {
              name: 'COMPANY_PREFIX'
              value: prefix
            }
            {
              name: 'LOG_LEVEL'
              value: 'INFO'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

output name string = containerApp.name
output fqdn string = containerApp.properties.configuration.?ingress.?fqdn ?? 'N/A (no ingress)'
output principalId string = containerApp.identity.principalId
