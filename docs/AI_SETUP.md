# AI Services Setup

> ← Back to [main README](../README.md)

Deploys **Azure AI Search** and **Azure AI Foundry** (with model deployments) for the hackathon. Uses the same `prefix` parameter as the [IoT Simulator Setup](IOT_SIMULATOR_SETUP.md) to keep all resources consistently named.

The Foundry resource uses the latest standalone model (`Microsoft.CognitiveServices/accounts` with `allowProjectManagement: true`) — no Hub or Project resources needed. Projects are created directly in the [AI Foundry portal](https://ai.azure.com).

## What Gets Deployed

| Resource | Name | Description |
|---|---|---|
| **Azure AI Search** | `<prefix>-search` | Search service for indexing and querying data (Basic SKU) |
| **Azure AI Foundry** | `<prefix>-foundry` | AI Services with Foundry project management enabled |
| **Model: text-embedding-3-small** | `text-embedding-3-small` | Embedding model for vectorizing text (Standard, 120K TPM) |
| **Model: gpt-4.1** | `gpt-41` | Chat/completion model (Global Standard, 80K TPM) |

The Foundry resource is automatically connected to AI Search for RAG (Retrieval-Augmented Generation) scenarios.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed and logged in (`az login`)
- An Azure subscription with access to Azure OpenAI models
- **Contributor** role on the resource group

## Deploy

**PowerShell:**
```powershell
.\infra\ai\deploy.ps1 -ResourceGroup "mbi-iot-rg" -Location "eastus" -Prefix "mmxiot"
```

**Bash:**
```bash
RESOURCE_GROUP=mbi-iot-rg LOCATION=eastus PREFIX=mmxiot bash infra/ai/deploy.sh
```

### Deploy Parameters

| Parameter (PS / Bash) | Default | Description |
|---|---|---|
| `ResourceGroup` / `RESOURCE_GROUP` | `mbi-iot-rg` | Resource group (created if it doesn't exist) |
| `Location` / `LOCATION` | `eastus` | Azure region |
| `Prefix` / `PREFIX` | `mbiiot` | Prefix for all resource names (use the same prefix as IoT deployment) |
| `AiSearchSku` / `AI_SEARCH_SKU` | `basic` | AI Search SKU (`free`, `basic`, or `standard`) |

## Verify the Deployment

After deployment, verify resources in the Azure portal or via CLI:

```bash
# List AI resources in the resource group
az resource list -g <resource-group> --query "[?contains(type,'Cognitive') || contains(type,'Search') || contains(type,'MachineLearning')].{name:name,type:type}" -o table

# Check model deployments
az cognitiveservices account deployment list -g <resource-group> -n <prefix>-aiservices -o table
```

## Access AI Foundry

Open [https://ai.azure.com](https://ai.azure.com) and select the **`<prefix>-foundry`** resource to start working with the deployed models and connected services.

The Foundry resource is pre-configured with:
- **Model deployments** — GPT-4.1 and text-embedding-3-small ready to use
- **AI Search connection** — for building RAG (Retrieval-Augmented Generation) solutions

## Architecture

```
┌──────────────────────────────────────────┐
│  AI Foundry (<prefix>-foundry)           │
│  kind: AIServices                        │
│  allowProjectManagement: true            │
│                                          │
│  Models:                                 │
│  • text-embedding-3-small (Standard)     │
│  • gpt-41 (Global Standard)             │
│                                          │
│  Connections:                            │
│  • AI Search                             │
└──────────────────┬───────────────────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │  AI Search           │
        │  (<prefix>-search)   │
        │                      │
        │  • Index IoT data    │
        │  • Vector search     │
        │  • Semantic ranking  │
        └─────────────────────┘
```

## References

- [Azure AI Foundry documentation](https://learn.microsoft.com/en-us/azure/ai-studio/)
- [Azure AI Search documentation](https://learn.microsoft.com/en-us/azure/search/)
- [Azure OpenAI model deployments](https://learn.microsoft.com/en-us/azure/ai-services/openai/how-to/create-resource)
