# tv-azurevirtualdesktop

## Purpose

Infrastructure as Code repository for the True Value Azure Virtual Desktop.

it deploys the required resources for a full Azure Virtual Desktop environment for use in the True Value environment.

- Host-Pools for each of the three user workloads defiend.
- Azure DevOps Pipelines
- Environment-specific parameter files
- Shared Bicep type and configuration files
- A reusable deployment script

This repository is an infrastructure repository, not an application repository.

## Ownership

| Item                      | Details             |
| ------------------------- | ------------------- |
| Owning Team               | Systems Engineering |
| Technical Owner           | Mitch Jurisch       |
| Operational Support Owner | Operations/SA       |
| SME(s)                    | Mitch Jurisch       |

## Azure Scope

| Item             | Details                   |
| ---------------- | ------------------------- |
| Azure Tenant     | truevalue.onmicrosoft.com |
| Management Group | Corp                      |
| Subscription     | avd-sub-poc, avd-sub-prod |
| Resource Group   | `[resource-group-name]`   |
| Region(s)        | useast                    |
| Environment(s)   | poc, prod                 |

## Repository Structure

```text
.
├── docs/
│   └── deployment.md
├── infra/
│   ├── modules/
│   │   ├── bootstrap
│   │   │    ├── main.bicep
│   │   │    └── poc.bicepparam
│   │   ├── compute/
│   │   │    ├── main.bicep
│   │   │    ├── resources.bicep
│   │   │    └── poc.bicepparam
│   │   ├── network/
│   │   │    └── peering.bicep
│   │   │    └── spoke-vnet.bicep
│   │   ├── serviceobjects/
│   │   │    ├── main.bicep
│   │   │    ├── resources.bicep
│   │   │    └── poc.bicepparam
│   │   └──  storage/
│   │        ├── main.bicep
│   │        ├── resources.bicep
│   │        └── poc.bicepparam
│   ├── parameters/
│   └── shared/
│       ├── naming.bicep
│       ├── config.bicep
│       └── types.bicep
├── pipelines/
│   ├── azure-pipelines-poc.yml
│   ├── azure-pipelines-dev.yml
│   ├── azure-pipelines-test.yml
│   ├── azure-pipelines-prod.yml
│   └── templates/
│       └── bicep-deployment-template.yml
└── scripts/
    └── Invoke-BicepDeployment.ps1
```

## Infrastructure Entry Point

Each Module deploys resources related to its service area.
The deployment flow must occur in this order:

| Order | Stage Name     | Description                                              |
| ----- | -------------- | -------------------------------------------------------- |
| 1     | bootstrap      | creates baseline resources                               |
| 2     | serviceobjects | Shared control Plane resources                           |
| 3     | network        | Builds hub and spoke networking for the AVD subscription |
| 4     | storage        | FsLogix Profile storage resources                        |
| 5     | storage-auth   | Grants proper access to the storage resources            |

## Shared Bicep Files

Shared Bicep types and reusable configuration are stored under:

```text
infra/shared/
```

| File           | Purpose                                                                 |
| -------------- | ----------------------------------------------------------------------- |
| `types.bicep`  | Defines shared type contracts used by templates and modules             |
| `config.bicep` | Defines shared environment mappings, defaults, and naming abbreviations |
| `naming.bicep` | Defines shared naming functions to ensure consistent resource naming    |

## Environment Naming

| Deployment Environment | Azure `Environment` Tag |
| ---------------------- | ----------------------- |
| `poc`                  | `Proof of Concept`      |
| `dev`                  | `Development`           |
| `test`                 | `Stage`                 |
| `prod`                 | `Production`            |

The short deployment environment value is used for:

- Pipeline selection
- Parameter file selection
- Resource naming suffixes
- Deployment targeting

The Azure policy-compliant environment value is used for:

- Azure resource tags
- Governance

## Required Tags

Azure resources deployed from this template must use the standard required tags:

| Tag           | Purpose                                                                 |
| ------------- | ----------------------------------------------------------------------- |
| `Environment` | Identifies the lifecycle stage of the resource                          |
| `Division`    | Identifies the owning VP-level organizational unit                      |
| `Product`     | Identifies the business product or service associated with the resource |

The `Environment` tag should be derived from `environmentName` through the shared environment configuration map.

The `Division` and `Product` values should be consistent across this repository and all resources deployed by it.

Example:

```bicep
param environmentName = 'poc'
param division = 'Information Technology'
param product = 'Azure Virtual Desktop'
```

The deployment should produce tags similar to:

```bicep
{
  Environment: 'Proof Of Concept'
  Division: 'Information Technology'
  Product: 'Azure Virtual Desktop'
}
```

## Workload Name vs. Product Name

`workloadName` and `product` are intentionally separate.

| Parameter      | Meaning                                        | Example     | Used For                             |
| -------------- | ---------------------------------------------- | ----------- | ------------------------------------ |
| `workloadName` | Technical name of the deployable workload      | `order-api` | Resource names and deployment naming |
| `product`      | Approved business product or service tag value | `OMS`       | Azure tags and cost reporting        |

A single product may have multiple workloads.

Example:

```bicep
param workloadName = 'oms-api'
param product = 'OMS'
```

## Parameter Files

Since this repository is broken down into smaller modules, and the configuration must be identical across these modules, much
of the configuration information is stored in the config.bicep file. This is imported into each module to ensure consistency across the
deployment.

Each individual module should have a matching `.bicepparam` file for each environment.

Recommended minimal pattern:

```bicep
using '../main.bicep'

param environmentName = 'dev'
param location = '<azure-region>'
param workloadName = '<workload-name>'
param division = 'Information Technology'
param product = '<product-name>'
param repositoryName = '<repository-name>'
```

Use the appropriate environment value in each parameter file:

| File              | `environmentName` |
| ----------------- | ----------------- |
| `poc.bicepparam`  | `poc`             |
| `dev.bicepparam`  | `dev`             |
| `test.bicepparam` | `test`            |
| `prod.bicepparam` | `prod`            |

Parameter files should not contain secrets, credentials, private keys, or certificate material.

Parameter files are expected to contain deployable values before pipeline execution. The deployment script blocks unreplaced placeholders such as `<workload-name>` or `<product-name>` before calling Azure CLI.

## Pipelines

This repository uses environment-specific Azure DevOps pipeline entry points and a shared pipeline stage template.

| Pipeline                                            | Purpose                                     |
| --------------------------------------------------- | ------------------------------------------- |
| `pipelines/azure-pipelines-poc.yml`                 | POC validation, what-if, and deployment     |
| `pipelines/azure-pipelines-dev.yml`                 | Dev validation, what-if, and deployment     |
| `pipelines/azure-pipelines-test.yml`                | Test validation, what-if, and deployment    |
| `pipelines/azure-pipelines-prod.yml`                | Prod validation, what-if, and deployment    |
| `pipelines/templates/bicep-deployment-template.yml` | Shared Validate, What-if, and Deploy stages |

For detailed deployment steps, approval behavior, rollback guidance, and troubleshooting, see [`docs/deployment.md`](docs/deployment.md).

### POC and Dec Pipelines

The poc and dev pipelines are configured to run on changes to:

- `infra/**`
- `scripts/**`
- `pipelines/**`

Documentation-only changes under `docs/**` are excluded.

### Test and Prod Pipelines

The test and prod pipelines are configured with:

```yaml
trigger: none
pr: none
```

These pipelines are intended to be run manually or through an approved release process.

## Pipeline Stages

The shared pipeline template defines three stages for each module:

| Stage      | Purpose                                           |
| ---------- | ------------------------------------------------- |
| `Validate` | Lints, builds, and validates the Bicep deployment |
| `WhatIf`   | Runs Azure deployment what-if                     |
| `Deploy`   | Creates the Azure deployment                      |

The stages use:

```text
scripts/Invoke-BicepDeployment.ps1
```

## Azure DevOps Environment Approvals

The deployment stage uses an Azure DevOps deployment job with the environment name matching the target environment:

- `dev`
- `test`
- `prod`

Deployment approval requirements are managed through Azure DevOps Environments, not directly in the YAML pipeline.

Recommended environment approval configuration:

| Environment | Approval Requirement                             |
| ----------- | ------------------------------------------------ |
| dev         | Optional                                         |
| test        | Optional or required, depending on workload risk |
| prod        | Required                                         |

For production deployments, configure the `prod` Azure DevOps Environment with required approvers before allowing deployment.

The pipeline itself prevents deployment during pull request validation and only allows deployment from the `main` branch. Environment approvals provide the final manual gate before infrastructure changes are applied.

## Azure DevOps Environment Branch Control

For additional deployment protection, configure Branch control checks on Azure DevOps Environments.

Recommended configuration:

| Environment | Allowed Branches  | Protection Requirement |
| ----------- | ----------------- | ---------------------- |
| poc         | `refs/heads/main` | Optional               |
| dev         | `refs/heads/main` | Optional               |
| test        | `refs/heads/main` | Recommended            |
| prod        | `refs/heads/main` | Required               |

For production deployments, the `prod` environment should require:

- Approval checks
- Branch control limited to `refs/heads/main`
- Branch protection enabled on `main`

This provides defense in depth:

1. Pull request policies control what can merge to `main`.
2. Pipeline YAML prevents deployment from pull request builds.
3. Pipeline YAML limits deployment to `main`.
4. Azure DevOps Environment approvals require human approval before deployment.
5. Azure DevOps Environment branch control prevents deployment from unapproved branches even if the YAML is changed incorrectly.

## Deployment Script

The deployment script supports three actions:

| Action     | Purpose                                               |
| ---------- | ----------------------------------------------------- |
| `Validate` | Runs Bicep lint/build and Azure deployment validation |
| `WhatIf`   | Runs Bicep lint/build and Azure deployment what-if    |
| `Deploy`   | Runs Bicep lint/build and creates the deployment      |

Script path:

```text
scripts/Invoke-BicepDeployment.ps1
```

Common script parameters include:

| Parameter            | Purpose                                    |
| -------------------- | ------------------------------------------ |
| `Action`             | `Validate`, `WhatIf`, or `Deploy`          |
| `ResourceGroupName`  | Target Azure resource group                |
| `TemplateFile`       | Path to `infra/main.bicep`                 |
| `ParameterFile`      | Path to the environment `.bicepparam` file |
| `DeploymentName`     | Optional deployment name                   |
| `ArtifactOutputPath` | Output path for deployment artifacts       |
| `ValidationLevel`    | ARM validation level                       |
| `WhatIfResultFormat` | What-if output format                      |
| `SkipBuild`          | Skips Bicep build                          |
| `SkipLint`           | Skips Bicep lint                           |

The script writes deployment artifacts including:

- `metadata.json`
- `compiled-template.json`
- `<action>-result.json`
- `summary.md`

## Local Validation

From the repository root, run:

```powershell
bicep build .\infra\main.bicep
```

Validate an environment parameter file with Azure CLI:

```powershell
az deployment group validate `
  --resource-group '<resource-group-name>' `
  --template-file '.\infra\main.bicep' `
  --parameters '@.\infra\parameters\dev.bicepparam'
```

Run what-if:

```powershell
az deployment group what-if `
  --resource-group '<resource-group-name>' `
  --template-file '.\infra\main.bicep' `
  --parameters '@.\infra\parameters\dev.bicepparam'
```

Run the repository deployment script locally:

```powershell
.\scripts\Invoke-BicepDeployment.ps1 `
  -Action Validate `
  -ResourceGroupName '<resource-group-name>' `
  -TemplateFile '.\infra\main.bicep' `
  -ParameterFile '.\infra\parameters\dev.bicepparam'
```

## Tooling Requirements

The following tools are expected for local development:

| Tool                    | Purpose                                      |
| ----------------------- | -------------------------------------------- |
| Azure CLI               | Azure authentication and deployment commands |
| Bicep CLI               | Bicep build, lint, and compile               |
| PowerShell 7+           | Running deployment scripts                   |
| Visual Studio Code      | Recommended editor                           |
| Bicep VS Code extension | Bicep language support                       |

Check local Bicep version:

```powershell
bicep --version
```

Check Azure CLI-managed Bicep version:

```powershell
az bicep version
```

Install Azure CLI-managed Bicep if needed:

```powershell
az bicep install
```

Upgrade Azure CLI-managed Bicep:

```powershell
az bicep upgrade
```

## Service Connections

Each environment pipeline requires an Azure DevOps service connection.

| Environment | Service Connection               | Scope     |
| ----------- | -------------------------------- | --------- |
| Poc         | `<dev-service-connection-name>`  | `<scope>` |
| Dev         | `<dev-service-connection-name>`  | `<scope>` |
| Test        | `<test-service-connection-name>` | `<scope>` |
| Prod        | `<prod-service-connection-name>` | `<scope>` |

Service connections must follow least-privilege access principles.

## Deployment Workflow

Recommended workflow:

1. Create a feature branch.
2. Make Bicep, parameter, pipeline, script, or documentation changes.
3. Run local Bicep validation where practical.
4. Open a pull request.
5. Review pipeline validation results.
6. Review what-if output before approving deployments.
7. Merge the pull request.
8. Deploy through the approved Azure DevOps pipeline.

## Security

This repository must not contain:

- Plaintext credentials
- Client secrets
- Private keys
- Certificates
- Unmanaged deployment credentials
- Production-only secrets in parameter files

Approved secret and identity patterns include:

- Azure Key Vault references
- Azure DevOps service connections
- Managed identities
- Approved enterprise secret management systems

## Module Guidance

Reusable Azure resource modules should be stored under:

```text
infra/modules/
```

Modules should:

- Accept required values as parameters
- Accept standard tags from `main.bicep`
- Avoid hardcoded subscription IDs, resource group names, and environment names
- Use shared types where useful
- Keep resource-specific defaults inside the module when appropriate

Example module call pattern:

```bicep
module exampleModule './modules/example.bicep' = {
  name: 'example-${environmentConfig.shortName}'
  params: {
    location: location
    tags: StandardTags
  }
}
```

## Documentation

Additional documentation may be stored under:

```text
docs/
```

Recommended docs include:

| Document                  | Purpose                                           |
| ------------------------- | ------------------------------------------------- |
| `docs/deployment.md`      | Deployment process and environment-specific notes |
| `docs/architecture.md`    | Architecture and design context                   |
| `docs/validation-plan.md` | Validation and testing approach                   |
| `docs/operations.md`      | Operational support notes                         |

## Exceptions

Any exception to the Azure IaC repository standard must be documented and approved before production deployment.

| Item                | Details           |
| ------------------- | ----------------- |
| Exception Required  | `[No]`            |
| Exception Reference | `[link-or-na]`    |
| Approver            | `[name-or-group]` |
