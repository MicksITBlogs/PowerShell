<#
	.SYNOPSIS
		Mandatory Reboot Custom Detection Method
	
	.DESCRIPTION
		This script will read the last time a system rebooted from the event viewer logs. It then calculates the number of days since that time. If the number of days equals or exceeds the RebootThreshold variable, the script will exit with a return code 0 and no data output. No data output is read by SCCM as a failure. If the number of days is less than the RebootThreshold, then a message is written saying the system is within the threshold and the script exits with a return code of 0. SCCM reads an error code 0 with data output as a success.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	6/8/2016 2:04 PM
		Created by:	Mick Pletcher
		Filename:	MandatoryRebootCustomDetection.ps1
		===========================================================================
#>

#Number of days until reboot becomes mandatory
$RebootThreshold = 14
$Today = Get-Date
#Returns "32-bit" or "64-bit"
$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
$Architecture = $Architecture.OSArchitecture
#Gets the last reboot from the event viewer logs
$LastReboot = get-winevent -filterhashtable @{ logname = 'system'; ID = 1074 } -maxevents 1 -ErrorAction SilentlyContinue
#Tests if the registry key Rebooted exists and creates it if it does not. It then reads if the system has been rebooted by the value being either a 0 or 1. This determines if the reboot has occurred and is set in the MandatoryReboot.ps1 file when the custom detection method triggers its execution
if ($Architecture -eq "32-bit") {
	if ((Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot") -eq $false) {
		New-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot" | New-ItemProperty -Name Rebooted -Value 0 -Force | Out-Null
	}
	$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot"
} else {
	if ((Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot") -eq $false) {
		New-Item "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot" | New-ItemProperty -Name Rebooted -Value 0 -Force | Out-Null
	}
	$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot"
}
#Get the 0 or 1 value if a system has been rebooted within the $RebootThreshold period
$Rebooted = $Rebooted.Rebooted
#Calculate how long since last reboot. If no event viewer entries since last reboot, then trigger a reboot
if ($LastReboot -eq $null) {
	$Difference = $RebootThreshold
} else {
	$Difference = New-TimeSpan -Start $Today -End $LastReboot.TimeCreated
	$Difference = [math]::Abs($Difference.Days)
}
#The first two conditions report to SCCM that the deployment is "installed" thereby not triggering a reboot. The last two report to SCCM the app is "not installed" and trigger an install
if (($Difference -lt $RebootThreshold) -and ($Rebooted -eq 0)) {
	Write-Host "Success"
	exit 0
}
if (($Difference -ge $RebootThreshold) -and ($Rebooted -eq 1)) {
	Write-Host "Success"
	exit 0
}
if (($Difference -ge $RebootThreshold) -and ($Rebooted -eq 0)) {
	exit 0
}
if (($Difference -lt $RebootThreshold) -and ($Rebooted -eq 1)) {
	exit 0
}
