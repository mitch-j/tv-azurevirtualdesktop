using 'main.bicep'

/*
AVD Deployment / Shared Resources Parameters

Environment:
- poc

Used by:
- infra/modules/sharedresources/main.bicep

Notes:
- This deploys shared image-building and automation resources for the AVD platform.
- The shared resources subscription may serve both POC and production consumers.
- Image Builder customization steps should stay empty until the image build process is intentionally defined.
- Do not store secrets, credentials, private keys, certificate material, or tokens in this file.
*/


param location = 'eastus'
param environment = 'poc'

param galleryDescription = 'Azure Compute Gallery for Azure Virtual Desktop custom images.'

param automationAccountSkuName = 'Basic'
param automationAccountPublicNetworkAccess = 'Disabled'

param imageBuilderVmSize = 'Standard_D4s_v5'
param imageBuilderOsDiskSizeGB = 128
param imageBuildTimeoutInMinutes = 240
param imageReplicationRegions = [
  'eastus'
]

param imageTemplateAutoRunState = 'Disabled'

param imageTemplateSource = {
  type: 'PlatformImage'
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'office-365'
  sku: 'win11-25h2-avd-m365'
  version: 'latest'
}

param imageTemplateCustomizers = [
    {
    restartTimeout: '10m'
    type: 'WindowsRestart'
  }
]

param imageDefinitions = [
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
