Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ProjectName,
    [string]$mailAddress,
    [string]$Connstr
)


$SQLQuery = "TRUNCATE TABLE GitRepositoriesPermissions"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SecurityNameSpaceIdGitRepositories = "2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87"

echo $PAT | az devops login --org $Organization

az devops configure --defaults organization=$Organization

$allUsers = az devops user list --org $Organization | ConvertFrom-Json
$allUsers = $allUsers.members 
$allUsers = $allusers.user | where-object {$_.mailAddress -eq $mailAddress}

$allProjects = az devops project list --org $Organization --top 500 | ConvertFrom-Json
$allProjects = $allProjects.value | Where name -EQ $ProjectName

$Domain = "vstfs:///Classification/TeamProject/$($allProjects.id)"       
$allrepos = az repos list --org $Organization --project $allProjects.id | ConvertFrom-Json
Foreach ($ar in $allrepos)
{
    $activeUserGroups = az devops security group membership list --id $allUsers.principalName --org $Organization --relationship memberof | ConvertFrom-Json
    [array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name

    foreach ($aug in $groups)
    {       
        if ($Domain -eq $activeUserGroups.$aug.domain)
        {
            $gitToken = "repoV2/$($allProjects.id)/$($ar.id)"
            $gitCommands = az devops security permission show --id $SecurityNameSpaceIdGitRepositories --subject $activeUserGroups.$aug.descriptor --token $gitToken --org $Organization | ConvertFrom-Json
            $gitPermissions = ($gitCommands[0].acesDictionary | Get-Member -MemberType NoteProperty).Name
            foreach($gp in $gitCommands.acesDictionary.$gitPermissions.resolvedPermissions)
            {
                $SQLQuery = "INSERT INTO GitRepositoriesPermissions (
                            TeamProjectName,
                            RepoName,
                            SecurityNameSpace,
                            UserPrincipalName,
                            UserDisplayName,
                            GroupDisplayName,
                            GroupAccountName,
                            GitCommandName,
                            GitCommandInternalName,
                            GitCommandPermission)
                            VALUES(
                            '$($allProjects.name)',
                            '$($ar.name)',
                            'Git Repositories',
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