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
        $uriLatestBuild = $UriOrganization + "$($project.id)/_apis/build/latest/$($builDef.id)?api-version=6.1-preview.1"
        Try 
        {
            $LatestBuildResult = Invoke-RestMethod -Uri $uriLatestBuild -Method get -Headers $AzureDevOpsAuthenicationHeader
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
                        BuildLink
                        )
                        VALUES(
                        '$($project.name)',
                        '$($builDef.id)',
                        '$($builDef.name)',
                        '$($LatestBuildResult.buildNumber)',
                        '$($LatestBuildResult.result)',
                        '$($LatestBuildResult.reason)',
                        '$($LatestBuildResult.requestedFor.displayName)',
                        '$($LatestBuildResult.repository.id)',
                        '$($LatestBuildResult.sourceBranch.Substring($LatestBuildResult.sourceBranch.LastIndexOf('/')+1))',
                        '$($LatestBuildResult.sourceVersion.Substring(1,6))',
                        CONVERT(DATETIME,SUBSTRING('$($LatestBuildResult.startTime)',1,19),127),
                        DATEDIFF(ss,'$($LatestBuildResult.startTime)','$($LatestBuildResult.finishTime)'),
                        '$($LatestBuildResult._links.web.href)'
                        )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        } 
        Catch 
        {
            if($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message } 
            else { Write-Host $_ }
        }
    }
}
