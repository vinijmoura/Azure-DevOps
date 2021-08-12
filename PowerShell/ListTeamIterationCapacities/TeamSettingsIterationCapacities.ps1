Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "DELETE FROM TeamSettingsIterationCapacities"
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
        $uriSprintsTeam = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/teamsettings/iterations"
        $SprintsTeamResult = Invoke-RestMethod -Uri $uriSprintsTeam -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($sprintteam in $SprintsTeamResult.value)
        {
            $startDate = $sprintteam.attributes.startDate
            $finishDate = $sprintteam.attributes.finishDate
            if (-not $startDate)
            {
                $startDate = '1900-01-01'
                $finishDate = '1900-01-01'
            }

            $uriTeamIterationCapacities =  $UriOrganization + "$($project.id)/_apis/work/iterations/$($sprintteam.id)/IterationCapacities?api-version=6.1-preview.1"
            $TeamIterationCapacitiesResult = Invoke-RestMethod -Uri $uriTeamIterationcapacities -Method get -Headers $AzureDevOpsAuthenicationHeader
            $SQLQuery = "INSERT INTO TeamSettingsIterationCapacities (
                            TeamProjectName,
                            TeamName,
                            IterationName,
                            IterationStartDate,
                            IterationFinishDate,
                            totalIterationCapacityPerDay,
                            totalIterationDaysOff
                            )
                            VALUES(
                            '$($project.name)',
                            '$($team.name)',
                            '$($sprintteam.name)',
                            CONVERT(DATETIME,SUBSTRING('$($startDate)',1,19),127),
                            CONVERT(DATETIME,SUBSTRING('$($finishDate)',1,19),127),
                            $($TeamIterationCapacitiesResult.totalIterationCapacityPerDay),
                            $($TeamIterationCapacitiesResult.totalIterationDaysOff)
                            )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}