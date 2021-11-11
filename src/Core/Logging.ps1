$currentDate = Get-Date
$currentDateFormatted = $currentDate.ToString("yyyy_MM_dd_HH_mm_ss")
$clonerVersion = "3.0.2"

$logFolder = "$PSScriptRoot\..\..\"
$logArchiveFolder = "$PSScriptRoot\..\..\logs\archive_$currentDateFormatted" 

$logPath = [System.IO.Path]::Combine($logFolder, "Log.txt")
$cleanupLogPath = [System.IO.Path]::Combine($logFolder, "CleanUp.txt")
$changeLog = [System.IO.Path]::Combine($logFolder, "ChangeLog.txt")

if (Test-Path $logPath)
{
    if ((Test-Path -Path $logArchiveFolder) -eq $false)
    {
        New-Item -Path $logArchiveFolder -ItemType Directory
    }

    Get-ChildItem -Path "$logFolder\*.txt" | Move-Item -Destination $logArchiveFolder
}

function Get-OctopusCleanUpLogPath
{
    return $cleanupLogPath
}

function Get-OctopusLogPath
{
    return $logPath
}

function Write-OctopusVerbose
{
    param($message) 
       
    if ($null -ne $message)
    {
        Write-Verbose $message
        Write-OctopusLog $message
    }
}

function Write-OctopusChangeLog
{
    param ($message)

    if ($null -ne $message)
    {
        Add-Content -Value $message -Path $changeLog
    }
}

function Write-OctopusChangeLogListDetails
{
    param (
        $prefixSpaces,
        $idList,        
        $destinationList,
        $listType,
        $skipNameConversion
    )

    if ($null -eq $idList)
    {
        return
    }

    if ($idList.Count -eq 0)
    {
        return
    }

    Write-OctopusChangeLog "$prefixSpaces - $listType"

    foreach ($id in $idList)
    {
        if ($skipNameConversion)
        {
            Write-OctopusChangeLog "$prefixSpaces    - $id"    
        }
        else
        {
            $item = Get-OctopusItemById -ItemList $destinationList -ItemId $id
            if ($null -eq $item)
            {
                continue
            }
            
            Write-OctopusChangeLog "$prefixSpaces    - $($item.Name)"
        }        
    }
}

function Write-OctopusSuccess
{
    param($message)
    
    if ($null -ne $message)
    {
        Write-Host $message -ForegroundColor Green
        Write-OctopusLog $message    
    }
}

function Write-OctopusWarning
{
    param($message)

    if ($null -ne $message)
    {
        Write-Host "Warning $message" -ForegroundColor Yellow    
        Write-OctopusLog $message
    }
}

function Write-OctopusCritical
{
    param ($message)

    if ($null -ne $message)
    {
        Write-Host "Critical Message: $message" -ForegroundColor Red
        Write-OctopusLog $message
    }
}

function Write-OctopusPostCloneCleanUp
{
    param($message)
    
    Add-Content -Value "   $message" -Path $cleanupLogPath
}

function Write-OctopusPostCloneCleanUpHeader
{
    param($message)

    Add-Content -Value $message -Path $cleanupLogPath
}

function Write-OctopusLog
{
    param ($message)

   $message | Out-File -FilePath $logPath -Append
}

Write-OctopusSuccess "Using version $clonerVersion of the cloner."
