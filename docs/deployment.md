# Deployment Guide

## Overview

This document describes how to validate, review, and deploy Azure infrastructure from this repository.

The repository uses:

- Bicep for Azure Infrastructure as Code
- Environment-specific `.bicepparam` files
- Azure DevOps pipelines
- A shared deployment script
- Azure DevOps Environment approvals/checks for deployment gates

## Deployment Flow

The deployment flow is:

1. Create a feature branch.
2. Update Bicep, parameter files, pipeline files, scripts, or documentation.
3. Run local validation where practical.
4. Open a pull request.
5. Review validation and what-if output.
6. Approve and merge the pull request.
7. Run or allow the main branch pipeline.
8. Review what-if output from the main branch run.
9. Approve the Azure DevOps Environment deployment gate, if required.
10. Validate deployed resources.

## Environments

The standard environments are:

| Environment | Parameter File                     | Azure DevOps Environment |
|-------------|------------------------------------|--------------------------|
| dev         | `infra/parameters/dev.bicepparam`  | `dev`                    |
| test        | `infra/parameters/test.bicepparam` | `test`                   |
| prod        | `infra/parameters/prod.bicepparam` | `prod`                   |

## Pipeline Behavior

Each environment pipeline uses the shared template:

```text
pipelines/templates/bicep-deployment-template.yml
```

The shared template runs three stages:

| Stage    | Purpose                                           |
|----------|---------------------------------------------------|
| Validate | Lints, builds, and validates the Bicep deployment |
| WhatIf   | Runs Azure deployment what-if                     |
| Deploy   | Creates or updates Azure resources                |

The Deploy stage is restricted to:

- Successful previous stages
- The `main` branch
- Non-pull-request builds

Pull request builds should run Validate and WhatIf only.

## Deployment Approvals

Deployment approvals are managed through Azure DevOps Environments.

Recommended configuration:

| Environment | Approval Requirement                             |
|-------------|--------------------------------------------------|
| dev         | Optional                                         |
| test        | Optional or required, depending on workload risk |
| prod        | Required                                         |

Production deployments should require approval on the `prod` Azure DevOps Environment.

## Branch Control

For additional deployment protection, configure Branch control checks on Azure DevOps Environments.

Recommended configuration:

| Environment | Allowed Branches  | Protection Requirement |
|-------------|-------------------|------------------------|
| dev         | `refs/heads/main` | Optional               |
| test        | `refs/heads/main` | Recommended            |
| prod        | `refs/heads/main` | Required               |

This provides defense in depth:

1. Pull request policies control what can merge to `main`.
2. Pipeline YAML prevents deployment from pull request builds.
3. Pipeline YAML limits deployment to `main`.
4. Azure DevOps Environment approvals require human approval before deployment.
5. Azure DevOps Environment branch control prevents deployment from unapproved branches even if the YAML is changed incorrectly.

## Local Validation

Run Bicep lint:

```powershell
az bicep lint --file infra/main.bicep
```

Run Bicep build:

```powershell
az bicep build --file infra/main.bicep
```

Run deployment validation:

```powershell
./scripts/Invoke-BicepDeployment.ps1 `
  -Action Validate `
  -ResourceGroupName '<resource-group-name>' `
  -TemplateFile './infra/main.bicep' `
  -ParameterFile './infra/parameters/dev.bicepparam' `
  -EnsureBicep
```

## What-if Review

Before approving deployment, review the what-if output.

Look for:

- Resources being created
- Resources being modified
- Resources being deleted
- Tag changes
- RBAC changes
- Diagnostic setting changes
- Network/security changes

Any unexpected delete or security-impacting change should be reviewed before deployment proceeds.

## Deployment

Deployments are normally performed by the Azure DevOps pipeline.

Manual local deployment is supported when approved:

```powershell
./scripts/Invoke-BicepDeployment.ps1 `
  -Action Deploy `
  -ResourceGroupName '<resource-group-name>' `
  -TemplateFile './infra/main.bicep' `
  -ParameterFile './infra/parameters/dev.bicepparam' `
  -EnsureBicep
```

Manual production deployments should follow the approved change process.

## Deployment Artifacts

Each stage publishes artifacts containing deployment evidence.

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

## Rollback and Recovery

Bicep deployments are declarative. Rollback usually means restoring the previous known-good template and parameters, then redeploying.

Common recovery options:

- Re-run the deployment after correcting parameters or template issues.
- Revert the pull request and redeploy from `main`.
- Redeploy a previous known-good commit.
- Manually remediate only when approved and documented.

Failed or partial deployments should be reviewed using:

- Azure deployment operation logs
- Pipeline logs
- Published deployment artifacts
- Azure Activity Log

## Troubleshooting

### Placeholder validation failure

Example:

```text
Parameter file contains unreplaced template placeholders
```

Replace the listed placeholder values in the relevant `.bicepparam` file.

### Missing Azure CLI

Example:

```text
Azure CLI was not found on this agent.
```

Install Azure CLI or use an agent image that includes it.

### Missing Bicep CLI

Example:

```text
Azure CLI-managed Bicep is not available.
```

Run with:

```powershell
-EnsureBicep
```

or install Bicep on the build agent.

### Deployment blocked

If deployment does not proceed, check:

- The source branch is `refs/heads/main`.
- The build is not a pull request build.
- Previous stages succeeded.
- Azure DevOps Environment approval is complete.
- Azure DevOps Environment branch control allows the source branch.
