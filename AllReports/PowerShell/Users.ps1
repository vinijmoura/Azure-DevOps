Param
(
    $PAT,
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $LogFile
)

$UriOrganization = "https://dev.azure.com/$($Organization)/"
echo $PAT | az devops login --org $UriOrganization
az devops configure --defaults organization=$UriOrganization

$Users = New-Object 'Collections.Generic.List[pscustomobject]'
$tableUsers = $db.Tables["Users"]

$UsersGroups = New-Object 'Collections.Generic.List[pscustomobject]'
$tableUsersGroups = $db.Tables["UsersGroups"]

$UsersPersonalAccessTokens = New-Object 'Collections.Generic.List[pscustomobject]'
$tableUsersPersonalAccessTokens = $db.Tables["UsersPersonalAccessTokens"]

$allUsers = az devops user list --org $UriOrganization --top 2000 | ConvertFrom-Json

foreach($au in $allUsers.members)
{
    if ($au.lastAccessedDate -eq '0001-01-01T00:00:00+00:00')
    {
        $LastDate = $au.dateCreated
    }
    else
    {
        $LastDate = $au.lastAccessedDate
    }
    $usersObject = [PSCustomObject] [ordered]@{
        UserId=$au.id
        UserPrincipalName=$au.user.principalName
        UserDisplayName=$au.user.displayName
        UserPictureLink=$au.user.url
        UserDateCreated=$au.dateCreated
        UserLastAccessedDate=$LastDate
        UserLicenseDisplayName=$au.accessLevel.licenseDisplayName
    }
    $Users.Add($usersObject)
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting user: $($au.user.principalName) on table Users"
    
    $activeUserGroups = az devops security group membership list --id $au.user.principalName --org $UriOrganization --relationship memberof | ConvertFrom-Json
    [array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name
    foreach ($aug in $groups)
    {
        $usersGroupsObject = [PSCustomObject] [ordered]@{
            UserId=$au.id
            GroupName=$activeUserGroups.$aug.principalName
        }
        $UsersGroups.Add($usersGroupsObject)
    }
    if ($UsersGroups.Count -gt 0)
    {
        & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Permission Groups to which user $($au.user.principalName) belongs on table UsersGroups"
    }

    $UriUserPAT = "https://vssps.dev.azure.com/$($Organization)/_apis/tokenadmin/personalaccesstokens/$($au.user.descriptor)?api-version=6.1-preview.1"
    $UserPATResult = Invoke-RestMethod -Uri $UriUserPAT -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($up in $UserPATResult.value)
    {
        if ($up.scope -eq 'app_token')
        {
            $accessToken = 'Full access'
        }
        else
        {
            $accessToken = $up.scope.Replace(" ","`r`n")
        }
        $usersPersonalAccessTokensObject = [PSCustomObject] [ordered]@{
            UserId=$au.id
            PATDisplayName=$up.displayName
            PATValidFrom=$up.validFrom
            PATValidTo=$up.validTo
            PATScope=$accessToken
        }
        $UsersPersonalAccessTokens.Add($usersPersonalAccessTokensObject)
    }
    if ($UsersPersonalAccessTokens.Count -gt 0)
    {
        & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Personal Access Tokens belonging to user $($au.user.principalName) on table UsersPersonalAccessTokens"
    }
}

Write-SqlTableData -InputData $Users -InputObject $tableUsers
Write-SqlTableData -InputData $UsersGroups -InputObject $tableUsersGroups
Write-SqlTableData -InputData $UsersPersonalAccessTokens -InputObject $tableUsersPersonalAccessTokens
