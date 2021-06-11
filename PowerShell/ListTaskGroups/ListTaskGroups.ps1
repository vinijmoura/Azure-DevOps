Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE TaskGroups"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriTaskGroups = $UriOrganization + "$($project.id)/_apis/distributedtask/taskgroups?api-version=6.1-preview.1"
    $TaskGroupsResult = Invoke-RestMethod -Uri $uriTaskGroups -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($taskgroup in $TaskGroupsResult.value)
    {
        Foreach ($tgt in $taskgroup.tasks)
        {
            $SQLQuery = "INSERT INTO TaskGroups (
                                TeamProjectName,
                                TaskGroupId,
                                TaskGroupName,
                                TaskGroupIconURL,
                                TaskGroupVersion,
                                TaskGroupCategory,
                                TaskGroupTaskDisplayName,
                                TaskGroupTaskReferenceId,
                                TaskGroupTaskVersionSpec,
                                TaskGroupTaskEnabled
                                )
                                VALUES(
                                '$($project.name)',
                                '$($taskgroup.id)',
                                '$($taskgroup.name)',
                                '$($taskgroup.iconUrl)',
                                '$($taskgroup.version.major.ToString() + '.' + $taskgroup.version.minor.ToString() + '.' + $taskgroup.version.patch.ToString())',
                                '$($taskgroup.category)',
                                '$($tgt.displayName.Replace('$',''))',
                                '$($tgt.task.id)',
                                '$($tgt.task.versionSpec)',
                                '$($tgt.enabled)'
                                )"
            $SQLQuery
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}

