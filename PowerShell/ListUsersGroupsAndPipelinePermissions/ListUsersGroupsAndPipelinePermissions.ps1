Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ProjectName,
    [string]$mailAddress,
    [string]$Connstr
)


$SQLQuery = "TRUNCATE TABLE PipelinePermissions"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr


$SecurityNameSpaceIds = @(
       [pscustomobject]@{SecurityNameSpace='ReleaseManagement';SecurityIdSpace='c788c23e-1b46-4162-8f5e-d7585343b5de';PermissionType='Release'}
       [pscustomobject]@{SecurityNameSpace='Build';SecurityIdSpace='33344d9c-fc72-4d6f-aba5-fa317101a7e9';PermissionType='Build'}
   )

echo $PAT | az devops login --org $Organization

az devops configure --defaults organization=$Organization

$allUsers = az devops user list --org $Organization | ConvertFrom-Json
$allUsers = $allUsers.members 
$allUsers = $allusers.user | where-object {$_.mailAddress -eq $mailAddress}

$allProjects = az devops project list --org $Organization --top 500 | ConvertFrom-Json
$allProjects = $allProjects.value | Where name -EQ $ProjectName

$Domain = "vstfs:///Classification/TeamProject/$($allProjects.id)"       

$activeUserGroups = az devops security group membership list --id $allUsers.principalName --org $Organization --relationship memberof | ConvertFrom-Json
[array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name

foreach ($aug in $groups)
{       
    if ($Domain -eq $activeUserGroups.$aug.domain)
    {
        $PipelineToken = "$($allProjects.id)"
        foreach ($snsi in $SecurityNameSpaceIds)
        {
            $PipelineCommands = az devops security permission show --id $snsi.SecurityIdSpace --subject $activeUserGroups.$aug.descriptor --token $PipelineToken --org $Organization | ConvertFrom-Json
            $PipelinePermissions = ($PipelineCommands[0].acesDictionary | Get-Member -MemberType NoteProperty).Name
            foreach($gp in $PipelineCommands.acesDictionary.$PipelinePermissions.resolvedPermissions)
            {
                $SQLQuery = "INSERT INTO PipelinePermissions (
                            TeamProjectName,
                            RepoName,
                            SecurityNameSpace,
                            UserPrincipalName,
                            UserDisplayName,
                            GroupDisplayName,
                            GroupAccountName,
                            PipelineCommandName,
                            PipelineCommandInternalName,
                            PipelineCommandPermission)
                            VALUES(
                            '$($allProjects.name)',
                            '$($ar.name)',
                            '$($snsi.PermissionType)',
                            '$($allUsers.principalName)',
                            '$($allUsers.displayName)',
                            '$($activeUserGroups.$aug.displayName)',
                            '$($activeUserGroups.$aug.principalName)',
                            '$($gp.displayName.Replace("'",''))',
                            '$($gp.name)',
                            '$($gp.effectivePermission)'
                            )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }
}
