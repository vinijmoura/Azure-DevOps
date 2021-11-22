Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "DELETE FROM RepositoriesAheadBehind"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM RepositoriesPullRequests"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM Repositories"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SQLQuery = "DELETE FROM Projects"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$minimumRev = "Minimum number of reviewers"
$reqReviewers = "Required reviewers"
$workItemLink = "Work item linking"
$commentReq = "Comment requirements"
$Build = "Build"

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects?`$top=500"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    #insert team projects
    $SQLQuery = "INSERT INTO Projects (
                            TeamProjectId,
                            TeamProjectName
                            )
                            VALUES(
                            '$($project.id)',
                            '$($project.name)'
                            )"
    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

    $uriRepositories = $UriOrganization + "$($project.id)/_apis/git/repositories?api-version=6.1-preview.1"
    $RepositoriesResult = Invoke-RestMethod -Uri $uriRepositories -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($repo in $RepositoriesResult.value)
    {
        if ($repo.defaultBranch)
        {
            #repos and branch policies (default branch)
            $ReposPolicyResult = az repos policy list --branch $repo.defaultBranch --org $UriOrganization --project $project.id --repository-id $repo.id | ConvertFrom-Json
            
            [bool] $repominimumRev = $false
            [bool] $reporeqReviewers = $false
            [bool] $repoworkItemLink = $false
            [bool] $repocommentReq = $false
            [bool] $repoBuild = $false

            Foreach ($repoPolicy in $ReposPolicyResult)
            {
                switch($repoPolicy.type.displayName)
                {
                    $minimumRev {$repominimumRev = $true}
                    $reqReviewers {$reporeqReviewers = $true}
                    $workItemLink {$repoworkItemLink = $true}
                    $commentReq {$repocommentReq = $true}
                    $Build {$repoBuild = $true}
                }
            }

            $SQLQuery = "INSERT INTO Repositories (
                                    TeamProjectId,
                                    RepositoryId,
                                    RepositoryName,
                                    RepositoryURL,
                                    RepositoryDefaultBranch,
                                    RepositoryDefaultBranchMinimumNumberOfReviewers,
                                    RepositoryDefaultBranchRequiredReviewers,
                                    RepositoryDefaultBranchWorkItemLinking,
                                    RepositoryDefaultBranchCommentRequirements,
                                    RepositoryDefaultBranchBuild
                                    )
                                    SELECT
                                    TeamProjectId,
                                    '$($repo.id)',
                                    '$($repo.name)',
                                    '$($repo.remoteUrl)',
                                    '$($repo.defaultBranch)',
                                    '$($repominimumRev)',
                                    '$($reporeqReviewers)',
                                    '$($repoworkItemLink)',
                                    '$($repocommentReq)',
                                    '$($repoBuild)' 
                                    FROM Projects
                                    WHERE TeamProjectId='$($project.id)'"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

            if ($repo.size)
            {
                #repos and branch ahead/behind
                $uriRepositoryStats = $UriOrganization + "$($project.id)/_apis/git/repositories/$($repo.id)/stats/branches?api-version=6.1-preview.1"
                $RepositoryStatsResult = Invoke-RestMethod -Uri $uriRepositoryStats -Method get -Headers $AzureDevOpsAuthenicationHeader
                Foreach ($repostats in $RepositoryStatsResult.value)
                {   
                    $SQLQuery = "INSERT INTO RepositoriesAheadBehind (
                                            RepositoryId,
                                            RepositoryBranchName,
                                            RepositoryBranchAheadCount,
                                            RepositoryBranchBehindCount,
                                            RepositoryBranchIsBaseVersion
                                            )
                                            SELECT
                                            RepositoryId,
                                            '$($repostats.name)',
                                            $($repostats.aheadCount),
                                            $($repostats.behindCount),
                                            '$($repostats.isBaseVersion)'
                                            FROM Repositories WHERE RepositoryId='$($repo.Id)'  "
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                }
            }

            #pull requests
            $uriRepositoryPullRequests = $UriOrganization + "$($project.id)/_apis/git/repositories/$($repo.id)/pullrequests?searchCriteria.includeLinks=true&searchCriteria.status=all&`$top=100&api-version=6.0"
            $RepositoryPullRequestsResult = Invoke-RestMethod -Uri $uriRepositoryPullRequests -Method get -Headers $AzureDevOpsAuthenicationHeader
            Foreach ($pullRequest in $RepositoryPullRequestsResult.value)
            {
                $SQLQuery = "INSERT INTO RepositoriesPullRequests (
                                        RepositoryId,
                                        PullRequestId,
                                        PullRequestTitle,
                                        PullRequestBranchSource,
                                        PullRequestBranchTarget,
                                        PullRequestCreatedBy,
                                        PullRequestCreatedDate,
                                        PullRequestStatus,
                                        PullRequestReviewers
                                        )
                                        SELECT
                                        RepositoryId,
                                        $($pullRequest.pullRequestId),
                                        '$($pullRequest.title)',
                                        '$($pullRequest.sourceRefName)',
                                        '$($pullRequest.targetRefName)',
                                        '$($pullRequest.createdBy.displayName)',
                                        CONVERT(DATETIME,SUBSTRING('$($pullRequest.creationDate)',1,19),127),
                                        '$($pullRequest.status)',
                                        '$($pullRequest.reviewers)'
                                        FROM Repositories WHERE RepositoryId='$($repo.Id)' "
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }  
}