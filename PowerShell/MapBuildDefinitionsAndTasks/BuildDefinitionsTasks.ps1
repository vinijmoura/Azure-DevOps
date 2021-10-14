Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE BuildDefinitionsTasks"
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
        $uriBuildDef = $UriOrganization + "$($project.id)/_apis/build/definitions/$($builDef.id)?api-version=6.1-preview.7"
        $BuildDefResult = Invoke-RestMethod -Uri $uriBuildDef -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($bdrPhases in $BuildDefResult.process.phases)
        {
            Foreach ($step in $bdrPhases.steps)
            {
                $uriTaskName = $UriOrganization + "_apis/distributedtask/tasks/$($step.task.id)?api-version=6.1-preview.1"
                $TaskNameResult = Invoke-RestMethod -Uri $uriTaskName -Method get -Headers $AzureDevOpsAuthenicationHeader

                $SQLQuery = "INSERT INTO BuildDefinitionsTasks (
                                    TeamProjectName,
                                    BuildDefinitionId,
                                    BuildDefinitionName,
                                    BuildDefinitionPhaseName,
                                    BuildDefintionTaskId,
                                    BuildDefintionTaskName,
                                    BuildDefintionTaskversionSpec
                                    )
                                    VALUES(
                                    '$($project.name)',
                                    '$($builDef.id)',
                                    '$($builDef.name)',
                                    '$($bdrPhases.refName)',
                                    '$($step.task.id)',
                                    '$($TaskNameResult.value[0].name)',
                                    '$($step.task.versionSpec)'
                                    )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }
}
