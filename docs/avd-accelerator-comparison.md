# AVD Accelerator Baseline Comparison

## Purpose

Compare the Microsoft AVD Accelerator baseline deployment against this repository's intended modular architecture.

## Guiding Decision

Use the accelerator as a capability checklist and reference implementation. Do not copy its root template structure directly.

## Responsibility Map

| Accelerator capability | Accelerator parameter/module | Repo destination | Decision | Notes |
|------------------------|------------------------------|------------------|----------|-------|

## Parameter Classification

| Accelerator parameter | Purpose | Repo destination | Decision | Notes |
|-----------------------|---------|------------------|----------|-------|

## Module Comparison Order

1. Network
2. Storage and storage-auth
3. AVD core
4. Compute
5. Monitoring
6. Image builder

## Parameter Comparison

Compare the Microsoft AVD Accelerator `deploy-baseline.bicep` parameters against this repository's intended modular architecture.

The accelerator baseline is used as a capability checklist and reference implementation. It should not be copied directly as this repository's primary structure.

## Decision Legend

| Decision | Meaning                                                                                  |
|----------|------------------------------------------------------------------------------------------|
| Keep     | Adopt the concept directly.                                                              |
| Adapt    | Use the idea, but reshape it to fit this repo.                                           |
| Defer    | Good idea, but not needed for the first POC pass.                                        |
| Ignore   | Not needed or not aligned with this repo.                                                |
| Secret   | Must not live in `.bicepparam`; use Key Vault, pipeline secret, or approved secret flow. |

---

## 1. Deployment Identity, Environment, and Location

| Accelerator parameter        | Purpose                                                              | Repo destination                   | Decision | Notes                                                                                                                      |
|------------------------------|----------------------------------------------------------------------|------------------------------------|----------|----------------------------------------------------------------------------------------------------------------------------|
| `deploymentPrefix`           | Short prefix used in accelerator naming.                             | `config.bicep`                     | Adapt    | Similar to your `namePrefix` or workload prefix. Keep controlled, not free-form everywhere.                                |
| `deploymentEnvironment`      | Dev/Test/Prod environment switch.                                    | `types.bicep` / `config.bicep`     | Adapt    | Your repo already uses `poc`, `dev`, `test`, `prod`. Do not adopt their exact values.                                      |
| `avdSessionHostLocation`     | Region for compute/session hosts.                                    | `config.bicep`                     | Keep     | Important distinction. Session hosts may not always live where AVD management plane lives.                                 |
| `avdManagementPlaneLocation` | Region for AVD workspace/host pool/app group/scaling plan.           | `config.bicep`                     | Keep     | Add this to your environment/location config even if POC uses the same region.                                             |
| `avdWorkloadSubsId`          | Workload subscription ID, especially for multi-subscription designs. | `config.bicep` / pipeline variable | Adapt    | Your modules already deploy subscription-scoped. Keep subscription awareness explicit.                                     |
| `time`                       | Unique value used to influence deterministic-ish names.              | Avoid                              | Ignore   | Do not use `utcNow()` as naming input. That makes names drift between deployments, because apparently chaos wanted an API. |

The accelerator separates session host location and management plane location, and it includes workload subscription ID as a parameter. Those are worth keeping conceptually. :contentReference[oaicite:2]{index=2}

---

## 2. AVD Service Principals and Identity Provider

| Accelerator parameter            | Purpose                                                             | Repo destination                                | Decision | Notes                                                                                                    |
|----------------------------------|---------------------------------------------------------------------|-------------------------------------------------|----------|----------------------------------------------------------------------------------------------------------|
| `avdServicePrincipalObjectId`    | Azure Virtual Desktop enterprise app object ID.                     | `service-objects` / `avd-core` param            | Adapt    | Needed only if specific AVD service principal permissions are required.                                  |
| `avdArmServicePrincipalObjectId` | AVD ARM Provider enterprise app object ID.                          | `service-objects` / `storage-auth`              | Adapt    | Especially relevant for App Attach with Entra ID scenarios.                                              |
| `avdIdentityServiceProvider`     | Identity provider: `ADDS`, `EntraDS`, `EntraID`, `EntraIDKerberos`. | `types.bicep` + `config.bicep`                  | Keep     | Make identity provider a first-class type. This affects storage auth, domain join, compute, and FSLogix. |
| `createIntuneEnrollment`         | Whether session hosts enroll in Intune.                             | `compute` config                                | Keep     | Should be decided with identity strategy.                                                                |
| `avdSecurityGroups`              | Groups granted AVD app group access and storage/NTFS permissions.   | `service-objects` / `storage-auth` / `avd-core` | Adapt    | Split by responsibility: app group assignments in `avd-core`; storage permissions in `storage-auth`.     |

The accelerator makes identity provider and Intune enrollment explicit, which is one of the better things to steal because AVD identity choices infect everything downstream like a cheerful compliance virus. :contentReference[oaicite:3]{index=3}

---

## 3. Local Admin, Domain Join, and AD/OU Details

| Accelerator parameter       | Purpose                                              | Repo destination                     | Decision | Notes                                                                       |
|-----------------------------|------------------------------------------------------|--------------------------------------|----------|-----------------------------------------------------------------------------|
| `avdVmLocalUserName`        | Local admin username for session hosts.              | Key Vault / pipeline secret flow     | Secret   | Do not store directly in `.bicepparam`.                                     |
| `avdVmLocalUserPassword`    | Local admin password for session hosts.              | Key Vault / pipeline secret flow     | Secret   | Secure param in accelerator. In your repo, keep out of parameter files.     |
| `identityDomainName`        | AD domain FQDN for FSLogix/storage/NTFS setup.       | `config.bicep` or environment param  | Adapt    | Only if AD DS / hybrid identity is used.                                    |
| `identityDomainGuid`        | AD domain GUID.                                      | `config.bicep` or environment param  | Adapt    | Needed for storage identity scenarios.                                      |
| `avdDomainJoinUserName`     | Domain join username.                                | Key Vault / pipeline secret flow     | Secret   | Avoid human-pasted secrets in param files, the traditional path to sadness. |
| `avdDomainJoinUserPassword` | Domain join password.                                | Key Vault / pipeline secret flow     | Secret   | Secure param only.                                                          |
| `avdOuPath`                 | OU for session host computer objects.                | `compute` param / environment config | Keep     | Should be environment-specific and coordinated with AD.                     |
| `storageOuPath`             | OU for Azure Files storage computer/service account. | `storage-auth` param                 | Adapt    | Only relevant for AD DS storage account domain join scenarios.              |

Your repo standard already says parameter files must not contain passwords, client secrets, private keys, certificates, tokens, or other secret material. :contentReference[oaicite:4]{index=4} Keep that rule brutally intact.

---

## 4. Host Pool and AVD Control Plane

| Accelerator parameter           | Purpose                                      | Repo destination | Decision | Notes                                                                    |
|---------------------------------|----------------------------------------------|------------------|----------|--------------------------------------------------------------------------|
| `avdHostPoolType`               | `Personal` or `Pooled`.                      | `avd-core`       | Keep     | Strong candidate for a typed host pool config object.                    |
| `hostPoolPreferredAppGroupType` | `Desktop` or `RemoteApp`.                    | `avd-core`       | Keep     | For now, likely `Desktop`.                                               |
| `hostPoolPublicNetworkAccess`   | Public network access setting for host pool. | `avd-core`       | Keep     | Important if AVD Private Link becomes required.                          |
| `workspacePublicNetworkAccess`  | Public network access setting for workspace. | `avd-core`       | Keep     | Same private access concern as host pool.                                |
| `avdPersonalAssignType`         | Personal desktop assignment type.            | `avd-core`       | Defer    | Only needed if using Personal host pools.                                |
| `avdHostPoolLoadBalancerType`   | BreadthFirst or DepthFirst.                  | `avd-core`       | Keep     | Pooled host pool design choice.                                          |
| `hostPoolMaxSessions`           | Max sessions per host.                       | `avd-core`       | Keep     | Workload-specific. Ops vs developers may differ.                         |
| `avdStartVmOnConnect`           | Enables Start VM on Connect.                 | `avd-core`       | Keep     | Useful for cost savings.                                                 |
| `avdHostPoolRdpProperties`      | Custom RDP property string.                  | `avd-core`       | Keep     | Should become a workload-level config value, not random string confetti. |
| `avdDeployScalingPlan`          | Whether to deploy scaling plan.              | `avd-core`       | Keep     | Very relevant for cost control.                                          |

These parameters map cleanly to a future `avd-core` module, not `service-objects`. The accelerator exposes host pool behavior, public network access, RDP properties, and scaling plan controls at the baseline level. :contentReference[oaicite:5]{index=5}

---

## 5. Networking

| Accelerator parameter                         | Purpose                                      | Repo destination                          | Decision | Notes                                                                                                             |
|-----------------------------------------------|----------------------------------------------|-------------------------------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `createAvdVnet`                               | Create new VNet or use existing.             | `network`                                 | Adapt    | POC can create. Long-term should support existing VNet/subnet inputs.                                             |
| `existingVnetAvdSubnetResourceId`             | Existing session host subnet.                | `network` / consumer param                | Keep     | Needed for brownfield or enterprise network ownership.                                                            |
| `existingVnetPrivateEndpointSubnetResourceId` | Existing private endpoint subnet.            | `network` / consumer param                | Keep     | Critical for storage/Key Vault/private link.                                                                      |
| `existingHubVnetResourceId`                   | Existing hub VNet for peering.               | `network`                                 | Keep     | Your network module should consume hub ID.                                                                        |
| `avdVnetworkAddressPrefixes`                  | VNet CIDR.                                   | `network` param                           | Keep     | Environment-specific, IPAM-approved.                                                                              |
| `vNetworkAvdSubnetAddressPrefix`              | Session host subnet CIDR.                    | `network` param                           | Keep     | Should be explicit.                                                                                               |
| `vNetworkPrivateEndpointSubnetAddressPrefix`  | Private endpoint subnet CIDR.                | `network` param                           | Keep     | Keep separate from session host subnet.                                                                           |
| `customDnsIps`                                | Custom DNS servers.                          | `network` param / config                  | Keep     | Important for AD DS and enterprise DNS.                                                                           |
| `deployDDoSNetworkProtection`                 | DDoS protection.                             | `network` / security                      | Defer    | Probably outside POC unless mandated.                                                                             |
| `deployPrivateEndpointKeyvaultStorage`        | Private endpoints for Key Vault and storage. | `network` + `storage` + `service-objects` | Adapt    | Do not make network own everything. Network owns subnet/DNS; storage owns storage PE unless you decide otherwise. |
| `deployAvdPrivateLinkService`                 | AVD Private Link.                            | `avd-core` + `network`                    | Defer    | Design for it, but do not force it into POC unless required.                                                      |
| `createPrivateDnsZones`                       | Create private DNS zones.                    | `network` / shared platform               | Adapt    | Depends on whether enterprise DNS owns zones.                                                                     |
| `avdVnetPrivateDnsZoneConnectionResourceId`   | Existing AVD connection private DNS zone.    | `network` / `avd-core`                    | Defer    | Needed only for AVD Private Link.                                                                                 |
| `avdVnetPrivateDnsZoneDiscoveryResourceId`    | Existing AVD discovery private DNS zone.     | `network` / `avd-core`                    | Defer    | Needed only for AVD Private Link.                                                                                 |
| `avdVnetPrivateDnsZoneFilesId`                | Existing Azure Files private DNS zone.       | `network` / `storage`                     | Keep     | Strong candidate for network output/input.                                                                        |
| `avdVnetPrivateDnsZoneKeyvaultId`             | Existing Key Vault private DNS zone.         | `network` / `service-objects`             | Adapt    | Only if Key Vault private endpoint is in scope.                                                                   |
| `vNetworkGatewayOnHub`                        | Indicates hub has gateway.                   | `network`                                 | Keep     | Affects peering flags.                                                                                            |
| `customStaticRoutes`                          | Extra route table routes.                    | `network` param                           | Keep     | Useful for firewall/NVA routing.                                                                                  |

This is the first area I’d deep-dive after the map. The accelerator includes new/existing VNet modes, session host and private endpoint subnets, hub peering, DNS, private endpoints, and static routes. :contentReference[oaicite:6]{index=6}

---

## 6. FSLogix and App Attach Storage

| Accelerator parameter            | Purpose                                   | Repo destination                   | Decision | Notes                                                                         |
|----------------------------------|-------------------------------------------|------------------------------------|----------|-------------------------------------------------------------------------------|
| `createAvdFslogixDeployment`     | Deploy FSLogix storage.                   | `storage`                          | Keep     | Core AVD requirement for profile containers.                                  |
| `createAppAttachDeployment`      | Deploy App Attach storage.                | `storage`                          | Defer    | Good later, not required for initial POC unless App Attach is in scope.       |
| `fslogixFileShareQuotaSize`      | FSLogix share quota.                      | `storage` param                    | Keep     | Set realistic default. Accelerator default is tiny.                           |
| `appAttachFileShareQuotaSize`    | App Attach share quota.                   | `storage` param                    | Defer    | Only when App Attach exists.                                                  |
| `zoneRedundantStorage`           | Use ZRS instead of LRS.                   | `storage` config                   | Adapt    | Environment-specific. POC probably LRS, prod maybe ZRS depending cost/region. |
| `fslogixStoragePerformance`      | Standard/Premium for FSLogix storage.     | `storage` config                   | Keep     | Default should likely be Premium for FSLogix.                                 |
| `appAttachStoragePerformance`    | Standard/Premium for App Attach storage.  | `storage` config                   | Defer    | Later App Attach module/config.                                               |
| `storageAccountPrefixCustomName` | Prefix for storage account custom naming. | `naming.bicep`                     | Ignore   | Your naming helpers should own this.                                          |
| `fslogixFileShareCustomName`     | Custom FSLogix share name.                | `naming.bicep` / optional override | Adapt    | Allow override only if needed.                                                |
| `appAttachFileShareCustomName`   | Custom App Attach share name.             | future App Attach config           | Defer    | Later.                                                                        |

The accelerator models FSLogix and App Attach separately, including share quota, storage performance, and redundancy choices. That is worth adopting as separate storage purposes rather than one vague “storage thing,” because vague storage things become invoice archaeology. :contentReference[oaicite:7]{index=7}

---

## 7. Session Host Deployment

| Accelerator parameter         | Purpose                                      | Repo destination                       | Decision | Notes                                                            |
|-------------------------------|----------------------------------------------|----------------------------------------|----------|------------------------------------------------------------------|
| `avdDeploySessionHosts`       | Whether to deploy VMs.                       | `compute`                              | Keep     | Useful switch for separating control plane from hosts.           |
| `avdDeploySessionHostsCount`  | Number of session hosts.                     | `compute` param                        | Keep     | Workload-specific.                                               |
| `avdSessionHostCountIndex`    | Starting host number.                        | `compute` param                        | Keep     | Very useful for adding hosts without name conflicts.             |
| `availability`                | None or Availability Zones.                  | `compute` param                        | Keep     | Prod likely wants a zone strategy.                               |
| `availabilityZones`           | Zones to use.                                | `compute` param                        | Keep     | Validate by region.                                              |
| `avdSessionHostsSize`         | VM SKU.                                      | `compute` param                        | Keep     | Workload-specific.                                               |
| `avdSessionHostDiskType`      | OS disk SKU.                                 | `compute` param                        | Keep     | Probably Premium SSD unless cost says otherwise.                 |
| `customOsDiskSizeGB`          | Optional OS disk size.                       | `compute` param                        | Keep     | Useful but default to image size.                                |
| `enableAcceleratedNetworking` | NIC accelerated networking.                  | `compute` param                        | Keep     | Default true where supported.                                    |
| `securityType`                | Standard or TrustedLaunch.                   | `compute` param                        | Keep     | Default Trusted Launch unless image blocks it.                   |
| `secureBootEnabled`           | Secure Boot flag.                            | `compute` param                        | Keep     | Tied to Trusted Launch.                                          |
| `vTpmEnabled`                 | vTPM flag.                                   | `compute` param                        | Keep     | Tied to Trusted Launch.                                          |
| `useSharedImage`              | Use Azure Compute Gallery image.             | `compute` / future image-builder       | Adapt    | Support marketplace first, shared image later.                   |
| `mpImageOffer`                | Marketplace image offer.                     | `compute` config                       | Keep     | Default image selection.                                         |
| `mpImageSku`                  | Marketplace image SKU.                       | `compute` config                       | Keep     | Their default is Windows 11 AVD M365 oriented.                   |
| `avdCustomImageDefinitionId`  | Custom image definition ID.                  | `compute` / image-builder              | Defer    | Use after image pipeline exists.                                 |
| `managementVmOsImage`         | Image for management VM used by accelerator. | Avoid / possible `storage-auth` helper | Defer    | Try not to need a management VM unless storage auth requires it. |
| `deployAntiMalwareExt`        | Deploy anti-malware VM extension.            | `compute` / security                   | Adapt    | Coordinate with Defender/endpoint security tooling.              |

The accelerator includes session host count/indexing, availability zones, VM SKU/disk/security options, marketplace vs shared image, and extension choices. Those belong in `compute`, but only after `network`, `storage`, `storage-auth`, and `avd-core` outputs are clean. :contentReference[oaicite:8]{index=8}

---

## 8. Monitoring

| Accelerator parameter            | Purpose                                              | Repo destination                   | Decision | Notes                                               |
|----------------------------------|------------------------------------------------------|------------------------------------|----------|-----------------------------------------------------|
| `avdDeployMonitoring`            | Deploy AVD monitoring resources.                     | `monitoring`                       | Defer    | Add hooks now, full module later.                   |
| `deployAlaWorkspace`             | Deploy Azure Log Analytics workspace.                | `monitoring`                       | Adapt    | Support create or existing workspace.               |
| `deployCustomPolicyMonitoring`   | Create/assign custom policy for diagnostic settings. | `monitoring` / policy module       | Defer    | Likely needs governance approval.                   |
| `avdAlaWorkspaceDataRetention`   | Log Analytics retention.                             | `monitoring` config                | Keep     | Environment-specific.                               |
| `alaExistingWorkspaceResourceId` | Existing workspace ID.                               | `monitoring` / module params       | Keep     | Important if enterprise already owns Log Analytics. |
| `avdAlaWorkspaceCustomName`      | Custom LA workspace name.                            | `naming.bicep` / optional override | Adapt    | Naming helper first, override only if needed.       |

Monitoring should be a module, but not a blocker. Hooks now; observability empire later. The accelerator includes switches for AVD monitoring, Log Analytics, existing workspace, retention, and policy-based diagnostics. :contentReference[oaicite:9]{index=9}

---

## 9. Security, Defender, Key Vault, and Zero Trust Disk Encryption

| Accelerator parameter                 | Purpose                                    | Repo destination                    | Decision       | Notes                                                 |
|---------------------------------------|--------------------------------------------|-------------------------------------|----------------|-------------------------------------------------------|
| `diskEncryptionKeyExpirationInDays`   | Expiration for disk encryption key.        | future security module              | Defer          | Only relevant if using disk zero trust/DES pattern.   |
| `diskZeroTrust`                       | Enable zero trust disk encryption.         | future security module              | Defer          | Too much complexity for baseline POC unless required. |
| `enableKvPurgeProtection`             | Enable Key Vault purge protection.         | `service-objects` / security config | Keep           | Should default true for real environments.            |
| `avdWrklKvPrefixCustomName`           | Workload Key Vault prefix.                 | `naming.bicep`                      | Adapt          | Use naming helper, not free-form parameter zoo.       |
| `ztDiskEncryptionSetCustomNamePrefix` | Disk encryption set prefix.                | future security module              | Defer          | Later.                                                |
| `ztKvPrefixCustomName`                | Zero trust Key Vault prefix.               | future security module              | Defer          | Later.                                                |
| `deployDefender`                      | Enable Microsoft Defender on subscription. | security/policy module              | Defer          | Likely outside AVD repo ownership.                    |
| `enableDefForServers`                 | Defender for Servers.                      | security/policy module              | Defer          | Governance/security team decision.                    |
| `enableDefForStorage`                 | Defender for Storage.                      | security/policy module              | Defer          | Governance/security team decision.                    |
| `enableDefForKeyVault`                | Defender for Key Vault.                    | security/policy module              | Defer          | Governance/security team decision.                    |
| `enableDefForArm`                     | Defender for Azure Resource Manager.       | security/policy module              | Defer          | Subscription-level governance concern.                |
| `deployGpuPolicies`                   | Deploy GPU extension policies.             | policy module                       | Ignore for now | Only relevant if GPU host pools are in scope.         |

The accelerator includes Defender subscription settings, Key Vault purge protection, and zero-trust disk encryption options. Good ideas, bad first-pass scope. Security features should be intentionally owned, not accidentally inherited because Microsoft shipped a switch. :contentReference[oaicite:10]{index=10}

---

## 10. Custom Naming Parameters

| Accelerator parameter group                     | Purpose                         | Repo destination                  | Decision | Notes                                                                   |
|-------------------------------------------------|---------------------------------|-----------------------------------|----------|-------------------------------------------------------------------------|
| `avdUseCustomNaming`                            | Master switch for custom names. | Avoid                             | Ignore   | Your repo should use deterministic naming helpers by default.           |
| `avdServiceObjectsRgCustomName`                 | Service objects RG name.        | `naming.bicep` / bootstrap output | Adapt    | Prefer generated name, optional override only for external constraints. |
| `avdNetworkObjectsRgCustomName`                 | Network RG name.                | `naming.bicep` / bootstrap output | Adapt    | Same.                                                                   |
| `avdComputeObjectsRgCustomName`                 | Compute RG name.                | `naming.bicep` / bootstrap output | Adapt    | Same.                                                                   |
| `avdStorageObjectsRgCustomName`                 | Storage RG name.                | `naming.bicep` / bootstrap output | Adapt    | Same.                                                                   |
| `avdMonitoringRgCustomName`                     | Monitoring RG name.             | `naming.bicep` / bootstrap output | Adapt    | Same.                                                                   |
| `avdVnetworkCustomName`                         | VNet name.                      | `naming.bicep`                    | Adapt    | Generated by naming helper.                                             |
| `avdVnetworkSubnetCustomName`                   | Session host subnet name.       | `naming.bicep`                    | Adapt    | Generated by naming helper.                                             |
| `privateEndpointVnetworkSubnetCustomName`       | Private endpoint subnet name.   | `naming.bicep`                    | Adapt    | Generated by naming helper.                                             |
| `avdNetworksecurityGroupCustomName`             | Session host NSG name.          | `naming.bicep`                    | Adapt    | Generated by naming helper.                                             |
| `privateEndpointNetworksecurityGroupCustomName` | Private endpoint NSG name.      | `naming.bicep`                    | Adapt    | Generated by naming helper.                                             |
| `avdRouteTableCustomName`                       | Session host route table name.  | `naming.bicep`                    | Adapt    | Generated by naming helper.                                             |
| `privateEndpointRouteTableCustomName`           | PE route table name.            | `naming.bicep`                    | Adapt    | Generated by naming helper.                                             |
| `avdApplicationSecurityGroupCustomName`         | ASG name.                       | `naming.bicep`                    | Defer    | Only if ASGs are used.                                                  |
| `avdWorkSpaceCustomName`                        | AVD workspace name.             | `naming.bicep` / `avd-core`       | Adapt    | Generated.                                                              |
| `avdWorkSpaceCustomFriendlyName`                | Workspace display name.         | `avd-core` config                 | Keep     | Friendly names are not the same as resource names.                      |
| `avdHostPoolCustomName`                         | Host pool name.                 | `naming.bicep` / `avd-core`       | Adapt    | Generated.                                                              |
| `avdHostPoolCustomFriendlyName`                 | Host pool display name.         | `avd-core` config                 | Keep     | Workload-friendly display value.                                        |
| `avdScalingPlanCustomName`                      | Scaling plan name.              | `naming.bicep` / `avd-core`       | Adapt    | Generated.                                                              |
| `avdApplicationGroupCustomName`                 | App group name.                 | `naming.bicep` / `avd-core`       | Adapt    | Generated.                                                              |
| `avdApplicationGroupCustomFriendlyName`         | App group display name.         | `avd-core` config                 | Keep     | User-facing enough to keep explicit.                                    |
| `avdSessionHostCustomNamePrefix`                | VM name prefix.                 | `naming.bicep` / `compute`        | Keep     | Needs careful handling due VM name length limits.                       |

The accelerator exposes custom names for nearly every resource. That makes sense for a generic accelerator, but your repo should centralize naming through shared helpers and only allow overrides where required. Your standard already emphasizes descriptive names and clear outputs. :contentReference[oaicite:11]{index=11}

---

## 11. Resource Tags

| Accelerator parameter               | Purpose                | Repo destination                          | Decision          | Notes                                             |
|-------------------------------------|------------------------|-------------------------------------------|-------------------|---------------------------------------------------|
| `createResourceTags`                | Whether to apply tags. | Remove switch; always apply required tags | Adapt             | Required tags should not be optional.             |
| `workloadNameTag`                   | Workload tag.          | `config.bicep` / `.bicepparam`            | Adapt             | Your repo separates workload and product.         |
| `workloadTypeTag`                   | Workload size/type.    | optional tag config                       | Defer             | Add only if required by governance.               |
| `dataClassificationTag`             | Data sensitivity.      | tag config                                | Keep if required  | Useful if enterprise policy expects it.           |
| `departmentTag`                     | Owning department.     | tag config                                | Adapt             | Your repo uses Division/Product/Environment.      |
| `workloadCriticalityTag`            | Criticality.           | tag config                                | Defer             | Good governance tag if required.                  |
| `workloadCriticalityCustomValueTag` | Custom criticality.    | tag config                                | Ignore            | Avoid unless governance needs it.                 |
| `applicationNameTag`                | Application name.      | tag config                                | Adapt             | Probably maps to Product/Application.             |
| `workloadSlaTag`                    | SLA tag.               | tag config                                | Defer             | Add later if governance asks.                     |
| `opsTeamTag`                        | Ops team tag.          | tag config                                | Keep              | Useful operational metadata.                      |
| `ownerTag`                          | Owner tag.             | tag config                                | Keep              | Useful operational metadata.                      |
| `costCenterTag`                     | Cost center tag.       | tag config                                | Keep if available | Finance will eventually find you. They always do. |

Your README already says the repo has required tags including `Environment`, `Division`, and `Product`, and that environment tag values should come from shared environment config. :contentReference[oaicite:12]{index=12} So do not adopt the accelerator tag model wholesale. Map useful governance tags into your existing tag object.

---

## 12. Telemetry and Miscellaneous

| Accelerator parameter               | Purpose                               | Repo destination      | Decision                | Notes                                                                      |
|-------------------------------------|---------------------------------------|-----------------------|-------------------------|----------------------------------------------------------------------------|
| `enableTelemetry`                   | Send usage telemetry to Microsoft.    | repo/global config    | Ignore or default false | Internal enterprise deployments often disable this unless approved.        |
| `removePostDeploymentTempResources` | Commented-out cleanup flag.           | none                  | Ignore                  | Not active in baseline.                                                    |
| `managementVmOsImage`               | Management VM image for config tasks. | avoid unless required | Defer                   | Prefer avoiding a management VM unless storage auth/domain tasks force it. |

---

# Repo Destination Summary

| Repo destination             | Accelerator concepts assigned here                                                                                                            |
|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------|
| `bootstrap`                  | Resource groups, base tags, maybe subscription-level prerequisites.                                                                           |
| `config.bicep`               | Environment mappings, locations, management/session host region split, identity provider default, shared defaults.                            |
| `types.bicep`                | Strong types for environment, location, identity provider, host pool type, load balancer type, storage performance, redundancy, availability. |
| `naming.bicep`               | Deterministic names for RGs, VNet, subnets, NSGs, storage, AVD resources, session host prefixes.                                              |
| `service-objects`            | Shared identities, Key Vault if owned here, AVD enterprise app object IDs if required, shared security principals.                            |
| `network`                    | VNet, existing subnet mode, session host subnet, private endpoint subnet, NSGs, routes, DNS zone links, hub peering.                          |
| `storage`                    | FSLogix storage account, file share, private endpoint, SKU/redundancy/share quota.                                                            |
| `storage-auth`               | RBAC, Azure Files auth, AD/Entra storage permissions, NTFS-related setup where applicable.                                                    |
| `avd-core`                   | Workspace, host pools, app groups, associations, scaling plans, AVD public/private access settings.                                           |
| `compute`                    | Session hosts, VM image, VM SKU, disk, Trusted Launch, domain/Entra join, Intune, extensions, host count/indexing.                            |
| `monitoring`                 | Log Analytics, DCRs, AVD Insights, diagnostic settings, existing workspace support.                                                           |
| future `image-builder`       | Azure Compute Gallery, image templates, custom image build and replication.                                                                   |
| future `security` / `policy` | Defender plans, custom Azure Policy, Zero Trust disk encryption, disk encryption sets.                                                        |

---

## Recommended First Changes to Your Architecture

## 1. Add management plane vs session host location to shared config

```bicep
type EnvironmentConfig = {
  shortName: string
  azureEnvironmentTag: string
  managementPlaneLocation: LocationName
  sessionHostLocation: LocationName
}
```

## Network Capability Comparison

| Accelerator capability                  | Accelerator parameter/module                  | Your destination                                 | Decision        | Notes                                                                                                                                    |
|:----------------------------------------|:----------------------------------------------|:-------------------------------------------------|:----------------|:-----------------------------------------------------------------------------------------------------------------------------------------|
| Create new AVD VNet                     | `createAvdVnet`                               | `network`                                        | Keep, but adapt | POC can create the spoke VNet. Long-term should support existing VNet mode.                                                              |
| Existing session host subnet            | `existingVnetAvdSubnetResourceId`             | `network` output or module input                 | Keep            | Needed for brownfield and enterprise network ownership.                                                                                  |
| Existing private endpoint subnet        | `existingVnetPrivateEndpointSubnetResourceId` | `network` output or module input                 | Keep            | Critical for storage, Key Vault, and future AVD Private Link.                                                                            |
| Existing hub VNet                       | `existingHubVnetResourceId`                   | `network` param                                  | Keep            | Your module should support spoke-to-hub peering when allowed.                                                                            |
| VNet address space                      | `avdVnetworkAddressPrefixes`                  | `network` param                                  | Keep            | Must be IPAM-approved. Do not bury this in shared defaults.                                                                              |
| Session host subnet CIDR                | `vNetworkAvdSubnetAddressPrefix`              | `network` param                                  | Keep            | Required explicit parameter.                                                                                                             |
| Private endpoint subnet CIDR            | `vNetworkPrivateEndpointSubnetAddressPrefix`  | `network` param                                  | Keep            | Keep this isolated from session host traffic.                                                                                            |
| Custom DNS servers                      | `customDnsIps`                                | `network` param/config                           | Keep            | Important for AD DS, hybrid identity, and enterprise DNS.                                                                                |
| DDoS Network Protection                 | `deployDDoSNetworkProtection`                 | `network` or future security module              | Defer           | Probably not POC scope unless mandated.                                                                                                  |
| Private endpoints for Key Vault/storage | `deployPrivateEndpointKeyvaultStorage`        | `storage`, `service-objects`, `network`          | Adapt           | Network should provide subnet/DNS. Resource-owning modules should create their own private endpoints unless you centralize PE ownership. |
| AVD Private Link                        | `deployAvdPrivateLinkService`                 | `avd-core` + `network`                           | Defer           | Design for it. Do not force into POC unless required.                                                                                    |
| Create private DNS zones                | `createPrivateDnsZones`                       | `network` or shared platform                     | Adapt           | Depends who owns enterprise private DNS.                                                                                                 |
| AVD connection DNS zone                 | `avdVnetPrivateDnsZoneConnectionResourceId`   | future `avd-core`/`network`                      | Defer           | Required only for AVD Private Link.                                                                                                      |
| AVD discovery DNS zone                  | `avdVnetPrivateDnsZoneDiscoveryResourceId`    | future `avd-core`/`network`                      | Defer           | Required only for AVD Private Link.                                                                                                      |
| Azure Files DNS zone                    | `avdVnetPrivateDnsZoneFilesId`                | `network` output/input used by `storage`         | Keep            | Needed for FSLogix over private endpoint.                                                                                                |
| Key Vault DNS zone                      | `avdVnetPrivateDnsZoneKeyvaultId`             | `network` output/input used by `service-objects` | Adapt           | Needed if Key Vault private endpoint is enabled.                                                                                         |
| Hub gateway flag                        | `vNetworkGatewayOnHub`                        | `network` param                                  | Keep            | Controls peering flags such as gateway transit/use remote gateway.                                                                       |
| Custom static routes                    | `customStaticRoutes`                          | `network` param                                  | Keep            | Useful for firewall/NVA routing.                                                                                                         |
