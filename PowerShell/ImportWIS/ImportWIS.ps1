Param
(
    [string]$PAT,
    [string]$Organization
)
#connect Azure DevOps
echo $PAT | az devops login --org $Organization
az devops configure --defaults organization=$Organization
#Read File
$data = Import-Csv -Delimiter '|' -Path "$home\desktop\wis.txt" -Header 'WorkItemType','Title','TeamProject','Area','Iteration'

#insert Work Item
$data | foreach { az boards work-item create --title $_.Title --type $_.WorkItemType --project $_.TeamProject --area $_.Area --iteration $_.Iteration }


