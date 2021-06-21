Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ProcessesWorkItemsFields"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }

$UriOrganization = "https://dev.azure.com/$($Organization)/" 
$uriProcess = $UriOrganization + "_apis/work/processes/"

$processesResult = Invoke-RestMethod -Uri $uriProcess -Method get -Headers $AzureDevOpsAuthenicationHeader

Foreach ($process in $processesResult.value)
{
    $uriWorkItemTypes = $uriProcess + "$($process.typeId)/workitemtypes/"
    $workItemTypesResult = Invoke-RestMethod -Uri $uriWorkItemTypes -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($wit in $workItemTypesResult.value)
    {
        $uriFields = $uriWorkItemTypes + "$($wit.referenceName)/fields"
        $fieldsResult = Invoke-RestMethod -Uri $uriFields -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($f in $fieldsResult.value)
        {
            $SQLQuery = "INSERT INTO ProcessesWorkItemsFields (
                                ProcessName,
                                ProcessCustomizationType,
                                ProcessWorkItemTypeName,
                                ProcessWorkItemTypeCustomationType,
                                ProcessWorkItemTypeFieldName,
                                ProcessWorkItemTypeFieldReferenceName,
                                ProcessWorkItemTypeFieldCustomizationType,
                                ProcessWorkItemTypeFieldTypeName
                                )
                                VALUES(
                                '$($process.name)',
                                '$($process.customizationType)',
                                '$($wit.name)',
                                '$($wit.customization)',
                                '$($f.name)',
                                '$($f.referenceName)',
                                '$($f.customization)',
                                '$($f.type)'
                                )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}