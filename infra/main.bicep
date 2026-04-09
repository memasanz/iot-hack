// ============================================================================
// IoT Telemetry Simulator Infrastructure
// 
// Deploys: ACR, IoT Hub, Container App Environment + App
// The Container App uses a system-assigned managed identity to register
// devices and send telemetry via the IoT Hub device SDK.
// ============================================================================

targetScope = 'resourceGroup'

@description('Prefix used for all resource names — choose something globally unique')
param prefix string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('Container image name (including tag)')
param containerImage string

@description('Number of simulated IoT devices')
param deviceCount int = 10

@description('Seconds between telemetry cycles')
param sendIntervalSeconds int = 5

@description('Probability of anomaly per reading (0.0–1.0)')
param anomalyProbability string = '0.05'

@description('Number of consumer groups to create (named team1, team2, etc.)')
param consumerGroupCount int = 2

// ============================================================================
// Modules
// ============================================================================

module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  params: {
    name: '${prefix}acr'
    location: location
  }
}

module iotHub 'modules/iot-hub.bicep' = {
  name: 'iot-hub-deployment'
  params: {
    name: '${prefix}-iothub'
    location: location
    consumerGroupCount: consumerGroupCount
  }
}

module containerAppEnv 'modules/container-app-env.bicep' = {
  name: 'container-app-env-deployment'
  params: {
    name: '${prefix}-env'
    location: location
  }
}

module containerApp 'modules/container-app.bicep' = {
  name: 'container-app-deployment'
  params: {
    name: '${prefix}-simulator'
    location: location
    environmentId: containerAppEnv.outputs.environmentId
    containerImage: containerImage
    acrLoginServer: acr.outputs.loginServer
    acrName: acr.outputs.name
    iotHubHostname: iotHub.outputs.hostname
    deviceCount: deviceCount
    sendIntervalSeconds: sendIntervalSeconds
    anomalyProbability: anomalyProbability
  }
}

// ============================================================================
// Outputs
// ============================================================================

output acrLoginServer string = acr.outputs.loginServer
output iotHubName string = iotHub.outputs.name
output iotHubHostname string = iotHub.outputs.hostname
output containerAppName string = containerApp.outputs.name
output containerAppFqdn string = containerApp.outputs.fqdn
output containerAppPrincipalId string = containerApp.outputs.principalId
