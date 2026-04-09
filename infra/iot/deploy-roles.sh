#!/bin/bash
# ============================================================================
# Assign Roles — IoT Hub Data Contributor
#
# Requires: Owner or User Access Administrator on the resource group.
# Run this AFTER deploy.sh has completed.
#
# Usage:
#   RESOURCE_GROUP=mbi-iot-rg PREFIX=mmxiot bash infra/deploy-roles.sh
#
# Or supply the values explicitly:
#   RESOURCE_GROUP=mbi-iot-rg IOT_HUB_NAME=mmxiot-iothub \
#     PRINCIPAL_ID=<guid> bash infra/deploy-roles.sh
# ============================================================================

set -euo pipefail

RESOURCE_GROUP="${RESOURCE_GROUP:?RESOURCE_GROUP is required}"
PREFIX="${PREFIX:-}"
IOT_HUB_NAME="${IOT_HUB_NAME:-}"
PRINCIPAL_ID="${PRINCIPAL_ID:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If values not supplied, derive them from the prefix
if [ -z "$IOT_HUB_NAME" ]; then
  if [ -z "$PREFIX" ]; then echo "ERROR: Provide either PREFIX or IOT_HUB_NAME"; exit 1; fi
  IOT_HUB_NAME="${PREFIX}-iothub"
fi

if [ -z "$PRINCIPAL_ID" ]; then
  if [ -z "$PREFIX" ]; then echo "ERROR: Provide either PREFIX or PRINCIPAL_ID"; exit 1; fi
  CONTAINER_APP_NAME="${PREFIX}-simulator"
  echo "→ Looking up managed identity for '$CONTAINER_APP_NAME'..."
  PRINCIPAL_ID=$(az containerapp show \
    -n "$CONTAINER_APP_NAME" \
    -g "$RESOURCE_GROUP" \
    --query "identity.principalId" -o tsv)
  if [ -z "$PRINCIPAL_ID" ]; then echo "ERROR: Could not find principalId for '$CONTAINER_APP_NAME'"; exit 1; fi
fi

echo "============================================================"
echo "  Role Assignment"
echo "============================================================"
echo "  Resource Group : $RESOURCE_GROUP"
echo "  IoT Hub        : $IOT_HUB_NAME"
echo "  Principal ID   : $PRINCIPAL_ID"
echo "============================================================"
echo ""

echo "→ Deploying IoT Hub Data Contributor role assignment..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$SCRIPT_DIR/role-assignment.bicep" \
  --parameters \
    iotHubName="$IOT_HUB_NAME" \
    principalId="$PRINCIPAL_ID" \
  --output none

echo "  ✓ Role assignment complete"
echo ""
