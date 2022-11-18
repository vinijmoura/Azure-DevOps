Param
(
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $projectId,
    $projectName,
    $LogFile
)

$UriOrganization = "https://dev.azure.com/$($Organization)/"

$EnvironmentsApprovalsChecks = New-Object 'Collections.Generic.List[pscustomobject]'
$table = $db.Tables["EnvironmentsApprovalsChecks"]

$uriEnvironments = $UriOrganization + "$($projectId)/_apis/distributedtask/environments?api-version=6.1-preview.1"
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
    $uriEnvironmentChecks = $UriOrganization + "$($projectId)/_apis/pipelines/checks/queryconfigurations?`$expand=settings&api-version=6.1-preview.1"
    $EnvironmentChecksResult = Invoke-RestMethod -Uri $uriEnvironmentChecks -Method Post -Body $body -Headers $AzureDevOpsAuthenicationHeader -ContentType application/json
    Foreach ($envcheck in $EnvironmentChecksResult.value)
    {
        switch ( $envcheck.type.name )
        {
            'ExtendsCheck' { $envCheckDisplayName = "Required template" }
            'Approval' { $envCheckDisplayName = 'Approvals' }
            'ExclusiveLock' { $envCheckDisplayName = 'Exclusive Lock' }
            'Task Check' { $envCheckDisplayName = $envcheck.settings.displayName }
            default { $envCheckDisplayName = $envcheck.type.name }

        }
        $environmentsApprovalsChecksObject = [PSCustomObject] [ordered]@{
            TeamProjectId=$projectId
            EnvironmentId=$environment.id
            EnvironmentName=$environment.name
            EnvironmentCheckName=$envcheck.type.name
            EnvironmentCheckDisplayName=$envCheckDisplayName
        }
        $EnvironmentsApprovalsChecks.Add($environmentsApprovalsChecksObject)        
    }
}

if ($EnvironmentsApprovalsChecks.Count -gt 0)
{
    Write-SqlTableData -InputData $EnvironmentsApprovalsChecks -InputObject $table
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Environments, Approvals and Checks from the project $($projectName) on table EnvironmentsApprovalsChecks"
}