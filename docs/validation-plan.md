# Validation Plan

## Overview

This document defines validation expectations for the Azure infrastructure managed by this repository.

## Validation Scope

Validation applies to:

- Bicep template syntax
- Parameter files
- Deployment scope
- Azure deployment validation
- Azure what-if output
- Post-deployment checks

## Validation Commands

### Bicep Build

```powershell
az bicep build --file infra/main.bicep
```

## Deployment Validation

```powershell
az deployment group validate `
  --resource-group "<resource-group-name>" `
  --template-file "infra/main.bicep" `
  --parameters "infra/parameters/dev.bicepparam"
  ```

## Deployment What-If

```Powershell
az deployment group what-if `
  --resource-group "<resource-group-name>" `
  --template-file "infra/main.bicep" `
  --parameters "infra/parameters/dev.bicepparam"
  ```

## Validation Matrix

| Validation          | Dev           | Test          | Prod  | Required                               |
|---------------------|---------------|---------------|-------|----------------------------------------|
| [Bicep build]       | [Yes]         | [Yes]         | [Yes] | [Yes]                                  |
| Deployment validate | [Yes]         | [Yes]         | [Yes] | [Yes]                                  |
| What-if             | [Recommended] | [Recommended] | [Yes] | [Yes for production-impacting changes] |
| Manual review       | [Recommended] | [Recommended] | [Yes] | [Yes for production]                   |

## Pull Request Validation

Pull requests should validate:

- Bicep files compile successfully
- Parameter files are present and environment-specific
- No secrets are committed
- Pipeline changes are reviewable
- Documentation is updated when scope or ownership changes

## Post-Deployment Validation

After deployment, validate:

| Check                     | Expected Result                              |
|---------------------------|----------------------------------------------|
| Resource deployment state | Succeeded                                    |
| Resource naming           | Matches naming standard                      |
| Tags                      | Required tags are present                    |
| RBAC                      | Expected assignments exist                   |
| Diagnostics               | Logging configured where required            |
| Networking                | Expected connectivity and restrictions exist |

## Validation Evidence

Validation evidence may include:

Pipeline run logs
What-if output
Deployment operation output
Pull request approvals
Screenshots or exported evidence when required by change process

## Known Limitations

Document any validation gaps or manual checks required.

| Limitation   | Impact   | Mitigation   |
|--------------|----------|--------------|
| [limitation] | [impact] | [mitigation] |
