Param
(
    [string]$LogFile,
    [string]$Message
)

#$repeat = '=' * 100
#Add-content -Path $LogFile -Value $repeat
$TimeStamp = (Get-Date).toString("dd/MM/yyyy HH:mm:ss:fff tt")
$Line = "$TimeStamp - $Message"
Add-content -Path $LogFile -Value $Line
#Add-content -Path $LogFile -Value $repeat