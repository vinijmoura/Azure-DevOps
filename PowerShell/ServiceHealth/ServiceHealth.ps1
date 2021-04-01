$UriHealthStatus = 'https://status.dev.azure.com/_apis/status/health?api-version=6.1-preview.1'
$HealthStatusResult = Invoke-RestMethod -Uri $UriHealthStatus -Method get

$HealthStatus = @()

Foreach ($healtstatus in $HealthStatusResult.services)
{
    Foreach ($geography in $healtstatus.geographies)
    {
        $HealthStatus += New-Object -TypeName PSObject -Property @{
            Service=$healtstatus.id
            RegionServiceHealth=$geography.health
            RegionServiceId=$geography.id
            RegionServiceName=$geography.name
        }
    }
}

$HealthStatus | ConvertTo-Json | Out-File -FilePath "$home\desktop\HealthStatus.json"