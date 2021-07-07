Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE EnvironmentsApprovalsChecks"
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
            switch ( $envcheck.type.name )
            {
                'ExtendsCheck' { $envCheckDisplayName = "Required template" }
                'Approval' { $envCheckDisplayName = 'Approvals' }
                'ExclusiveLock' { $envCheckDisplayName = 'Exclusive Lock' }
                'Task Check' { $envCheckDisplayName = $envcheck.settings.displayName }
                deafult { $envCheckDisplayName = $envcheck.type.name }

            }
            $SQLQuery = "INSERT INTO EnvironmentsApprovalsChecks (
                            TeamProjectName,
                            EnvironmentId,
                            EnvironmentName,
                            EnvironmentCheckName,
                            EnvironmentCheckDisplayName)
                            VALUES(
                            '$($project.name)',
                            $($environment.id),
                            '$($environment.name)',
                            '$($envcheck.type.name)',
                            '$($envCheckDisplayName)'
                            )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}