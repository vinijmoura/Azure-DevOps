Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ConnStr
)

$SQLQuery = "DELETE FROM TeamCardRuleSettings"
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
        Foreach ($teamBoard in $TeamBoardsResult.value)
        {
            $uriCardRuleSettings = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/boards/$($teamBoard.name)/cardrulesettings?api-version=6.1-preview.2"
            $TeamCardRuleSettings = Invoke-RestMethod -Uri $uriCardRuleSettings -Method get -Headers $AzureDevOpsAuthenicationHeader
            [array]$propertyRules = ($TeamCardRuleSettings.rules | Get-Member -MemberType NoteProperty).Name
            if ($propertyRules)
            {
                Foreach ($cardRuleSetting in $TeamCardRuleSettings.rules)
                {
                    Foreach ($fill in $cardRuleSetting.fill)
                    {
                        $ruleFilter = $fill.filter.Replace("'","")
                        $SQLQuery = "INSERT INTO TeamCardRuleSettings (
                                TeamProjectName,
                                TeamName,
                                TeamBackLogLevel,
                                TeamCardRuleSettingName,
                                TeamCardRuleSettingFilter,
                                TeamCardRuleSettingBackGroundColor
                                )
                                VALUES
                                (
                                '$($project.name)',
                                '$($team.name)',
                                '$($teamBoard.name)',
                                '$($fill.name)',
                                '$($ruleFilter)',
                                '$($fill.settings.'background-color')'
                                )"
                        Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                    }
                }
            }
        }
    }
}