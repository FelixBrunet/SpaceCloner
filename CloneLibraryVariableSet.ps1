param (
    $SourceOctopusUrl,
    $SourceOctopusApiKey,
    $SourceSpaceName,
    $DestinationOctopusUrl,
    $DestinationOctopusApiKey,
    $DestinationSpaceName,  
    $SourceVariableSetName,
    $DestinationVariableSetName,
    $OverwriteExistingVariables,    
    $IgnoreVersionCheckResult,
    $SkipPausingWhenIgnoringVersionCheckResult,
    $VariableChannelScopingMatch,
    $VariableEnvironmentScopingMatch,
    $VariableProcessOwnerScopingMatch,
    $VariableActionScopingMatch,
    $VariableMachineScopingMatch,
    $VariableAccountScopingMatch,
    $VariableCertificateScopingMatch,
    $WhatIf     
)

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Logging.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Core", "Util.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataAdapter.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusDataFactory.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusRepository.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "DataAccess", "OctopusFakeFactory.ps1"))

. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "LibraryVariableSetCloner.ps1"))
. ([System.IO.Path]::Combine($PSScriptRoot, "src", "Cloners", "VariableSetValuesCloner.ps1"))

$ErrorActionPreference = "Stop"

if ($null -eq $OverwriteExistingVariables)
{
    $OverwriteExistingVariables = $false
}

if ($null -eq $IgnoreVersionCheckResult)
{
    $IgnoreVersionCheckResult = $false
}

if ($null -eq $SkipPausingWhenIgnoringVersionCheckResult)
{
    $SkipPausingWhenIgnoringVersionCheckResult = $false
}

if ($null -eq $WhatIf)
{
    $WhatIf = $false
}

$VariableChannelScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableChannelScopingMatch" -ParameterValue $VariableChannelScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableEnvironmentScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableEnvironmentScopingMatch" -ParameterValue $VariableEnvironmentScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableProcessOwnerScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableProcessOwnerScopingMatch" -ParameterValue $VariableProcessOwnerScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableActionScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableActionScopingMatch" -ParameterValue $VariableActionScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableMachineScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableMachineScopingMatch" -ParameterValue $VariableMachineScopingMatch -DefaultValue "SkipUnlessPartialMatch" -SingleValueItem $false
$VariableAccountScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableAccountScopingMatch" -ParameterValue $VariableAccountScopingMatch -DefaultValue "SkipUnlessExactMatch" -SingleValueItem $true
$VariableCertificateScopingMatch = Test-OctopusScopeMatchParameter -ParameterName "VariableCertificateScopingMatch" -ParameterValue $VariableCertificateScopingMatch -DefaultValue "SkipUnlessExactMatch" -SingleValueItem $true

$CloneScriptOptions = @{
    OverwriteExistingVariables = $OverwriteExistingVariables;     
    LibraryVariableSetsToClone = $SourceVariableSetName;
    DestinationVariableSetName = $DestinationVariableSetName;   
    VariableChannelScopingMatch = $VariableChannelScopingMatch;
    VariableEnvironmentScopingMatch = $VariableEnvironmentScopingMatch;
    VariableProcessOwnerScopingMatch = $VariableProcessOwnerScopingMatch;
    VariableActionScopingMatch = $VariableActionScopingMatch;
    VariableMachineScopingMatch = $VariableMachineScopingMatch;
    VariableAccountScopingMatch = $VariableAccountScopingMatch;
    VariableCertificateScopingMatch = $VariableCertificateScopingMatch;
}

Write-OctopusVerbose "The clone parameters sent in are:"
Write-OctopusVerbose $($CloneScriptOptions | ConvertTo-Json -Depth 10)

$sourceData = Get-OctopusData -octopusUrl $SourceOctopusUrl -octopusApiKey $SourceOctopusApiKey -spaceName $SourceSpaceName -whatIf $whatIf
$destinationData = Get-OctopusData -octopusUrl $DestinationOctopusUrl -octopusApiKey $DestinationOctopusApiKey -spaceName $DestinationSpaceName -whatIf $whatIf

Compare-OctopusVersions -SourceData $sourceData -DestinationData $destinationData -IgnoreVersionCheckResult $IgnoreVersionCheckResult -SkipPausingWhenIgnoringVersionCheckResult $SkipPausingWhenIgnoringVersionCheckResult

Copy-OctopusLibraryVariableSets -SourceData $sourceData -DestinationData $destinationData  -cloneScriptOptions $CloneScriptOptions -CloneLibraryVariableSets $true

$logPath = Get-OctopusLogPath
$cleanupLogPath = Get-OctopusCleanUpLogPath

Write-OctopusSuccess "The script to clone the variable set $SourceVariableSetName on the space $SourceSpaceName on $SourceOctopusUrl to the variable set $DestinationVariableSetName on the space $DestinationSpaceName on $DestinationOctopusUrl.  Please see $logPath for more details."
Write-OctopusWarning "You might have post clean-up tasks to finish.  Any sensitive variables or encrypted values were created with dummy values which you must replace.  Please see $cleanUpLogPath for a list of items to fix."
