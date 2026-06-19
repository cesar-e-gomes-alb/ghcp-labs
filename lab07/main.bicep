// =============================================================================
// main.bicep — Secure Storage Account with encryption, network controls, and
//              monitoring/logging.
//
// Deployment pattern: "Secure-by-default storage landing zone"
//   1. Encryption at rest    → service-level (Account key) + infrastructure
//                              encryption (double encryption).
//   2. Access & network      → public access disabled, default-deny firewall,
//                              shared-key auth off (Entra ID only), TLS 1.2 min.
//   3. Monitoring & logging   → Log Analytics workspace + diagnostic settings
//                              for blob data-plane logs and account metrics.
//
// Scope: resourceGroup. Deploy with:
//   az deployment group create -g <rg> -f main.bicep -p storageAccountName=<name>
//
// Sources (Microsoft Learn):
//   - Infrastructure encryption: learn.microsoft.com/azure/storage/common/infrastructure-encryption-enable
//   - Storage networkAcls / publicNetworkAccess: learn.microsoft.com/azure/templates/microsoft.storage/2025-01-01/storageaccounts
//   - Diagnostic settings in Bicep: learn.microsoft.com/azure/azure-resource-manager/bicep/scenarios-monitoring
// =============================================================================

// ─── Parameters ──────────────────────────────────────────────────────────────

@description('Globally-unique storage account name (3-24 lowercase letters/digits).')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Storage redundancy SKU.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param skuName string = 'Standard_GRS'

@description('Retention in days for diagnostic logs in the Log Analytics workspace.')
@minValue(30)
@maxValue(730)
param logRetentionInDays int = 90

@description('Optional resource tags applied to every resource.')
param tags object = {
  workload: 'lab07'
  environment: 'production'
  managedBy: 'bicep'
}

// ─── Monitoring foundation: Log Analytics workspace ──────────────────────────
// Created first so the storage diagnostic settings can target it. Centralizing
// logs here enables querying, alerting, and long-term retention.

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${storageAccountName}-law'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// ─── Storage account: encryption + access + network security ─────────────────
// Security posture applied at creation time. Note: infrastructure encryption
// (requireInfrastructureEncryption) CANNOT be changed after creation.

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  kind: 'StorageV2'
  // System-assigned identity enables passwordless access to other Azure services
  // and is required for customer-managed keys if adopted later.
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // ── Encryption ──────────────────────────────────────────────────────────
    encryption: {
      keySource: 'Microsoft.Storage'        // Microsoft-managed keys.
      requireInfrastructureEncryption: true  // Double encryption (service + infra).
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Account'
        }
        table: {
          enabled: true
          keyType: 'Account'
        }
      }
    }

    // ── Access controls ──────────────────────────────────────────────────────
    minimumTlsVersion: 'TLS1_2'        // Reject legacy TLS.
    supportsHttpsTrafficOnly: true     // No plaintext HTTP.
    allowBlobPublicAccess: false       // No anonymous blob/container access.
    allowSharedKeyAccess: false        // Force Microsoft Entra ID auth (no account keys).
    defaultToOAuthAuthentication: true // Default portal/data-plane auth to Entra ID.
    accessTier: 'Hot'

    // ── Network security ─────────────────────────────────────────────────────
    // publicNetworkAccess + a default-deny firewall. Set both: tools such as
    // Defender for Storage also inspect networkAcls.defaultAction.
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'            // Deny all unless explicitly allowed.
      bypass: 'AzureServices'          // Allow trusted Microsoft services.
      ipRules: []                      // Add allowed public IP ranges here.
      virtualNetworkRules: []          // Add allowed subnet resource IDs here.
    }
  }
}

// Reference to the implicit blob service (needed to scope blob diagnostic logs).
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' existing = {
  parent: storageAccount
  name: 'default'
}

// ─── Diagnostic settings: blob data-plane logs ───────────────────────────────
// Diagnostic settings are an extension resource applied via `scope`. Read/Write/
// Delete logs are captured at the blob service level (not the account level).

resource blobDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'blob-diagnostics'
  scope: blobService
  properties: {
    workspaceId: logAnalytics.id
    logs: [
      {
        category: 'StorageRead'
        enabled: true
      }
      {
        category: 'StorageWrite'
        enabled: true
      }
      {
        category: 'StorageDelete'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// ─── Diagnostic settings: account-level metrics ──────────────────────────────
// Account-scope captures capacity/transaction metrics for the storage account.

resource accountDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'account-diagnostics'
  scope: storageAccount
  properties: {
    workspaceId: logAnalytics.id
    metrics: [
      {
        category: 'Transaction'
        enabled: true
      }
    ]
  }
}

// ─── Outputs ─────────────────────────────────────────────────────────────────

@description('Resource ID of the storage account.')
output storageAccountId string = storageAccount.id

@description('Primary blob endpoint for the storage account.')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('Resource ID of the Log Analytics workspace receiving diagnostics.')
output logAnalyticsWorkspaceId string = logAnalytics.id

@description('Principal ID of the storage account system-assigned identity.')
output storagePrincipalId string = storageAccount.identity.principalId
