Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ProjectsPickLists"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/" 

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriProjectPickList = $UriOrganization + "$($project.id)/_apis/wit/fields?api-version=6.0"
    $ProjectsPickListResult = Invoke-RestMethod -Uri $uriProjectPickList -Method get -Headers $AzureDevOpsAuthenicationHeader
    $ProjectsPickListResult = $ProjectsPickListResult.value | where-object {$_.isPicklist -eq $true}
    Foreach ($fieldPickList in $ProjectsPickListResult)
    {
        $uriPickList = $UriOrganization + "_apis/work/processes/lists/$($fieldPickList.picklistId)?api-version=6.0-preview.1"
        $PickListResult = Invoke-RestMethod -Uri $uriPickList -Method get -Headers $AzureDevOpsAuthenicationHeader
        $items = $PickListResult.items
        $items = "$items".Replace(" ","`r`n")
        
        $SQLQuery = "INSERT INTO ProjectsPickLists(
                    TeamProjectId,
                    TeamProjectName,
                    FieldName,
                    FieldReferenceName,
                    FieldType,
                    FieldPickListId,
                    FieldPickListItems
                    )
                    VALUES(
                    '$($project.id)',
                    '$($project.name)',
                    '$($fieldPickList.name)',
                    '$($fieldPickList.referenceName)',
                    '$($fieldPickList.type)',
                    '$($fieldPickList.picklistId)',
                    '$($items)'
                    )"
        Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
    }
}