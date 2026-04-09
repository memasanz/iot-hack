using 'main.bicep'

param prefix = 'mmxiot'
param containerImage = 'mmxiotacr.azurecr.io/mbi-iot-simulator:latest'
param deviceCount = 10
param sendIntervalSeconds = 5
param anomalyProbability = '0.05'
param consumerGroupCount = 2
