Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$newUser,
    [string]$newUserLicenseType,
    [string]$activeUser
)

echo $PAT | az devops login --org $Organization

Write-Host '==Configuring connection to organization'
az devops configure --defaults organization=$Organization

Write-Host '====Insert new user on Azure DevOps'
az devops user add --email-id $newUser --license-type $newUserLicenseType --org $Organization --send-email-invite true

Write-Host '====Listing permissions of the active user' $activeUser
$activeUserGroups = az devops security group membership list --id $activeUser --org $Organization --relationship memberof | ConvertFrom-Json
[array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name

foreach ($aug in $groups)
{
    Write-Host '======Inserting' $newUser 'on' $activeUserGroups.$aug.principalName 'group'
    az devops security group membership add --group-id $activeUserGroups.$aug.descriptor --member-id $newUser --org $Organization
}