# ============================================================================
# Assign Roles — IoT Hub Data Contributor
#
# Requires: Owner or User Access Administrator on the resource group.
# Run this AFTER deploy.ps1 has completed.
#
# Usage:
#   .\infra\deploy-roles.ps1 -ResourceGroup "mbi-iot-rg" -Prefix "mmxiot"
#
# Or supply the values explicitly:
#   .\infra\deploy-roles.ps1 -ResourceGroup "mbi-iot-rg" `
#       -IoTHubName "mmxiot-iothub" -PrincipalId "<guid>"
# ============================================================================

param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [string]$Prefix,
    [string]$IoTHubName,
    [string]$PrincipalId
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# If values not supplied, derive them from the prefix
if (-not $IoTHubName) {
    if (-not $Prefix) { Write-Error "Provide either -Prefix or -IoTHubName"; exit 1 }
    $IoTHubName = "${Prefix}-iothub"
}

if (-not $PrincipalId) {
    if (-not $Prefix) { Write-Error "Provide either -Prefix or -PrincipalId"; exit 1 }
    $ContainerAppName = "${Prefix}-simulator"
    Write-Host "-> Looking up managed identity for '$ContainerAppName'..."
    $PrincipalId = az containerapp show `
        -n $ContainerAppName `
        -g $ResourceGroup `
        --query "identity.principalId" -o tsv
    if (-not $PrincipalId) { Write-Error "Could not find principalId for '$ContainerAppName'"; exit 1 }
}

Write-Host "============================================================"
Write-Host "  Role Assignment"
Write-Host "============================================================"
Write-Host "  Resource Group : $ResourceGroup"
Write-Host "  IoT Hub        : $IoTHubName"
Write-Host "  Principal ID   : $PrincipalId"
Write-Host "============================================================"
Write-Host ""

Write-Host "-> Deploying IoT Hub Data Contributor role assignment..."
az deployment group create `
    --resource-group $ResourceGroup `
    --template-file "$ScriptDir\role-assignment.bicep" `
    --parameters `
        iotHubName=$IoTHubName `
        principalId=$PrincipalId `
    --output none

Write-Host "  [OK] Role assignment complete"
Write-Host ""
