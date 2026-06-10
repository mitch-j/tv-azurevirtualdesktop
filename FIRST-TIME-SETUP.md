# First-Time Setup Checklist

<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ul>
    <li><a href="#overview">Overview</a></li>
    <li>
      <a href=#procedure>First Time Procedure</a>
      <ol>
        <li><a href="#1.-plan-the-repository">Plan the Repository</a></li>
      </ol>
  </ul>
</details>

## Overview

Use this checklist when creating a new Azure Infrastructure as Code repository from this template.

The checklist covers the minimum setup required to turn the template into a deployable, governed IaC repository.

For detailed guidance, naming examples, environment selection rules, service connection setup, and approval standards, see the related Infrastructure Wiki articles.

## 1. Plan the Repository

Confirm the basic repository decisions before creating the new repo.

### Checklist

- [ ] Confirm the workload or service this repository will manage.
- [ ] Confirm the target tenant.
- [ ] Confirm the Azure DevOps project.
- [ ] Confirm the repository name.
- [ ] Confirm the supported environments.
- [ ] Confirm the Azure deployment scope.
- [ ] Confirm the preferred service connection scope.
- [ ] Confirm the repository owner.
- [ ] Confirm the resource owner.
- [ ] Confirm whether this repository deploys new resources or adds to an existing resource area.
- [ ] Confirm whether any exceptions are required.

### Output of This Step

- Workload or service is known.
- Tenant and Azure DevOps project are selected.
- Repository name is approved.
- Environments and deployment scope are known.
- Ownership and exception requirements are understood.

## 2. Create the Repository from the Template

Create the new Azure DevOps repository after planning is complete.

This process is currently manual, but should eventually be automated.

### Checklist

- [ ] Create the repository in the correct Azure DevOps project.
- [ ] Use this template repository as the starting point.
- [ ] Confirm the repository name matches the approved name.
- [ ] Clone the new repository locally.
- [ ] Create a setup branch for initial configuration changes.
- [ ] Confirm the expected template files are present.

### Recommended Setup Branch

```powershell
git checkout -b setup/initial-repository-configuration
```

### Output of This Step

- Repository exists in Azure DevOps.
- Repository is cloned locally.
- Setup branch is created.
- Template files are ready to customize.

## 3. Replace the Repository README

Replace the default template repository README with the IaC repository README template.

### Checklist

- [ ] Rename the existing `README.md` to `README.old.md`.
- [ ] Rename `README.template.md` to `README.md`.
- [ ] Update the new `README.md` using the decisions from Step 1.
- [ ] Search the new `README.md` for placeholder values.
- [ ] Replace placeholders that apply to the repository.
- [ ] Remove or adjust sections that do not apply to the workload.
- [ ] Confirm the new `README.md` describes the IaC deployment repository, not the template repository.
- [ ] Delete `README.old.md` when it is no longer needed for reference.

### Search for Placeholders

```powershell
Select-String -Path .\README.md -Pattern '<[^>]+>'
```

### Output of This Step

- `README.md` is based on `README.template.md`.
- README contains repository-specific values.
- Original template README is preserved temporarily as `README.old.md`.

## 4. Update Repository Ownership

Update ownership details in `README.md` and any supporting documentation.

### Checklist

- [ ] Confirm the owning team.
- [ ] Confirm the technical owner.
- [ ] Confirm the operational support owner.
- [ ] Confirm any workload SMEs.
- [ ] Confirm whether repository ownership and resource ownership are the same.
- [ ] Update the ownership sections in `README.md`.
- [ ] Update supporting documentation if ownership details are repeated elsewhere.

### Ownership Fields

| Item                      | Description                                                    |
|---------------------------|----------------------------------------------------------------|
| Owning Team               | Team responsible for the repository and workload.              |
| Technical Owner           | Person or group responsible for technical decisions.           |
| Operational Support Owner | Team responsible for support after deployment.                 |
| SME(s)                    | Subject matter experts for the workload or deployed resources. |

### Output of This Step

- Repository ownership is documented.
- Technical decision ownership is documented.
- Operational support ownership is documented.
- Ownership differences between the repo and deployed resources are understood.

## 5. Confirm Azure Scope

Confirm the Azure target for the repository before configuring parameters, pipelines, and service connections.

### Checklist

- [ ] Confirm the Azure tenant.
- [ ] Confirm the management group, if applicable.
- [ ] Confirm the subscription.
- [ ] Confirm the deployment scope.
- [ ] Confirm the target resource group or resource groups.
- [ ] Confirm the Azure region or regions.
- [ ] Confirm whether the deployment requires resource group, subscription, management group, or tenant scope.
- [ ] Confirm whether the selected scope requires an exception or approval.

### Azure Scope Fields

| Item             | Description                                                |
|------------------|------------------------------------------------------------|
| Azure Tenant     | Target Azure tenant name or ID.                            |
| Management Group | Target management group, if applicable.                    |
| Subscription     | Target subscription name or ID.                            |
| Deployment Scope | Scope used by the Bicep deployment.                        |
| Resource Group   | Target resource group name, if using resource group scope. |
| Region(s)        | Azure region or regions used by the workload.              |

### Output of This Step

- Azure tenant is confirmed.
- Subscription and resource group targets are known.
- Deployment scope is documented.
- Scope exceptions or approvals are identified.

## 6. Configure Supported Environments

Confirm which environments this repository supports and remove or add environment files as needed.

### Checklist

- [ ] Confirm the supported deployment environments.
- [ ] Update the environment list in `README.md`.
- [ ] Confirm each supported environment has a matching parameter file.
- [ ] Confirm each supported environment has a matching pipeline file, if needed.
- [ ] Remove parameter files for unsupported environments.
- [ ] Remove pipeline files for unsupported environments.
- [ ] Add parameter or pipeline files for additional supported environments, if needed.
- [ ] Confirm environment names match the approved short names.

### Supported Environments

| Deployment Environment | Azure `Environment` Tag | Environment Code |
|------------------------|-------------------------|------------------|
| `dev`                  | `Development`           | `d`              |
| `devstage`             | `Dev/Stage`             | `t`              |
| `stage`                | `Stage`                 | `s`              |
| `prod`                 | `Production`            | `p`              |
| `e2e`                  | `End to End`            | `e`              |
| `poc`                  | `Proof of Concept`      | `x`              |
| `dr`                   | `Disaster Recovery`     | `r`              |
| `shared`               | `Shared`                | `h`              |

### Expected File Pattern

| Environment | Parameter File                         | Pipeline File                            |
|-------------|----------------------------------------|------------------------------------------|
| `dev`       | `infra/parameters/dev.bicepparam`      | `pipelines/azure-pipelines-dev.yml`      |
| `devstage`  | `infra/parameters/devstage.bicepparam` | `pipelines/azure-pipelines-devstage.yml` |
| `stage`     | `infra/parameters/stage.bicepparam`    | `pipelines/azure-pipelines-stage.yml`    |
| `prod`      | `infra/parameters/prod.bicepparam`     | `pipelines/azure-pipelines-prod.yml`     |
| `e2e`       | `infra/parameters/e2e.bicepparam`      | `pipelines/azure-pipelines-e2e.yml`      |
| `poc`       | `infra/parameters/poc.bicepparam`      | `pipelines/azure-pipelines-poc.yml`      |
| `dr`        | `infra/parameters/dr.bicepparam`       | `pipelines/azure-pipelines-dr.yml`       |
| `shared`    | `infra/parameters/shared.bicepparam`   | `pipelines/azure-pipelines-shared.yml`   |

### Output of This Step

- Supported environments are documented.
- Parameter files match the supported environments.
- Pipeline files match the supported environments.
- Unsupported environment files are removed or intentionally retained.

## 7. Configure Deployment Values

Configure the repository values used by Bicep deployments.

Decide whether shared values should live in `infra/commonConfig.bicep` or directly in the environment parameter files.

### Checklist

- [ ] Decide whether this repository should use `infra/commonConfig.bicep`.
- [ ] If using `infra/commonConfig.bicep`, update it with shared repository values.
- [ ] If not using `infra/commonConfig.bicep`, define required values in the environment parameter files.
- [ ] Confirm each supported environment has a matching `.bicepparam` file.
- [ ] Remove parameter files for unsupported environments.
- [ ] Update each parameter file with required environment-specific values.
- [ ] Confirm each parameter file uses the correct `environment` value.
- [ ] Add workload-specific configuration under `infra/workloads/`, if needed.
- [ ] Do not modify files under `infra/base/` during first-time setup.
- [ ] Confirm no secrets or credentials are stored in Bicep configuration or parameter files.
- [ ] Confirm no template placeholders remain.

### Configuration Locations

| Location                        | Use For                                                                                 |
|---------------------------------|-----------------------------------------------------------------------------------------|
| `infra/commonConfig.bicep`      | Shared values reused across multiple modules, deployments, or parameter files.          |
| `infra/parameters/*.bicepparam` | Environment-specific values and smaller deployments where common config is unnecessary. |
| `infra/workloads/`              | Workload-specific configuration, types, naming helpers, or overrides.                   |
| `infra/base/`                   | Standard shared configuration, naming, and types. Treat as read-only.                   |

### Search for Placeholders

```powershell
Select-String -Path .\infra\*.bicep,.\infra\parameters\*.bicepparam,.\infra\workloads\* -Pattern '<[^>]+>'
```

### Output of This Step

- Deployment values are defined in the appropriate location.
- Parameter files exist for supported environments.
- Unsupported parameter files are removed.
- Base Bicep files remain unchanged.
- Workload-specific configuration is placed under `infra/workloads/`, if required.
- No secrets or unresolved placeholders remain.

## 8. Configure Pipeline Variables

Update pipeline variables for each supported environment.

### Checklist

- [ ] Confirm each supported environment has a matching pipeline file, if needed.
- [ ] Remove pipeline files for unsupported environments.
- [ ] Confirm each pipeline uses the correct environment name.
- [ ] Confirm each pipeline uses the correct parameter file.
- [ ] Confirm each pipeline uses the correct Azure service connection.
- [ ] Confirm each pipeline uses the correct resource group.
- [ ] Confirm each pipeline uses the correct validation level.
- [ ] Confirm each pipeline uses the correct what-if result format.
- [ ] Confirm pull request builds do not deploy infrastructure.
- [ ] Confirm deployment stages only run from approved branches.

### Current Pipeline Files

| Environment | Pipeline File                         | Default Behavior                                              |
|-------------|---------------------------------------|---------------------------------------------------------------|
| `dev`       | `pipelines/azure-pipelines-dev.yml`   | Runs on changes to `main` and pull requests targeting `main`. |
| `stage`     | `pipelines/azure-pipelines-stage.yml` | Manual only.                                                  |
| `prod`      | `pipelines/azure-pipelines-prod.yml`  | Manual only.                                                  |

### Common Pipeline Values

| Value                    | Description                                                        |
|--------------------------|--------------------------------------------------------------------|
| `workloadName`           | Workload name used in pipeline and deployment naming.              |
| `azureServiceConnection` | Azure DevOps service connection used for deployment.               |
| `environmentName`        | Short deployment environment name passed to the pipeline template. |
| `resourceGroupName`      | Target resource group for the deployment.                          |
| `validationLevel`        | ARM validation level.                                              |
| `whatIfResultFormat`     | What-if output format.                                             |

### Output of This Step

- Pipeline files match the supported environments.
- Pipeline variables point to the correct Azure targets.
- Pipeline variables point to the correct parameter files.
- Pull request builds validate but do not deploy.
- Deployments are limited to approved branches.

## 9. Create or Confirm Service Connection Identity

Create or confirm the Azure identity used by the Azure DevOps service connection.

For detailed setup instructions, see the Infrastructure Wiki article:

```text
Create Azure DevOps Service Connections for IaC Deployments
```

### Checklist

- [ ] Confirm the identity type used by the service connection.
- [ ] Confirm the identity follows the approved naming pattern.
- [ ] Prefer Workload Identity Federation over client secrets.
- [ ] Create or confirm the required app registration, service principal, managed identity, or federated credential.
- [ ] Confirm the identity exists in the correct tenant.
- [ ] Assign the identity the minimum required Azure RBAC role.
- [ ] Assign access at the narrowest practical scope.
- [ ] Prefer resource group scope when possible.
- [ ] Document and approve subscription, management group, or tenant scoped access.
- [ ] Confirm credentials, secrets, certificates, or private keys are not stored in the repository.
- [ ] Record the identity name and Azure scope for service connection setup.

### Naming Pattern

```text
<repo-or-workload>-<scope>-<environment>-<action>-<resource-abbreviation>
```

Examples:

```text
tv-avd-rg-poc-deploy-app
tv-avd-rg-shared-deploy-app
tv-azure-landing-zones-sub-prod-plan-id
tv-azure-landing-zones-sub-prod-apply-id
```

### Output of This Step

- Service connection identity exists.
- Identity name follows the approved naming pattern.
- Identity uses an approved authentication method.
- Identity is scoped to the correct Azure target.
- Identity has the minimum required permissions.
- Broader access is documented and approved.

## 10. Confirm Azure DevOps Service Connections

Confirm that each pipeline uses the correct Azure DevOps service connection.

For detailed setup instructions, see the Infrastructure Wiki article:

```text
Create Azure DevOps Service Connections for IaC Deployments
```

### Checklist

- [ ] Confirm each supported environment has an Azure DevOps service connection.
- [ ] Confirm each service connection follows the approved naming pattern.
- [ ] Confirm each service connection name matches the pipeline variable value.
- [ ] Confirm each service connection uses the approved identity.
- [ ] Confirm each service connection targets the correct tenant.
- [ ] Confirm each service connection targets the correct subscription.
- [ ] Confirm each service connection uses the narrowest practical scope.
- [ ] Confirm resource group scoped service connections are used when possible.
- [ ] Confirm broader service connection scopes are approved, if required.
- [ ] Confirm each service connection is authorized only for required pipelines.
- [ ] Confirm unnecessary permissions have not been granted.

### Naming Pattern

```text
<repo-or-workload>-<scope>-<environment>-<action>-sc
```

Examples:

```text
tv-avd-rg-poc-deploy-sc
tv-avd-rg-shared-deploy-sc
tv-azure-landing-zones-sub-prod-plan-sc
tv-azure-landing-zones-sub-prod-apply-sc
```

### Output of This Step

- Required service connections exist.
- Service connection names follow the approved naming pattern.
- Service connection names match the pipeline files.
- Service connections use the approved identity.
- Service connections target the correct Azure scope.
- Service connections use least-privilege permissions where possible.
- Broader permissions are documented and approved.

## 11. Configure Azure DevOps Environments

Create or confirm Azure DevOps Environments for each supported deployment environment.

### Checklist

- [ ] Confirm each supported deployment environment has a matching Azure DevOps Environment.
- [ ] Confirm Azure DevOps Environment names follow the approved naming pattern.
- [ ] Confirm Azure DevOps Environment names match the pipeline environment values.
- [ ] Configure approvals where required.
- [ ] Configure checks where required.
- [ ] Confirm production deployments require approval.
- [ ] Confirm approval ownership matches the documented operational ownership.
- [ ] Confirm deployment history is visible through the Azure DevOps Environment.

### Naming Pattern

For most repositories, use the short deployment environment name:

```text
<environment>
```

Examples:

```text
dev
stage
prod
poc
shared
```

If the Azure DevOps project contains multiple deployment domains that need separate approval paths, use:

```text
<repo-or-workload>-<environment>
```

Examples:

```text
avd-prod
private-dns-shared
aks-platform-stage
```

### Expected Environment Names

| Deployment Environment | Default Azure DevOps Environment |
|------------------------|----------------------------------|
| `dev`                  | `dev`                            |
| `devstage`             | `devstage`                       |
| `stage`                | `stage`                          |
| `prod`                 | `prod`                           |
| `e2e`                  | `e2e`                            |
| `poc`                  | `poc`                            |
| `dr`                   | `dr`                             |
| `shared`               | `shared`                         |

### Recommended Approval Requirements

| Environment | Approval Requirement                        |
|-------------|---------------------------------------------|
| `dev`       | Optional                                    |
| `devstage`  | Optional or required based on workload risk |
| `stage`     | Optional or required based on workload risk |
| `prod`      | Required                                    |
| `e2e`       | Optional or required based on workload risk |
| `poc`       | Optional                                    |
| `dr`        | Required if production-impacting            |
| `shared`    | Required if production-impacting            |

### Output of This Step

- Azure DevOps Environments exist for supported environments.
- Environment names match pipeline environment values.
- Required approvals and checks are configured.
- Production-impacting deployments require approval.

## 12. Configure Branch Protection and Environment Checks

Configure branch protection and Azure DevOps Environment checks for deployment safety.

### Checklist

- [ ] Confirm branch protection is enabled on `main`.
- [ ] Confirm pull requests are required before merging to `main`.
- [ ] Confirm required reviewers are configured, if needed.
- [ ] Confirm required pipeline validation is configured, if needed.
- [ ] Confirm direct pushes to `main` are restricted.
- [ ] Confirm Azure DevOps Environment branch control checks are configured, if required.
- [ ] Confirm production deployments are limited to `refs/heads/main`.
- [ ] Confirm stage, shared, and disaster recovery branch rules match the workload risk.
- [ ] Confirm environment checks align with the approval requirements from Step 11.

### Recommended Branch Control

| Environment | Allowed Branches  | Recommendation                   |
|-------------|-------------------|----------------------------------|
| `dev`       | `refs/heads/main` | Optional                         |
| `devstage`  | `refs/heads/main` | Recommended                      |
| `stage`     | `refs/heads/main` | Recommended                      |
| `prod`      | `refs/heads/main` | Required                         |
| `e2e`       | `refs/heads/main` | Optional or recommended          |
| `poc`       | `refs/heads/main` | Optional                         |
| `dr`        | `refs/heads/main` | Required if production-impacting |
| `shared`    | `refs/heads/main` | Required if production-impacting |

### Output of This Step

- `main` branch protection is configured.
- Pull request requirements are configured.
- Deployment branch control checks are configured where required.
- Production-impacting deployments are limited to approved branches.

## 13. Run Local Validation

Run local validation before opening a pull request.

At this stage, `infra/main.bicep` may only validate and output incoming parameter values. This is expected. The goal is to confirm the initialized repository is valid, parameterized correctly, and free of unresolved placeholders.

For detailed validation guidance, see the Infrastructure Wiki article:

```text
Azure - IaC Validation and What-If Process
```

### Checklist

- [ ] Confirm Azure CLI is installed.
- [ ] Confirm Bicep CLI is installed.
- [ ] Sign in to the correct Azure tenant.
- [ ] Set the correct Azure subscription.
- [ ] Confirm the target resource group exists, if using resource group scope.
- [ ] Run local validation using `scripts/Invoke-BicepDeployment.ps1`.
- [ ] Confirm validation uses the correct parameter file.
- [ ] Confirm validation uses the correct deployment scope.
- [ ] Confirm no unresolved placeholders remain.
- [ ] Confirm output values match the expected repository, workload, environment, and tag values.
- [ ] Resolve validation errors before opening a pull request.

### Example Validation

```powershell
.\scripts\Invoke-BicepDeployment.ps1 `
  -Action Validate `
  -ResourceGroupName "<resource-group-name>" `
  -TemplateFile ".\infra\main.bicep" `
  -ParameterFile ".\infra\parameters\dev.bicepparam"
```

### Optional What-If

Run what-if if the repository already contains deployable resources.

```powershell
.\scripts\Invoke-BicepDeployment.ps1 `
  -Action WhatIf `
  -ResourceGroupName "<resource-group-name>" `
  -TemplateFile ".\infra\main.bicep" `
  -ParameterFile ".\infra\parameters\dev.bicepparam"
```

### Output of This Step

- Local validation succeeds.
- Parameter files are valid.
- Placeholder validation passes.
- Output values match the expected setup decisions.
- The repository is ready for the initial pull request.

## 14. Open a Pull Request

Open a pull request for the initial repository setup changes.

### Checklist

- [ ] Confirm local validation completed successfully.
- [ ] Confirm setup changes are committed to a short-lived setup or feature branch.
- [ ] Push the branch to Azure DevOps.
- [ ] Open a pull request into `main`.
- [ ] Confirm the pull request title clearly identifies the setup work.
- [ ] Confirm the pull request description summarizes the repository setup decisions.
- [ ] Confirm reviewers are assigned.
- [ ] Confirm required pipeline validation runs.
- [ ] Confirm pull request validation does not deploy infrastructure.
- [ ] Resolve review comments before merging.

### Recommended Branch Names

| Branch Type | Pattern                                   | Use When                                                          |
|-------------|-------------------------------------------|-------------------------------------------------------------------|
| Setup       | `setup/<short-description>`               | Initial repository setup work.                                    |
| Feature     | `feature/<ticket-id>-<short-description>` | Planned infrastructure changes.                                   |
| Hotfix      | `hotfix/<ticket-id>-<short-description>`  | Urgent production-impacting fixes.                                |
| Release     | `release/<version>`                       | Optional. Use only when formal release stabilization is required. |

### Suggested Pull Request Title

```text
Initialize Azure IaC repository
```

### Suggested Pull Request Summary

```text
Initializes the Azure Infrastructure as Code repository from the approved template.

Includes:
- Repository README setup
- Ownership and Azure scope documentation
- Supported environment configuration
- Deployment parameter setup
- Pipeline variable configuration
- Service connection references
- Azure DevOps Environment and branch protection expectations
- Local validation results
```

### Output of This Step

- Setup or feature branch is pushed.
- Pull request is open against `main`.
- Reviewers are assigned.
- Pipeline validation has started.
- Pull request does not deploy infrastructure.

## 15. Review Pull Request Validation

Review the pull request validation results before merging.

### Checklist

- [ ] Confirm the pull request validation pipeline completed successfully.
- [ ] Confirm Bicep build validation passed.
- [ ] Confirm deployment validation passed.
- [ ] Confirm placeholder validation passed.
- [ ] Confirm the correct parameter file was used.
- [ ] Confirm the correct Azure service connection was used.
- [ ] Confirm the correct deployment scope was used.
- [ ] Confirm what-if output was reviewed, if generated.
- [ ] Confirm no unexpected destructive changes are shown.
- [ ] Confirm the pull request did not deploy infrastructure.
- [ ] Resolve failed checks or review comments before merging.

### Output of This Step

- Pull request validation succeeds.
- Validation output has been reviewed.
- What-if output has been reviewed, if generated.
- No unexpected deployment behavior is present.
- Pull request is ready to merge.

## 16. Merge the Initial Setup Pull Request

Merge the initial setup pull request after validation and review are complete.

### Checklist

- [ ] Confirm all pull request comments are resolved.
- [ ] Confirm required reviewers have approved.
- [ ] Confirm required validation checks have passed.
- [ ] Confirm no unresolved placeholders remain.
- [ ] Confirm no unexpected what-if results are present, if what-if was generated.
- [ ] Squash merge the setup branch into `main`.
- [ ] Delete the setup branch after merge, if appropriate.

### Output of This Step

- Initial setup changes are merged into `main`.
- Setup branch is deleted or intentionally retained.
- Repository setup is now part of the protected main branch history.

## 17. Run the First Post-Merge Pipeline

Run or verify the first pipeline execution from `main`.

### Checklist

- [ ] Confirm the `dev` pipeline runs automatically after merge, if configured.
- [ ] Confirm the pipeline uses the expected service connection.
- [ ] Confirm the pipeline uses the expected parameter file.
- [ ] Confirm the pipeline uses the expected Azure DevOps Environment.
- [ ] Confirm validation completes successfully.
- [ ] Confirm what-if output is reviewed, if generated.
- [ ] Confirm deployment does not run unless expected and approved.
- [ ] Confirm pipeline artifacts are published.

### Output of This Step

- First post-merge pipeline run succeeds.
- Pipeline behavior matches the repository standard.
- Pipeline artifacts are available for review.
- No unexpected deployment behavior occurred.

## 18. Finalize Documentation and Cleanup

Clean up temporary setup files and confirm repository documentation is accurate.

### Checklist

- [ ] Delete `README.old.md` if it is no longer needed.
- [ ] Confirm `README.md` describes the new IaC repository.
- [ ] Confirm supporting documentation under `docs/` is accurate.
- [ ] Confirm ownership, scope, environments, and service connection expectations are documented.
- [ ] Move `FIRST-TIME-SETUP.md` to `docs/FIRST-TIME-SETUP.completed.md`.
- [ ] Add a completion note to `docs/FIRST-TIME-SETUP.completed.md`.
- [ ] Remove unused template files or examples that do not apply.
- [ ] Confirm no temporary setup notes remain in production-facing documentation.

### Completion Note

Add a note near the top of the archived checklist:

```markdown
> This checklist was completed during initial repository setup and is retained for historical reference.
```

### Output of This Step

- Temporary setup files are removed.
- Completed setup checklist is archived under `docs/`.
- Repository documentation is accurate.
- Supporting docs match the initialized repository.

## 19. Confirm Setup Completion

Confirm the repository is ready for infrastructure development.

### Completion Criteria

- [ ] Repository planning decisions are documented.
- [ ] Repository exists in the correct Azure DevOps project.
- [ ] `README.md` is based on `README.template.md`.
- [ ] Ownership is documented.
- [ ] Azure scope is documented.
- [ ] Supported environments are configured.
- [ ] Deployment values are configured.
- [ ] Pipeline variables are configured.
- [ ] Service connection identity exists and is scoped correctly.
- [ ] Azure DevOps service connections exist and are authorized correctly.
- [ ] Azure DevOps Environments are configured.
- [ ] Branch protection and environment checks are configured.
- [ ] Local validation succeeds.
- [ ] Pull request validation succeeds.
- [ ] Initial setup pull request is merged.
- [ ] First post-merge pipeline run succeeds.
- [ ] Documentation cleanup is complete.
- [ ] `FIRST-TIME-SETUP.md` has been archived as `docs/FIRST-TIME-SETUP.completed.md`.

### Output of This Step

- First-time setup is complete.
- Repository is ready for infrastructure development.
