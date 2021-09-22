Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ProjectStats"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) } + @{"Content-Type"="application/json"; "Accept"="application/json"}
$UriOrganization = "https://dev.azure.com/$($Organization)/"
$UriOrganizationRM = "https://vsrm.dev.azure.com/$($Organization)/"

$monthAgo = (Get-Date).AddMonths(-1).ToString("yyyy-MM-dd")

$uriProject = $UriOrganization + "_apis/projects?`$top=500&api-version=6.1-preview.4"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriProjectStats = $UriOrganization + "_apis/Contribution/HierarchyQuery/project/$($project.id)?api-version=6.1-preview.1"   
    $projectStatsBody = @{
        "contributionIds"= @("ms.vss-work-web.work-item-metrics-data-provider-verticals", "ms.vss-code-web.code-metrics-data-provider-verticals", "ms.vss-code-web.build-metrics-data-provider-verticals")
        "dataProviderContext" = @{
            "properties" =@{
                "numOfDays"=30
                "sourcePage"=@{
                    "url"=($UriOrganization + $project.name)
                    "routeId"="ms.vss-tfs-web.project-overview-route"
                    "routeValues" =@{
                        "project" = $project.id
                        "controller"="Apps"
                        "action"="ContributedHub"
                        "serviceHost"=$Organization
                        }
                    }          
                }
            }
        }  | ConvertTo-Json -Depth 5

    $projectStatsResult = Invoke-WebRequest -Uri $uriProjectStats -Headers $AzureDevOpsAuthenicationHeader -Method Post -Body $projectStatsBody 
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
           
    $uriBuildMetrics = $UriOrganization + "$($project.id)/_apis/build/Metrics/Daily?minMetricsTime=$($monthAgo)" 
    $buildMetricsResult = Invoke-RestMethod -Uri $uriBuildMetrics -Method get -Headers $AzureDevOpsAuthenicationHeader
    $totalBuilds = 0
    $buildMetricsResult.value | Where-Object {$_.name -eq 'TotalBuilds'} | ForEach-Object { $totalBuilds+= $_.intValue }

    $totalReleases = 0
    $UriReleaseMetrics = $UriOrganizationRM + "$($project.id)/_apis/Release/metrics?minMetricsTime=minMetricsTime=$($monthAgo)"
    $releaseMetricsResult = Invoke-RestMethod -Uri $UriReleaseMetrics -Method get -Headers $AzureDevOpsAuthenicationHeader
    $releaseMetricsResult.value | ForEach-Object { $totalReleases+= $_.value }

    $SQLQuery = "INSERT INTO ProjectStats(
                TeamProjectName,
                TeamProjectCountWorkItemCreated,
                TeamProjectCountWorkItemCompleted,
                TeamProjectCountCommitsPushed,
                TeamProjectCountPRsCreated,
                TeamProjectCountPRsCompleted,
                TeamProjectCountBuilds,
                TeamProjectCountReleases
            )
            VALUES(
                '$($project.name)',
                $workItemsCreated,
                $workItemsCompleted,
                $commitsPushed,
                $pullRequestsCreated,
                $pullRequestsCompleted,
                $totalBuilds,
                $totalReleases
            )"
    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
}
