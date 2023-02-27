Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE BuildApprovalsRequired"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriBuildDefinitions = "$($UriOrganization)$($project.id)/_apis/build/definitions?api-version=6.1-preview.7"
    $BuildDefintionsResult = Invoke-RestMethod -Uri $uriBuildDefinitions -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($buildDef in $BuildDefintionsResult.value)
    {
        $uriBuilds="$($UriOrganization)$($project.id)/_apis/build/builds?definitions=$($buildDef.id)&queryOrder=startTimeAscending"
        $Builds = Invoke-RestMethod -Uri $uriBuilds -Method get -Headers $AzureDevOpsAuthenicationHeader
        $Builds = $Builds.value | Where-Object {$_.status -eq 'InProgress'}
        Foreach ($build in $Builds)
        {
            $uriBuildTimeline = "$($UriOrganization)$($project.id)/_apis/build/builds/$($build.id)/timeline?api-version=6.0"
            $Timeline = Invoke-RestMethod -Uri $uriBuildTimeline -Method get -Headers $AzureDevOpsAuthenicationHeader
            $Timeline = $Timeline.records
            $CheckpointApproval = $Timeline | Where-Object {($_.name -eq "Checkpoint.Approval") -and ($_.state -eq "inProgress")}
            if ($CheckpointApproval)
            {
                $Checkpoint = $Timeline | Where-Object {($_.id -eq $CheckpointApproval.parentId) -and ($_.type -eq "Checkpoint")}
                $PendingStage = $Timeline | Where-Object {($_.id -eq $Checkpoint.parentId) -and ($_.type -eq "Stage")}
                $SQLQuery = "INSERT INTO BuildApprovalsRequired (
                            TeamProjectName,
                            BuildDefinitionId,
                            BuildDefinitionName,
                            BuildId,
                            BuildNumber,
                            BuildLink,
                            BuildStageName,
                            BuildEnvironmentName
                            )
                            VALUES(
                            '$($project.name)',
                            '$($buildDef.id)',
                            '$($buildDef.name)',
                            '$($build.id)',
                            '$($build.buildNumber)',
                            '$($build._links.web.href)',
                            '$($PendingStage.name)',
                            '$($PendingStage.identifier)'
                            )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }
}