Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE LatestReleases"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"
$uriReleases = "https://vsrm.dev.azure.com/$($Organization)/"
[bool] $enabled = $true

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{   
    $uriReleaseDefinitions = $uriReleases + "$($project.id)/_apis/release/definitions?api-version=6.1-preview.4"
    $ReleaseDefintionsResult = Invoke-RestMethod -Uri $uriReleaseDefinitions -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($releaseDef in $ReleaseDefintionsResult.value)
    {    
        $uriLatestRelease = $uriReleases + "$($project.id)/_apis/release/releases?definitionId=$($releaseDef.id)&queryOrder=descending&`$top=1&`$expand=environments&api-version=6.0"
        $LatestReleaseResult = Invoke-RestMethod -Uri $uriLatestRelease -Method get -Headers $AzureDevOpsAuthenicationHeader
        if ($LatestReleaseResult.count -gt 0)
        {
            Foreach ($environmentStatus in $LatestReleaseResult.value[0].environments)
            {
                $EnvironmentBadge = $uriReleases + "_apis/public/Release/badge/$($project.id)/$($releaseDef.id)/$($environmentStatus.definitionEnvironmentId)"

                $SQLQuery = "INSERT INTO LatestReleases (
                            TeamProjectName,
                            ReleaseDefinitionId,
                            ReleaseDefinitionName,
                            ReleaseNumber,
                            ReleaseCreatedOn,
                            ReleaseLink,
                            ReleaseEnvironmentName,
                            ReleaseEnvironmentResult,
                            ReleaseEnvironmentReason,
                            ReleaseEnvironmentRequestedFor,
                            ReleaseEnvironmentRank,
                            ReleaseEnvironmentBadge,
                            ReleaseEnvironmentBadgeEnabled
                            )
                            VALUES(
                            '$($project.name)',
                            '$($releaseDef.id)',
                            '$($releaseDef.name)',
                            '$($LatestReleaseResult.value[0].name)',
                            CONVERT(DATETIME,SUBSTRING('$($LatestReleaseResult.value[0].createdOn)',1,19),127),
                            '$($LatestReleaseResult.value[0]._links.web.href)',
                            '$($environmentStatus.name)',
                            '$($environmentStatus.deploySteps[0].status)',
                            '$($environmentStatus.deploySteps[0].reason)',
                            '$($environmentStatus.deploySteps[0].requestedFor.displayName)',
                            $($environmentStatus.rank),
                            '$($EnvironmentBadge)',
                            '$($enabled)'
                            )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }
}