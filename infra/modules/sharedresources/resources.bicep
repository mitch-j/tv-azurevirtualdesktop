targetScope = 'resourceGroup'

/*
AVD Deployment / Shared Resources / Resources

Scope:
- Resource Group

Deploys:
- Azure Compute Gallery
- VM image definition
- Azure VM Image Builder managed identity
- Azure VM Image Builder template
- Automation Account

Does not deploy:
- Image versions
- Image build triggers
- Session host virtual machines
- Key Vault, Azure Monitor, Network Watcher, role entitlement, or policy assignments yet
*/

// Imports

import {
  resourcePurpose
  resourceType
} from '../../shared/config.bicep'

import {
  computeGalleryName
  resourceNameWithPurpose
} from '../../shared/naming.bicep'

// Types

type GalleryImageSecurityType =
  | 'Standard'
  | 'ConfidentialVM'
  | 'ConfidentialVMSupported'
  | 'TrustedLaunch'
  | 'TrustedLaunchSupported'
  | 'TrustedLaunchAndConfidentialVmSupported'

@sealed()
type GalleryImageDefinitionConfig = {
  @description('Name of the image definition inside the Azure Compute Gallery.')
  name: string

  @description('Optional description of the gallery image definition.')
  description: string?

  @description('Optional tags applied directly to the image definition.')
  tags: object?

  @description('Whether the existing gallery image definition can be updated.')
  allowUpdateImage: bool?

  @description('Operating system type.')
  osType: 'Windows' | 'Linux'

  @description('Operating system state.')
  osState: 'Generalized' | 'Specialized'

  @description('Gallery image definition identifier.')
  identifier: {
    publisher: string
    offer: string
    sku: string
  }

  @description('Supported vCPU range for VMs created from this image.')
  vCPUs: {
    min: int?
    max: int?
  }?

  @description('Supported memory range in GB for VMs created from this image.')
  memory: {
    min: int?
    max: int?
  }?

  @description('Hyper-V generation.')
  hyperVGeneration: 'V1' | 'V2'?

  @description('Security type for the image definition.')
  securityType: GalleryImageSecurityType?

  @description('Whether accelerated networking is supported.')
  isAcceleratedNetworkSupported: bool?

  @description('Whether hibernation is supported.')
  isHibernateSupported: bool?

  @description('Supported disk controller type.')
  diskControllerType: 'SCSI' | 'NVMe, SCSI' | 'SCSI, NVMe'?

  @description('CPU architecture.')
  architecture: 'x64' | 'Arm64'?

  @description('End-user license agreement URI.')
  eula: string?

  @description('Privacy statement URI.')
  privacyStatementUri: string?

  @description('Release notes URI.')
  releaseNoteUri: string?

  @description('Marketplace purchase plan metadata.')
  purchasePlan: {
    name: string?
    publisher: string?
    product: string?
  }?

  @description('End-of-life date for the image definition.')
  endOfLife: string?

  @description('Disk types excluded for this image definition.')
  excludedDiskTypes: string[]?
}

// Parameters

@description('Azure region for shared resources.')
param location string

@description('Standard tags applied to deployed resources.')
param tags object

@description('Standard resource name prefix.')
param namePrefix string

@description('Technical workload name used in resource names.')
param workloadName string

@description('Short environment name used in resource names.')
param environmentShortName string

@description('Azure Compute Gallery description.')
param galleryDescription string = 'Azure Compute Gallery for Azure Virtual Desktop custom images.'

@description('Automation Account SKU.')
@allowed([
  'Free'
  'Basic'
])
param automationAccountSkuName string = 'Basic'

@description('Whether Automation Account public network access is enabled.')
@allowed([
  ''
  'Enabled'
  'Disabled'
])
param automationAccountPublicNetworkAccess string = 'Disabled'

@description('VM size used by Azure VM Image Builder.')
param imageBuilderVmSize string = 'Standard_D4s_v5'

@description('OS disk size in GB used by Azure VM Image Builder.')
param imageBuilderOsDiskSizeGB int = 128

@description('Maximum image build timeout in minutes. Zero uses the Image Builder default.')
@minValue(0)
@maxValue(960)
param imageBuildTimeoutInMinutes int = 240

@description('Target replication regions for image versions created by Image Builder.')
param imageReplicationRegions string[] = [
  location
]

@description('Azure Compute Gallery image definitions to create.')
param imageDefinitions array = [
  {
    name: 'win11-25h2-avd-m365'
    description: 'Windows 11 Enterprise multi-session image for Azure Virtual Desktop with Microsoft 365 Apps.'
    allowUpdateImage: true
    osType: 'Windows'
    osState: 'Generalized'
    identifier: {
      publisher: 'TrueValue'
      offer: 'AVD'
      sku: 'win11-25h2-avd-m365'
    }
    vCPUs: {
      min: 2
      max: 64
    }
    memory: {
      min: 4
      max: 512
    }
    hyperVGeneration: 'V2'
    securityType: 'TrustedLaunchSupported'
    isAcceleratedNetworkSupported: true
    isHibernateSupported: false
    diskControllerType: 'NVMe, SCSI'
    architecture: 'x64'
    eula: null
    privacyStatementUri: null
    releaseNoteUri: null
    purchasePlan: null
    endOfLife: '2033-01-01'
    excludedDiskTypes: null
  }
]

@description('Source image used by Azure VM Image Builder.')
param imageTemplateSource object = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'office-365'
  sku: 'win11-25h2-avd-m365'
  version: 'latest'
}

@description('Image Builder customizers.')
param imageTemplateCustomizers array

@description('Whether Image Builder should automatically run when the image template is created or updated.')
@allowed([
  'Enabled'
  'Disabled'
])
param imageTemplateAutoRunState string = 'Disabled'

@description('Whether to deploy image build monitoring resources.')
param enableImageBuildMonitoring bool = true

@description('Existing Log Analytics Workspace resource ID. Leave empty to deploy a workspace in this resource group.')
param existingLogAnalyticsWorkspaceResourceId string = ''

@description('Log Analytics workspace retention in days.')
@minValue(30)
@maxValue(730)
param logAnalyticsWorkspaceRetentionInDays int = 30

@description('Email address used for image build alert notifications. Leave empty to skip email receiver and alert actions.')
param imageBuildAlertsEmailAddress string = ''

@description('Whether to deploy scheduled query alerts for Image Builder automation results.')
param enableImageBuildAlerts bool = false

@description('Whether to deploy an Automation schedule for Image Builder runs.')
param enableImageBuildSchedule bool = false

@description('Image build schedule frequency.')
@allowed([
  'OneTime'
  'Day'
  'Hour'
  'Week'
])
param imageBuildScheduleFrequency string = 'Day'

@description('Image build schedule interval.')
@minValue(1)
param imageBuildScheduleInterval int = 1

@description('Time zone used by the Image Builder automation schedule.')
param imageBuildScheduleTimeZone string = 'America/Chicago'

@description('Optional subnet resource ID used by Azure VM Image Builder build VMs.')
param imageBuilderSubnetResourceId string = ''

@description('Storage account type used for image versions distributed by Image Builder.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param imageVersionStorageAccountType string = 'Standard_LRS'

@description('Image build schedule start time. Must be a future ISO 8601 datetime.')
param imageBuildScheduleStartTime string = dateTimeAdd(utcNow(), 'PT15M')

@description('Target Azure Compute Gallery image version produced by Azure VM Image Builder. Must use Major.Minor.Build format.')
param galleryImageDefinitionTargetVersion string

@description('Deterministic suffix used for Azure VM Image Builder template names. Pass this from the pipeline when creating a new image template build definition.')
param imageTemplateBaseTime string = 'manual'

// Variables

var galleryName = computeGalleryName(
  namePrefix,
  workloadName,
  resourcePurpose.images
)

var imageBuilderIdentityName = resourceNameWithPurpose(
  namePrefix,
  workloadName,
  resourceType.managedIdentity,
  resourcePurpose.images,
  environmentShortName
)

var imageTemplateName = resourceNameWithPurpose(
  namePrefix,
  workloadName,
  resourceType.imageTemplate,
  resourcePurpose.images,
  environmentShortName
)

var automationAccountName = resourceNameWithPurpose(
  namePrefix,
  workloadName,
  resourceType.automationAccount,
  resourcePurpose.sharedResources,
  environmentShortName
)

var logAnalyticsWorkspaceName = resourceNameWithPurpose(
  namePrefix,
  workloadName,
  resourceType.logAnalyticsWorkspace,
  resourcePurpose.logs,
  environmentShortName
)

var imageBuildActionGroupName = resourceNameWithPurpose(
  namePrefix,
  workloadName,
  resourceType.actionGroup,
  resourcePurpose.images,
  environmentShortName
)

var imageBuildRunbookName = 'aib-build-automation'
var imageBuildScheduleName = '${imageTemplateName}-schedule'

var deployLogAnalyticsWorkspace = enableImageBuildMonitoring && empty(existingLogAnalyticsWorkspaceResourceId)

var effectiveLogAnalyticsWorkspaceResourceId = !empty(existingLogAnalyticsWorkspaceResourceId)
  ? existingLogAnalyticsWorkspaceResourceId
  : resourceId('Microsoft.OperationalInsights/workspaces', logAnalyticsWorkspaceName)

var useLogAnalyticsWorkspace = enableImageBuildMonitoring && (deployLogAnalyticsWorkspace || !empty(existingLogAnalyticsWorkspaceResourceId))

var automationModules = [
  {
    name: 'Az.Accounts'
    uri: 'https://www.powershellgallery.com/api/v2/package'
    version: '4.0.2'
  }
  {
    name: 'Az.ImageBuilder'
    uri: 'https://www.powershellgallery.com/api/v2/package'
    version: '0.4.1'
  }
]

var imageBuildAlerts = [
  {
    name: 'Azure Image Builder - Build Failure'
    description: 'Sends an alert when an Azure Image Builder template build fails.'
    severity: 0
    query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category == "JobStreams"\n| where ResultDescription has "Image Template build failed"'
  }
  {
    name: 'Azure Image Builder - Build Success'
    description: 'Sends an informational alert when an Azure Image Builder template build succeeds.'
    severity: 3
    query: 'AzureDiagnostics\n| where ResourceProvider == "MICROSOFT.AUTOMATION"\n| where Category == "JobStreams"\n| where ResultDescription has "Image Template build succeeded"'
  }
]

var deployImageBuildActionGroup = enableImageBuildAlerts && !empty(imageBuildAlertsEmailAddress)

var imageBuildActionGroupResourceId = resourceId(
  'Microsoft.Insights/actionGroups',
  imageBuildActionGroupName
)

var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

var imageBuilderIdentityResourceId = resourceId(
  'Microsoft.ManagedIdentity/userAssignedIdentities',
  imageBuilderIdentityName
)

var imageTemplateDeploymentName = '${imageTemplateName}-${imageTemplateBaseTime}'

// Modules

module imageBuilderIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.5.1' = {
  name: '${deployment().name}-id-img'
  params: {
    name: imageBuilderIdentityName
    location: location
    tags: tags
  }
}

module automationAccount 'br/public:avm/res/automation/automation-account:0.19.1' = {
  name: '${deployment().name}-aa'
  params: {
    name: automationAccountName
    location: location
    tags: tags
    skuName: automationAccountSkuName
    disableLocalAuth: true
    publicNetworkAccess: automationAccountPublicNetworkAccess

    diagnosticSettings: enableImageBuildMonitoring && !empty(effectiveLogAnalyticsWorkspaceResourceId) ? [
      {
        name: 'send-to-log-analytics'
        workspaceResourceId: effectiveLogAnalyticsWorkspaceResourceId
      }
    ] : []

    managedIdentities: {
      systemAssigned: false
      userAssignedResourceIds: [
        imageBuilderIdentity.outputs.resourceId
      ]
    }

    runbooks: [
      {
        name: imageBuildRunbookName
        description: 'Checks the Azure VM Image Builder template and starts a build when the marketplace source image has changed.'
        type: 'PowerShell'
        uri: 'https://raw.githubusercontent.com/Azure/avdaccelerator/main/workload/scripts/New-AzureImageBuilderBuild.ps1'
        version: '1.0.0.0'
      }
    ]

    schedules: enableImageBuildSchedule ? [
      {
        name: imageBuildScheduleName
        frequency: imageBuildScheduleFrequency
        interval: imageBuildScheduleInterval
        starttime: imageBuildScheduleStartTime
        timeZone: imageBuildScheduleTimeZone
        advancedSchedule: {}
      }
    ] : []

    jobSchedules: enableImageBuildSchedule ? [
      {
        runbookName: imageBuildRunbookName
        scheduleName: imageBuildScheduleName
        parameters: {
          ClientId: imageBuilderIdentity.outputs.clientId
          EnvironmentName: environment().name
          ImageOffer: imageTemplateSource.offer
          ImagePublisher: imageTemplateSource.publisher
          ImageSku: imageTemplateSource.sku
          Location: location
          SubscriptionId: subscription().subscriptionId
          TemplateName: imageTemplateDeploymentName
          TemplateResourceGroupName: resourceGroup().name
          TenantId: subscription().tenantId
        }
      }
    ] : []
  }
}

@batchSize(1)
module automationAccountModules 'br/public:avm/res/automation/automation-account/module:0.1.0' = [
  for automationModule in automationModules: {
    name: '${deployment().name}-aa-module-${automationModule.name}'
    params: {
      name: automationModule.name
      location: location
      automationAccountName: automationAccount.outputs.name
      uri: automationModule.uri
      version: automationModule.version
    }
  }
]

module imageBuildScheduledQueryRules 'br/public:avm/res/insights/scheduled-query-rule:0.6.0' = [
  for alert in imageBuildAlerts: if (enableImageBuildAlerts && useLogAnalyticsWorkspace) {
    name: '${deployment().name}-sqr-${uniqueString(alert.name)}'
    params: {
      name: alert.name
      location: location
      tags: tags
      kind: 'LogAlert'
      enabled: true
      alertDescription: alert.description
      severity: alert.severity
      evaluationFrequency: 'PT5M'
      windowSize: 'PT5M'
      scopes: [
        effectiveLogAnalyticsWorkspaceResourceId
      ]
      actions: deployImageBuildActionGroup ? {
        actionGroupResourceIds: [
          imageBuildActionGroupResourceId
        ]
        actionProperties: null
        customProperties: null
      } : null
      criterias: {
        allOf: [
          {
            query: alert.query
            timeAggregation: 'Count'
            operator: 'GreaterThanOrEqual'
            threshold: 1
            failingPeriods: {
              numberOfEvaluationPeriods: 1
              minFailingPeriodsToAlert: 1
            }
          }
        ]
      }
      autoMitigate: false
      skipQueryValidation: false
    }
  }
]

module imageBuildActionGroup 'br/public:avm/res/insights/action-group:0.8.0' = if (deployImageBuildActionGroup) {
  name: '${deployment().name}-ag-img'
  params: {
    name: imageBuildActionGroupName
    location: 'global'
    tags: tags
    groupShortName: 'aib'
    enabled: true
    emailReceivers: [
      {
        name: 'ImageBuildAlerts'
        emailAddress: imageBuildAlertsEmailAddress
        useCommonAlertSchema: true
      }
    ]
  }
}

module computeGallery 'br/public:avm/res/compute/gallery:0.9.5' = {
  name: '${deployment().name}-gal'
  params: {
    name: galleryName
    location: location
    tags: tags
    description: galleryDescription

    // Image Builder needs permission to publish image versions into the gallery.
    roleAssignments: [
      {
        principalId: imageBuilderIdentity.outputs.principalId
        principalType: 'ServicePrincipal'
        roleDefinitionIdOrName: contributorRoleDefinitionId
      }
    ]
  }
}

resource galleryImages 'Microsoft.Compute/galleries/images@2025-03-03' = [
  for imageDefinition in imageDefinitions: {
    name: '${galleryName}/${imageDefinition.name}'
    location: location
    tags: imageDefinition.?tags ?? tags

    properties: union(
      {
        osType: imageDefinition.osType
        osState: imageDefinition.osState

        identifier: {
          publisher: imageDefinition.identifier.publisher
          offer: imageDefinition.identifier.offer
          sku: imageDefinition.identifier.sku
        }

        description: imageDefinition.?description
        allowUpdateImage: imageDefinition.?allowUpdateImage
        architecture: imageDefinition.?architecture
        hyperVGeneration: imageDefinition.?hyperVGeneration
        eula: imageDefinition.?eula
        privacyStatementUri: imageDefinition.?privacyStatementUri
        releaseNoteUri: imageDefinition.?releaseNoteUri
        endOfLifeDate: imageDefinition.?endOfLife

        recommended: {
          vCPUs: imageDefinition.?vCPUs
          memory: imageDefinition.?memory
        }

        disallowed: {
          diskTypes: imageDefinition.?excludedDiskTypes ?? []
        }

        features: union(
          imageDefinition.?isAcceleratedNetworkSupported != null ? [
            {
              name: 'IsAcceleratedNetworkSupported'
              value: '${imageDefinition.isAcceleratedNetworkSupported}'
              startsAtVersion: galleryImageDefinitionTargetVersion
            }
          ] : [],
          imageDefinition.?securityType != null && imageDefinition.securityType != 'Standard' ? [
            {
              name: 'SecurityType'
              value: '${imageDefinition.securityType}'
              startsAtVersion: galleryImageDefinitionTargetVersion
            }
          ] : [],
          imageDefinition.?isHibernateSupported != null ? [
            {
              name: 'IsHibernateSupported'
              value: '${imageDefinition.isHibernateSupported}'
              startsAtVersion: galleryImageDefinitionTargetVersion
            }
          ] : [],
          imageDefinition.?diskControllerType != null ? [
            {
              name: 'DiskControllerTypes'
              value: '${imageDefinition.diskControllerType}'
              startsAtVersion: galleryImageDefinitionTargetVersion
            }
          ] : []
        )
      },
      imageDefinition.?purchasePlan != null ? {
        purchasePlan: imageDefinition.purchasePlan
      } : {}
    )

    dependsOn: [
      computeGallery
    ]
  }
]

resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2024-02-01' = {
  name: imageTemplateDeploymentName
  location: location
  tags: tags

  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${imageBuilderIdentityResourceId}': {}
    }
  }

  properties: {
    buildTimeoutInMinutes: imageBuildTimeoutInMinutes

    source: imageTemplateSource

    customize: imageTemplateCustomizers

  distribute: [
    {
      type: 'SharedImage'
      runOutputName: '${imageDefinitions[0].name}-${environmentShortName}'
      galleryImageId: '${galleryImages[0].id}/versions/${galleryImageDefinitionTargetVersion}'
      replicationRegions: imageReplicationRegions
      storageAccountType: imageVersionStorageAccountType
      artifactTags: tags
    }
  ]

    vmProfile: union(
      {
        vmSize: imageBuilderVmSize
        osDiskSizeGB: imageBuilderOsDiskSizeGB
        userAssignedIdentities: [
          imageBuilderIdentityResourceId
        ]
      },
      !empty(imageBuilderSubnetResourceId) ? {
        vnetConfig: {
          subnetId: imageBuilderSubnetResourceId
        }
      } : {}
    )

    autoRun: {
      state: imageTemplateAutoRunState
    }
  }
}

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.15.1' = if (deployLogAnalyticsWorkspace) {
  name: '${deployment().name}-log'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    tags: tags
    dataRetention: logAnalyticsWorkspaceRetentionInDays
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
  }
}

// Outputs

@description('Name of the Azure Compute Gallery.')
output computeGalleryName string = computeGallery.outputs.name

@description('Resource ID of the Azure Compute Gallery.')
output computeGalleryResourceId string = computeGallery.outputs.resourceId

@description('Resource IDs of the Azure Compute Gallery image definitions.')
output galleryImageDefinitionResourceIds string[] = [
  for (imageDefinition, index) in imageDefinitions: galleryImages[index].id
]

@description('Name of the primary VM image definition.')
output primaryImageDefinitionName string = imageDefinitions[0].name

@description('Resource ID of the primary VM image definition.')
output primaryImageDefinitionResourceId string = galleryImages[0].id

@description('Name of the Azure VM Image Builder managed identity.')
output imageBuilderIdentityName string = imageBuilderIdentity.outputs.name

@description('Resource ID of the Azure VM Image Builder managed identity.')
output imageBuilderIdentityResourceId string = imageBuilderIdentity.outputs.resourceId

@description('Principal ID of the Azure VM Image Builder managed identity.')
output imageBuilderIdentityPrincipalId string = imageBuilderIdentity.outputs.principalId

@description('Name of the Azure VM Image Builder template.')
output imageTemplateName string = imageTemplate.name

@description('Input name prefix of the Azure VM Image Builder template.')
output imageTemplateNamePrefix string = imageTemplateName

@description('Resource ID of the Azure VM Image Builder template.')
output imageTemplateResourceId string = imageTemplate.id

@description('Command to trigger the Azure VM Image Builder template run.')
output imageTemplateRunCommand string = 'az resource invoke-action --ids ${imageTemplate.id} --action Run'

@description('Name of the Automation Account.')
output automationAccountName string = automationAccount.outputs.name

@description('Resource ID of the Automation Account.')
output automationAccountResourceId string = automationAccount.outputs.resourceId

@description('Principal ID of the Automation Account system-assigned managed identity.')
output automationAccountPrincipalId string? = automationAccount.outputs.?systemAssignedMIPrincipalId

@description('Name of the Log Analytics workspace used by the shared resources module.')
output logAnalyticsWorkspaceName string = useLogAnalyticsWorkspace
  ? (!empty(existingLogAnalyticsWorkspaceResourceId) ? last(split(existingLogAnalyticsWorkspaceResourceId, '/')) : logAnalyticsWorkspaceName)
  : ''

@description('Resource ID of the Log Analytics workspace used by the shared resources module.')
output logAnalyticsWorkspaceResourceId string = useLogAnalyticsWorkspace
  ? effectiveLogAnalyticsWorkspaceResourceId
  : ''

@description('Name of the Image Builder alert action group.')
output imageBuildActionGroupName string = deployImageBuildActionGroup
  ? imageBuildActionGroupName
  : ''

@description('Resource ID of the Image Builder alert action group.')
output imageBuildActionGroupResourceId string = deployImageBuildActionGroup
  ? imageBuildActionGroupResourceId
  : ''
