Param
(
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $projectId,
    $projectName,
    $LogFile
)

$UriOrganization = "https://dev.azure.com/$($Organization)/"
echo $PAT | az devops login --org $UriOrganization
az devops configure --defaults organization=$UriOrganization

$minimumRev = "Minimum number of reviewers"
$reqReviewers = "Required reviewers"
$workItemLink = "Work item linking"
$commentReq = "Comment requirements"
$Build = "Build"

$uriRepositories = $UriOrganization + "$($projectId)/_apis/git/repositories?api-version=6.1-preview.1"
$RepositoriesResult = Invoke-RestMethod -Uri $uriRepositories -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($repo in $RepositoriesResult.value)
{
    if ($repo.defaultBranch)
    {
        #repos and branch policies (default branch)
        $ReposPolicyResult = az repos policy list --branch $repo.defaultBranch --org $UriOrganization --project $projectId --repository-id $repo.id | ConvertFrom-Json
            
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

        $Repositories = New-Object 'Collections.Generic.List[pscustomobject]'
        $table = $db.Tables["Repositories"]

        $repoObject = [PSCustomObject] [ordered]@{
            TeamProjectId=$projectId
            RepositoryId=$repo.id
            RepositoryName=$repo.name
            RepositoryURL=$repo.remoteUrl
            RepositoryDefaultBranch=$repo.defaultBranch
            RepositoryMinimumNumberOfReviewers=$repominimumRev
            RepositoryRequiredReviewers=$reporeqReviewers
            RepositoryWorkItemLinking=$repoworkItemLink
            RepositoryCommentRequirements=$repocommentReq
            RepositoryBranchBuild=$repoBuild
        }
        $Repositories.Add($repoObject)
        Write-SqlTableData -InputData $Repositories -InputObject $table
        & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting repository: $($repo.name) from the project $($projectName) on table Repositories"

        $RepositoriesAheadBehind = New-Object 'Collections.Generic.List[pscustomobject]'
        $table = $db.Tables["RepositoriesAheadBehind"]

        if ($repo.size)
        {
            #repos and branch ahead/behind
            $uriRepositoryStats = $UriOrganization + "$($projectId)/_apis/git/repositories/$($repo.id)/stats/branches?api-version=6.1-preview.1"
            $RepositoryStatsResult = Invoke-RestMethod -Uri $uriRepositoryStats -Method get -Headers $AzureDevOpsAuthenicationHeader
            Foreach ($repostats in $RepositoryStatsResult.value)
            {   
                $repositoriesAheadBehindObject = [PSCustomObject] [ordered]@{
                    RepositoryId=$repo.Id
                    RepositoryBranchName=$repostats.name
                    RepositoryBranchAheadCount=$repostats.aheadCount
                    RepositoryBranchBehindCount=$repostats.behindCount
                    RepositoryBranchIsBaseVersion=$repostats.isBaseVersion
                }
                $RepositoriesAheadBehind.Add($repositoriesAheadBehindObject)
            }

            if ($RepositoriesAheadBehind.Count -gt 0)
            {
                Write-SqlTableData -InputData $RepositoriesAheadBehind -InputObject $table
                & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Commits Ahead/Behind to which project $($projectName) and repository $($repo.name) belongs on table RepositoriesAheadBehind"
            }
        }

        
        #pull requests
        $RepositoriesPullRequests = New-Object 'Collections.Generic.List[pscustomobject]'
        $table = $db.Tables["RepositoriesPullRequests"]

        $uriRepositoryPullRequests = $UriOrganization + "$($projectId)/_apis/git/repositories/$($repo.id)/pullrequests?searchCriteria.includeLinks=true&searchCriteria.status=all&`$top=100&api-version=6.0"
        $RepositoryPullRequestsResult = Invoke-RestMethod -Uri $uriRepositoryPullRequests -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($pullRequest in $RepositoryPullRequestsResult.value)
        {
            $pullRequestReviewers = ''
            if ($pullRequest.reviewers.Count -gt 0)
            {
                Foreach ($prr in $pullRequest.reviewers)
                {
                    $pullRequestReviewers += $prr.displayName + "`r`n"
                }
            }

            $repositoriesPullRequestsObject = [PSCustomObject] [ordered]@{
                RepositoryId=$repo.Id
                PullRequestId=$pullRequest.pullRequestId
                PullRequestTitle=$pullRequest.title
                PullRequestBranchSource=$pullRequest.sourceRefName
                PullRequestBranchTarget=$pullRequest.targetRefName
                PullRequestCreatedBy=$pullRequest.createdBy.displayName
                PullRequestCreatedDate=$pullRequest.creationDate
                PullRequestStatus=$pullRequest.status
                PullRequestReviewers=$pullRequestReviewers
            }
            $RepositoriesPullRequests.Add($repositoriesPullRequestsObject)
        }

        if ($RepositoriesPullRequests.Count)
        {
            Write-SqlTableData -InputData $RepositoriesPullRequests -InputObject $table
            & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Pull Requests to which project $($projectName) and repository $($repo.name) belongs on table RepositoriesPullRequests"
        }
    }
}