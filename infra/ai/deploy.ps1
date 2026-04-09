# ============================================================================
# Deploy AI Infrastructure (PowerShell)
#
# Deploys: AI Search, AI Services (with model deployments), AI Hub, AI Project
#
# Usage:
#   .\infra\ai-deploy.ps1 -ResourceGroup "mbi-iot-rg" -Location "eastus" -Prefix "mmxiot"
# ============================================================================

param(
    [string]$ResourceGroup = "mbi-iot-rg",
    [string]$Location = "eastus",
    [string]$Prefix = "mbiiot",
    [string]$AiSearchSku = "standard"
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "============================================================"
Write-Host "  AI Infrastructure Deployment"
Write-Host "============================================================"
Write-Host "  Resource Group  : $ResourceGroup"
Write-Host "  Location        : $Location"
Write-Host "  Prefix          : $Prefix"
Write-Host "  AI Search SKU   : $AiSearchSku"
Write-Host "============================================================"
Write-Host ""

# Step 1: Create resource group
Write-Host "-> Step 1/2: Creating resource group '$ResourceGroup' in '$Location'..."
az group create `
    --name $ResourceGroup `
    --location $Location `
    --output none

# Step 2: Deploy AI infrastructure
Write-Host "-> Step 2/2: Deploying AI infrastructure via Bicep..."
az deployment group create `
    --resource-group $ResourceGroup `
    --template-file "$ScriptDir\main.bicep" `
    --parameters `
        prefix=$Prefix `
        location=$Location `
        aiSearchSku=$AiSearchSku `
    --output none
Write-Host "  [OK] AI infrastructure deployed"

Write-Host ""
Write-Host "============================================================"
Write-Host "  [OK] Deployment complete!"
Write-Host "============================================================"
Write-Host ""
Write-Host "  Resources deployed:"
Write-Host "    AI Search        : ${Prefix}-search"
Write-Host "    AI Foundry       : ${Prefix}-foundry"
Write-Host "    AI Multi-Service : ${Prefix}-aiservices"
Write-Host "    Project          : team01"
Write-Host ""
Write-Host "  Model deployments:"
Write-Host "    text-embedding-3-small  (Standard, 1.5K TPM)"
Write-Host "    gpt-4.1                 (Global Standard, 500K TPM)"
Write-Host ""
Write-Host "  AI Foundry portal:"
Write-Host "    https://ai.azure.com"
Write-Host ""
