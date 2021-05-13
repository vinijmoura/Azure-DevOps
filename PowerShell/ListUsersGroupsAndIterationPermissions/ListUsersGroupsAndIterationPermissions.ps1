Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$ProjectName,
    [string]$mailAddress,
    [string]$Connstr
)

Function get-Identifier ($children,[ref]$AllIterationPaths)
{
    ForEach ( $ac in $children )
    {         
        $IterationNodes.Add((add-IterationMember -member $ac))
        $ac | get-Identifier -children $ac.children -IterationNodes ([ref]$AllIterationPaths)
    }
}

Function add-IterationMember ($member)
{
    $newMember = New-Object PSObject
    $newMember | Add-Member -MemberType NoteProperty -Name "Identifier" -Value $member.identifier
    $newMember | Add-Member -MemberType NoteProperty -Name "Path" -Value $member.path.Replace("\Iteration",'').Substring(1)   
    return $newMember
}

$SQLQuery = "TRUNCATE TABLE IterationPermissions"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$SecurityNameSpaceIdIteration = "bf7bfa03-b2b7-47db-8113-fa2e002cc5b1"

echo $PAT | az devops login --org $Organization

az devops configure --defaults organization=$Organization

#select user on organization
$allUsers = az devops user list --org $Organization | ConvertFrom-Json
$allUsers = $allUsers.members 
$allUsers = $allusers.user | where-object {$_.mailAddress -eq $mailAddress}

#select project
$allProjects = az devops project list --org $Organization --top 500 | ConvertFrom-Json
$allProjects = $allProjects.value | Where name -EQ $ProjectName
$Domain = "vstfs:///Classification/TeamProject/$($allProjects.id)"

#Get Root Iteration Path
$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$uriProjectRootIteration = $Organization + "/$($ProjectName)/_apis/wit/classificationnodes?api-version=6.0"
$ProjectRootIterationResult = Invoke-RestMethod -Uri $uriProjectRootIteration -Method get -Headers $AzureDevOpsAuthenicationHeader
$ProjectRootIterationResult = $ProjectRootIterationResult.value | Where structureType -EQ "iteration"
$iterationRootToken = "vstfs:///Classification/Node/$($ProjectRootIterationResult.identifier)*"

#Get All Iterations Path
$uriIterationPath = $Organization + "/$($ProjectName)/_apis/wit/classificationnodes/Iterations?`$depth=5&api-version=4.1"
$IterationPathResult = Invoke-RestMethod -Uri $uriIterationPath -Method get -Headers $AzureDevOpsAuthenicationHeader
$IterationNodes = New-Object 'System.Collections.Generic.List[psobject]'
$IterationNodes.Add((add-IterationMember -member $IterationPathResult))
$IterationPathResult | get-Identifier -children $IterationPathResult.children -IterationNodes ([ref]$IterationNodes)

#Get all group that respective user belongs
$activeUserGroups = az devops security group membership list --id $allUsers.principalName --org $Organization --relationship memberof | ConvertFrom-Json
[array]$groups = ($activeUserGroups | Get-Member -MemberType NoteProperty).Name

Foreach ($aug in $groups)
{       
    if ($Domain -eq $activeUserGroups.$aug.domain)
    {
        #Get All Tokens from respective group and filter respective project
        $allIterationsTokens = az devops security permission list --id $SecurityNameSpaceIdIteration --subject $activeUserGroups.$aug.descriptor | ConvertFrom-Json
        $allIterationsTokens = $allIterationsTokens | where-object {$_.token -like $iterationRootToken}
        Foreach ($ait in $allIterationsTokens)
        {
            $IterationPathName = $IterationNodes | Where-Object {$_.identifier -EQ $ait.token.Substring($ait.token.lastIndexOf('/') + 1)}

            #Get Iteration Path Commands and Permissions from respective group and token
            $IterationCommands = az devops security permission show --id $SecurityNameSpaceIdIteration --subject $activeUserGroups.$aug.descriptor --token $ait.token --org $Organization | ConvertFrom-Json
            $IterationPermissions = ($IterationCommands[0].acesDictionary | Get-Member -MemberType NoteProperty).Name
            foreach($ip in $IterationCommands.acesDictionary.$IterationPermissions.resolvedPermissions)
            {               
                $SQLQuery = "INSERT INTO IterationPermissions (
                            TeamProjectName,
                            IterationPathName,
                            SecurityNameSpace,
                            UserPrincipalName,
                            UserDisplayName,
                            GroupDisplayName,
                            GroupAccountName,
                            IterationCommandName,
                            IterationCommandInternalName,
                            IterationCommandPermission)
                            VALUES(
                            '$($allProjects.name)',
                            '$($IterationPathName.path)',
                            'Iteration',
                            '$($allUsers.principalName)',
                            '$($allUsers.displayName)',
                            '$($activeUserGroups.$aug.displayName)',
                            '$($activeUserGroups.$aug.principalName)',
                            '$($ip.displayName.Replace("'",''))',
                            '$($ip.name)',
                            '$($ip.effectivePermission)'
                            )"
                Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
            }
        }
    }
}
