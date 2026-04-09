#!/bin/bash
# ============================================================================
# Deploy AI Infrastructure
#
# Deploys: AI Search, AI Services (with model deployments), AI Hub, AI Project
#
# Usage:
#   RESOURCE_GROUP=mbi-iot-rg LOCATION=eastus PREFIX=mmxiot bash infra/ai-deploy.sh
# ============================================================================

set -euo pipefail

# ---------- Configuration ----------
RESOURCE_GROUP="${RESOURCE_GROUP:-mbi-iot-rg}"
LOCATION="${LOCATION:-eastus}"
PREFIX="${PREFIX:-mbiiot}"
AI_SEARCH_SKU="${AI_SEARCH_SKU:-basic}"
# ------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo "  AI Infrastructure Deployment"
echo "============================================================"
echo "  Resource Group  : $RESOURCE_GROUP"
echo "  Location        : $LOCATION"
echo "  Prefix          : $PREFIX"
echo "  AI Search SKU   : $AI_SEARCH_SKU"
echo "============================================================"
echo ""

# Step 1: Create resource group
echo "→ Step 1/2: Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# Step 2: Deploy AI infrastructure
echo "→ Step 2/2: Deploying AI infrastructure via Bicep..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$SCRIPT_DIR/main.bicep" \
  --parameters \
    prefix="$PREFIX" \
    location="$LOCATION" \
    aiSearchSku="$AI_SEARCH_SKU" \
  --output none
echo "  ✓ AI infrastructure deployed"

echo ""
echo "============================================================"
echo "  ✓ Deployment complete!"
echo "============================================================"
echo ""
echo "  Resources deployed:"
echo "    AI Search     : ${PREFIX}-search"
echo "    AI Foundry    : ${PREFIX}-foundry"
echo ""
echo "  Model deployments:"
echo "    text-embedding-3-small  (Standard)"
echo "    gpt-41                  (Global Standard)"
echo ""
echo "  AI Foundry portal:"
echo "    https://ai.azure.com"
echo ""
