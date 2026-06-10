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

    [Parameter()]
    [AllowEmptyString()]
    [string]$TemplateFile = '',

    [Parameter(Mandatory)]
    [string]$ParameterFile,

    [Parameter()]
    [AllowEmptyString()]
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
    [switch]$SkipLint,

    [Parameter()]
    [string[]]$AdditionalParameters = @(),

)

$ErrorActionPreference = 'Stop'

function Write-Section {
    param([string]$Message)
    Write-Host ""
    Write-Host "========== $Message =========="
}

function Save-JsonText {
    param(
        [Parameter()]
        [AllowEmptyString()]
        [string]$JsonText,

        [Parameter(Mandatory)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($JsonText)) {
        $JsonText = '{ "status": "Succeeded", "message": "Azure CLI returned no JSON output." }'
    }

    $JsonText | Out-File -FilePath $Path -Encoding utf8
}

function Invoke-AzCliJson {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [string]$OperationName
    )

    Write-Host "az $($Arguments -join ' ')"
    $output = & az @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()

    if ($exitCode -ne 0) {
        throw "$OperationName failed with exit code $exitCode. Azure CLI output: $text"
    }

    return $text
}

function Invoke-NativeCommand {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments,

        [Parameter(Mandatory)]
        [string]$OperationName
    )

    Write-Host "az $($Arguments -join ' ')"
    $output = & az @Arguments 2>&1
    $exitCode = $LASTEXITCODE
    $text = ($output | Out-String).Trim()

    if ($exitCode -ne 0) {
        throw "$OperationName failed with exit code $exitCode. Azure CLI output: $text"
    }

    if (-not [string]::IsNullOrWhiteSpace($text)) {
        Write-Host $text
    }
}

function Test-TemplatePlaceholder {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Name,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Value,

        [Parameter()]
        [switch]$AllowEmpty
    )

    if (-not $AllowEmpty -and [string]::IsNullOrWhiteSpace($Value)) {
        throw "$Name is empty or whitespace."
    }

    if ($Value -match '<[^>]+>') {
        throw "$Name still contains a template placeholder value: $Value"
    }
}

function Test-DeploymentTooling {
    param([switch]$EnsureBicep)

    Write-Section "Checking deployment tooling"

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI was not found on this agent."
    }

    $azureCliVersionJson = Invoke-AzCliJson -OperationName 'az version' -Arguments @('version', '--output', 'json')
    $azureCliVersion = $azureCliVersionJson | ConvertFrom-Json

    if ($EnsureBicep) {
        Write-Section "Ensuring Azure CLI-managed Bicep is installed"
        Invoke-NativeCommand -OperationName 'az bicep install' -Arguments @('bicep', 'install', '--only-show-errors')
        Invoke-NativeCommand -OperationName 'az bicep upgrade' -Arguments @('bicep', 'upgrade', '--only-show-errors')
    }

    $bicepVersionOutput = & az bicep version --only-show-errors 2>&1
    $bicepExitCode = $LASTEXITCODE
    $bicepVersion = ($bicepVersionOutput | Out-String).Trim()

    if ($bicepExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($bicepVersion)) {
        throw "Azure CLI-managed Bicep is not available. Run 'az bicep install' on the agent image, add -EnsureBicep when calling this script, or add an install step before deployment. Error: $bicepVersion"
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

function Get-BicepParamUsingPath {
    param(
        [Parameter(Mandatory)]
        [string]$ParameterFilePath
    )

    $content = Get-Content -Path $ParameterFilePath -Raw
    $match = [regex]::Match($content, '(?m)^\s*using\s+[''" ](?<path>[^''" ]+)[''" ]')

    if (-not $match.Success) {
        return $null
    }

    $usingPath = $match.Groups['path'].Value
    if ([System.IO.Path]::IsPathRooted($usingPath)) {
        return $usingPath
    }

    $parameterDirectory = Split-Path -Path $ParameterFilePath -Parent
    return [System.IO.Path]::GetFullPath((Join-Path $parameterDirectory $usingPath))
}

function Remove-BicepComments {
    param(
        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Content
    )

    $result = [System.Text.StringBuilder]::new()
    $inSingleQuotedString = $false
    $inDoubleQuotedString = $false
    $inLineComment = $false
    $inBlockComment = $false

    for ($i = 0; $i -lt $Content.Length; $i++) {
        $current = $Content[$i]
        $next = if ($i + 1 -lt $Content.Length) { $Content[$i + 1] } else { [char]0 }

        if ($inLineComment) {
            if ($current -eq "`r" -or $current -eq "`n") {
                $inLineComment = $false
                [void]$result.Append($current)
            }

            continue
        }

        if ($inBlockComment) {
            if ($current -eq '*' -and $next -eq '/') {
                $inBlockComment = $false
                $i++
                continue
            }

            if ($current -eq "`r" -or $current -eq "`n") {
                [void]$result.Append($current)
            }

            continue
        }

        if (-not $inSingleQuotedString -and -not $inDoubleQuotedString) {
            if ($current -eq '/' -and $next -eq '/') {
                $inLineComment = $true
                $i++
                continue
            }

            if ($current -eq '/' -and $next -eq '*') {
                $inBlockComment = $true
                $i++
                continue
            }
        }

        if (-not $inDoubleQuotedString -and $current -eq "'") {
            $inSingleQuotedString = -not $inSingleQuotedString
        }
        elseif (-not $inSingleQuotedString -and $current -eq '"') {
            $inDoubleQuotedString = -not $inDoubleQuotedString
        }

        [void]$result.Append($current)
    }

    return $result.ToString()
}

try {
    Write-Section "Preparing $Action operation"

    if ([string]::IsNullOrWhiteSpace($DeploymentName)) {
        $DeploymentName = New-DefaultDeploymentName -Action $Action
    }

    Write-Section "Checking script inputs"

    $isBicepParam = [System.IO.Path]::GetExtension($ParameterFile).Equals('.bicepparam', [System.StringComparison]::OrdinalIgnoreCase)

    if ($DeploymentScope -eq 'ResourceGroup') {
        Test-TemplatePlaceholder -Name 'ResourceGroupName' -Value $ResourceGroupName
    }
    else {
        Test-TemplatePlaceholder -Name 'ResourceGroupName' -Value $ResourceGroupName -AllowEmpty
    }

    Test-TemplatePlaceholder -Name 'DeploymentLocation' -Value $DeploymentLocation
    Test-TemplatePlaceholder -Name 'TemplateFile' -Value $TemplateFile -AllowEmpty:$isBicepParam
    Test-TemplatePlaceholder -Name 'ParameterFile' -Value $ParameterFile
    Test-TemplatePlaceholder -Name 'DeploymentName' -Value $DeploymentName
    Test-TemplatePlaceholder -Name 'ArtifactOutputPath' -Value $ArtifactOutputPath

    if ($DeploymentScope -eq 'Subscription' -and [string]::IsNullOrWhiteSpace($DeploymentLocation)) {
        throw "DeploymentLocation is required when DeploymentScope is Subscription."
    }

    if (-not (Test-Path $ParameterFile)) {
        throw "Parameter file not found: $ParameterFile"
    }

    if (-not $isBicepParam -and -not (Test-Path $TemplateFile)) {
        throw "Template file not found: $TemplateFile"
    }

    if ($isBicepParam) {
        $usingTemplatePath = Get-BicepParamUsingPath -ParameterFilePath $ParameterFile
        if (-not [string]::IsNullOrWhiteSpace($usingTemplatePath) -and -not (Test-Path $usingTemplatePath)) {
            throw "The Bicep parameters file uses '$usingTemplatePath', but that template file was not found. Update the 'using' line in the .bicepparam file or move/rename the template."
        }
    }

    Write-Section "Checking parameter file placeholders"

    $parameterFileContent = Get-Content -Path $ParameterFile -Raw
    $parameterFileContentWithoutComments = Remove-BicepComments -Content $parameterFileContent

    if ($parameterFileContentWithoutComments -match '<[^>]+>') {
        $placeholderValues = [regex]::Matches($parameterFileContentWithoutComments, '<[^>]+>') |
        ForEach-Object { $_.Value } |
        Sort-Object -Unique

        throw "Parameter file contains unreplaced template placeholders outside comments: $($placeholderValues -join ', ')"
    }

    $tooling = Test-DeploymentTooling -EnsureBicep:$EnsureBicep

    New-Item -ItemType Directory -Force -Path $ArtifactOutputPath | Out-Null

    $compiledTemplatePath = Join-Path $ArtifactOutputPath "compiled-template.json"
    $compiledParametersPath = Join-Path $ArtifactOutputPath "compiled-parameters.json"
    $resultPath = Join-Path $ArtifactOutputPath "$($Action.ToLowerInvariant())-result.json"
    $metadataPath = Join-Path $ArtifactOutputPath "metadata.json"
    $summaryPath = Join-Path $ArtifactOutputPath "summary.md"

    Write-Section "Capturing metadata"

    $metadata = [ordered]@{
        action             = $Action
        deploymentScope    = $DeploymentScope
        generatedAtUtc     = (Get-Date).ToUniversalTime().ToString('o')
        resourceGroupName  = $ResourceGroupName
        deploymentLocation = $DeploymentLocation
        templateFile       = $TemplateFile
        parameterFile      = $ParameterFile
        isBicepParam       = $isBicepParam
        deploymentName     = $DeploymentName
        validationLevel    = $ValidationLevel
        buildId            = $env:BUILD_BUILDID
        buildNumber        = $env:BUILD_BUILDNUMBER
        sourceBranch       = $env:BUILD_SOURCEBRANCH
        sourceVersion      = $env:BUILD_SOURCEVERSION
        azureCliVersion    = $tooling.azureCliVersion
        bicepVersion       = $tooling.bicepVersion
    }

    $metadata | ConvertTo-Json -Depth 20 | Out-File -FilePath $metadataPath -Encoding utf8

    if (-not $SkipLint) {
        Write-Section "Linting Bicep template"

        if ($isBicepParam) {
            $usingTemplatePath = Get-BicepParamUsingPath -ParameterFilePath $ParameterFile
            if (-not [string]::IsNullOrWhiteSpace($usingTemplatePath)) {
                Invoke-NativeCommand -OperationName 'az bicep lint' -Arguments @('bicep', 'lint', '--file', $usingTemplatePath)
            }
            else {
                Write-Host "Skipping lint because no using statement was found in $ParameterFile."
            }
        }
        else {
            Invoke-NativeCommand -OperationName 'az bicep lint' -Arguments @('bicep', 'lint', '--file', $TemplateFile)
        }
    }

    if (-not $SkipBuild) {
        Write-Section "Building Bicep template"

        if ($isBicepParam) {
            Invoke-NativeCommand -OperationName 'az bicep build-params' -Arguments @('bicep', 'build-params', '--file', $ParameterFile, '--outfile', $compiledParametersPath)
        }
        else {
            Invoke-NativeCommand -OperationName 'az bicep build' -Arguments @('bicep', 'build', '--file', $TemplateFile, '--outfile', $compiledTemplatePath)
        }
    }

    $baseArgs = @('--name', $DeploymentName)

    if ($DeploymentScope -eq 'Subscription') {
        $scopeArgs = @('deployment', 'sub')
        $baseArgs += @('--location', $DeploymentLocation)
    }
    else {
        $scopeArgs = @('deployment', 'group')
        $baseArgs += @('--resource-group', $ResourceGroupName)
    }

    if ($isBicepParam) {
        # For .bicepparam files, pass the file directly and do not pass --template-file.
        $deploymentArgs = $baseArgs + @('--parameters', $ParameterFile)
    }
    else {
        $deploymentArgs = $baseArgs + @('--template-file', $TemplateFile, '--parameters', "@$ParameterFile")
    }

    if ($AdditionalParameters.Count -gt 0) {
        $deploymentArgs += @('--parameters')
        $deploymentArgs += $AdditionalParameters
    }

    switch ($Action) {
        'Validate' {
            Write-Section "Validating deployment"
            $deploymentArgsFinal = $scopeArgs + @('validate') + $deploymentArgs + @('--validation-level', $ValidationLevel, '--output', 'json')
            $result = Invoke-AzCliJson -OperationName 'az deployment validate' -Arguments $deploymentArgsFinal
            Save-JsonText -JsonText $result -Path $resultPath
        }

        'WhatIf' {
            Write-Section "Running what-if"
            $deploymentArgsFinal = $scopeArgs + @('what-if') + $deploymentArgs + @('--validation-level', $ValidationLevel, '--result-format', $WhatIfResultFormat, '--no-pretty-print', '--output', 'json')
            $result = Invoke-AzCliJson -OperationName 'az deployment what-if' -Arguments $deploymentArgsFinal
            Save-JsonText -JsonText $result -Path $resultPath
        }

        'Deploy' {
            Write-Section "Creating deployment"
            $deploymentArgsFinal = $scopeArgs + @('create') + $deploymentArgs + @('--output', 'json')
            $result = Invoke-AzCliJson -OperationName 'az deployment create' -Arguments $deploymentArgsFinal
            Save-JsonText -JsonText $result -Path $resultPath
        }
    }

    Write-Section "Writing summary"

    $summary = @"
# Bicep $Action Summary

| Field | Value |
|---|---|
| Action | $Action |
| Deployment scope | $DeploymentScope |
| Resource group | $ResourceGroupName |
| Deployment location | $DeploymentLocation |
| Template file | $TemplateFile |
| Parameter file | $ParameterFile |
| Parameter file type | $(if ($isBicepParam) { '.bicepparam' } else { 'JSON parameters' }) |
| Deployment name | $DeploymentName |
| Validation level | $ValidationLevel |
| Generated UTC | $((Get-Date).ToUniversalTime().ToString('o')) |

## Artifacts

- ``metadata.json``
- ``$($Action.ToLowerInvariant())-result.json``
$(if (-not $SkipBuild -and $isBicepParam) { "- ``compiled-parameters.json``" } elseif (-not $SkipBuild) { "- ``compiled-template.json``" })

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
