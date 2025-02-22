function Copy-OctopusScriptModules
{
    param
    (
        $SourceData,
        $DestinationData,
        $cloneScriptOptions,
        $CloneLibraryVariableSets
    )

    $filteredList = Get-OctopusFilteredList -itemList $sourceData.ScriptModuleList -itemType "Script Modules" -filters $cloneScriptOptions.ScriptModulesToClone

    Write-OctopusChangeLog "Script Modules"
    if ($filteredList.length -eq 0)
    {
        Write-OctopusChangeLog " - No script modules found to clone matching the filters"
        return
    }

    Write-OctopusVerbose "Getting a clone of the script options so we can always update the module text"
    $newCloneScriptOptions = Copy-OctopusObject -ItemToCopy $cloneScriptOptions -ClearIdValue $false -SpaceId $null
    $newCloneScriptOptions.OverwriteExistingVariables = $true

    foreach($scriptModule in $filteredList)
    {
        Write-OctopusVerbose "Starting clone of $($scriptModule.Name)"

        $destinationVariableSet = Get-OctopusItemByName -ItemList $destinationData.ScriptModuleList -ItemName $scriptModule.Name

        if ($null -eq $destinationVariableSet)
        {
            Write-OctopusVerbose "Script Module Variable Set $($scriptModule.Name) was not found in destination, creating new base record."
            Write-OctopusChangeLog " - Add $($scriptModule.Name) variable set"
            
            $copyscriptModule = Copy-OctopusObject -ItemToCopy $scriptModule -ClearIdValue $true -SpaceId $destinationData.SpaceId                       
            $copyscriptModule.VariableSetId = $null
            
            $destinationVariableSet = Save-OctopusVariableSet -libraryVariableSet $copyscriptModule -destinationData $destinationData
            $destinationData.ScriptModuleList += $destinationVariableSet            
        }
        else
        {
            Write-OctopusVerbose "Script Module Variable Set $($scriptModule.Name) already exists in destination."
            Write-OctopusChangeLog " - $($scriptModule.Name) already exits, skipping creation"
        }
        
        Write-OctopusVerbose "The script module variable set has been created, time to copy over the script module itself"

        $scriptModuleVariables = Get-OctopusVariableSetVariables -variableSet $scriptModule -OctopusData $sourceData
        $destinationVariableSetVariables = Get-OctopusVariableSetVariables -variableSet $destinationVariableSet -OctopusData $destinationData 

        if ($CloneLibraryVariableSets -eq $true)
        {
            Write-OctopusPostCloneCleanUp "*****************Starting clone of script module $($scriptModule.Name)*****************"
            Copy-OctopusVariableSetValues -SourceVariableSetVariables $scriptModuleVariables -DestinationVariableSetVariables $destinationVariableSetVariables -SourceData $SourceData -DestinationData $DestinationData -SourceProjectData @{} -DestinationProjectData @{} -CloneScriptOptions $newCloneScriptOptions
            Write-OctopusPostCloneCleanUp "*****************Ending clone of script module $($scriptModule.Name)*******************"
        }
    }

    Write-OctopusSuccess "Script Modules successfully cloned"        
}