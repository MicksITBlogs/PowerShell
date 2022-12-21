<#
	.SYNOPSIS
		Set Wake-On-LAN
	
	.DESCRIPTION
		Set the Wake-on-LAN BIOS Setting
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.207
		Created on:   	6/29/2022 8:26 AM
		Created by:   	Mick Pletcher
		Filename:     	WakeOnLAN.ps1
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
#Wake on LAN/WLAN
#Set-Item -Path DellSMBIOS:\PowerManagement\WakeOnLan LanWlan
Write-Host "Wake-On-LAN....." -NoNewline
If ((Get-Item -Path DellSmbios:\PowerManagement\WakeOnLan).CurrentValue -ne 'LanOnly')
{
	Set-Item -Path DellSMBIOS:\PowerManagement\WakeOnLan -Value 'LanOnly'
}
If ((Get-Item -Path DellSmbios:\PowerManagement\WakeOnLan).CurrentValue -eq 'LanOnly')
{
	Write-Host "Enabled" -ForegroundColor Yellow
}
else
{
	Write-Host "Disabled" -ForegroundColor Red
}
