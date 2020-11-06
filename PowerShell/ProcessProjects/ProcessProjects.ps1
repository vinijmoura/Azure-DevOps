Param
(
    [string]$PAT,
    [string]$Organization
)

$ProcessProjects = @()

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }

$UriOrganization = "https://dev.azure.com/$($Organization)/" 
$uriProcess = $UriOrganization + "/_apis/work/processes?`$expand=projects"

$processesResult = Invoke-RestMethod -Uri $uriProcess -Method get -Headers $AzureDevOpsAuthenicationHeader

Foreach ($process in $processesResult.value)
{
    Foreach ($prj in $process.projects)
    {
        $ProcessProjects += New-Object -TypeName PSObject -Property @{
                                        ProcessName=$process.name
                                        ProjectName=$prj.name
                                    }
    }
    
}

$ProcessProjects | ConvertTo-Json | Out-File -FilePath "$home\desktop\ProcessProjects.json"