Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ReleaseDefinitionsTasks"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"
$uriReleases = "https://vsrm.dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{   
    $uriReleaseDefinitions = $uriReleases + "$($project.id)/_apis/release/definitions?api-version=6.1-preview.4"
    $ReleaseDefintionsResult = Invoke-RestMethod -Uri $uriReleaseDefinitions -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($releaseDef in $ReleaseDefintionsResult.value)
    {
        $uriReleaseDef = $uriReleases + "$($project.id)/_apis/release/definitions/$($releaseDef.id)?api-version=6.1-preview.4"
        $ReleaseDefResult = Invoke-RestMethod -Uri $uriReleaseDef -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($environment in $ReleaseDefResult.environments)
        {
            Foreach ($deployPhase in $environment.deployPhases)
            {
                Foreach ($task in $deployPhase.workflowTasks)
                {
                    $SQLQuery = "INSERT INTO ReleaseDefinitionsTasks (
                                    TeamProjectName,
                                    ReleaseDefinitionId,
                                    ReleaseDefinitionName,
                                    ReleaseDefinitionEnvironmentName,
                                    ReleaseDefinitionPhaseName,
                                    ReleaseDefintionTaskId,
                                    ReleaseDefintionTaskName,
                                    ReleaseDefintionTaskversion
                                    )
                                    VALUES(
                                    '$($project.name)',
                                    '$($releaseDef.id)',
                                    '$($releaseDef.name)',
                                    '$($environment.name)',
                                    '$($deployPhase.name)',
                                    '$($task.taskId)',
                                    '$($task.name)',
                                    '$($task.version)'
                                    )"
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                }
            }
        }
    }
}
