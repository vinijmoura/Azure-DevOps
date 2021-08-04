Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "DELETE FROM DeploymentGroupReleases"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"
$UriOrgRelease = "https://vsrm.dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader

foreach ($teamproject in $ProjectsResult.value)
{
    $uriReleaseDefinition = $UriOrgRelease + "$($teamproject.name)/_apis/release/definitions"
    $ReleaseDefinitionsResult = Invoke-RestMethod -Uri $uriReleaseDefinition -Method Get -Headers $AzureDevOpsAuthenicationHeader

    foreach  ($releasedefinition in $ReleaseDefinitionsResult.value)
    {
        $uriReleaseDef = $UriOrgRelease + "$($teamproject.name)/_apis/release/definitions/$($releasedefinition.id)"
        $ReleaseDefResult = Invoke-RestMethod -Uri $uriReleaseDef -Method Get -Headers $AzureDevOpsAuthenicationHeader

        foreach ($releasedefenv in $ReleaseDefResult.environments)
        {
            foreach ($deployphases in $releasedefenv.deployPhases)
            {
                if ($deployphases.phaseType -eq "machineGroupBasedDeployment")
                {
                    $uriDeploymentGroup = $UriOrganization + "$($teamproject.name)/_apis/distributedtask/deploymentgroups/$($deployphases.deploymentInput.queueId)"
                    $DeploymentGroupResult = Invoke-RestMethod -Uri $uriDeploymentGroup -Method Get -Headers $AzureDevOpsAuthenicationHeader

                    foreach ($machine in $DeploymentGroupResult.machines)
                    {
                        $SQLQuery = "INSERT INTO DeploymentGroupReleases (
                                        TeamProjectName,
                                        ReleaseDefinitionName,
                                        EnvironmentName,
                                        DeploymentPhaseName,
                                        DeploymentGroupName,
                                        MachineName
                                        )
                                        VALUES(
                                        '$($teamproject.name)',
                                        '$($releasedefinition.name)',
                                        '$($releasedefenv.name)',
                                        '$($deployphases.name)',
                                        '$($DeploymentGroupResult.name)',
                                        '$($machine.agent.name)'
                                        )"
                        Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                    }
                }
            }
        }
    }
}