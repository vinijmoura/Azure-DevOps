Param
(
    $AzureDevOpsAuthenicationHeader,
    $Organization,
    $db,
    $LogFile
)

$InstalledExtensions = New-Object 'Collections.Generic.List[pscustomobject]'
$table = $db.Tables["InstalledExtensions"]

$UriInstalledExtensions = "https://extmgmt.dev.azure.com/$($Organization)/_apis/extensionmanagement/installedextensions?api-version=6.0-preview.1"
$InstalledExtensionsResult = Invoke-RestMethod -Uri $UriInstalledExtensions -Method get -Headers $AzureDevOpsAuthenicationHeader

Foreach ($extension in $InstalledExtensionsResult.value)
{
    $extName = $($extension.extensionName).Replace("'","")
    $extPublisherName = $($extension.publisherName).Replace("'","")

    $installedExtensionsObject = [PSCustomObject] [ordered]@{
        ExtensionId=$($extension.extensionId)
        ExtensionName=$extName
        ExtensionPublisherName=$extPublisherName
        ExtensionVersion=$extension.version
        ExtensionLastPublished=$extension.lastPublished
    }
    $InstalledExtensions.Add($installedExtensionsObject)
}
if ($InstalledExtensions.Count -gt 0)
{
    Write-SqlTableData -InputData $InstalledExtensions -InputObject $table
    & .\LogFile.ps1 -LogFile $LogFile -Message "Inserting installed extensions to which organization $($Organization) belongs on table InstalledExtensions"
}