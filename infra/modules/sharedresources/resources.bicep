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
    tags: {}
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
    diskControllerType: 'SCSI'
    architecture: 'x64'
    eula: null
    privacyStatementUri: null
    releaseNoteUri: null
    purchasePlan: null
    endOfLife: null
    excludedDiskTypes: null
  }
]

@description('Source image used by Azure VM Image Builder.')
param imageTemplateSource object = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'Windows-11'
  sku: 'win11-24h2-avd'
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

var contributorRoleDefinitionId = 'b24988ac-6180-42a0-ab88-20f7382dd24c'

// Modules

module imageBuilderIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.4.0' = {
  name: '${deployment().name}-id-img'
  params: {
    name: imageBuilderIdentityName
    location: location
    tags: tags
  }
}

module automationAccount 'br/public:avm/res/automation/automation-account:0.12.0' = {
  name: '${deployment().name}-aa'
  params: {
    name: automationAccountName
    location: location
    tags: tags
    skuName: automationAccountSkuName
    disableLocalAuth: true
    publicNetworkAccess: automationAccountPublicNetworkAccess
    managedIdentities: {
      systemAssigned: true
    }
  }
}

module computeGallery 'br/public:avm/res/compute/gallery:0.9.5' = {
  name: '${deployment().name}-gal'
  params: {
    name: galleryName
    location: location
    tags: tags
    description: galleryDescription
    images: imageDefinitions

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

module imageTemplate 'br/public:avm/res/virtual-machine-images/image-template:0.6.1' = {
  name: '${deployment().name}-it'
  params: {
    name: imageTemplateName
    location: location
    tags: tags

    imageSource: imageTemplateSource
    customizationSteps: imageTemplateCustomizers

    distributions: [
      {
        type: 'SharedImage'
        sharedImageGalleryImageDefinitionResourceId: computeGallery.outputs.imageResourceIds[0]
        runOutputName: '${imageDefinitions[0].name}-${environmentShortName}'
        replicationRegions: imageReplicationRegions
        artifactTags: tags
      }
    ]

    managedIdentities: {
      userAssignedResourceIds: [
        imageBuilderIdentity.outputs.resourceId
      ]
    }

    vmUserAssignedIdentities: [
      imageBuilderIdentity.outputs.resourceId
    ]

    vmSize: imageBuilderVmSize
    osDiskSizeGB: imageBuilderOsDiskSizeGB
    buildTimeoutInMinutes: imageBuildTimeoutInMinutes
    autoRunState: imageTemplateAutoRunState
  }
}

// Outputs

@description('Name of the Azure Compute Gallery.')
output computeGalleryName string = computeGallery.outputs.name

@description('Resource ID of the Azure Compute Gallery.')
output computeGalleryResourceId string = computeGallery.outputs.resourceId

@description('Resource IDs of the Azure Compute Gallery image definitions.')
output galleryImageDefinitionResourceIds string[] = computeGallery.outputs.imageResourceIds

@description('Name of the primary VM image definition.')
output primaryImageDefinitionName string = imageDefinitions[0].name

@description('Resource ID of the primary VM image definition.')
output primaryImageDefinitionResourceId string = computeGallery.outputs.imageResourceIds[0]

@description('Name of the Azure VM Image Builder managed identity.')
output imageBuilderIdentityName string = imageBuilderIdentity.outputs.name

@description('Resource ID of the Azure VM Image Builder managed identity.')
output imageBuilderIdentityResourceId string = imageBuilderIdentity.outputs.resourceId

@description('Principal ID of the Azure VM Image Builder managed identity.')
output imageBuilderIdentityPrincipalId string = imageBuilderIdentity.outputs.principalId

@description('Name of the Azure VM Image Builder template.')
output imageTemplateName string = imageTemplate.outputs.name

@description('Input name prefix of the Azure VM Image Builder template.')
output imageTemplateNamePrefix string = imageTemplate.outputs.namePrefix

@description('Resource ID of the Azure VM Image Builder template.')
output imageTemplateResourceId string = imageTemplate.outputs.resourceId

@description('Command to trigger the Azure VM Image Builder template run.')
output imageTemplateRunCommand string = imageTemplate.outputs.runThisCommand

@description('Name of the Automation Account.')
output automationAccountName string = automationAccount.outputs.name

@description('Resource ID of the Automation Account.')
output automationAccountResourceId string = automationAccount.outputs.resourceId

@description('Principal ID of the Automation Account system-assigned managed identity.')
output automationAccountPrincipalId string? = automationAccount.outputs.?systemAssignedMIPrincipalId
