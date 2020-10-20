Param
(
    [string]$PAT,
    [string]$Organization
)

$UserGroups = @()

echo $PAT | az devops login --org $Organization

az devops configure --defaults organization=$Organization

$allUsers = az devops user list --org $Organization | ConvertFrom-Json

foreach($au in $allUsers.members)
{
    $activeUserGroups = az devops security group membership list --id $au.user.principalName --org $Organization --relationship memberof | ConvertFrom-Json
    [array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name

    foreach ($aug in $groups)
    {
        $UserGroups += New-Object -TypeName PSObject -Property @{
                                            principalName=$au.user.principalName
                                            displayName=$au.user.displayName
                                            GroupName=$activeUserGroups.$aug.principalName
                                            }
    }
}

$UserGroups | ConvertTo-Json | Out-File -FilePath "$home\desktop\UserGroups.json"