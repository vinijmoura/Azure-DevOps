Param
(
    [string]$LogFile,
    [string]$Message
)
$TimeStamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss:fff tt")
$Line = "$TimeStamp - $Message"
Add-content -Path $LogFile -Value $Line