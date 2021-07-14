Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ConnStr
)

$SQLQuery = "DELETE FROM TeamSettingsBackLogLevels"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM TeamSettingsWorkingDays"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM TeamSettings"
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
        $uriTeamSettings = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/teamsettings?api-version=6.1-preview.1"
        $TeamSettingsResult = Invoke-RestMethod -Uri $uriTeamSettings -Method get -Headers $AzureDevOpsAuthenicationHeader
         
        $SQLQuery = "INSERT INTO TeamSettings (
                        TeamProjectName,
                        TeamName,
                        TeamWorkingWithBugs
                        )
                        VALUES(
                        '$($project.name)',
                        '$($team.name)',
                        '$($TeamSettingsResult.bugsBehavior)'
                        )"
        Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        
        [array]$backlogVisibilities = ($TeamSettingsResult.backlogVisibilities | Get-Member -MemberType NoteProperty).Name
        Foreach ($blv in $backlogVisibilities)
        {
            if ($TeamSettingsResult.backlogVisibilities.$blv -eq $true)
            {
                $uriBackLogLevel = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/backlogs/$($blv)?api-version=6.0-preview.1"
                $backLogLevelResult = Invoke-RestMethod -Uri $uriBackLogLevel -Method get -Headers $AzureDevOpsAuthenicationHeader
                $SQLQuery = "INSERT INTO TeamSettingsBackLogLevels (
                                TeamSettingId,
                                TeamBackLogLevel
                                )
                                SELECT
                                TeamSettingId,
                                '$($backLogLevelResult.name)' 
                                FROM TeamSettings WHERE TeamProjectName='$($project.name)' AND TeamName='$($team.name)'"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
     
        Foreach($wd in $TeamSettingsResult.workingDays)
        {
            $SQLQuery = "INSERT INTO TeamSettingsWorkingDays (
                                TeamSettingId,
                                TeamWorkingDay
                                )
                                SELECT
                                TeamSettingId,
                                '$($wd)'
                                FROM TeamSettings WHERE TeamProjectName='$($project.name)' AND TeamName='$($team.name)'"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}