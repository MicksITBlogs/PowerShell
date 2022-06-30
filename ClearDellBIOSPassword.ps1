<#
	.SYNOPSIS
		Clear Dell BIOS Password
	
	.DESCRIPTION
		Clear the BIOS Password
	
	.PARAMETER Password
		BIOS Password
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.207
		Created on:   	6/29/2022 8:24 AM
		Created by:   	Mick Pletcher
		Filename:     	ClearBIOSPassword.ps1
		===========================================================================
#>
param
(
	[ValidateNotNullOrEmpty()]
	[string]$Password
)
#Install Dell BIOS Provider PowerShell Module
Try {
	Import-Module -Name DellBIOSProvider
} Catch {
	Find-Module -Name DellBIOSProvider | Install-Module -Force
	Import-Module -Name DellBIOSProvider
}
#Clear BIOS Password if set
Write-Host "Clearing BIOS Password....." -NoNewline
If ((Get-Item -Path DellSmbios:\Security\IsAdminPasswordSet).CurrentValue -eq $true) {
	Set-Item DellSmbios:\Security\AdminPassword "" -Password $Password
}
If ((Get-Item -Path DellSmbios:\Security\IsAdminPasswordSet).CurrentValue -eq $false) {
	Write-Host "Success" -ForegroundColor Yellow
} else {
	Write-Host "Failed" -ForegroundColor Red
}