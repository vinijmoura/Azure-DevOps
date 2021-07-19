Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ConnStr
)

$SQLQuery = "DELETE FROM TeamSettingsBoardLanes"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM TeamSettingsBoardColumns"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM TeamSettingsBoards"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriTeams = $UriOrganization + "_apis/projects/$($project.id)/teams"
    $TeamsResult = Invoke-RestMethod -Uri $uriTeams -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($team in $TeamsResult.value)
    {
        $uriTeamBoards = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/boards?api-version=6.1-preview.1"
        $TeamBoardsResult = Invoke-RestMethod -Uri $uriTeamBoards -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($teamboard in $TeamBoardsResult.value)
        {
            $SQLQuery = "INSERT INTO TeamSettingsBoards (
                            TeamProjectName,
                            TeamName,
                            TeamBackLogLevel
                            )
                            VALUES(
                            '$($project.name)',
                            '$($team.name)',
                            '$($teamboard.name)'
                            )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

            $bc = 1
            $TeamBoardsBacklogLevelResult = Invoke-RestMethod -Uri $teamboard.url -Method get -Headers $AzureDevOpsAuthenicationHeader
            Foreach ($boardColumn in $TeamBoardsBacklogLevelResult.columns)
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
                    $SQLQuery = "INSERT INTO TeamSettingsBoardColumns (
                                    TeamSettingBoardsId,
                                    BoardColumnOrder,
                                    BoardColumnName,
                                    BoardColumnStateMappingsWorkItemType,
                                    BoardColumnStateMappingsState,
                                    BoardColumnIsSplit
                                    )
                                    SELECT
                                    TeamSettingBoardsId,
                                    $bc,
                                    '$($boardColumn.Name)',
                                    '$($sm)',
                                    '$($boardColumn.stateMappings.$sm)',
                                    '$($isSplit)'
                                    FROM TeamSettingsBoards WHERE TeamProjectName='$($project.name)' AND TeamName='$($team.name)' AND TeamBackLogLevel='$($teamboard.name)' "
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                }
                $bc++
            }

            $bl = 1 
            Foreach ($boardLane in $TeamBoardsBacklogLevelResult.rows)
            {
                if (!$boardLane.name) { $boardLaneName = 'Default' } else { $boardLaneName = $boardLane.name }
                $SQLQuery = "INSERT INTO TeamSettingsBoardLanes (
                                TeamSettingBoardsId,
                                BoardLaneOrder,
                                BoardLaneName
                                )
                                SELECT
                                TeamSettingBoardsId,
                                $($bl),
                                '$($boardLaneName)'
                                FROM TeamSettingsBoards WHERE TeamProjectName='$($project.name)' AND TeamName='$($team.name)' AND TeamBackLogLevel='$($teamboard.name)' "
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                $bl++
            }
        }
    }
}