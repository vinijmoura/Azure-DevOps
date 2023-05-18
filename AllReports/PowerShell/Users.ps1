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

foreach ($au in $allUsers.value) {
    $yearAccess = ([datetime]$au.lastAccessedDate).Year
    if ($yearAccess -eq 1) {
        $LastDate = $au.dateCreated
    }
    else {
        $LastDate = $au.lastAccessedDate
    }
    $usersObject = [PSCustomObject] [ordered]@{
        UserId                 = $au.id
        UserPrincipalName      = $au.user.principalName
        UserDisplayName        = $au.user.displayName
        UserPictureLink        = $au.user.url
        UserDateCreated        = $au.dateCreated
        UserLastAccessedDate   = $LastDate
        UserLicenseDisplayName = $au.accessLevel.licenseDisplayName
    }
    $Users.Add($usersObject)
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting user: $($au.user.principalName) on table Users"
    
    $UriActiveUserGroups = "https://vssps.dev.azure.com/$($Organization)/_apis/graph/Memberships/$($au.user.descriptor)?api-version=7.0-preview.1"
    $activeUserGroups = Invoke-RestMethod -Uri $UriActiveUserGroups -Method get -Headers $AzureDevOpsAuthenicationHeader
    foreach ($aug in $activeUserGroups.value) {
        $groupPrincipalName = Invoke-RestMethod -Uri $aug._links.container.href -Method get -Headers $AzureDevOpsAuthenicationHeader
        if ($groupPrincipalName) {  
            $usersGroupsObject = [PSCustomObject] [ordered]@{
                UserId    = $au.id
                GroupName = $groupPrincipalName.principalName
            }
            $UsersGroups.Add($usersGroupsObject)
        }
    }
    
    if ($UsersGroups.Count -gt 0) {
        & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Permission Groups to which user $($au.user.principalName) belongs on table UsersGroups"
    }

    $UriUserPAT = "https://vssps.dev.azure.com/$($Organization)/_apis/tokenadmin/personalaccesstokens/$($au.user.descriptor)?api-version=6.1-preview.1"
    $UserPATResult = Invoke-RestMethod -Uri $UriUserPAT -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($up in $UserPATResult.value) {
        if ($up.scope -eq 'app_token') {
            $accessToken = 'Full access'
        }
        else {
            $accessToken = $up.scope.Replace(" ", "`r`n")
        }
        $usersPersonalAccessTokensObject = [PSCustomObject] [ordered]@{
            UserId         = $au.id
            PATDisplayName = $up.displayName
            PATValidFrom   = $up.validFrom
            PATValidTo     = $up.validTo
            PATScope       = $accessToken
        }
        $UsersPersonalAccessTokens.Add($usersPersonalAccessTokensObject)
    }
    if ($UsersPersonalAccessTokens.Count -gt 0) {
        & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Personal Access Tokens belonging to user $($au.user.principalName) on table UsersPersonalAccessTokens"
    }
}
Write-SqlTableData -InputData $Users -InputObject $tableUsers
Write-SqlTableData -InputData $UsersGroups -InputObject $tableUsersGroups
Write-SqlTableData -InputData $UsersPersonalAccessTokens -InputObject $tableUsersPersonalAccessTokens

