Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE EnvironmentsApprovalsNames"
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
        $body = @(
                  @{
                    type="queue"
                    id="1"
                    name="Default"
                  },
                  @{
                    type="environment"
                    id="$($environment.id)"
                    name="$($environment.name)"
                  }
                ) | ConvertTo-Json
        $uriEnvironmentChecks = $UriOrganization + "$($project.id)/_apis/pipelines/checks/queryconfigurations?`$expand=settings&api-version=6.1-preview.1"
        $EnvironmentChecksResult = Invoke-RestMethod -Uri $uriEnvironmentChecks -Method Post -Body $body -Headers $AzureDevOpsAuthenicationHeader -ContentType application/json
        Foreach ($envcheck in $EnvironmentChecksResult.value)
        {
            if ($envcheck.type.name -eq 'Approval')
            {
                $ApproversResult = Invoke-RestMethod -Uri $envcheck.url -Method get -Headers $AzureDevOpsAuthenicationHeader
                Foreach ($approver in $ApproversResult.settings.approvers)
                {
                    $SQLQuery = "INSERT INTO EnvironmentsApprovalsNames (
                            TeamProjectName,
                            EnvironmentId,
                            EnvironmentName,
                            ApproverUniqueName,
                            ApproverDisplayName
                            )
                            VALUES(
                            '$($project.name)',
                            $($environment.id),
                            '$($environment.name)',
                            '$($approver.uniqueName)',
                            '$($approver.displayName)'
                            )"
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr         
                }                
            }
        }
    }
}