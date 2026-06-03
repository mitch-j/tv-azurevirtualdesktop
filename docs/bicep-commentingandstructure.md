# Bicep Commenting and Structure Policy

## Purpose

Use consistent comments and section ordering in Bicep files so templates are easy to scan, review, and maintain.

Comments should explain intent, ownership, scope, or important design decisions. They should not restate what the code already says.

## Bicep File Header

Each major `.bicep` file must include a short header comment immediately after `targetScope`.

The header must identify:

- The deployment area or module name
- The deployment scope
- What the file deploys or owns
- What the file intentionally does not deploy or own

Example:

```bicep
targetScope = 'subscription'

/*
AVD Deployment / Network

Scope:
- Subscription

Deploys:
- Network resource group
- Spoke virtual network
- Session host subnet
- Private endpoint subnet
- Network security group

Does not deploy:
- Session host virtual machines
- Storage accounts or file shares
- AVD host pools or workspaces
*/
```

The `Scope` value must match the file's `targetScope`.

Use one of these values unless the file requires something more specific:

```bicep
Scope:
- Tenant
```

```bicep
Scope:
- Management Group
```

```bicep
Scope:
- Subscription
```

```bicep
Scope:
- Resource Group
```

This is especially important because this repository uses Azure Verified Modules, and AVM modules may be deployed at different scopes depending on the resource type.

## Standard Section Order

Use these section headings in this order when they apply:

```bicep
// Imports

// Parameters

// Variables

// Existing Resources

// Resources

// Modules

// Role Assignments

// Outputs
```

Omit sections that do not apply. Do not include empty headings.

## Section Comments

Keep section comments short and plain.

Use:

```bicep
// Parameters
```

Avoid decorative separators:

```bicep
// ======================================================
// PARAMETERS
// ======================================================
```

Readable code does not need ASCII scaffolding. This is infrastructure, not a medieval gatehouse.

## Parameter and Output Descriptions

Use `@description()` for parameters unless the purpose is completely obvious.

Use `@description()` for outputs when another module, pipeline, or operator will consume them.

Example:

```bicep
@description('Deployment environment.')
param environment EnvironmentName

@description('Resource ID of the deployed session host subnet.')
output sessionHostSubnetResourceId string = sessionHostSubnet.id
```

## Comment Quality

Good comments explain why something exists, what owns it, or what boundary it enforces.

Good:

```bicep
// Existing Resources

resource existingVirtualNetwork 'Microsoft.Network/virtualNetworks@2025-07-01' existing = {
  name: virtualNetworkName
}
```

```bicep
/*
Does not deploy:
- Hub virtual network
- Reciprocal hub-to-spoke peering
*/
```

Avoid comments that repeat the code.

Bad:

```bicep
// Set the environment config variable.
var environmentConfig = environmentConfigMap[environment]
```

```bicep
// Create the resource group.
module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
```

## Module Responsibility

Each module must make its ownership clear, especially when working with shared infrastructure.

Call out ownership boundaries for resources such as:

- Resource groups
- Virtual networks
- Subnets
- Private endpoints
- Role assignments
- Managed identities
- Key Vaults
- AVD host pools
- Storage accounts
- Session host virtual machines

The goal is to avoid two modules quietly fighting over the same resource like badly managed departments with matching acronyms.

## Azure Verified Modules

When using Azure Verified Modules, comments should describe the resource responsibility, not the AVM implementation.

Good:

```bicep
/*
Deploys:
- Storage resource group
- FSLogix storage account
- Profile container file share
*/
```

Avoid:

```bicep
// Calls the AVM storage account module.
```

The module declaration already shows the AVM call. The comment should explain what the deployment owns and why it exists.

## Naming and Readability

Use descriptive names for resources, modules, variables, and outputs.

Prefer:

```bicep
module storageResourceGroup ...
var storageResourceGroupName ...
output storageAccountResourceId string ...
```

Avoid:

```bicep
module rg ...
var name1 ...
output id string ...
```

Output names should remain clear when consumed by other modules or reviewed in deployment history.

Prefer:

```bicep
output networkResourceGroupName string
output sessionHostSubnetResourceId string
output storageAccountResourceId string
```

Avoid:

```bicep
output resourceGroupName string
output subnetId string
output id string
```

## Minimal Commenting Standard

Use enough comments to make the file easier to understand. Do not comment every line.

Do not comment:

- Basic Bicep syntax
- Obvious assignments
- Information already clear from symbol names

A well-structured Bicep file should have:

- One clear top-level responsibility block
- Consistent section headings
- Parameter and output descriptions
- Occasional comments for non-obvious design decisions

## Bicep Parameter Files

`.bicepparam` files must be easy to review and safe to modify.

Comments should explain:

- Which deployment the file targets
- Which environment the file represents
- Which values are environment-specific
- Which values require coordination with external systems
- Which values must not contain secrets

Do not repeat parameter names or describe obvious values.

## Bicep Parameter File Header

Each `.bicepparam` file must include a short header comment immediately after the `using` statement.

Example:

```bicep
using 'main.bicep'

/*
AVD Deployment / Network Parameters

Environment:
- poc

Used by:
- infra/modules/network/main.bicep

Notes:
- Address spaces must be approved through network/IPAM before deployment.
- Hub VNet peering values must match the enterprise hub network design.
- Do not store secrets, credentials, private keys, or certificate material in this file.
*/
```

## Parameter File Rules

Parameter files may contain environment-specific values, approved configuration, and references to shared naming or deployment conventions.

Parameter files must not contain:

- Passwords
- Client secrets
- Private keys
- Certificates
- Tokens
- Any other secret material

Use Key Vault, managed identities, Azure DevOps service connections, or another approved secret-management pattern instead.

## Review Checklist

Before committing a Bicep or `.bicepparam` file, confirm that:

- The file has the required header
- The scope is accurate
- Section headings are present only where useful
- Parameters and consumed outputs have descriptions
- Module ownership is clear
- Comments explain intent rather than syntax
- Names are descriptive
- Parameter files contain no secrets
