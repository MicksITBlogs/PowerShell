<#
	.SYNOPSIS
		Configure PPI
	
	.DESCRIPTION
		Configure TPM PPI settings
	
	.PARAMETER Password
		BIOS Password
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.207
		Created on:   	6/29/2022 1:37 PM
		Created by:   	Mick Pletcher
		Filename:		PPI.ps1
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
}
Catch {
	Find-Module -Name DellBIOSProvider | Install-Module -Force
	Import-Module -Name DellBIOSProvider
}
#TPM PPI Provision Override
If ("TpmPpiPo" -in (Get-ChildItem DellSmbios:\TPMSecurity\).Attribute) {
	Write-Host "TPM PPI Provision Override....." -NoNewline
	If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmPpiPo).CurrentValue -ne "Enabled") {
		Set-Item -Path DellSMBIOS:\TPMSecurity\TpmPpiPo Enabled -Password $Password
	}
	If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmPpiPo).CurrentValue -eq "Enabled") {
		Write-Host "Enabled" -ForegroundColor Yellow
	}
	else {
		Write-Host "Disabled" -ForegroundColor Red
	}
}
#TPM PPI Deprovision Override
If ("TpmPpiDpo" -in (Get-ChildItem DellSmbios:\TPMSecurity\).Attribute) {
	Write-Host "TPM PPI Deprovision Override....." -NoNewline
	If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmPpiDpo).CurrentValue -ne "Enabled") {
		Set-Item -Path DellSMBIOS:\TPMSecurity\TpmPpiDpo Enabled -Password $Password
	}
	If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmPpiDpo).CurrentValue -eq "Enabled") {
		Write-Host "Enabled" -ForegroundColor Yellow
	}
	else {
		Write-Host "Disabled" -ForegroundColor Red
	}
}
#PPI Clear Override
If ("TpmPpiClearOverride" -in (Get-ChildItem DellSmbios:\TPMSecurity\).Attribute) {
	Write-Host "TPM PPI Clear Override....." -NoNewline
	If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmPpiClearOverride).CurrentValue -ne "Enabled") {
		Set-Item -Path DellSMBIOS:\TPMSecurity\TpmPpiClearOverride Enabled -Password $Password
	}
	If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmPpiClearOverride).CurrentValue -eq "Enabled") {
		Write-Host "Enabled" -ForegroundColor Yellow
	}
	else {
		Write-Host "Disabled" -ForegroundColor Red
	}
}