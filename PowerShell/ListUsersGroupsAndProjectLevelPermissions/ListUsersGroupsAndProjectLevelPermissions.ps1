Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ProjectName,
    [string]$mailAddress,
    [string]$Connstr
)


$SQLQuery = "TRUNCATE TABLE ProjectLevelPermissions"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SecurityNameSpaceIds = @(
    [pscustomobject]@{SecurityNameSpace='Project';SecurityIdSpace='52d39943-cb85-4d7f-8fa8-c6baac873819'}
    [pscustomobject]@{SecurityNameSpace='Tagging';SecurityIdSpace='bb50f182-8e5e-40b8-bc21-e8752a1e7ae2'}
    [pscustomobject]@{SecurityNameSpace='AnalyticsViews';SecurityIdSpace='d34d3680-dfe5-4cc6-a949-7d9c68f73cba'}
    [pscustomobject]@{SecurityNameSpace='Analytics';SecurityIdSpace='58450c49-b02d-465a-ab12-59ae512d6531'}
)

$Commands = @(
[pscustomobject]@{CommandType='General';CommandName='View project-level information'}
[pscustomobject]@{CommandType='General';CommandName='Edit project-level information'}
[pscustomobject]@{CommandType='General';CommandName='Delete team project'}
[pscustomobject]@{CommandType='General';CommandName='Rename team project'}
[pscustomobject]@{CommandType='General';CommandName='Manage project properties'}
[pscustomobject]@{CommandType='General';CommandName='Suppress notifications for work item updates'}
[pscustomobject]@{CommandType='General';CommandName='Update project visibility'}
[pscustomobject]@{CommandType='Test Plans';CommandName='Create test runs'}
[pscustomobject]@{CommandType='Test Plans';CommandName='Delete test runs'}
[pscustomobject]@{CommandType='Test Plans';CommandName='View test runs'}
[pscustomobject]@{CommandType='Test Plans';CommandName='Manage test environments'}
[pscustomobject]@{CommandType='Test Plans';CommandName='Manage test configurations'}
[pscustomobject]@{CommandType='Boards';CommandName='Delete and restore work items'}
[pscustomobject]@{CommandType='Boards';CommandName='Move work items out of this project'}
[pscustomobject]@{CommandType='Boards';CommandName='Permanently delete work items'}
[pscustomobject]@{CommandType='Boards';CommandName='Bypass rules on work item updates'}
[pscustomobject]@{CommandType='Boards';CommandName='Change process of team project.'}
[pscustomobject]@{CommandType='Boards';CommandName='Create tag definition'}
[pscustomobject]@{CommandType='Analytics';CommandName='Delete shared Analytics views'}
[pscustomobject]@{CommandType='Analytics';CommandName='Edit shared Analytics views'}
[pscustomobject]@{CommandType='Analytics';CommandName='View analytics'}
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
        foreach ($snsi in $SecurityNameSpaceIds)
        {
            switch ( $snsi.SecurityNameSpace )
            {
                'Project' { $Token = "`$PROJECT:vstfs:///Classification/TeamProject/$($allProjects.id)" }
                'Tagging' { $Token = "/$($allProjects.id)" }
                'AnalyticsViews' { $Token = "`$/Shared/$($allProjects.id)" }
                'Analytics' { $Token = "`$/$($allProjects.id)" }
            }
            $projectCommands = az devops security permission show --id $snsi.SecurityIdSpace --subject $activeUserGroups.$aug.descriptor --token $Token --org $Organization | ConvertFrom-Json
            $projectPermissions = ($projectCommands[0].acesDictionary | Get-Member -MemberType NoteProperty).Name
            foreach($pp in $projectCommands.acesDictionary.$projectPermissions.resolvedPermissions)
            {
                
                $validCommand =  $Commands | Where CommandName -EQ $pp.displayName
                if ($validCommand)
                {
                    $SQLQuery = "INSERT INTO ProjectLevelPermissions (
                                TeamProjectName,
                                SecurityNameSpace,
                                UserPrincipalName,
                                UserDisplayName,
                                GroupDisplayName,
                                GroupAccountName,
                                ProjectLevelType,
                                ProjectLevelCommandName,
                                ProjectLevelCommandInternalName,
                                ProjectLevelCommandPermission)
                                VALUES(
                                '$($allProjects.name)',
                                '$($snsi.SecurityNameSpace)',
                                '$($allUsers.principalName)',
                                '$($allUsers.displayName)',
                                '$($activeUserGroups.$aug.displayName)',
                                '$($activeUserGroups.$aug.principalName)',
                                '$($validCommand.CommandType)',
                                '$($pp.displayName.Replace("'",''))',
                                '$($pp.name)',
                                '$($pp.effectivePermission)'
                                )"
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                }
            }
        }
    }
}