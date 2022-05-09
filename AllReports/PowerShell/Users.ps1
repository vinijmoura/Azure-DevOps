Param
(
    $PAT,
    $Organization,
    $db,
    $LogFile
)

$UriOrganization = "https://dev.azure.com/$($Organization)"

echo $PAT | az devops login --org $UriOrganization
az devops configure --defaults organization=$UriOrganization

$allUsers = az devops user list --org $UriOrganization | ConvertFrom-Json

foreach($au in $allUsers.members)
{
    $Users = New-Object 'Collections.Generic.List[pscustomobject]'
    $table = $db.Tables["Users"]
    
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
    Write-SqlTableData -InputData $Users -InputObject $table
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting user: $($au.user.principalName) on table Users"
    
    $activeUserGroups = az devops security group membership list --id $au.user.principalName --org $UriOrganization --relationship memberof | ConvertFrom-Json
    [array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name

    $UsersGroups = New-Object 'Collections.Generic.List[pscustomobject]'
    $table = $db.Tables["UsersGroups"]

    foreach ($aug in $groups)
    {
        $usersGroupsObject = [PSCustomObject] [ordered]@{
            principalName=$au.id
            GroupName=$activeUserGroups.$aug.principalName
        }
        $UsersGroups.Add($usersGroupsObject)
    }
    if ($UsersGroups.Count -gt 0)
    {
        Write-SqlTableData -InputData $UsersGroups -InputObject $table
        & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting Permission Groups to which user $($au.user.principalName) belongs on table UsersGroups"
    }
}