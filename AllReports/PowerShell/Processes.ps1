Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

Get-Date
Import-Module -Name SqlServer

$LogDate = (Get-Date).tostring("yyyyMMddHHmmss")
$LogFile = $PSScriptRoot + "\" + $LogDate + ".log"

#Create LogFile Header
& .\LogFile.ps1 -LogFile $LogFile -Message "Starting Azure DevOps data extraction..."

$sqlcc = New-Object -TypeName System.Data.SqlClient.SqlConnection -ArgumentList $Connstr
$sc = New-Object -TypeName Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $sqlcc
$srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $sc
$db = $srv.Databases["azuredevopsreports"]

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) } + @{"Content-Type"="application/json"; "Accept"="application/json"}
$UriOrganization = "https://dev.azure.com/$($Organization)/"

#INSERT FeedPackageVersions
& .\FeedPackageVersions.ps1 -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -LogFile $LogFile

#INSERT InstalledExtensions
& .\Extensions.ps1 -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -LogFile $LogFile

#INSERT Users and UsersGroups
& .\Users.ps1 -PAT $PAT -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -LogFile $LogFile

$table = $db.Tables["Processes"]

#INSERT Processess
$uriProcess = $UriOrganization + "_apis/work/processes?`$expand=projects"
$ProcessResult = Invoke-RestMethod -Uri $uriProcess -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($process in $ProcessResult.value)
{
    $Processes = New-Object 'Collections.Generic.List[pscustomobject]'
    $processObject = [PSCustomObject] [ordered]@{
        ProcessTypeId=$process.typeId
	    ProcessName=$process.name
	    ProcessReferenceName=$process.referenceName
	    ProcessCustomizationType=$process.customizationType
    }
    $Processes.Add($processObject)
    Write-SqlTableData -InputData $Processes -InputObject $table
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Process Template: $($process.name) on table Processes"

    #INSERT ProcessesWorkItemsFields
    & .\ProcessesWorkItemsFields.ps1 -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -processtypeId $process.typeId -processName $process.name -LogFile $LogFile
    
    Foreach ($project in $process.projects)
    {
        #INSERT Projects
        & .\Projects.ps1 -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -projectId $project.id -projectName $project.name -processtypeId $process.typeId -LogFile $LogFile

        #INSERT Teams
        & .\Teams.ps1 -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -projectId $project.id -projectName $project.name -LogFile $LogFile

        #INSERT Repositories
        & .\Repos.ps1 -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -projectId $project.id -projectName $project.name -LogFile $LogFile

        #INSERT EnvironmentsApprovalsChecks
        & .\EnvironmentsApprovalsChecks.ps1 -AzureDevOpsAuthenicationHeader $AzureDevOpsAuthenicationHeader -Organization $Organization -db $db -projectId $project.id -projectName $project.name -LogFile $LogFile
    }
}

Get-Date
#Create LogFile Footer
& .\LogFile.ps1 -LogFile $LogFile -Message "Finishing Azure DevOps data extraction..."
