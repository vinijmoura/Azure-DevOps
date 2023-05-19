Param
(
    $PAT,
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $LogFile
)

$Users = New-Object 'Collections.Generic.List[pscustomobject]'
$tableUsers = $db.Tables["Users"]

$UsersGroups = New-Object 'Collections.Generic.List[pscustomobject]'
$tableUsersGroups = $db.Tables["UsersGroups"]

$UsersPersonalAccessTokens = New-Object 'Collections.Generic.List[pscustomobject]'
$tableUsersPersonalAccessTokens = $db.Tables["UsersPersonalAccessTokens"]

#Get All Users
$UriUsers = "https://vsaex.dev.azure.com/$($Organization)/_apis/userentitlements?top=10000&api-version=4.1-preview.1"
$allUsers = Invoke-RestMethod -Uri $UriUsers -Method get -Headers $AzureDevOpsAuthenicationHeader

$allUsers.value | ForEach-Object -ThrottleLimit 10 -Parallel  {
#foreach ($au in $allUsers.value) {
    $yearAccess = ([datetime]$_.lastAccessedDate).Year
    if ($yearAccess -eq 1) {
        $LastDate = $_.dateCreated
    }
    else {
        $LastDate = $_.lastAccessedDate
    }
    $usersObject = [PSCustomObject] [ordered]@{
        UserId                 = $_.id
        UserPrincipalName      = $_.user.principalName
        UserDisplayName        = $_.user.displayName
        UserPictureLink        = $_.user.url
        UserDateCreated        = $_.dateCreated
        UserLastAccessedDate   = $LastDate
        UserLicenseDisplayName = $_.accessLevel.licenseDisplayName
    }
    ($using:Users).Add($usersObject)
    & .\LogFile.ps1 -LogFile $using:LogFile -Message "Inserting user: $($_.user.principalName) on table Users"
    
    $UriActiveUserGroups = "https://vssps.dev.azure.com/$($using:Organization)/_apis/graph/Memberships/$($_.user.descriptor)?api-version=7.0-preview.1"
    $activeUserGroups = Invoke-RestMethod -Uri $UriActiveUserGroups -Method get -Headers $using:AzureDevOpsAuthenicationHeader
    foreach ($aug in $activeUserGroups.value) {
        $groupPrincipalName = Invoke-RestMethod -Uri $aug._links.container.href -Method get -Headers $using:AzureDevOpsAuthenicationHeader
        if ($groupPrincipalName) {  
            $usersGroupsObject = [PSCustomObject] [ordered]@{
                UserId    = $_.id
                GroupName = $groupPrincipalName.principalName
            }
            ($using:UsersGroups).Add($usersGroupsObject)
        }
    }
    
    if ($using:UsersGroups.Count -gt 0) {
        & .\LogFile.ps1 -LogFile $using:LogFile -Message "Inserting Permission Groups to which user $($_.user.principalName) belongs on table UsersGroups"
    }

    $UriUserPAT = "https://vssps.dev.azure.com/$($using:Organization)/_apis/tokenadmin/personalaccesstokens/$($_.user.descriptor)?api-version=6.1-preview.1"
    $UserPATResult = Invoke-RestMethod -Uri $UriUserPAT -Method get -Headers $using:AzureDevOpsAuthenicationHeader
    Foreach ($up in $UserPATResult.value) {
        if ($up.scope -eq 'app_token') {
            $accessToken = 'Full access'
        }
        else {
            $accessToken = $up.scope.Replace(" ", "`r`n")
        }
        $usersPersonalAccessTokensObject = [PSCustomObject] [ordered]@{
            UserId         = $_.id
            PATDisplayName = $up.displayName
            PATValidFrom   = $up.validFrom
            PATValidTo     = $up.validTo
            PATScope       = $accessToken
        }
        ($using:UsersPersonalAccessTokens).Add($usersPersonalAccessTokensObject)
    }
    if ($using:UsersPersonalAccessTokens.Count -gt 0) {
        & .\LogFile.ps1 -LogFile $using:LogFile -Message "Inserting Personal Access Tokens belonging to user $($_.user.principalName) on table UsersPersonalAccessTokens"
    }
}
Write-SqlTableData -InputData $Users -InputObject $tableUsers
Write-SqlTableData -InputData $UsersGroups -InputObject $tableUsersGroups
Write-SqlTableData -InputData $UsersPersonalAccessTokens -InputObject $tableUsersPersonalAccessTokens

