#!/bin/bash
# ============================================================================
# Deploy IoT Telemetry Simulator
#
# This script:
#   1. Creates a resource group
#   2. Deploys ACR first
#   3. Builds & pushes the Docker image to ACR
#   4. Deploys full infrastructure (IoT Hub, Container App Env, Container App)
# ============================================================================

set -euo pipefail

# ---------- Configuration ----------
RESOURCE_GROUP="${RESOURCE_GROUP:-mbi-iot-rg}"
LOCATION="${LOCATION:-eastus}"
PREFIX="${PREFIX:-mbiiot}"
DEVICE_COUNT="${DEVICE_COUNT:-10}"
SEND_INTERVAL="${SEND_INTERVAL:-5}"
ANOMALY_PROB="${ANOMALY_PROB:-0.05}"
CONSUMER_GROUP_COUNT="${CONSUMER_GROUP_COUNT:-2}"
COMPANY_PREFIX="${COMPANY_PREFIX:-MBI}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
# ------------------------------------

ACR_NAME="${PREFIX}acr"
IMAGE_NAME="mbi-iot-simulator"
FULL_IMAGE="${ACR_NAME}.azurecr.io/${IMAGE_NAME}:${IMAGE_TAG}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "============================================================"
echo "  IoT Simulator Deployment"
echo "============================================================"
echo "  Resource Group    : $RESOURCE_GROUP"
echo "  Location          : $LOCATION"
echo "  Prefix            : $PREFIX"
echo "  Device Count      : $DEVICE_COUNT"
echo "  Send Interval     : ${SEND_INTERVAL}s"
echo "  Anomaly Prob      : $ANOMALY_PROB"
echo "  Consumer Groups   : $CONSUMER_GROUP_COUNT"
echo "  Company Prefix    : $COMPANY_PREFIX"
echo "============================================================"
echo ""

# Step 1: Create resource group
echo "→ Step 1/4: Creating resource group '$RESOURCE_GROUP' in '$LOCATION'..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output none

# Step 2: Deploy ACR only (so we have a registry to push to)
echo "→ Step 2/4: Deploying Azure Container Registry..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$SCRIPT_DIR/modules/acr.bicep" \
  --parameters name="$ACR_NAME" location="$LOCATION" \
  --output none
echo "  ✓ ACR deployed: $ACR_NAME"

# Step 3: Build & push Docker image to ACR
echo "→ Step 3/4: Building and pushing container image..."
az acr build \
  --registry "$ACR_NAME" \
  --image "${IMAGE_NAME}:${IMAGE_TAG}" \
  --file "$ROOT_DIR/Dockerfile" \
  "$ROOT_DIR"
echo "  ✓ Image pushed: $FULL_IMAGE"

# Step 4: Deploy full infrastructure (IoT Hub, Container App Env, Container App)
echo "→ Step 4/4: Deploying full infrastructure via Bicep..."
az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file "$SCRIPT_DIR/main.bicep" \
  --parameters \
    prefix="$PREFIX" \
    containerImage="$FULL_IMAGE" \
    deviceCount="$DEVICE_COUNT" \
    sendIntervalSeconds="$SEND_INTERVAL" \
    anomalyProbability="$ANOMALY_PROB" \
    consumerGroupCount="$CONSUMER_GROUP_COUNT" \
    companyPrefix="$COMPANY_PREFIX" \
  --output none
echo "  ✓ Infrastructure deployed"

CONTAINER_APP_NAME="${PREFIX}-simulator"

echo ""
echo "============================================================"
echo "  ✓ Deployment complete!"
echo "============================================================"
echo ""

FQDN=$(az containerapp show -n "$CONTAINER_APP_NAME" -g "$RESOURCE_GROUP" --query "properties.configuration.ingress.fqdn" -o tsv 2>/dev/null || echo "")
if [ -n "$FQDN" ]; then
  echo "  API URL:"
  echo "    https://$FQDN"
  echo ""
  echo "  Endpoints:"
  echo "    GET  https://$FQDN/health"
  echo "    GET  https://$FQDN/status"
  echo "    POST https://$FQDN/start"
  echo "    POST https://$FQDN/stop"
  echo "    GET  https://$FQDN/docs    (Swagger UI)"
fi
echo ""
echo "  NEXT STEP — assign roles (requires Owner or User Access Administrator):"
echo "    RESOURCE_GROUP=$RESOURCE_GROUP PREFIX=$PREFIX bash infra/deploy-roles.sh"
echo ""
echo "  View logs:"
echo "    az containerapp logs show -n $CONTAINER_APP_NAME -g $RESOURCE_GROUP --follow"
echo ""
