﻿<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.207
	 Created on:   	6/29/2022 10:59 AM
	 Created by:   	Mick Pletcher
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

#Install Dell BIOS Provider PowerShell Module
Try {
	Import-Module -Name DellBIOSProvider
}
Catch {
	Find-Module -Name DellBIOSProvider | Install-Module -Force
	Import-Module -Name DellBIOSProvider
}
#Enable SMART Reporting
Write-Host "SMART Reporting....." -NoNewline
If ((Get-Item -Path DellSmbios:\SecureBoot\SecureBoot).CurrentValue -ne "Enabled") {
	Set-Item -Path DellSMBIOS:\SecureBoot\SecureBoot Enabled
}
If ((Get-Item -Path DellSmbios:\SecureBoot\SecureBoot).CurrentValue -eq "Enabled") {
	Write-Host "Enabled" -ForegroundColor Yellow
}
else {
	Write-Host "Disabled" -ForegroundColor Red
}
