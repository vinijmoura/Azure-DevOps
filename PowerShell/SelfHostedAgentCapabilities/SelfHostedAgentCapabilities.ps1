#Param
#(
#    [string]$PAT,
#    [string]$Organization
#)

$PAT = 'ldjud4acfkbnil67g77patcbrpdgym7wvbiqnjm4euhutzpwcmga'
$Organization = 'vstssprints'

$SelfHostedAgentCapabilities = @()

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }

$UriOrganization = "https://dev.azure.com/$($Organization)/"
$UriPools = $UriOrganization + '/_apis/distributedtask/pools?api-version=6.0'

$PoolsResult = Invoke-RestMethod -Uri $UriPools -Method get -Headers $AzureDevOpsAuthenicationHeader | where {$_.agentCloudId -ne 1}

Foreach ($pool in $PoolsResult.value)
{
    $uriAgents = $UriOrganization + "_apis/distributedtask/pools/$($pool.Id)/agents?api-version=6.0"
    $AgentsResults = Invoke-RestMethod -Uri $uriAgents -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($agent in $AgentsResults.value)
    {
        $uriSelfHostedAgentCapabilities = $UriOrganization + "_apis/distributedtask/pools/$($pool.Id)/agents/$($agent.Id)?includeCapabilities=true&api-version=6.0"
        $SelfHostedAgentCapabilitiesResult = Invoke-RestMethod -Uri $uriSelfHostedAgentCapabilities -Method get -Headers $AzureDevOpsAuthenicationHeader
        Foreach ($shac in $SelfHostedAgentCapabilitiesResult)
        {
            $Capabilities = $shac.systemCapabilities | Get-Member | where {$_.MemberType -eq 'NoteProperty'}
            Foreach ($cap in $Capabilities)
            {
                $SelfHostedAgentCapabilities += New-Object -TypeName PSObject -Property @{
                    PoolName=$pool.name
                    AgentName=$agent.name
                    CapabilityName=$cap.Name
                    CapabilityValue=$($shac.systemCapabilities.$($cap.Name))
                }
            }
        }
    }
}

$SelfHostedAgentCapabilities | ConvertTo-Json | Out-File -FilePath "$home\desktop\SelfHostedAgentCapabilities.json"