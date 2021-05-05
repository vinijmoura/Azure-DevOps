Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$mailAddress,
    [string]$Connstr
)


$SQLQuery = "TRUNCATE TABLE OrganizationLevelPermissions"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SecurityNameSpaceIds = @(
    [pscustomobject]@{SecurityNameSpace='AuditLog';SecurityIdSpace='a6cc6381-a1ca-4b36-b3c1-4e65211e82b6'} # /AllPermissions
    [pscustomobject]@{SecurityNameSpace='Collection';SecurityIdSpace='3e65f728-f8bc-4ecd-8764-7e378b19bfa7'} # NAMESPACE
    [pscustomobject]@{SecurityNameSpace='BuildAdministration';SecurityIdSpace='302acaca-b667-436d-a946-87133492041c'} # BuildPrivileges
    [pscustomobject]@{SecurityNameSpace='Project';SecurityIdSpace='52d39943-cb85-4d7f-8fa8-c6baac873819'} # $PROJECT
    [pscustomobject]@{SecurityNameSpace='VersionControlPrivileges';SecurityIdSpace='66312704-deb5-43f9-b51c-ab4ff5e351c3'} # Global
    [pscustomobject]@{SecurityNameSpace='Process';SecurityIdSpace='2dab47f9-bd70-49ed-9bd5-8eb051e59c02'} # $PROCESS
    [pscustomobject]@{SecurityNameSpace='Server';SecurityIdSpace='1f4179b3-6bac-4d01-b421-71ea09171400'} # FrameworkGlobalSecurity
)

$Commands = @(
[pscustomobject]@{CommandType='General';CommandName='Alter trace settings'}
[pscustomobject]@{CommandType='General';CommandName='Create new projects'}
[pscustomobject]@{CommandType='General';CommandName='Delete team project'}
[pscustomobject]@{CommandType='General';CommandName='Edit instance-level information'}
[pscustomobject]@{CommandType='General';CommandName='View instance-level information'}
[pscustomobject]@{CommandType='Service Account';CommandName='Make requests on behalf of others'}
[pscustomobject]@{CommandType='Service Account';CommandName='Trigger events'}
[pscustomobject]@{CommandType='Service Account';CommandName='View system synchronization information'}
[pscustomobject]@{CommandType='Boards';CommandName='Administer process permissions'}
[pscustomobject]@{CommandType='Boards';CommandName='Create process'}
[pscustomobject]@{CommandType='Boards';CommandName='Delete field from organization'}
[pscustomobject]@{CommandType='Boards';CommandName='Delete process'}
[pscustomobject]@{CommandType='Boards';CommandName='Edit process'}
[pscustomobject]@{CommandType='Repos';CommandName='Administer shelved changes'}
[pscustomobject]@{CommandType='Repos';CommandName='Administer workspaces'}
[pscustomobject]@{CommandType='Repos';CommandName='Create a workspace'}
[pscustomobject]@{CommandType='Pipelines';CommandName='Administer build resource permissions'}
[pscustomobject]@{CommandType='Pipelines';CommandName='Manage build resources'}
[pscustomobject]@{CommandType='Pipelines';CommandName='Manage pipeline policies'}
[pscustomobject]@{CommandType='Pipelines';CommandName='Use build resources'}
[pscustomobject]@{CommandType='Pipelines';CommandName='View build resources'}
[pscustomobject]@{CommandType='Test Plans';CommandName='Manage test controllers'}
[pscustomobject]@{CommandType='Auditing';CommandName='Delete audit streams'}
[pscustomobject]@{CommandType='Auditing';CommandName='Manage audit streams'}
[pscustomobject]@{CommandType='Auditing';CommandName='View audit log'}
[pscustomobject]@{CommandType='Policies';CommandName='Manage enterprise policies'}
)

echo $PAT | az devops login --org $Organization

az devops configure --defaults organization=$Organization

$allUsers = az devops user list --org $Organization | ConvertFrom-Json
$allUsers = $allUsers.members 
$allUsers = $allusers.user | where-object {$_.mailAddress -eq $mailAddress}

$activeUserGroups = az devops security group membership list --id $allUsers.principalName --org $Organization --relationship memberof | ConvertFrom-Json
[array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name
$groups = $groups | Where-Object {$activeUserGroups.$_.domain -like "vstfs:///Framework*"}

foreach ($aug in $groups)
{       
    foreach ($snsi in $SecurityNameSpaceIds)
    {
        switch ( $snsi.SecurityNameSpace )
        {
            'AuditLog' { $Token = "/AllPermissions" }
            'Collection' { $Token = "NAMESPACE" }
            'BuildAdministration' { $Token = "BuildPrivileges" }
            'Project' { $Token = "`$PROJECT" }
            'VersionControlPrivileges' { $Token = "Global"}
            'Process' { $Token = "`$PROCESS" }
            'Server' { $Token = "FrameworkGlobalSecurity" }
        }

        $organizationCommands = az devops security permission show --id $snsi.SecurityIdSpace --subject $activeUserGroups.$aug.descriptor --token $Token --org $Organization | ConvertFrom-Json
        $organizationPermissions = ($organizationCommands[0].acesDictionary | Get-Member -MemberType NoteProperty).Name
        foreach($op in $organizationCommands.acesDictionary.$organizationPermissions.resolvedPermissions)
        {
            $validCommand =  $Commands | Where CommandName -EQ $op.displayName
            if ($validCommand)
            {
                $SQLQuery = "INSERT INTO OrganizationLevelPermissions (
                            SecurityNameSpace,
                            UserPrincipalName,
                            UserDisplayName,
                            GroupDisplayName,
                            GroupAccountName,
                            OrganizationLevelType,
                            OrganizationLevelCommandName,
                            OrganizationLevelCommandInternalName,
                            OrganizationLevelCommandPermission)
                            VALUES(
                            '$($snsi.SecurityNameSpace)',
                            '$($allUsers.principalName)',
                            '$($allUsers.displayName)',
                            '$($activeUserGroups.$aug.displayName)',
                            '$($activeUserGroups.$aug.principalName)',
                            '$($validCommand.CommandType)',
                            '$($op.displayName.Replace("'",''))',
                            '$($op.name)',
                            '$($op.effectivePermission)'
                            )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }
} 