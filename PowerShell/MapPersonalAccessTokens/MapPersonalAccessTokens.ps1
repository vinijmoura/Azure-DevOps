[CmdletBinding()]
Param
(
    [Parameter(ParameterSetName = "Normal")]
    [Parameter(ParameterSetName = "ActiveDirectory")]
    [string]$PAT,
    [Parameter(ParameterSetName = "Normal")]
    [Parameter(ParameterSetName = "ActiveDirectory")]
    [string]$Organization,
    [Parameter(ParameterSetName = "Normal")]
    [Parameter(ParameterSetName = "ActiveDirectory")]
    [string]$Connstr,
    [Parameter(ParameterSetName = "ActiveDirectory")]
    [string]$ADDomainName,
    [Parameter(ParameterSetName = "ActiveDirectory")]
    [string]$ADAccountName
)

$SQLQuery = "TRUNCATE TABLE PersonalAccessTokens"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

switch ($PsCmdlet.ParameterSetName) {
    "ActiveDirectory" {
        # Token pattern for an Azure Active Directory authenticated project is [AccountName]@[ADDomainName]:[PAT]. Ex: john.doe@company.com:12345ABCDEBlahToken
        $AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($ADAccountName)@$($ADDomainName):$($PAT)")) }
    }
    "Normal" {
        # Token pattern for a non-Azure Active Directory authenticated project is [PAT]. Ex: 12345ABCDEBlahToken
        $AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
    }
}

$UriUsers = "https://vssps.dev.azure.com/$($Organization)/_apis/graph/users?api-version=6.1-preview.1"
$UsersResult = Invoke-RestMethod -Uri $UriUsers -Method get -Headers $AzureDevOpsAuthenicationHeader

Foreach ($user in $UsersResult.value)
{
    $UriUserPAT = "https://vssps.dev.azure.com/$($Organization)/_apis/tokenadmin/personalaccesstokens/$($user.descriptor)?api-version=6.1-preview.1"
    $UserPATResult = Invoke-RestMethod -Uri $UriUserPAT -Method get -Headers $AzureDevOpsAuthenicationHeader
    Foreach ($up in $UserPATResult.value)
    {
        if ($up.scope -eq 'app_token')
        {
            $accessToken = 'Full access'
        }
        else
        {
            $accessToken = $up.scope.Replace(" ","`r`n")
        }
        $SQLQuery = "INSERT INTO PersonalAccessTokens (
                                 UserDisplayName,
                                 UserMailAddress,
                                 PATDisplayName,
                                 PATValidFrom,
                                 PATValidTo,
                                 PATScope
                                 )
                                 VALUES(
                                 '$($user.displayName)',
                                 '$($user.mailAddress)',
                                 '$($up.displayName)',
                                 '$($up.validFrom)',
                                 '$($up.validTo)',
                                 '$($accessToken)'
                                 )"
        Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
    }
}