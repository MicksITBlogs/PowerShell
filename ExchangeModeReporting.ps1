<#
	.SYNOPSIS
		Exchange Cached Mode Reporting
	
	.DESCRIPTION
		This script will read the RPC client access logs from the exchange server and generate a report showing if a user is cached or classic mode. You will need to retrieve the RPC logs from each exchange server. To do so, go to the drive on the exchange server that has exchange installed. The following directory contains the log you will need. Delete the Log Text, #Software, #Version, #Log-type, #Date, and #Fields lines from the file. That leaves the raw data. You can merge all of the logs into one file. This script will filter out repetitive entries. 
	
	.PARAMETER LogFile
		Name of the log file that contains the exchange RPC logs
	
	.PARAMETER Cached
		Generate report of systems in cached mode
	
	.PARAMETER Online
		Generate report of all systems in online mode
	
	.PARAMETER Full
		Generate report showing both cached and online users
	
	.PARAMETER OutputFile
		Name of the file to write the output to. If left blank, no file is written to.
	
	.EXAMPLE
		Generate a list of all machines in cached mode
			powershell.exe -file ExchangeModeReporting.ps1 -Cached -LogFile "Exchange.LOG"

		Generate a list of all machines in cached mode and export list to a .CSV
			powershell.exe -file ExchangeModeReporting.ps1 -Cached -LogFile "Exchange.LOG" -OutputFile "Report.csv"

		Generate a list of all machines in Online mode
			powershell.exe -file ExchangeModeReporting.ps1 -Online -LogFile "Exchange.LOG"

		Generate a list of all machines in either cached or online mode
			powershell.exe -file ExchangeModeReporting.ps1 -Full -LogFile "Exchange.LOG"

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.128
		Created on:   	10/4/2016 10:13 AM
		Created by:		Mick Pletcher
		Organization:
		Filename:		ExchangeModeReporting.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]
	$LogFile,
	[switch]
	$Cached,
	[switch]
	$Online,
	[switch]
	$Full,
	[string]
	$OutputFile
)

function Get-RelativePath {
<#
	.SYNOPSIS
		Get the relative path
	
	.DESCRIPTION
		Returns the location of the currently running PowerShell script
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Get-AccountInfo {
<#
	.SYNOPSIS
		Retrieve and format account infomation
	
	.DESCRIPTION
		This function will read the exchange log and extract the username and mailbox status, while putting the data into an object.
	
	.EXAMPLE
		PS C:\> Get-AccountInfo
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([array])]
	param ()
	
	$RelativePath = Get-RelativePath
	$Logs = Get-Content $RelativePath$LogFile
	$Systems = @()
	foreach ($Log in $Logs) {
		$System = New-Object System.Management.Automation.PSObject
		$SplitLog = $Log.split(",")
		$Username = ((($SplitLog | Where-Object { $_ -like "*cn=*" }).split("/") | Where-Object { ($_ -like "*cn=*") -and ($_ -notcontains "cn=Recipients") }).split("="))[1]
		$Mode = $SplitLog | Where-Object { ($_ -contains "Classic") -or ($_ -contains "Cached") }
		If ($Mode -eq "Classic") {
			$Mode = "Online"
		}
		$System | Add-Member -type NoteProperty -Name Username -Value $Username
		$System | Add-Member -type NoteProperty -Name Mode -Value $Mode
		If ($Systems.Username -notcontains $Username) {
			$Systems += $System
		}
	}
	$Systems = $Systems | Sort-Object
	Return $Systems
}

$Logs = Get-AccountInfo
if ($Cached.IsPresent) {
	$Logs = $Logs | Where-Object { $_.Mode -eq "Cached" } | Sort-Object Username
	$Logs | Format-Table
}
if ($Online.IsPresent) {
	$Logs = $Logs | Where-Object { ($_.Mode -eq "Online") } | Sort-Object Username
	$Logs | Format-Table
}
if ($Full.IsPresent) {
	$Logs | Sort-Object Username
}
if (($OutputFile -ne $null) -and ($OutputFile -ne "")) {
	$RelativePath = Get-RelativePath
	$Logs | Sort-Object Username | Export-Csv $RelativePath$OutputFile -NoTypeInformation
}