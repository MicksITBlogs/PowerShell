<#
	.SYNOPSIS
		Deprovision Specified Windows 10 Apps
	
	.DESCRIPTION
		This script will add the appropriate registry keys to deprovision the built-in Windows 10 applications specified in the associated text file, or hardcoded in the script.
	
	.PARAMETER AppListFile
		File containing list of Windows 10 files to deprovision
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	9/15/2020 9:56 AM
		Created by:   	Mick Pletcher
		Filename:		Windows10AppDeprovisioning.ps1
		===========================================================================
#>

[CmdletBinding()]

param
(
	[string]$AppListFile
)

#Get list of Windows 10 Applications to uninstall from text file
$Applications = Get-Content -Path $AppListFile
#Deprovisioned Registry Key
$RegKey = 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Appx\AppxAllUserStore\Deprovisioned'
#Create deprovisioned registry key if it does not exist
If (!(Test-Path $RegKey)) {
	New-Item -Path $RegKey -Force | Out-Null
}
#Add list of Apps from the imported text file to the deprovisioned registry key
foreach ($App in $Applications) {
	#Install registry key if it does not exist
	If (!(Test-Path ($RegKey + '\' + $App))) {
		New-Item -Path ($RegKey + '\' + $App) -Force | Out-Null
	}
}
