Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ReposAheadBehind"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriRepositories = $UriOrganization + "$($project.id)/_apis/git/repositories?api-version=6.1-preview.1"
    $RepositoriesResult = Invoke-RestMethod -Uri $uriRepositories -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($repo in $RepositoriesResult.value)
    {
        if ($repo.size)
        {
            $uriRepositoryStats = $UriOrganization + "$($project.id)/_apis/git/repositories/$($repo.id)/stats/branches?api-version=6.1-preview.1"
            $RepositoryStatsResult = Invoke-RestMethod -Uri $uriRepositoryStats -Method get -Headers $AzureDevOpsAuthenicationHeader
            Foreach ($repostats in $RepositoryStatsResult.value)
            {   
                $SQLQuery = "INSERT INTO ReposAheadBehind (
                                        TeamProjectName,
                                        RepositoryId,
                                        RepositoryName,
                                        RepositoryBranchName,
                                        RepositoryBranchAheadCount,
                                        RepositoryBranchBehindCount,
                                        RepositoryBranchIsBaseVersion
                                        )
                                        VALUES(
                                        '$($project.name)',
                                        '$($repo.id)',
                                        '$($repo.name)',
                                        '$($repostats.name)',
                                        $($repostats.aheadCount),
                                        $($repostats.behindCount),
                                        '$($repostats.isBaseVersion)'
                                        )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }  
}



            
       
