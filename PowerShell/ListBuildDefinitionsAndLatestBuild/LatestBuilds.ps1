Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE LatestBuilds"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriBuildDefinitions = $UriOrganization + "$($project.id)/_apis/build/definitions?api-version=6.1-preview.7"
    $BuildDefintionsResult = Invoke-RestMethod -Uri $uriBuildDefinitions -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($builDef in $BuildDefintionsResult.value)
    {
        #$uriLatestBuild = $UriOrganization + "$($project.id)/_apis/build/latest/$($builDef.id)?api-version=6.1-preview.1"
        $uriLatestBuild = $UriOrganization + "$($project.id)/_apis/build/builds?definitions=$($builDef.id)&`$top=1&queryOrder=finishTimeDescending&api-version=6.0"
        $LatestBuildResult = Invoke-RestMethod -Uri $uriLatestBuild -Method get -Headers $AzureDevOpsAuthenicationHeader
        if ($LatestBuildResult.count -gt 0)
        {
            $SQLQuery = "INSERT INTO LatestBuilds (
                        TeamProjectName,
                        BuildDefinitionId,
                        BuildDefinitionName,
                        BuildNumber,
                        BuildResult,
                        BuildReason,
                        BuildRequestedFor,
                        BuildRepository,
                        BuildSourceBranch,
                        BuildCommit,
                        BuildStartTime,
                        BuildTime,                
                        BuildLink,
                        BuildBadge
                        )
                        VALUES(
                        '$($project.name)',
                        '$($builDef.id)',
                        '$($builDef.name)',
                        '$($LatestBuildResult.value[0].buildNumber)',
                        '$($LatestBuildResult.value[0].result)',
                        '$($LatestBuildResult.value[0].reason)',
                        '$($LatestBuildResult.value[0].requestedFor.displayName)',
                        '$($LatestBuildResult.value[0].repository.id)',
                        '$($LatestBuildResult.value[0].sourceBranch.Substring($LatestBuildResult.value[0].sourceBranch.LastIndexOf('/')+1))',
                        '$($LatestBuildResult.value[0].sourceVersion.Substring(1,6))',
                        CONVERT(DATETIME,SUBSTRING('$($LatestBuildResult.value[0].startTime)',1,19),127),
                        DATEDIFF(ss,'$($LatestBuildResult.value[0].startTime)','$($LatestBuildResult.value[0].finishTime)'),
                        '$($LatestBuildResult.value[0]._links.web.href)',
                        '$($LatestBuildResult.value[0]._links.badge.href)'
                        )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}
