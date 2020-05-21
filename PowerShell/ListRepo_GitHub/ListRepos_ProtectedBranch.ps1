$token = '[Personal Acces Token]'
$base64Token = [System.Convert]::ToBase64String([char[]]$token)
$headers = @{
    Authorization = 'Basic {0}' -f $base64Token
};

$response = Invoke-RestMethod -Headers $headers -Uri https://api.github.com/user/repos

foreach ($obj in $response)
{
    Write-Host '=RepoName:'($obj.name)
    Write-Host '==BranchesURL:'($obj.branches_url)
    $branch = $obj.branches_url.Replace('{/branch}','/master')
    $branchInfo = Invoke-RestMethod -Headers $headers -Uri $branch
    if ($branchInfo.protected)
    {
        Write-Host '===MasterProtectionURL:'$branchInfo.protection_url        
        $branchProtection = Invoke-RestMethod -Headers $headers -Uri $branchInfo.protection_url
        If ($branchProtection)
        {
            Write-Host '====allow_deletions'$branchProtection.allow_deletions
            Write-Host '====allow_force_pushes'$branchProtection.allow_force_pushes
            Write-Host '====enforce_admins'$branchProtection.enforce_admins
            Write-Host '====required_linear_history'$branchProtection.required_linear_history
            Write-Host '====required_pull_request_reviews'$branchProtection.required_pull_request_reviews
        }
    }
}