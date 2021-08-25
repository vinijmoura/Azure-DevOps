Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE TestPlansConfigurations"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }

$UriOrganization = "https://dev.azure.com/$($Organization)/" 
$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriTestPlansConfigurations = $UriOrganization + "$($project.id)/_apis/testplan/configurations?api-version=6.1-preview.1"
    $TestPlansConfigurationsResult = Invoke-RestMethod -Uri $uriTestPlansConfigurations -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($tpconfig in $TestPlansConfigurationsResult.value)
    {
        Foreach ($value in $tpconfig.values)
        {
            $SQLQuery = "INSERT INTO TestPlansConfigurations (
                        TeamProjectName,
                        TeamPlanConfigurationId,
                        TeamPlanConfigurationName,
                        TeamPlanConfigurationVariableName,
                        TeamPlanConfigurationVariableValue
                        )
                        VALUES(
                        '$($project.name)',
                        $($tpconfig.id),
                        '$($tpconfig.name)',
                        '$($value.name)',
                        '$($value.value)'
                        )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}