# Prerequisites:
# 1. Install the Azure CLI (https://aka.ms/install-azure-cli). You must have at least v2.0.49, which you can verify with az --version command.
# 2. Add the Azure DevOps Extension az extension add --name azure-devops
# 3. Run the az login command first, then there is no need for a PAT
# 4. Set parameters in this script and run

Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Project,
    [string]$TeamName,
    [DateTime]$StartDate,
    [int]$CurrentSprint,
    [int]$NumberOfSprints,
    [int]$SprintFrequency,
    [int]$SprintLength
)

# Example parameters
$Organization = 'https://dev.azure.com/ORGANIZATION/'
$Project = 'PROJECT'
$TeamName = 'TEAM'
# set start date for first new sprint
$StartDate = [DateTime]::Parse('21-5-2021') #or: [DateTime]'5/21/2021' (PS uses US format)
# set last sprint already available in DevOps
$CurrentSprint = 10 
# set number of sprints to add
$NumberOfSprints = 20
# set frequency (number of days)
$SprintFrequency = 14
# set length of sprint (number of days)
$SprintLength = 13

# no longer required if already signed in with 'az login': https://docs.microsoft.com/nl-nl/azure/devops/cli/log-in-via-pat?view=azure-devops&tabs=windows
#echo $PAT | az devops login --org $Organization

Write-Host '===Configuring connection to organization and Team Project'
az devops configure --defaults organization=$Organization project=$Project

For ($i=1; $i -le $NumberOfSprints; $i++) 
{
    $Sprint = 'Sprint ' + ($CurrentSprint + $i)
    $StartDateIteration = $StartDate.AddDays(($i - 1) * $SprintFrequency)
    $FinishDateIteration = $StartDateIteration.AddDays($SprintLength)
    $createIteration = az boards iteration project create --name $Sprint --start-date $StartDateIteration --finish-date $FinishDateIteration --org $Organization --project $Project | ConvertFrom-Json
    $addIteration = az boards iteration team add --id $createIteration.Identifier --team $TeamName --org $Organization --project $Project | ConvertFrom-Json
    Write-Host $addIteration.name 'created on path'$addIteration.path
}
