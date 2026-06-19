# Preflight Validation Report

## Summary

| Field | Value |
|-------|-------|
| Status | ⚠️ Incomplete — required tooling unavailable in this environment |
| Timestamp | 2026-06-19 |
| Template validated | `lab07/main.bicep` |
| Project type | Standalone Bicep (no `azure.yaml`) |
| Target scope | `resourceGroup` (no `targetScope` declared → default) |
| Parameter file | None detected (`main.bicepparam` / `main.parameters.json` absent) |

Bicep syntax validation and what-if analysis **could not be executed** because the
Azure CLI, Azure Developer CLI, and Bicep CLI are not installed on this machine.
A static review of the template was performed instead. Run the commands in
[Recommendations](#recommendations) on a machine with the tooling (or via the
`validate-iac` CI job) to complete the preflight.

## Tools Executed

| Tool | Required Version | Status | Result |
|------|------------------|--------|--------|
| `bicep` | latest | ❌ NOT INSTALLED | `bicep build` skipped |
| `az` | 2.76.0+ | ❌ NOT INSTALLED | `az deployment group what-if` skipped |
| `azd` | latest | ❌ NOT INSTALLED | n/a (not an azd project) |

No validation commands completed. CI note: the repository workflow
`.github/workflows/lab07-supply-chain.yml` already runs
`az bicep build --file lab07/main.bicep` in the `validate-iac` job, which will
perform the syntax validation automatically on push/PR.

## Issues

### Errors
- **Tooling unavailable (blocking):** `bicep`, `az`, and `azd` are not on PATH, so
  syntax compilation and what-if preview cannot run locally.
  - Remediation: install Azure CLI (`winget install Microsoft.AzureCLI`) and Bicep
    (`az bicep install`), or rely on the CI `validate-iac` job.
- **Not authenticated:** No active Azure session detected (`az` absent).
  - Remediation: `az login` and `az account set --subscription <id>` before what-if.

### Warnings (from static review)
- **Missing required inputs for what-if:** no resource group, subscription, or
  parameter file is defined. `storageAccountName` is a required parameter with no
  default and must be supplied at deploy time.
- **No parameter file:** consider adding `main.bicepparam` for repeatable deploys.
- **Account unreachable post-deploy:** `publicNetworkAccess: 'Disabled'` +
  `networkAcls.defaultAction: 'Deny'` with no private endpoint or IP/VNet rules
  means no client can reach the account until connectivity is added.
- **Microsoft-managed keys only:** `keySource: 'Microsoft.Storage'`. For a
  compliance posture, consider customer-managed keys (the system-assigned
  identity is already provisioned to support this).
- **No blob data-protection:** soft-delete, container soft-delete, and versioning
  are not configured (the `blobServices` resource is declared `existing`).

## What-If Results

What-if analysis was **not executed** (Azure CLI unavailable). Based on a static
read of the template, a successful deployment to an empty resource group would
create the following resources:

| Change | Resource | Type |
|--------|----------|------|
| `+` Create | `<storageAccountName>-law` | `Microsoft.OperationalInsights/workspaces` |
| `+` Create | `<storageAccountName>` | `Microsoft.Storage/storageAccounts` |
| `+` Create | `blob-diagnostics` | `Microsoft.Insights/diagnosticSettings` (scope: blob service) |
| `+` Create | `account-diagnostics` | `Microsoft.Insights/diagnosticSettings` (scope: account) |

> The `blobServices` `default` resource is referenced as `existing` and is not
> created or modified by this template.

Actual create/modify/delete results must be confirmed by running what-if against
the target resource group.

## Recommendations

1. **Install tooling**, then validate syntax:
   ```bash
   az bicep install
   az bicep build --file lab07/main.bicep --stdout
   ```
2. **Authenticate and run what-if** at resource group scope:
   ```bash
   az login
   az account set --subscription <subscription-id>
   az deployment group what-if \
     --resource-group <rg-name> \
     --template-file lab07/main.bicep \
     --parameters storageAccountName=<globally-unique-name> \
     --validation-level Provider
   ```
   If RBAC errors occur, fall back to `--validation-level ProviderNoRbac` and note
   that the account may lack full deployment permissions.
3. **Add a parameter file** (`lab07/main.bicepparam`) to make deployments
   repeatable and to satisfy the required `storageAccountName` input.
4. **Plan connectivity** before deploying: add a private endpoint or IP/VNet
   allow-rules, otherwise the account is unreachable.
5. **Re-run this preflight** after the above to capture real what-if output, or
   let the `validate-iac` CI job perform syntax validation on push/PR.
