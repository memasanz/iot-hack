// ============================================================================
// AI Infrastructure — AI Search, AI Foundry (Hub + Project), Model Deployments
//
// Deploys: AI Search, AI Services, AI Hub, AI Project,
//          text-embedding-3-small + gpt-4.1 (global) model deployments
// ============================================================================

targetScope = 'resourceGroup'

@description('Prefix used for all resource names (same prefix as IoT deployment)')
param prefix string

@description('Azure region for all resources')
param location string = resourceGroup().location

@description('AI Search SKU')
@allowed(['free', 'basic', 'standard'])
param aiSearchSku string = 'basic'

// ============================================================================
// Modules
// ============================================================================

module aiSearch 'modules/ai-search.bicep' = {
  name: 'ai-search-deployment'
  params: {
    name: '${prefix}-search'
    location: location
    sku: aiSearchSku
  }
}

module aiFoundry 'modules/ai-foundry.bicep' = {
  name: 'ai-foundry-deployment'
  params: {
    prefix: prefix
    location: location
    aiSearchName: aiSearch.outputs.name
  }
}

// ============================================================================
// Outputs
// ============================================================================

output aiSearchName string = aiSearch.outputs.name
output aiSearchEndpoint string = aiSearch.outputs.endpoint
output foundryName string = aiFoundry.outputs.foundryName
output foundryEndpoint string = aiFoundry.outputs.foundryEndpoint
