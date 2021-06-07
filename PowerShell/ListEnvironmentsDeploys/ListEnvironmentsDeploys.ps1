Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE EnvironmentsDeploys"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriEnvironments = $UriOrganization + "$($project.id)/_apis/distributedtask/environments?api-version=6.1-preview.1"
    $EnvironmentsResult = Invoke-RestMethod -Uri $uriEnvironments -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($environment in $EnvironmentsResult.value)
    {
        $uriEnvironmentDeployment = $UriOrganization + "$($project.id)/_apis/distributedtask/environments/$($environment.id)/environmentdeploymentrecords?api-version=6.1-preview.1"
        $EnvironmentDeploymentResult = Invoke-RestMethod -Uri $uriEnvironmentDeployment -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($envdeploy in $EnvironmentDeploymentResult.value)
        {
            $SQLQuery = "INSERT INTO EnvironmentsDeploys (
                            TeamProjectName,
                            EnvironmentId,
                            EnvironmentName,
                            EnvironmentDeployDefinitionName,
                            EnvironmentDeployStageName,
                            EnvironmentDeployJobName,
                            EnvironmentDeployResult,
                            EnvironmentDeployQueueTime,
                            EnvironmentDeployStartTime,
                            EnvironmentDeployFinishTime)
                            VALUES(
                            '$($project.name)',
                            $($environment.id),
                            '$($environment.name)',
                            '$($envdeploy.definition.name)',
                            '$($envdeploy.stageName)',
                            '$($envdeploy.jobName)',
                            '$($envdeploy.result)',
                            CONVERT(DATETIME,SUBSTRING('$($envdeploy.queueTime)',1,19),127),
                            CONVERT(DATETIME,SUBSTRING('$($envdeploy.startTime)',1,19),127),
                            CONVERT(DATETIME,SUBSTRING('$($envdeploy.finishTime)',1,19),127)
                            )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}

