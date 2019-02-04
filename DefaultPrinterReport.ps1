<#
	.SYNOPSIS
		Default Printer Report
	
	.DESCRIPTION
		This script will retrieve a list of all user profiles and report to a text file inside each user profile what the default printer is. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	2/4/2019 8:56 AM
		Created by:   	Mick Pletcher
		Filename:		DefaultPrinterReport.ps1
		===========================================================================
#>

[CmdletBinding()]
param ()

$Profiles = (Get-ChildItem -Path REGISTRY::HKEY_USERS -Exclude *Classes | Where-Object {$_.Name -like '*S-1-5-21*'}).Name
$ProfileArray = @()
foreach ($Item in $Profiles) {
	$object = New-Object -TypeName System.Management.Automation.PSObject
	$object | Add-Member -MemberType NoteProperty -Name Profile -Value ((Get-ItemProperty -Path ('REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\' + ($Item.split('\')[1].Trim())) -Name ProfileImagePath).ProfileImagePath).Split('\')[2]
	$object | Add-Member -MemberType NoteProperty -Name DefaultPrinter -Value ((Get-ItemProperty -Path ('REGISTRY::' + $Item + '\Software\Microsoft\Windows NT\CurrentVersion\Windows') -Name Device).Device).Split(',')[0]
	$ProfileArray += $object
}
$ProfileArray
($env:SystemDrive + '\users\' + $Item.Profile + '\DefaultPrinter.csv')
foreach ($Item in $ProfileArray) {
	Export-Csv -InputObject $Item -Path ($env:SystemDrive + '\users\' + $Item.Profile + '\DefaultPrinter.csv') -NoTypeInformation -Force
}
