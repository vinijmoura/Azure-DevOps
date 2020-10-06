Param
(
    [string]$PAT,
    [string]$Organization
)
$Capacities = @()

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects/"
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
            if ($sprintteam.attributes.startDate)
            {
                $uriCapacities = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/teamsettings/iterations/$($sprintteam.id)/capacities"
                $CapacitiesResult = Invoke-RestMethod -Uri $uriCapacities -Method get -Headers $AzureDevOpsAuthenicationHeader
                Foreach ($capacity in $CapacitiesResult.value)
                {
                    Foreach($activity in $capacity.activities)
                    {
                        if ($activity.capacityPerDay -gt 0)
                        {
                            $Capacities += New-Object -TypeName PSObject -Property @{
                                ProjectName=$project.name
                                TeamName=$team.name
                                SprintName=$sprintteam.name
                                SprintStartDate="{0:yyyy-MM-dd}"-f ((Get-date $($sprintteam.attributes.startDate).ToString()).ToUniversalTime())
                                SprintFinishDate="{0:yyyy-MM-dd}"-f ((Get-date $($sprintteam.attributes.finishDate).ToString()).ToUniversalTime())
                                UserName=$capacity.teamMember.displayName
                                UserNameActivity=$activity.name
                                UserNameHour=$activity.capacityPerDay
                            }
                        }
                    }
                }
            }
        }
    }
}

$Capacities | ConvertTo-Json | Out-File -FilePath "$home\desktop\Capacities.json"