[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Validate', 'WhatIf', 'Deploy')]
    [string]$Action,

    [Parameter()]
    [ValidateSet('ResourceGroup', 'Subscription')]
    [string]$DeploymentScope = 'ResourceGroup',

    [Parameter()]
    [string]$DeploymentLocation = 'eastus',

    [Parameter()]
    [AllowEmptyString()]
    [string]$ResourceGroupName = '',

    [Parameter(Mandatory)]
    [string]$TemplateFile,

    [Parameter(Mandatory)]
    [string]$ParameterFile,

    [Parameter()]
    [string]$DeploymentName,

    [Parameter()]
    [string]$ArtifactOutputPath = "$env:BUILD_ARTIFACTSTAGINGDIRECTORY/bicep-$Action",

    [Parameter()]
    [ValidateSet('Provider', 'ProviderNoRbac', 'Template')]
    [string]$ValidationLevel = 'Provider',

    [Parameter()]
    [ValidateSet('FullResourcePayloads', 'ResourceIdOnly')]
    [string]$WhatIfResultFormat = 'FullResourcePayloads',

    [Parameter()]
    [switch]$EnsureBicep,

    [Parameter()]
    [switch]$SkipBuild,

    [Parameter()]
    [switch]$SkipLint
)

$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Message)

    Write-Host ""
    Write-Host "========== $Message =========="
}

function Save-JsonText {
    param(
        [Parameter(Mandatory)]
        [string]$JsonText,

        [Parameter(Mandatory)]
        [string]$Path
    )

    $JsonText | Out-File -FilePath $Path -Encoding utf8
}

function Test-TemplatePlaceholder {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "$Name is empty or whitespace."
    }

    if ($Value -match '<[^>]+>') {
        throw "$Name still contains a template placeholder value: $Value"
    }
}

function Test-DeploymentTooling {
    param(
        [Parameter()]
        [switch]$EnsureBicep
    )

    Write-Section "Checking deployment tooling"

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI was not found on this agent."
    }

    try {
        $azureCliVersionJson = az version --output json
        $azureCliVersion = $azureCliVersionJson | ConvertFrom-Json
    }
    catch {
        throw "Azure CLI was found, but 'az version' failed. Confirm Azure CLI is installed correctly and available in PATH. Error: $_"
    }

    if ($EnsureBicep) {
        Write-Section "Ensuring Azure CLI-managed Bicep is installed"

        try {
            az bicep install
        }
        catch {
            throw "Failed to install Azure CLI-managed Bicep. Error: $_"
        }

        try {
            az bicep upgrade
        }
        catch {
            throw "Failed to upgrade Azure CLI-managed Bicep. Error: $_"
        }
    }

    try {
        $bicepVersion = az bicep version
    }
    catch {
        throw "Azure CLI-managed Bicep is not available. Run 'az bicep install' on the agent image, add -EnsureBicep when calling this script, or add an install step before deployment. Error: $_"
    }

    if ([string]::IsNullOrWhiteSpace($bicepVersion)) {
        throw "Azure CLI-managed Bicep version could not be determined. Run 'az bicep install' on the agent image, add -EnsureBicep when calling this script, or add an install step before deployment."
    }

    Write-Host "Azure CLI version: $($azureCliVersion.'azure-cli')"
    Write-Host "Bicep version: $bicepVersion"

    return [ordered]@{
        azureCliVersion = $azureCliVersion
        bicepVersion    = $bicepVersion
    }
}

function New-DefaultDeploymentName {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Validate', 'WhatIf', 'Deploy')]
        [string]$Action
    )

    $actionName = $Action.ToLowerInvariant()
    $buildId = $env:BUILD_BUILDID

    if (-not [string]::IsNullOrWhiteSpace($buildId)) {
        return "bicep-$actionName-$buildId"
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    return "bicep-$actionName-$timestamp"
}

try {
    Write-Section "Preparing $Action operation"

    Write-Section "Checking script inputs"

    if ($DeploymentScope -eq 'ResourceGroup') {
        Test-TemplatePlaceholder -Name 'ResourceGroupName' -Value $ResourceGroupName
    }
    Test-TemplatePlaceholder -Name 'DeploymentLocation' -Value $DeploymentLocation
    Test-TemplatePlaceholder -Name 'TemplateFile' -Value $TemplateFile
    Test-TemplatePlaceholder -Name 'ParameterFile' -Value $ParameterFile
    Test-TemplatePlaceholder -Name 'DeploymentName' -Value $DeploymentName
    Test-TemplatePlaceholder -Name 'ArtifactOutputPath' -Value $ArtifactOutputPath

    if ([string]::IsNullOrWhiteSpace($DeploymentName)) {
        $DeploymentName = New-DefaultDeploymentName -Action $Action
    }

    if ($DeploymentScope -eq 'ResourceGroup' -and [string]::IsNullOrWhiteSpace($ResourceGroupName)) {
        throw "ResourceGroupName is required when DeploymentScope is ResourceGroup."
    }

    if ($DeploymentScope -eq 'Subscription' -and [string]::IsNullOrWhiteSpace($DeploymentLocation)) {
        throw "DeploymentLocation is required when DeploymentScope is Subscription."
    }

    if (-not (Test-Path $TemplateFile)) {
        throw "Template file not found: $TemplateFile"
    }

    if (-not (Test-Path $ParameterFile)) {
        throw "Parameter file not found: $ParameterFile"
    }

    Write-Section "Checking parameter file placeholders"

    $parameterFileContent = Get-Content -Path $ParameterFile -Raw

    if ($parameterFileContent -match '<[^>]+>') {
        $placeholderValues = [regex]::Matches($parameterFileContent, '<[^>]+>') |
            ForEach-Object { $_.Value } |
            Sort-Object -Unique

        throw "Parameter file contains unreplaced template placeholders: $($placeholderValues -join ', ')"
    }

    $tooling = Test-DeploymentTooling -EnsureBicep:$EnsureBicep

    New-Item -ItemType Directory -Force -Path $ArtifactOutputPath | Out-Null

    $compiledTemplatePath = Join-Path $ArtifactOutputPath "compiled-template.json"
    $resultPath = Join-Path $ArtifactOutputPath "$($Action.ToLowerInvariant())-result.json"
    $metadataPath = Join-Path $ArtifactOutputPath "metadata.json"
    $summaryPath = Join-Path $ArtifactOutputPath "summary.md"

    Write-Section "Capturing metadata"

    $metadata = [ordered]@{
        action            = $Action
        generatedAtUtc    = (Get-Date).ToUniversalTime().ToString("o")
        deploymentScope   = $DeploymentScope
        deploymentLocation = $DeploymentLocation
        resourceGroupName = $ResourceGroupName
        templateFile      = $TemplateFile
        parameterFile     = $ParameterFile
        deploymentName    = $DeploymentName
        validationLevel   = $ValidationLevel
        buildId           = $env:BUILD_BUILDID
        buildNumber       = $env:BUILD_BUILDNUMBER
        sourceBranch      = $env:BUILD_SOURCEBRANCH
        sourceVersion     = $env:BUILD_SOURCEVERSION
        azureCliVersion   = $tooling.azureCliVersion
        bicepVersion      = $tooling.bicepVersion
    }

    $metadata | ConvertTo-Json -Depth 20 | Out-File -FilePath $metadataPath -Encoding utf8

    if (-not $SkipLint) {
        Write-Section "Linting Bicep template"

        az bicep lint `
            --file $TemplateFile
    }

    if (-not $SkipBuild) {
        Write-Section "Building Bicep template"

        az bicep build `
            --file $TemplateFile `
            --outfile $compiledTemplatePath
    }

    if ($DeploymentScope -eq 'ResourceGroup') {
        $deploymentCommandScope = 'group'
        $commonArgs = @(
            '--name', $DeploymentName,
            '--resource-group', $ResourceGroupName,
            '--template-file', $TemplateFile,
            '--parameters', "@$ParameterFile"
        )
    }
    else {
        $deploymentCommandScope = 'sub'
        $commonArgs = @(
            '--name', $DeploymentName,
            '--location', $DeploymentLocation,
            '--template-file', $TemplateFile,
            '--parameters', "@$ParameterFile"
        )
    }

    switch ($Action) {
        'Validate' {
            Write-Section "Validating $DeploymentScope deployment"

            if ($deploymentCommandScope -eq 'group') {
                $result = az deployment group validate `
                    @commonArgs `
                    --validation-level $ValidationLevel `
                    --output json
            }
            else {
                $result = az deployment sub validate `
                    @commonArgs `
                    --validation-level $ValidationLevel `
                    --output json
            }

            Save-JsonText -JsonText $result -Path $resultPath
        }

        'WhatIf' {
            Write-Section "Running $DeploymentScope what-if"

            if ($deploymentCommandScope -eq 'group') {
                $result = az deployment group what-if `
                    @commonArgs `
                    --validation-level $ValidationLevel `
                    --result-format $WhatIfResultFormat `
                    --no-pretty-print `
                    --output json
            }
            else {
                $result = az deployment sub what-if `
                    @commonArgs `
                    --validation-level $ValidationLevel `
                    --result-format $WhatIfResultFormat `
                    --no-pretty-print `
                    --output json
            }

            Save-JsonText -JsonText $result -Path $resultPath
        }

        'Deploy' {
            Write-Section "Creating $DeploymentScope deployment"

            if ($deploymentCommandScope -eq 'group') {
                $result = az deployment group create `
                    @commonArgs `
                    --output json
            }
            else {
                $result = az deployment sub create `
                    @commonArgs `
                    --output json
            }

            Save-JsonText -JsonText $result -Path $resultPath
        }
    }

    Write-Section "Writing summary"

    $summary = @"
# Bicep $Action Summary

| Field            | Value                 |
|------------------|-----------------------|
| Action           | $Action               |
| Scope            | $DeploymentScope      |
| Location         | $DeploymentLocation   |
| Resource group   | $ResourceGroupName    |
| Template file    | $TemplateFile         |
| Parameter file   | $ParameterFile        |
| Deployment name  | $DeploymentName       |
| Validation level | $ValidationLevel      |
| Generated UTC    | $((Get-Date).ToUniversalTime().ToString("o")) |

## Artifacts

- ``metadata.json``
- ``$($Action.ToLowerInvariant())-result.json``
$(if (-not $SkipBuild) { "- ``compiled-template.json``" })

## Result

$Action completed successfully.
"@

    $summary | Out-File -FilePath $summaryPath -Encoding utf8

    Write-Host "$Action completed successfully."
    Write-Host "Artifacts written to: $ArtifactOutputPath"
}
catch {
    Write-Error "$Action failed: $_"
    exit 1
}
