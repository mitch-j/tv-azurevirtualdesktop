# Architecture

## Overview

This document describes the architecture for the Azure infrastructure managed by this repository.

## Architecture Summary

| Item                     | Details                          |
|--------------------------|----------------------------------|
| Workload / Platform Area | [name]                           |
| Azure Tenant             | [tenant-name-or-id]              |
| Subscription             | [subscription-name-or-id]        |
| Resource Group(s)        | [resource-group-list]            |
| Region(s)                | [azure-region-list]              |
| Criticality              | [low / medium / high / critical] |
| Data Classification      | [classification]                 |

## Managed Resources

This repository manages the following Azure resources:

| Resource Type   | Name / Pattern | Purpose   |
|-----------------|----------------|-----------|
| [resource-type] | [name]         | [purpose] |

## Resource Group Design

Describe the resource group structure used by this deployment.

```text
<subscription>
└── <resource-group>
    ├── <resource>
    ├── <resource>
    └── <resource>
```

## Network Design

Describe any network dependencies, including:

- Virtual networks
- Subnets
- Private endpoints
- DNS zones
- Network security groups
- Route tables
- Firewall dependencies
- Connectivity to on-premises or other cloud environments

## Identity and Access

Describe managed identities, role assignments, service principals, groups, and service connections.

| Principal  | Role   | Scope   | Purpose   |
|------------|--------|---------|-----------|
| [identity] | [role] | [scope] | [purpose] |

## Dependency Map

| Dependency   | Type                | Required For |
|--------------|---------------------|--------------|
| [dependency] | [internal/external] | [purpose]    |

## Security Considerations

Document security controls, including:

- Least-privilege access
- Key Vault usage
- Network restrictions
- Diagnostic logging
- Policy assignments
- Secret handling
- Private connectivity

## Monitoring and Operations

Document operational visibility, including:

- Diagnostic settings
- Log Analytics workspaces
- Alerts
- Dashboards
- Runbooks
- Ownership

## Backup / Recovery

Describe backup, restore, disaster recovery, or rebuild expectations.

## Architecture Decisions

| Decision   | Rationale | Date         |
|------------|-----------|--------------|
| [decision] | [reason]  | [yyyy-mm-dd] |

## Open Questions

| Question   | Owner   | Status   |
|------------|---------|----------|
| [question] | [owner] | [status] |
