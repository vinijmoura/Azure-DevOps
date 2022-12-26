Param
(
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $projectId,
    $projectName,
    $processtypeId,
    $LogFile
)

$UriOrganization = "https://dev.azure.com/$($Organization)/"
$UriOrganizationRM = "https://vsrm.dev.azure.com/$($Organization)/"
$monthAgo = (Get-Date).AddMonths(-1).ToString("yyyy-MM-dd")

$uriProjectStats = $UriOrganization + "_apis/Contribution/HierarchyQuery/project/$($projectId)?api-version=6.1-preview.1"
$projectStatsBody = @{
    "contributionIds"= @("ms.vss-work-web.work-item-metrics-data-provider-verticals", "ms.vss-code-web.code-metrics-data-provider-verticals", "ms.vss-code-web.build-metrics-data-provider-verticals")
    "dataProviderContext" = @{
        "properties" =@{
            "numOfDays"=30
            "sourcePage"=@{
                "url"=($UriOrganization + $projectName)
                "routeId"="ms.vss-tfs-web.project-overview-route"
                "routeValues" =@{
                    "project" = $projectId
                    "controller"="Apps"
                    "action"="ContributedHub"
                    "serviceHost"=$Organization
                    }
                }          
            }
        }
    }  | ConvertTo-Json -Depth 5

$projectStatsResult = Invoke-WebRequest -Uri $uriProjectStats -Headers $AzureDevOpsAuthenicationHeader -Method Post -Body $projectStatsBody -UseBasicParsing 
$projectStatsJson = ConvertFrom-Json $projectStatsResult.Content

$workItemsCreated = 0
$workItemsCompleted = 0
$commitsPushed = 0
$pullRequestsCreated = 0
$pullRequestsCompleted = 0

$workItemsCreated = $projectStatsJson.dataProviders.'ms.vss-work-web.work-item-metrics-data-provider-verticals'.workMetrics.workItemsCreated
$workItemsCompleted = $projectStatsJson.dataProviders.'ms.vss-work-web.work-item-metrics-data-provider-verticals'.workMetrics.workItemsCompleted
$commitsPushed = $projectStatsJson.dataProviders.'ms.vss-code-web.code-metrics-data-provider-verticals'.gitmetrics.commitsPushedCount
if (!$commitsPushed) {$commitsPushed = 0}

$pullRequestsCreated = $projectStatsJson.dataProviders.'ms.vss-code-web.code-metrics-data-provider-verticals'.gitmetrics.pullRequestsCreatedCount
if (!$pullRequestsCreated) {$pullRequestsCreated = 0}

$pullRequestsCompleted = $projectStatsJson.dataProviders.'ms.vss-code-web.code-metrics-data-provider-verticals'.gitmetrics.pullRequestsCompletedCount
if (!$pullRequestsCompleted) {$pullRequestsCompleted = 0}
           
$uriBuildMetrics = $UriOrganization + "$($projectId)/_apis/build/Metrics/Daily?minMetricsTime=$($monthAgo)" 
$buildMetricsResult = Invoke-RestMethod -Uri $uriBuildMetrics -Method get -Headers $AzureDevOpsAuthenicationHeader
$totalBuilds = 0
$buildMetricsResult.value | Where-Object {$_.name -eq 'TotalBuilds'} | ForEach-Object { $totalBuilds+= $_.intValue }
        
$UriReleaseMetrics = $UriOrganizationRM + "$($projectId)/_apis/Release/metrics?minMetricsTime=minMetricsTime=$($monthAgo)"
$releaseMetricsResult = Invoke-RestMethod -Uri $UriReleaseMetrics -Method get -Headers $AzureDevOpsAuthenicationHeader
$totalReleases = 0
$releaseMetricsResult.value | ForEach-Object { $totalReleases+= $_.value }

$Projects = New-Object 'Collections.Generic.List[pscustomobject]'
$table = $db.Tables["Projects"]

$projectObject = [PSCustomObject] [ordered]@{
    TeamProjectId=$projectId
    TeamProjectName=$projectName
    ProcessTypeId=$processtypeId
    TeamProjectCountWorkItemCreated=$workItemsCreated
    TeamProjectCountWorkItemCompleted=$workItemsCompleted
    TeamProjectCountCommitsPushed=$commitsPushed
    TeamProjectCountPRsCreated=$pullRequestsCreated
    TeamProjectCountPRsCompleted=$pullRequestsCompleted
    TeamProjectCountBuilds=$totalBuilds
    TeamProjectCountReleases=$totalReleases
}
$Projects.Add($projectObject)

Write-SqlTableData -InputData $Projects -InputObject $table
& .\LogFile.ps1 -LogFile $LogFile -Message "Inserting project name: $($projectName) and project stats on table Projects"