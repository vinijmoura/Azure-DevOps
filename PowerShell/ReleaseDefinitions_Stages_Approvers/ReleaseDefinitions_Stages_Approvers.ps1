Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ReleaseDefinitionsClassic"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

echo $PAT | az devops login --org $Organization

az devops configure --defaults organization=$Organization
$ProjectsResult = az devops project list --org $Organization | ConvertFrom-Json

Foreach ($project in $ProjectsResult.value)
{
    $ReleaseDefinitionResult = az pipelines release definition list --org $Organization --project $project.name | ConvertFrom-Json
    Foreach ($releaseDef in $ReleaseDefinitionResult)
    {
        $releaseDefId = az pipelines release definition show --org $Organization --project $project.name --id $releaseDef.id | ConvertFrom-Json
        Foreach ($envRelease in $releaseDefId.environments)
        {
            $preDeployApprovalsName = ''
            $postDeployApprovalsName = ''
            Foreach ($preDeployApprovals in $envRelease.preDeployApprovals.approvals)
            {
                if ($preDeployApprovals.approver.displayName)
                {
                    $preDeployApprovalsName += $preDeployApprovals.approver.displayName + ','
                }
                else
                {
                    $preDeployApprovalsName = 'No Approvals,'
                }
            }
            
            
            Foreach ($postDeployApprovals in $envRelease.postDeployApprovals.approvals)
            {
                if ($postDeployApprovals.approver.displayName)
                {
                    $postDeployApprovalsName += $postDeployApprovals.approver.displayName + ','
                }
                else
                {
                    $postDeployApprovalsName = 'No Approvals,'
                }
            }
            $SQLQuery = "INSERT INTO ReleaseDefinitionsClassic (
                         TeamProjectId,
                         TeamProjectName,
                         ReleaseDefinitionId,
                         ReleaseDefintionName,
                         ReleaseDefinitionURL,
                         ReleaseDefintionEnvironmentName,
                         ReleaseDefinitionEnvironmentRank,
                         ReleaseDefinitionEnvironmentPreDeployApprovalsName,
                         ReleaseDefinitionEnvironmentPostDeployApprovalsName)
                         VALUES(
                         '$($project.id)',
                         '$($project.name)',
                         $($releaseDef.id),
                         '$($releaseDef.name)',
                         '$($Organization)/$($project.name)/_releaseDefinition?definitionId=$($releaseDef.id)&_a=environments-editor-preview',
                         '$($envRelease.name)',
                         $($envRelease.rank),
                         '$($preDeployApprovalsName.Substring(0,$preDeployApprovalsName.Length-1))',
                         '$($postDeployApprovalsName.Substring(0,$postDeployApprovalsName.Length-1))'
                         )"
            Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
        }
    }
}

