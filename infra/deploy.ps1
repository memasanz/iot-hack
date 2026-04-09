# ============================================================================
# Deploy IoT Telemetry Simulator (PowerShell)
#
# This script:
#   1. Creates a resource group
#   2. Deploys ACR first
#   3. Builds & pushes the Docker image to ACR
#   4. Deploys full infrastructure (IoT Hub, Container App Env, Container App)
# ============================================================================

param(
    [string]$ResourceGroup = "mbi-iot-rg",
    [string]$Location = "eastus",
    [string]$Prefix = "mbiiot",
    [int]$DeviceCount = 10,
    [int]$SendInterval = 5,
    [string]$AnomalyProb = "0.05",
    [int]$ConsumerGroupCount = 2,
    [string]$CompanyPrefix = "MBI",
    [string]$ImageTag = "latest"
)

$ErrorActionPreference = "Stop"

$AcrName = "${Prefix}acr"
$ImageName = "mbi-iot-simulator"
$FullImage = "${AcrName}.azurecr.io/${ImageName}:${ImageTag}"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RootDir = Split-Path -Parent $ScriptDir

Write-Host "============================================================"
Write-Host "  IoT Simulator Deployment"
Write-Host "============================================================"
Write-Host "  Resource Group    : $ResourceGroup"
Write-Host "  Location          : $Location"
Write-Host "  Prefix            : $Prefix"
Write-Host "  Device Count      : $DeviceCount"
Write-Host "  Send Interval     : ${SendInterval}s"
Write-Host "  Anomaly Prob      : $AnomalyProb"
Write-Host "  Consumer Groups   : $ConsumerGroupCount"
Write-Host "  Company Prefix    : $CompanyPrefix"
Write-Host "============================================================"
Write-Host ""

# Step 1: Create resource group
Write-Host "-> Step 1/4: Creating resource group '$ResourceGroup' in '$Location'..."
az group create `
    --name $ResourceGroup `
    --location $Location `
    --output none

# Step 2: Deploy ACR only (so we have a registry to push to)
Write-Host "-> Step 2/4: Deploying Azure Container Registry..."
az deployment group create `
    --resource-group $ResourceGroup `
    --template-file "$ScriptDir\modules\acr.bicep" `
    --parameters name=$AcrName location=$Location `
    --output none
Write-Host "  [OK] ACR deployed: $AcrName"

# Step 3: Build & push Docker image to ACR
Write-Host "-> Step 3/4: Building and pushing container image..."
az acr build `
    --registry $AcrName `
    --image "${ImageName}:${ImageTag}" `
    --file "$RootDir\Dockerfile" `
    $RootDir
Write-Host "  [OK] Image pushed: $FullImage"

# Step 4: Deploy full infrastructure (IoT Hub, Container App Env, Container App)
Write-Host "-> Step 4/4: Deploying full infrastructure via Bicep..."
az deployment group create `
    --resource-group $ResourceGroup `
    --template-file "$ScriptDir\main.bicep" `
    --parameters `
        prefix=$Prefix `
        containerImage=$FullImage `
        deviceCount=$DeviceCount `
        sendIntervalSeconds=$SendInterval `
        anomalyProbability=$AnomalyProb `
        consumerGroupCount=$ConsumerGroupCount `
        companyPrefix=$CompanyPrefix `
    --output none
Write-Host "  [OK] Infrastructure deployed"

$ContainerAppName = "${Prefix}-simulator"

Write-Host ""
Write-Host "============================================================"
Write-Host "  [OK] Deployment complete!"
Write-Host "============================================================"
Write-Host ""
Write-Host "  API URL:"
$fqdn = az containerapp show -n $ContainerAppName -g $ResourceGroup --query "properties.configuration.ingress.fqdn" -o tsv 2>$null
if ($fqdn) {
    Write-Host "    https://$fqdn"
    Write-Host ""
    Write-Host "  Endpoints:"
    Write-Host "    GET  https://$fqdn/health"
    Write-Host "    GET  https://$fqdn/status"
    Write-Host "    POST https://$fqdn/start"
    Write-Host "    POST https://$fqdn/stop"
    Write-Host "    GET  https://$fqdn/docs    (Swagger UI)"
}
Write-Host ""
Write-Host "  NEXT STEP — assign roles (requires Owner or User Access Administrator):"
Write-Host "    .\infra\deploy-roles.ps1 -ResourceGroup $ResourceGroup -Prefix $Prefix"
Write-Host ""
Write-Host "  View logs:"
Write-Host "    az containerapp logs show -n $ContainerAppName -g $ResourceGroup --follow"
Write-Host ""
