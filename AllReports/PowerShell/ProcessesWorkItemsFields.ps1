Param
(
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $processtypeId,
    $processName,
    $LogFile
)
$UriOrganization = "https://dev.azure.com/$($Organization)/" 
$uriProcess = $UriOrganization + "_apis/work/processes/"

$table = $db.Tables["ProcessesWorkItemsFields"]

$ProcessesWorkItemsFields = New-Object 'Collections.Generic.List[pscustomobject]'

$uriWorkItemTypes = $uriProcess + "$($processtypeId)/workitemtypes/"
$workItemTypesResult = Invoke-RestMethod -Uri $uriWorkItemTypes -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($wit in $workItemTypesResult.value)
{
    $uriFields = $uriWorkItemTypes + "$($wit.referenceName)/fields"
    $fieldsResult = Invoke-RestMethod -Uri $uriFields -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($f in $fieldsResult.value)
    {
        $fieldObject = [PSCustomObject] [ordered]@{
            ProcessTypeId=$processtypeId
            ProcessWorkItemTypeName=$wit.name
            ProcessWorkItemTypeCustomationType=$wit.customization
            ProcessWorkItemTypeFieldName=$f.name
            ProcessWorkItemTypeFieldReferenceName=$f.referenceName
            ProcessWorkItemTypeFieldCustomizationType=$f.customization
            ProcessWorkItemTypeFieldTypeName=$f.type
        }
        $ProcessesWorkItemsFields.Add($fieldObject)
    }
}

Write-SqlTableData -InputData $ProcessesWorkItemsFields -InputObject $table -Force
& .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Processes Templates, Work Item Types and Fields to which processId $($processtypeId) and ProcessName $($processName) belongs on table ProcessesWorkItemsFields"