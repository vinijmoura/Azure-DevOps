Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE RepoBranchPolicies"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$RepoBranchPolicies = @()

$minimumRev = "Minimum number of reviewers"
$reqReviewers = "Required reviewers"
$workItemLink = "Work item linking"
$commentReq = "Comment requirements"
$Build = "Build"

echo $PAT | az devops login --org $Organization

az devops configure --defaults organization=$Organization
$ProjectsResult = az devops project list --org $Organization --top 500 | ConvertFrom-Json

Foreach ($project in $ProjectsResult.value)
{
    $ReposResult = az repos list --org $Organization --project $project.id | ConvertFrom-Json
    Foreach ($repo in $ReposResult)
    {
        if ($repo.defaultBranch)
        {
            $ReposPolicyResult = az repos policy list --branch $repo.defaultBranch --org $Organization --project $project.id --repository-id $repo.id | ConvertFrom-Json
        
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
            $RepoBranchPolicies += New-Object -TypeName PSObject -Property @{
                    TeamProjectId=$project.id
                    TeamProjectName=$project.name
                    RepositoryId=$repo.id
                    RepositoryName=$repo.name
                    RepositoryURL=$repo.remoteUrl
                    RepositoryDefaultBranch=$repo.defaultBranch
                    RepositoryDefaultBranchMinimumNumberOfReviewers=$repominimumRev
                    RepositoryDefaultBranchRequiredReviewers=$reporeqReviewers
                    RepositoryDefaultBranchWorkItemLinking=$repoworkItemLink
                    RepositoryDefaultBranchCommentRequirements=$repocommentReq
                    RepositoryDefaultBranchBuild=$repoBuild
            }
            $SQLQuery = "INSERT INTO RepoBranchPolicies (
                         TeamProjectId,
                         TeamProjectName,
                         RepositoryId,
                         RepositoryName,
                         RepositoryURL,
                         RepositoryDefaultBranch,
                         RepositoryDefaultBranchMinimumNumberOfReviewers,
                         RepositoryDefaultBranchRequiredReviewers,
                         RepositoryDefaultBranchWorkItemLinking,
                         RepositoryDefaultBranchCommentRequirements,
                         RepositoryDefaultBranchBuild )
                         VALUES(
                         '$($project.id)',
                         '$($project.name)',
                         '$($repo.id)',
                         '$($repo.name)',
                         '$($repo.remoteUrl)',
                         '$($repo.defaultBranch)',
                         '$($repominimumRev)',
                         '$($reporeqReviewers)',
                         '$($repoworkItemLink)',
                         '$($repocommentReq)',
                         '$($repoBuild)'
                         )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}

$RepoBranchPolicies | ConvertTo-Json | Out-File -FilePath "$home\desktop\RepoBranchPolicies.json"

