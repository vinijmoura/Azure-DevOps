Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ProjectName,
    [string]$RepositoryName,
    [string]$BranchName
)
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriRepositories = "$($UriOrganization)$($ProjectName)/_apis/git/repositories/$($RepositoryName)?api-version=7.0"
$RepositoriesResult = Invoke-RestMethod -Uri $uriRepositories -Method get -Headers $AzureDevOpsAuthenicationHeader

if ($RepositoriesResult)
{ 
    $uribranchExists="$($UriOrganization)_apis/git/repositories/$($RepositoriesResult.id)/refs"
    $branchExistsResults = Invoke-RestMethod -Uri $uribranchExists -Method get -Headers $AzureDevOpsAuthenicationHeader
    $validBranch = $branchExistsResults.value | where-object {$_.name -eq "refs/heads/$($BranchName)"}

    if ($validBranch)
    {
        $body = ConvertTo-Json (
                                    @(
                                        @{
                                            name        = $validBranch.name;
                                            oldObjectId = $validBranch.objectId;
                                            newObjectId = "0000000000000000000000000000000000000000";
                                        }
                                        )
                                )
        $urlDeleteBranch = "$($UriOrganization)$($ProjectName)/_apis/git/repositories/$($RepositoriesResult.id)/refs?api-version=7.1-preview.1"
        $DeleteBranchResult = Invoke-RestMethod -Uri $urlDeleteBranch -Method Post -Headers $AzureDevOpsAuthenicationHeader -Body $body -ContentType "application/json"                                
    }
}
