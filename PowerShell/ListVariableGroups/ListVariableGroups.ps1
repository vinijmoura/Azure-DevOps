Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE VariableGroups"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriVariableGroups = $UriOrganization + "$($project.id)/_apis/distributedtask/variablegroups?api-version=6.0-preview.2"
    $VariableGroupsResult = Invoke-RestMethod -Uri $uriVariableGroups -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($vg in $VariableGroupsResult.value)
    {
        if ($vg.type -eq "Vsts")
        {
            $VariableGroupType = 'Azure DevOps'
            $VariableGroupKeyVaultName = 'local'
            
        }
        else
        {
            $VariableGroupType = 'Azure key vault'
            $VariableGroupKeyVaultName = $vg.providerData.vault
        }
        [array]$variables = ($vg.variables | Get-Member -MemberType NoteProperty).Name
        Foreach ($vgvar in $variables)
        {
            $variableValue = if ($vg.variables.$vgvar.value) {$vg.variables.$vgvar.value} else {'***'}
            $SQLQuery = "INSERT INTO VariableGroups (
                            TeamProjectName,
                            VariableGroupName,
                            VariableGroupType,
                            VariableGroupKeyVaultName,
                            VariableGroupVariableName,
                            VariableGroupVariableValue)
                            VALUES(
                            '$($project.name)',
                            '$($vg.name)',
                            '$($VariableGroupType)',
                            '$($VariableGroupKeyVaultName)',
                            '$($vgvar)',
                            '$($variableValue)'
                            )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}

