<#
	.SYNOPSIS
		Turn On TPM
	
	.DESCRIPTION
		Turn on the TPM
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.207
		Created on:   	6/29/2022 10:16 AM
		Created by:   	Mick Pletcher
		Filename:		TurnOnTPM.ps1
		===========================================================================
#>

#Install Dell BIOS Provider PowerShell Module
Try {
	Import-Module -Name DellBIOSProvider
}
Catch {
	Find-Module -Name DellBIOSProvider | Install-Module -Force
	Import-Module -Name DellBIOSProvider
}
#TPM On
Write-Host "TPM....." -NoNewline
If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmSecurity).CurrentValue -ne "Enabled") {
	Set-Item -Path DellSMBIOS:\TPMSecurity\TpmSecurity Enabled
}
If ((Get-Item -Path DellSmbios:\TPMSecurity\TpmSecurity).CurrentValue -eq "Enabled") {
	Write-Host "On" -ForegroundColor Yellow
}
else {
	Write-Host "Off" -ForegroundColor Red
}


