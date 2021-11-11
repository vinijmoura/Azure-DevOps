Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE ProcessesWorkItemsRules"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/" 

$uriProcess = $UriOrganization + "_apis/work/processes/"
$processesResult = Invoke-RestMethod -Uri $uriProcess -Method get -Headers $AzureDevOpsAuthenicationHeader
$inheritedProcess = $processesResult.value | Where-Object {$_.customizationType -eq 'inherited'}
if ($inheritedProcess.Count -gt 0)
{
    Foreach ($process in $inheritedProcess)
    {
        $uriWorkItemTypes = $uriProcess + "$($process.typeId)/workitemtypes/"
        $workItemTypesResult = Invoke-RestMethod -Uri $uriWorkItemTypes -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($wit in $workItemTypesResult.value)
        {
            $uriRules = $uriWorkItemTypes + "$($wit.referenceName)/rules?api-version=6.0-preview.2"
            $rulesResult = Invoke-RestMethod -Uri $uriRules -Method get -Headers $AzureDevOpsAuthenicationHeader
            $customRules = $rulesResult.value | Where-Object {$_.customizationType -eq 'custom'}
            if ($customRules)
            {
                $allConditionsTypes = ''
                $allConditionsFields = ''
                $allConditionsValues = ''

                $allActionsTypes = ''
                $allActionsTargetFields = ''
                $allActionsValues = ''

                Foreach ($rule in $customRules)
                {
                    Foreach ($condition in $rule.conditions)
                    {
                        $allConditionsTypes += $condition.conditionType + "`r`n"
                        $allConditionsFields += $condition.field + "`r`n"
                        $allConditionsValues += $condition.value + "`r`n"
                    }

                    Foreach ($action in $rule.actions)
                    {
                        $allActionsTypes += $action.actionType + "`r`n"
                        $allActionsTargetFields += $action.targetField + "`r`n"
                        $allActionsValues += $action.value + "`r`n"
                    }

                    $SQLQuery = "INSERT INTO ProcessesWorkItemsRules (
                                ProcessName,
                                ProcessWorkItemTypeName,
                                ProcessWorkItemTypeRuleName,
                                ProcessWorkItemTypeRuleConditionsTypes,
	                            ProcessWorkItemTypeRuleConditionsFields,
	                            ProcessWorkItemTypeRuleConditionsValues,
	                            ProcessWorkItemTypeRuleActionsTypes,
	                            ProcessWorkItemTypeRuleActionsTargetFields,
	                            ProcessWorkItemTypeRuleActionsValues
                                )
                                VALUES(
                                '$($process.name)',
                                '$($wit.name)',
                                '$($rule.name)',
                                '$($allConditionsTypes)',
                                '$($allConditionsFields)',
                                '$($allConditionsValues)',
                                '$($allActionsTypes)',
                                '$($allActionsTargetFields)',
                                '$($allActionsValues)'
                                )"
                    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
                }
            }
        }
    }
}