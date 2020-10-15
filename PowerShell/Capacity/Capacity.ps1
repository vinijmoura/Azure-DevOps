Param
(
    [string]$PAT,
    [string]$Organization
)

$Capacities = @()

enum DayTypes {
    WorkDay = 0
    IndividualDayOff = 1
    TeamDayOff = 2
}

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriOrganization = "https://dev.azure.com/$($Organization)/"

$uriProject = $UriOrganization + "_apis/projects/"
$ProjectsResult = Invoke-RestMethod -Uri $uriProject -Method get -Headers $AzureDevOpsAuthenicationHeader
Foreach ($project in $ProjectsResult.value)
{
    $uriTeams = $UriOrganization + "_apis/projects/$($project.id)/teams"
    $TeamsResult = Invoke-RestMethod -Uri $uriTeams -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($team in $TeamsResult.value)
    {
        $uriSprintsTeam = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/teamsettings/iterations"
        $SprintsTeamResult = Invoke-RestMethod -Uri $uriSprintsTeam -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($sprintteam in $SprintsTeamResult.value)
        {
            $uriWorkingDaysTeam = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/teamsettings"
            $WorkingDaysTeamResult = Invoke-RestMethod -Uri $uriWorkingDaysTeam -Method get -Headers $AzureDevOpsAuthenicationHeader
            $workingDays = new-object 'Collections.Generic.List[System.String]'
            Foreach ($workingDay in $WorkingDaysTeamResult.workingDays)
            {
                $workingDays += $workingDay.ToUpper()
            }
            
            if ($sprintteam.attributes.startDate)
            {
                
                $startDate = ((Get-date $($sprintteam.attributes.startDate).ToString()).ToUniversalTime())
                $finishDate = ((Get-date $($sprintteam.attributes.finishDate).ToString()).ToUniversalTime())

                $uriTeamdaysoff =  $UriOrganization + "$($project.id)/$($team.id)/_apis/work/teamsettings/iterations/$($sprintteam.id)/teamdaysoff"
                $TeamdaysoffResult = Invoke-RestMethod -Uri $uriTeamdaysoff -Method get -Headers $AzureDevOpsAuthenicationHeader

                $teamdaysoff = new-object 'Collections.Generic.List[DateTime]'
                Foreach ($tdo in $TeamdaysoffResult.daysOff)
                {
                    [DateTime] $startdateteam = ((Get-date $($tdo.start).ToString()).ToUniversalTime())
                    [DateTime] $enddateteam = ((Get-date $($tdo.end).ToString()).ToUniversalTime())
                    while ($startdateteam -le $enddateteam)
                    {
                        $teamdaysoff.Add($startdateteam)
                        $startdateteam = $startdateteam.AddDays(1).ToUniversalTime()
                    }
                }

                $uriCapacities = $UriOrganization + "$($project.id)/$($team.id)/_apis/work/teamsettings/iterations/$($sprintteam.id)/capacities"
                $CapacitiesResult = Invoke-RestMethod -Uri $uriCapacities -Method get -Headers $AzureDevOpsAuthenicationHeader
                Foreach ($capacity in $CapacitiesResult.value)
                {
                    $individualdaysoff = new-object 'Collections.Generic.List[DateTime]'
                    Foreach ($ido in $capacity.daysOff)
                    {
                        [DateTime] $startdateindividual = ((Get-date $($ido.start).ToString()).ToUniversalTime())
                        [DateTime] $enddateindividual = ((Get-date $($ido.end).ToString()).ToUniversalTime())
                        while ($startdateindividual -le $enddateindividual)
                        {
                            $individualdaysoff.Add($startdateindividual)
                            $startdateindividual = $startdateindividual.AddDays(1).ToUniversalTime()
                        }
                    }
                    Foreach($activity in $capacity.activities)
                    {
                        if ($activity.capacityPerDay -gt 0)
                        {
                            $i=0
                            $WorkDate = $startDate
                            while ($WorkDate -le $finishDate)
                            {
                                $WorkDate = $startDate.AddDays($i)

                                if ($workingDays -contains $WorkDate.DayOfWeek.ToString().ToUpper())
                                {
                                    $DayType = [DayTypes]::WorkDay.ToString()
                                    if ($teamdaysoff -contains $WorkDate)
                                    {
                                        $DayType = [DayTypes]::TeamDayOff.ToString()
                                    }
                                    elseif ($individualdaysoff -contains $WorkDate)
                                    {
                                        $DayType = [DayTypes]::IndividualDayOff.ToString()
                                    }
                                    $Capacities += New-Object -TypeName PSObject -Property @{
                                        ProjectName=$project.name
                                        TeamName=$team.name
                                        SprintName=$sprintteam.name
                                        SprintStartDate="{0:yyyy-MM-dd}"-f $startDate
                                        SprintFinishDate="{0:yyyy-MM-dd}"-f $finishDate
                                        UserName=$capacity.teamMember.displayName
                                        UserNameActivity=$activity.name
                                        UserNameHour=$activity.capacityPerDay
                                        DayType = $DayType
                                        WorkDate = "{0:yyyy-MM-dd}"-f ((Get-date $($WorkDate).ToString()).ToUniversalTime())
                                    }
                                }
                                $i++
                            }
                        }
                    }
                }
            }
        }
    }
}

$Capacities | ConvertTo-Json | Out-File -FilePath "$home\desktop\Capacities.json"