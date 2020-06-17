Param
(
    [string]$PAT,
    [string]$Organization
)

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }

$UriOrganization = "https://dev.azure.com/$($Organization)/" 
$uriProcess = $UriOrganization + "_apis/work/processes/"

$processesResult = Invoke-RestMethod -Uri $uriProcess -Method get -Headers $AzureDevOpsAuthenicationHeader

Foreach ($process in $processesResult.value)
{
    Write-Host '=Process name:'$process.name
    Write-Host '=Process customization:'$process.customizationType
    $uriWorkItemTypes = $uriProcess + "$($process.typeId)/workitemtypes/"
    $workItemTypesResult = Invoke-RestMethod -Uri $uriWorkItemTypes -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($wit in $workItemTypesResult.value)
    {
        Write-Host '==Work item type:'$wit.name
        $uriFields = $uriWorkItemTypes + "$($wit.referenceName)/fields"
        $fieldsResult = Invoke-RestMethod -Uri $uriFields -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($f in $fieldsResult.value)
        {
            Write-Host '===Field name:'$f.name
            Write-Host '===Field reference name:'$f.referenceName
            Write-Host '===Field type:'$f.type
        }
    }
}