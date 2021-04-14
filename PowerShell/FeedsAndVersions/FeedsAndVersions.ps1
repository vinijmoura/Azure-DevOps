Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE FeedPackageVersions"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriRootFeeds = "https://feeds.dev.azure.com/$($Organization)/"

$UriFeeds = $UriRootFeeds + "_apis/packaging/feeds?api-version=6.0-preview.1"
$FeedResult = Invoke-RestMethod -Uri $UriFeeds -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($feed in $FeedResult.value)
{
    $UriFeedPackages = $UriRootFeeds + "$($feed.project.name)/_apis/packaging/Feeds/$($feed.id)/packages?api-version=6.0-preview.1"
    $FeedPackageResult = Invoke-RestMethod -Uri $UriFeedPackages -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($feedpackage in $FeedPackageResult.value)
    {
        $UriFeedPackageVersion = $UriRootFeeds + "$($feed.project.name)/_apis/packaging/Feeds/$($feed.id)/Packages/$($feedpackage.id)/versions?api-version=6.0-preview.1"
        $FeedPackageVersionResult = Invoke-RestMethod -Uri $UriFeedPackageVersion -Method get -Headers $AzureDevOpsAuthenicationHeader
         Foreach ($feedpackageversion in $FeedPackageVersionResult.value)
        {
            $BodyPackageVersionIds = @{ packageVersionIds = @($feedpackageversion.id) } | ConvertTo-Json
            $UriFeedPackageVersionUsage = $UriRootFeeds + "$($feed.project.name)/_apis/packaging/Feeds/$($feed.id)/Packages/$($feedpackage.id)/versionmetricsbatch?api-version=6.0-preview.1"
            $FeedPackageVersionUsageResult = Invoke-RestMethod -Uri $UriFeedPackageVersionUsage -ContentType "application/json" -Method Post -Body $BodyPackageVersionIds -Headers $AzureDevOpsAuthenicationHeader
            $downloadCount = 0
            $downloadUniqueUsers = 0
            $feedPackageSource = "This feed"
            if ($FeedPackageVersionUsageResult.value)
            {
                foreach ($feedpackageversionusage in $FeedPackageVersionUsageResult.value)
                {
                    $downloadCount = $feedpackageversionusage.downloadCount
                    $downloadUniqueUsers = $feedpackageversionusage.downloadUniqueUsers
                }
            }
            if ($feedpackageversion.sourceChain)
            {
                $feedPackageSource = $feedpackageversion.sourceChain | Select -ExpandProperty name
            }

            $SQLQuery = "INSERT INTO FeedPackageVersions(
                FeedName,
                FeedDescription,
                FeedPackageName,
                FeedPackageType,
                FeedPackageSource,
                FeedPackageVersion,
                FeedPackageVersionLatest,
                FeedPackageVersionDate,
                FeedPackageVersionDownloadCount,
                FeedPackageVersionDownloadUniqueUsers
            )
            VALUES(
                '$($feed.name)',
                '$($feed.description)',
                '$($feedpackage.name)',
                '$($feedpackage.protocolType)',
                '$($feedPackageSource)',
                '$($feedpackageversion.version)',
                '$($feedpackageversion.isLatest)',
                '$(get-date $feedpackageversion.publishDate -Format 'yyyy-MM-dd HH:mm:ss')',
                $($downloadCount),
                $($downloadUniqueUsers)
            )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}
