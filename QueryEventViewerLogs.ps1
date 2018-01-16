<#
	.SYNOPSIS
		Query Event Viewer Logs
	
	.DESCRIPTION
		This script will query the event viewer logs and write the computer name to a designated, centralized log file, thereby indicating the system met the query specifications.
	
	.PARAMETER LogFileLocation
		The network location of where the log file resides.
	
	.PARAMETER LogFileName
		The name of the centralized log file
	
	.PARAMETER EventLogName
		Name of the event viewer log
	
	.PARAMETER LogMessage
		The message to filter the log files for.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.119
		Created on:   	4/13/2016 1:54 PM
		Created by:   	Mick Pletcher
		Filename:     	OutlookLogs.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[string]$LogFileLocation,
		[string]$LogFileName,
		[string]$EventLogName,
		[string]$LogMessage
)

#Declare Variable
Set-Variable -Name Logs -Value $null -Scope Local -Force

cls
$ReportFile = $LogFileLocation + $LogFileName
$LogMessage = [char]42 + $LogMessage + [char]42
$Logs = Get-EventLog -LogName $EventLogName | where { $_.Message -like $LogMessage }
If ($Logs -ne $null) {
	$Logs
	Do {
		Try {
			$Written = $true
			Out-File -FilePath $ReportFile -InputObject $env:COMPUTERNAME -Append -Encoding UTF8 -ErrorAction SilentlyContinue
		} Catch {
			Start-Sleep -Seconds 1
			$Written = $false
		}
	} while ($Written -eq $false)
}
