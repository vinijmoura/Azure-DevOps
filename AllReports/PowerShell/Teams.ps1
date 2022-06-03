Param
(
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $projectId,
    $projectName,
    $LogFile
)

$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriTeams = $UriOrganization + "_apis/projects/$($projectId)/teams"
$TeamsResult = Invoke-RestMethod -Uri $uriTeams -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($team in $TeamsResult.value)
{
    $uriTeamSettings = $UriOrganization + "$($projectId)/$($team.id)/_apis/work/teamsettings?api-version=6.1-preview.1"
    $TeamSettingsResult = Invoke-RestMethod -Uri $uriTeamSettings -Method get -Headers $AzureDevOpsAuthenicationHeader
    
    #Teams
    $Teams = New-Object 'Collections.Generic.List[pscustomobject]'
    $table = $db.Tables["Teams"]

    $teamObject = [PSCustomObject] [ordered]@{
        TeamProjectId=$projectId
	    TeamId=$team.id
	    TeamName=$team.name
	    TeamWorkingWithBugs=$TeamSettingsResult.bugsBehavior
    }
    $Teams.Add($teamObject)
    Write-SqlTableData -InputData $Teams -InputObject $table
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting team: $($team.name) from the project $($projectName) on table Teams"
    
    [array]$backlogVisibilities = ($TeamSettingsResult.backlogVisibilities | Get-Member -MemberType NoteProperty).Name
    Foreach ($blv in $backlogVisibilities)
    {
        #TeamsBackLogLevels        
        $table = $db.Tables["TeamsBackLogLevels"]        
        if ($TeamSettingsResult.backlogVisibilities.$blv -eq $true)
        {
            $TeamsBackLogLevels = New-Object 'Collections.Generic.List[pscustomobject]'
            $uriBackLogLevel = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/backlogs/$($blv)?api-version=6.0-preview.1"
            $backLogLevelResult = Invoke-RestMethod -Uri $uriBackLogLevel -Method get -Headers $AzureDevOpsAuthenicationHeader

            $teamBackLogLevelsObject = [PSCustomObject] [ordered]@{
                TeamId=$team.id
	            TeamBackLogLevel=$backLogLevelResult.name
            }
            $TeamsBackLogLevels.Add($teamBackLogLevelsObject)
            Write-SqlTableData -InputData $TeamsBackLogLevels -InputObject $table
            & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting BackLogLevel: $($backLogLevelResult.name) from the project $($projectName) and team $($team.name) on table TeamsBackLogLevels"

            $TeamsBoardColumns = New-Object 'Collections.Generic.List[pscustomobject]'
            $table = $db.Tables["TeamsBoardColumns"]
            $bc = 1

            $uriBoardsColumns =  $UriOrganization + "$($project.id)/$($team.id)/_apis/work/boards/$($backLogLevelResult.name)"
            $BoardsColumnsResult = Invoke-RestMethod -Uri $uriBoardsColumns -Method get -Headers $AzureDevOpsAuthenicationHeader
            Foreach ($boardColumn in $BoardsColumnsResult.columns)
            {
                switch ( $boardColumn.columnType )
                {
                    'incoming' { $isSplit = $false }
                    'outgoing' { $isSplit = $false }
                    default
                    {
                        $isSplit = $boardColumn.isSplit
                    }
                }
                
                [array]$stateMappings = ($boardColumn.stateMappings | Get-Member -MemberType NoteProperty).Name

                Foreach ($sm in $stateMappings)
                {
                    $teamsBoardColumnsObject = [PSCustomObject] [ordered]@{
                        TeamId=$team.id
                        TeamBackLogLevel=$backLogLevelResult.name
                        BoardColumnOrder=$bc
                        BoardColumnName=$($boardColumn.Name)
                        BoardColumnStateMappingsWorkItemType=$sm
                        BoardColumnStateMappingsState=$($boardColumn.stateMappings.$sm)
                        BoardColumnIsSplit=$($isSplit)
                    }
                    $TeamsBoardColumns.Add($teamsBoardColumnsObject)                
                }
                $bc++
            }
            if ($TeamsBoardColumns.Count -gt 0)
            {
                Write-SqlTableData -InputData $TeamsBoardColumns -InputObject $table
                & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Team Board Columns to which project $($projectName) and team $($team.name) belongs on table TeamsBoardColumns"
            }

            $TeamsBoardLanes = New-Object 'Collections.Generic.List[pscustomobject]'
            $table = $db.Tables["TeamsBoardLanes"]
            $bl = 1 
            Foreach ($boardLane in $BoardsColumnsResult.rows)
            {
                if (!$boardLane.name) { $boardLaneName = 'Default' } else { $boardLaneName = $boardLane.name }
                $teamsBoardLanesObject = [PSCustomObject] [ordered]@{
                    TeamId=$team.id
                    TeamBackLogLevel=$backLogLevelResult.name
                    BoardLaneOrder=$bl
                    BoardLaneName=$boardLaneName
                }
                $TeamsBoardLanes.Add($teamsBoardLanesObject)        
                $bl++
            }
            if ($TeamsBoardLanes.Count -gt 0)
            {
                Write-SqlTableData -InputData $TeamsBoardLanes -InputObject $table
                & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Team Board Lanes to which project $($projectName) and team $($team.name) belongs on table TeamsBoardLanes"
            }
        }
    }
     
    #TeamsWorkingDays
    $TeamsWorkingDays = New-Object 'Collections.Generic.List[pscustomobject]'
    $table = $db.Tables["TeamsWorkingDays"]

    Foreach($wd in $TeamSettingsResult.workingDays)
    {
        $teamWorkingDaysObject = [PSCustomObject] [ordered]@{
            TeamId=$team.id
	        TeamWorkingDay=$wd
        }
        $TeamsWorkingDays.Add($teamWorkingDaysObject)
    }
    if ($TeamsWorkingDays.Count)
    {
        Write-SqlTableData -InputData $TeamsWorkingDays -InputObject $table
        & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Team Board Working Days to which project $($projectName) and team $($team.name) belongs on table TeamsWorkingDays"
    }
}