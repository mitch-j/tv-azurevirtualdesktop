# First-Time Setup

## Overview

This checklist should be completed when creating a new Azure Infrastructure as Code repository from this template.

The goal is to replace template placeholders, confirm the Azure deployment target, configure pipeline access, and validate the repository before using it for real infrastructure deployments.

## 1. Update Repository Ownership

Update the ownership information in `README.md`.

Confirm the following values are correct:

| Item                      | Description                                         |
|---------------------------|-----------------------------------------------------|
| Owning Team               | Team responsible for the repository and workload    |
| Technical Owner           | Person or group responsible for technical decisions |
| Operational Support Owner | Team responsible for support after deployment       |
| SME(s)                    | Subject matter experts for the workload             |

## 2. Confirm Azure Scope

Update the Azure scope information in `README.md`.

Confirm these values:

| Item             | Description                                  |
|------------------|----------------------------------------------|
| Azure Tenant     | Target Azure tenant name or ID               |
| Management Group | Target management group, if applicable       |
| Subscription     | Target subscription name or ID               |
| Resource Group   | Target resource group name                   |
| Region(s)        | Azure region or regions used by the workload |
| Environment(s)   | Expected deployment environments             |

## 3. Update Pipeline Variables

Update each environment pipeline:

- `pipelines/azure-pipelines-dev.yml`
- `pipelines/azure-pipelines-test.yml`
- `pipelines/azure-pipelines-prod.yml`

Confirm these values are set correctly:

| Value                    | Description                                                    |
|--------------------------|----------------------------------------------------------------|
| `workloadName`           | Technical workload name used in pipeline and deployment naming |
| `azureServiceConnection` | Azure DevOps service connection used for deployment            |
| `resourceGroupName`      | Target resource group for the environment                      |

The `workloadName` should be short, descriptive, and safe for use in deployment names.

Example:

```yaml
variables:
  workloadName: example-workload
```

## 4. Update Environment Parameter Files

Update each environment parameter file:

- `infra/parameters/dev.bicepparam`
- `infra/parameters/test.bicepparam`
- `infra/parameters/prod.bicepparam`

Replace all placeholder values, including:

- `<azure-region>`
- `<repository-name>`
- `<product-name>`
- `<workload-name>`

Example pattern:

```bicep
using '../main.bicep'

param environmentName = 'dev'
param location = 'eastus'
param repositoryName = 'example-iac-repo'
param division = 'Information Technology'
param product = 'ExampleProduct'
param workloadName = 'example-workload'
```

## 5. Confirm Valid Division Value

The `division` parameter must use one of the approved values from `infra/shared/types.bicep`.

Common example:

```bicep
param division = 'Information Technology'
```

Do not leave this as a placeholder value.

## 6. Confirm Required Tags

The deployment should produce the standard required tags:

| Tag           | Source                                                                  |
|---------------|-------------------------------------------------------------------------|
| `Environment` | Derived from `environmentName` through shared environment configuration |
| `Division`    | Supplied by the environment parameter file                              |
| `Product`     | Supplied by the environment parameter file                              |

Confirm that `product` uses the approved business product or service name expected for cost reporting and governance.

## 7. Configure Azure DevOps Environments

Create or verify Azure DevOps Environments matching the deployment environment names:

- `dev`
- `test`
- `prod`

Recommended approval configuration:

| Environment | Approval Requirement                             |
|-------------|--------------------------------------------------|
| `dev`       | Optional                                         |
| `test`      | Optional or required, depending on workload risk |
| `prod`      | Required                                         |

Production deployments should require approval on the `prod` environment.

## 8. Configure Azure DevOps Environment Branch Control

For additional deployment protection, configure Branch control checks on Azure DevOps Environments.

Recommended configuration:

| Environment | Allowed Branches  | Protection Requirement |
|-------------|-------------------|------------------------|
| `dev`       | `refs/heads/main` | Optional               |
| `test`      | `refs/heads/main` | Recommended            |
| `prod`      | `refs/heads/main` | Required               |

For production deployments, the `prod` environment should require:

- Approval checks
- Branch control limited to `refs/heads/main`
- Branch protection enabled on `main`

## 9. Confirm Service Connections

Each environment pipeline requires an Azure DevOps service connection.

Confirm that each service connection:

- Exists in Azure DevOps
- Has the minimum required Azure permissions
- Targets the correct subscription or resource group scope
- Is approved for use by the pipeline
- Does not use unnecessary broad permissions

Recommended service connection scope should follow least-privilege access principles.

## 10. Validate Bicep Locally

Run Bicep lint:

```powershell
az bicep lint --file infra/main.bicep
```

Run Bicep build:

```powershell
az bicep build --file infra/main.bicep
```

Both commands should complete successfully before opening a pull request.

## 11. Run Deployment Validation Locally

Run the deployment script in validation mode:

```powershell
./scripts/Invoke-BicepDeployment.ps1 `
  -Action Validate `
  -ResourceGroupName '<resource-group-name>' `
  -TemplateFile './infra/main.bicep' `
  -ParameterFile './infra/parameters/dev.bicepparam' `
  -EnsureBicep
```

Replace `<resource-group-name>` with the target development resource group.

## 12. Confirm Placeholder Validation Passes

The deployment script intentionally fails when unreplaced placeholders remain.

Example failure:

```text
Parameter file contains unreplaced template placeholders: <workload-name>, <product-name>
```

If this occurs, replace the listed placeholder values before continuing.

Do not bypass placeholder validation for real deployments.

## 13. Run the Pipeline

After local validation succeeds:

1. Create a feature branch.
2. Make the required Bicep, parameter, pipeline, script, or documentation changes.
3. Open a pull request.
4. Confirm the pipeline runs `Validate` and `WhatIf`.
5. Review the what-if output.
6. Merge to `main` after approval.
7. Approve deployment through the Azure DevOps Environment gate, if required.

Pull request builds should not deploy infrastructure.

## 14. Review Deployment Artifacts

Pipeline stages publish deployment artifacts for review and evidence.

Typical artifacts include:

- `metadata.json`
- `compiled-template.json`
- `validate-result.json`
- `whatif-result.json`
- `deploy-result.json`
- `summary.md`

Artifact names include the environment and stage, such as:

- `dev-bicep-validate`
- `dev-bicep-whatif`
- `dev-bicep-deploy`
- `prod-bicep-validate`
- `prod-bicep-whatif`
- `prod-bicep-deploy`

## 15. Update Supporting Documentation

Update supporting documentation as needed:

- `docs/architecture.md`
- `docs/implementation-plan.md`
- `docs/validation-plan.md`
- `docs/deployment.md`

At minimum, confirm that ownership, scope, deployment expectations, validation requirements, and operational support details are accurate before production deployment.

## Completion Criteria

First-time setup is complete when:

- Repository ownership is documented.
- Azure scope is confirmed.
- Pipeline variables are updated.
- Environment parameter files contain real deployable values.
- Azure DevOps service connections are configured.
- Azure DevOps Environment approvals/checks are configured.
- Bicep lint and build succeed.
- Deployment validation succeeds.
- Pull request validation runs successfully.
- What-if output has been reviewed.
- Production deployment gates are configured before any production deployment.
