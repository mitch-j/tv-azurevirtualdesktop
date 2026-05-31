# Implementation Plan

## Overview

This document defines the implementation plan for the Azure infrastructure managed by this repository.

## Implementation Scope

### In Scope

- [item]
- [item]

### Out of Scope

- [item]
- [item]

## Environments

| Environment | Subscription   | Resource Group   | Parameter File                   |
|-------------|----------------|------------------|----------------------------------|
| Dev         | [subscription] | [resource-group] | infra/parameters/dev.bicepparam  |
| Test        | [subscription] | [resource-group] | infra/parameters/test.bicepparam |
| Prod        | [subscription] | [resource-group] | infra/parameters/prod.bicepparam |

## Prerequisites

| Requirement                          | Owner   | Status   |
|--------------------------------------|---------|----------|
| Azure subscription available         | [owner] | [status] |
| Resource group created or deployable | [owner] | [status] |
| Service connection created           | [owner] | [status] |
| Required RBAC assigned               | [owner] | [status] |
| Required policies reviewed           | [owner] | [status] |

## Implementation Steps

1. Confirm Azure scope and ownership.
2. Confirm service connection scope and permissions.
3. Update environment parameter files.
4. Run Bicep build validation.
5. Run deployment validation.
6. Run what-if review.
7. Review pull request.
8. Deploy to non-production.
9. Validate deployed resources.
10. Deploy to production after approval.

## Deployment Order

| Step | Action                | Environment | Owner   |
|------|-----------------------|-------------|---------|
| 1    | Validate templates    | Dev         | [owner] |
| 2    | Deploy infrastructure | Dev         | [owner] |
| 3    | Validate deployment   | Dev         | [owner] |
| 4    | Run what-if           | Prod        | [owner] |
| 5    | Deploy infrastructure | Prod        | [owner] |

## Rollback / Recovery Plan

Describe how failed or partial deployments should be handled.

Options may include:

- Re-run deployment with corrected parameters
- Revert pull request
- Redeploy previous known-good template
- Manually remediate only when approved and documented

## Risks

| Risk   | Impact   | Mitigation   |
|--------|----------|--------------|
| [risk] | [impact] | [mitigation] |

## Communication Plan

| Audience   | Message   | Channel   |
|------------|-----------|-----------|
| [audience] | [message] | [channel] |

## Completion Criteria

Implementation is complete when:

- Infrastructure is deployed successfully.
- Validation checks pass.
- Required documentation is updated.
- Operational ownership is confirmed.
- Monitoring and support processes are in place.
