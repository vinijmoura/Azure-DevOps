Param
(
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $LogFile
)

$FeedPackageVersions = New-Object 'Collections.Generic.List[pscustomobject]'
$table = $db.Tables["FeedPackageVersions"]

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

            If (!$feed.description)
            {
                $FeedDescription=''
            }
            else
            {
                $FeedDescription=$feed.description
            }

            $feedPackageVersionsObject = [PSCustomObject] [ordered]@{
                FeedId=$feed.id
                FeedName=$feed.name
                FeedDescription=$FeedDescription
                FeedPackageName=$feedpackage.name
                FeedPackageType=$feedpackage.protocolType
                FeedPackageSource=$feedPackageSource
                FeedPackageVersion=$feedpackageversion.version
                FeedPackageVersionLatest=$feedpackageversion.isLatest
                FeedPackageVersionDate=$(get-date $feedpackageversion.publishDate -Format 'yyyy-MM-dd HH:mm:ss')
                FeedPackageVersionDownloadCount=$downloadCount
                FeedPackageVersionDownloadUniqueUsers=$downloadUniqueUsers
            }
            $FeedPackageVersions.Add($feedPackageVersionsObject)
        }
    }
}
if ($FeedPackageVersions.Count -gt 0)
{
    Write-SqlTableData -InputData $FeedPackageVersions -InputObject $table
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Feed Packages and versions to which organization $($Organization) belongs on table FeedPackageVersions"
}
