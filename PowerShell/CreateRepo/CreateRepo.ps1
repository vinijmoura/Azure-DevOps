Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Project,
    [string]$RepoName,
    [string]$Reviewers
)

Function Set-BranchPolicy
{
    Param
    (
        [string]$Organization,
        [string]$Project,
        [string]$repoId, 
        [string]$branchName,
        [string]$Reviewers
    )

    Write-Host "===Creating branch policies on $($branchName)"

    Write-Host '======Policy: Require a minimum number of reviewers'
    $policyApproverCount = az repos policy approver-count create --allow-downvotes false --blocking true --branch $branchName --creator-vote-counts false --enabled true --minimum-approver-count 1 --repository-id $repoId --reset-on-source-push false  --project $Project --organization $Organization | ConvertFrom-Json
    Write-Host '======Creating on Date:' $policyApproverCount.createdDate
    
    Write-Host '======Policy: Checked for linked work items'
    $policyWorkItemLinking = az repos policy work-item-linking create --blocking true --branch $branchName --enabled true --repository-id $repoId --project $Project --organization $Organization | ConvertFrom-Json
    Write-Host '======Creating on Date:' $policyWorkItemLinking.createdDate 

    Write-Host '======Policy: Checked for comment resolution'
    $policyCommentRequired = az repos policy comment-required create --blocking true --branch $branchName --enabled true --repository-id $repoId --project $Project --organization $Organization | ConvertFrom-Json
    Write-Host '======Creating on Date:' $policyCommentRequired.createdDate

    Write-Host '======Policy: Automatically include code reviewers'
    $policyRequiredReviewer = az repos policy required-reviewer create --blocking true --branch $branchName --enabled true --repository-id $repoId --message "master" --required-reviewer-ids $Reviewers  --project $Project --organization $Organization| ConvertFrom-Json
    Write-Host '======Creating on Date: ' $policyRequiredReviewer.createdDate
}

echo $PAT | az devops login --org $Organization

Write-Host '===Configuring connection to organization and Team Project'
az devops configure --defaults organization=$Organization project=$Project

Write-Host '===Creating repository'
$createRepo = az repos create --name $RepoName --project $Project --organization $Organization | ConvertFrom-Json

Write-Host '======Remote URL: ' $createRepo.remoteUrl
Write-Host '======Repo ID: ' $createRepo.id

Set-BranchPolicy -Organization $Organization -Project $Project -repoId $createRepo.id -Reviewers $Reviewers -branchName "main"