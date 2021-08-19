Param
(
    [string]$PAT,
    [string]$Organization,
    [string]$Connstr
)

$SQLQuery = "TRUNCATE TABLE InstalledExtensions"
Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr

$AzureDevOpsAuthenicationHeader = @{Authorization = 'Basic ' + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($PAT)")) }
$UriInstalledExtensions = "https://extmgmt.dev.azure.com/$($Organization)/_apis/extensionmanagement/installedextensions?api-version=6.0-preview.1"
$InstalledExtensionsResult = Invoke-RestMethod -Uri $UriInstalledExtensions -Method get -Headers $AzureDevOpsAuthenicationHeader

Foreach ($extension in $InstalledExtensionsResult.value)
{
    $extName = $($extension.extensionName).Replace("'","")
    $extPublisherName = $($extension.publisherName).Replace("'","")

    $SQLQuery = "INSERT INTO InstalledExtensions (
                                ExtensionId,
                                ExtensionName,
                                ExtensionPublisherName,
                                ExtensionVersion,
                                ExtensionLastPublished
                                )
                                VALUES(
                                '$($extension.extensionId)',
                                '$($extName)',
                                '$($extPublisherName)',
                                '$($extension.version)',
                                CONVERT(DATETIME,SUBSTRING('$($extension.lastPublished)',1,19),127)
                                )"
    Invoke-Sqlcmd -query $SQLQuery -ConnectionString $Connstr
}

            
