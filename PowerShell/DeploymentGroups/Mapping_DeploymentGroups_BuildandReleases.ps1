#Param
#(
#    [string]$PAT,
#    [string]$Organization
#)

$PAT=''
$Organization='vstssprints'

$DeploymentGroups = @()

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"
$UriOrgRelease = "https://vsrm.dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects/"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader

foreach ($teamproject in $ProjectsResult.value)
{
    $uriReleaseDefinition = $UriOrgRelease + "$($teamproject.name)/_apis/release/definitions"
    $ReleaseDefinitionsResult = Invoke-RestMethod -Uri $uriReleaseDefinition -Method Get -Headers $AzureDevOpsAuthenicationHeader
    Write-Host $uriReleaseDefinition

    foreach  ($releasedefinition in $ReleaseDefinitionsResult.value)
    {
        $uriReleaseDef = $UriOrgRelease + "$($teamproject.name)/_apis/release/definitions/$($releasedefinition.id)"
        $ReleaseDefResult = Invoke-RestMethod -Uri $uriReleaseDef -Method Get -Headers $AzureDevOpsAuthenicationHeader
        Write-Host $uriReleaseDef

        foreach ($releasedefenv in $ReleaseDefResult.environments)
        {
            foreach ($deployphases in $releasedefenv.deployPhases)
            {
                if ($deployphases.phaseType -eq "machineGroupBasedDeployment")
                {
                    $phasetags = $deployphases.deploymentInput.tags
                    $uriDeploymentGroup = $UriOrganization + "$($teamproject.name)/_apis/distributedtask/deploymentgroups/$($deployphases.deploymentInput.queueId)"
                    $DeploymentGroupResult = Invoke-RestMethod -Uri $uriDeploymentGroup -Method Get -Headers $AzureDevOpsAuthenicationHeader

                    foreach ($machine in $DeploymentGroupResult.machines)
                    {
                        if ([string]::IsNullOrEmpty($phasetags) -or $machine.tags -contains $phasetags)
                        {
                            $DeploymentGroups += New-Object -TypeName PSObject -Property @{
                                ProjectName=$teamproject.name
                                ReleaseDefinitionName=$releasedefinition.name
                                EnvironmentName=$releasedefenv.name
                                DeploymentPhaseType=$deployphases.phaseType
                                DeploymentPhaseName=$deployphases.name
                                DeploymentGroupName=$DeploymentGroupResult.name
                                DeploymentPhaseTag=$phasetags
                                MachineName=$machine.agent.name
                                MachineTag=$machine.tags
                            }
                        }
                    }
                }
                elseif ($deployphases.phaseType -eq "agentBasedDeployment")
                {
                    $uriAgentQueue = $UriOrganization + "$($teamproject.name)/_apis/distributedtask/queues/$($deployphases.deploymentInput.queueId)"
                    $AgentQueueResult = Invoke-RestMethod -Uri $uriAgentQueue -Method Get -Headers $AzureDevOpsAuthenicationHeader
                    Write-Host $uriAgentQueue

                    if ($AgentQueueResult)
                    {
                        $DeploymentGroups += New-Object -TypeName PSObject -Property @{
                            ProjectName=$teamproject.name
                            ReleaseDefinitionName=$releasedefinition.name
                            EnvironmentName=$releasedefenv.name
                            DeploymentPhaseType=$deployphases.phaseType
                            DeploymentPhaseName=$deployphases.name
                            DeploymentGroupName=''
                            DeploymentPhaseTag=''
                            MachineName=$AgentQueueResult.name
                            MachineTag=''
                        }
                    }
                }
            }
        }
    }
}
$DeploymentGroups | ConvertTo-Json | Out-File -FilePath "$home\desktop\DeploymentGroups.json"