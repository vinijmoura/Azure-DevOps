Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ServiceHooks"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriServiceHooks = "https://dev.azure.com/$($Organization)/_apis/hooks/subscriptions?api-version=6.1-preview.1"
$ServiceHooksResult = Invoke-RestMethod -Uri $UriServiceHooks -Method get -Headers $AzureDevOpsAuthenicationHeader

Foreach ($serviceHook in $ServiceHooksResult.value)
{
    $UriGetProject = "https://dev.azure.com/$($Organization)/_apis/projects/$($serviceHook.publisherInputs.projectId)?api-version=6.1-preview.4"
    $GetProjectResult = Invoke-RestMethod -Uri $UriGetProject -Method get -Headers $AzureDevOpsAuthenicationHeader
    $SQLQuery = "INSERT INTO ServiceHooks (
                                ProjectName,
                                eventDescription,
                                eventType,
                                publisherId,
                                consumerId,
                                consumerActionId,
                                actionDescription,
                                createdBy
                                )
                                VALUES(
                                '$($GetProjectResult.name)',
                                '$($serviceHook.eventDescription)',
                                '$($serviceHook.eventType)',
                                '$($serviceHook.publisherId)',
                                '$($serviceHook.consumerId)',
                                '$($serviceHook.consumerActionId)',
                                '$($serviceHook.actionDescription)',
                                '$($serviceHook.createdBy.displayName)'
                                )"
    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
}