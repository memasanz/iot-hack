// Azure AI Foundry — AI Services with Foundry project management + model deployments
param prefix string
param location string
param aiSearchName string

// ============================================================================
// AI Foundry resource (new standalone model — no Hub/Project needed)
// ============================================================================

resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: '${prefix}-foundry'
  location: location
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    customSubDomainName: '${prefix}-foundry'
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: true
    allowProjectManagement: true
  }
}

// ============================================================================
// Model deployments
// ============================================================================

resource embeddingDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundry
  name: 'text-embedding-3-small'
  sku: {
    name: 'Standard'
    capacity: 150
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'text-embedding-3-small'
      version: '1'
    }
  }
}

resource gpt41Deployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: foundry
  name: 'gpt-4.1'
  dependsOn: [embeddingDeployment]
  sku: {
    name: 'GlobalStandard'
    capacity: 500
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-4.1'
      version: '2025-04-14'
    }
  }
}

// ============================================================================
// Project
// ============================================================================

resource team01Project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  parent: foundry
  name: 'team01'
  location: location
  sku: {
    name: 'S0'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: 'team01'
  }
}

// ============================================================================
// Connection to AI Search
// ============================================================================

resource searchService 'Microsoft.Search/searchServices@2025-05-01' existing = {
  name: aiSearchName
}

resource aiSearchConnection 'Microsoft.CognitiveServices/accounts/connections@2025-06-01' = {
  parent: foundry
  name: '${prefix}-aisearch'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${searchService.name}.search.windows.net'
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ApiType: 'Azure'
      ResourceId: searchService.id
    }
  }
}

// ============================================================================
// Outputs
// ============================================================================

output foundryName string = foundry.name
output foundryEndpoint string = foundry.properties.endpoint
output projectName string = team01Project.name
