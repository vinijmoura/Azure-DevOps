Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "DELETE FROM DeploymentGroupsMachinesCapabilities"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"
$UriOrgRelease = "https://vsrm.dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader

foreach ($teamproject in $ProjectsResult.value)
{
    $uriDeploymentGroup = $UriOrganization + "$($teamproject.name)/_apis/distributedtask/deploymentgroups"
    $DeploymentGroupResult = Invoke-RestMethod -Uri $uriDeploymentGroup -Method Get -Headers $AzureDevOpsAuthenicationHeader
    foreach ($deploymentGroup in $DeploymentGroupResult.value)
    {
        if ($deploymentGroup.machineCount -gt 0)
        {
            $uriDeploymentGroupMachines = $UriOrganization + "$($teamproject.name)/_apis/distributedtask/deploymentgroups/$($deploymentGroup.id)"
            $DeploymentGroupMachinesResult = Invoke-RestMethod -Uri $uriDeploymentGroupMachines -Method Get -Headers $AzureDevOpsAuthenicationHeader
            foreach ($dgMachine in $DeploymentGroupMachinesResult.machines)
            {
                $uriMachineCapabilities = $UriOrganization + "$($teamproject.name)/_apis/distributedtask/deploymentgroups/$($deploymentGroup.Id)/targets/$($dgMachine.agent.id)?`$expand=capabilities&api-version=6.0-preview.1"
                $MachineCapabilitiesResult = Invoke-RestMethod -Uri $uriMachineCapabilities -Method Get -Headers $AzureDevOpsAuthenicationHeader
                $machCap = $MachineCapabilitiesResult.agent.systemCapabilities | Get-Member | where {$_.MemberType -eq 'NoteProperty'}
                Foreach ($cap in $machCap)
                {
                    $SQLQuery = "INSERT INTO DeploymentGroupsMachinesCapabilities (
                                    TeamProjectName,
                                    DeploymentGroupName,
                                    MachineName,
                                    CapabilityName,
                                    CapabilityValue
                                    )
                                    VALUES(
                                    '$($teamproject.name)',
                                    '$($deploymentGroup.name)',
                                    '$($dgMachine.agent.name)',
                                    '$($cap.Name)',
                                    '$($MachineCapabilitiesResult.agent.systemCapabilities.$($cap.Name))'
                                    )"
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                }
            }
        }
    }
}