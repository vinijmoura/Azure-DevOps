Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Project,
    [string]$TeamName,
    [DateTime]$StartDate,
    [int]$NumberOfSprints
)

echo $PAT | az devops login --org $Organization

Write-Host '===Configuring connection to organization and Team Project'
az devops configure --defaults organization=$Organization project=$Project

For ($i=1; $i -le $NumberOfSprints; $i++) 
{
    $Sprint = 'Sprint ' + $i
    $StartDateIteration = $StartDate.AddDays(($i - 1) * 14)
    $FinishDateIteration = $StartDateIteration.AddDays(11)
    $createIteration = az boards iteration project create --name $Sprint --start-date $StartDateIteration --finish-date $FinishDateIteration --org $Organization --project $Project | ConvertFrom-Json
    $addIteration = az boards iteration team add --id $createIteration.Identifier --team $TeamName --org $Organization --project $Project | ConvertFrom-Json
    Write-Host $addIteration.name 'created on path'$addIteration.path
}