<#
	.SYNOPSIS
		Mandatory Reboot
	
	.DESCRIPTION
		This script will read the last time a system rebooted from the event viewer logs. It then calculates the number of days since that time. If the number of days equals or exceeds the RebootThreshold variable, the script will change the registry key Rebooted to a 0. It then exits with an error code 3010, which tells SCCM 2012 to perform a soft reboot.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	6/8/2016 1:58 PM
		Created by:	Mick Pletcher
		Filename:	MandatoryReboot.ps1
		===========================================================================
#>

#Returns "32-bit" or "64-bit"
$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
$Architecture = $Architecture.OSArchitecture
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
#Number of days until reboot becomes mandatory
$RebootThreshold = 14
$Today = Get-Date
#Gets the last reboot from the event viewer logs
$LastReboot = get-winevent -filterhashtable @{ logname = 'system'; ID = 1074 } -maxevents 1 -ErrorAction SilentlyContinue
#Calculate how long since last reboot. If no event viewer entries since last reboot, then trigger a reboot
if ($LastReboot -eq $null) {
	$Difference = $RebootThreshold
} else {
	$Difference = New-TimeSpan -Start $Today -End $LastReboot.TimeCreated
	$Difference = [math]::Abs($Difference.Days)
}
#Change the HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot key to a 1 if the system is over the pre-determined threshold and $Rebooted = 0
if (($Difference -ge $RebootThreshold) -and ($Rebooted -eq 0)) {
	if ((Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot") -eq $true) {
		Set-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot" -Name Rebooted -Value 1 -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot"
	} else {
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot" -Name Rebooted -Value 1 -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot"
	}
}
$Rebooted = $Rebooted.Rebooted
#Change the HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot key back to 0 if the system has been rebooted within the $RebootThreshold period
if (($Difference -lt $RebootThreshold) -and ($Rebooted -eq 1)) {
	if ((Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot") -eq $true) {
		Set-ItemProperty -Name Rebooted -Value 0 -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot" -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Reboot"
	} else {
		Set-ItemProperty -Name Rebooted -Value 0 -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot" -Type DWORD -Force
		$Rebooted = Get-ItemProperty -Name Rebooted -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Reboot"
	}
	$Rebooted = $Rebooted.Rebooted
	Write-Host "System is within"$RebootThreshold" Day Reboot Threshold"
}
Write-Host "Reboot Threshold:"$RebootThreshold
Write-Host "Difference:"$Difference
Write-Host "Rebooted:"$Rebooted
Exit 3010