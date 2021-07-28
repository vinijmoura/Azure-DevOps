Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ConnStr
)

$SQLQuery = "DELETE FROM TeamSettingsTaskBoardColumnsWorkItemType"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM TeamSettingsTaskBoardColumns"
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
        $uriTeamTaskboardColumns = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/taskboardcolumns?api-version=6.1-preview.1"
        $TeamTaskboardColumnsResult = Invoke-RestMethod -Uri $uriTeamTaskboardColumns -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($teamTaskBoardColumn in $TeamTaskboardColumnsResult.columns)
        {
            Foreach ($mapping in $teamTaskBoardColumn.mappings)
            {
                $SQLQuery = "INSERT INTO TeamSettingsTaskBoardColumns (
                            TeamProjectName,
                            TeamName,
                            TeamSettingsTaskBoardColumnName,
                            TeamSettingsTaskBoardColumnOrder
                            )
                            VALUES(
                            '$($project.name)',
                            '$($team.name)',
                            '$($teamTaskBoardColumn.name)',
                            $($teamTaskBoardColumn.order)
                            )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

                $SQLQuery = "INSERT INTO TeamSettingsTaskBoardColumnsWorkItemType (
                                    TeamSettingsTaskBoardColumnsId,
                                    WorkItemType,
                                    WorkItemState
                                    )
                                    SELECT
                                    TeamSettingsTaskBoardColumnsId,
                                    '$($mapping.workItemType)',
                                    '$($mapping.state)'
                                    FROM TeamSettingsTaskBoardColumns WHERE TeamProjectName='$($project.name)' AND TeamName='$($team.name)' AND TeamSettingsTaskBoardColumnName='$($teamTaskBoardColumn.name)' "
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }
}