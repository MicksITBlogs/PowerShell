<#
	.SYNOPSIS
		Initialize TPM
	
	.DESCRIPTION
		This script will turn on the PPI Bypass for TPM clear and Initialize the TPM.
	
	.PARAMETER Password
		BIOS Password
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.207
		Created on:   	6/28/2022 10:02 AM
		Created by:   	Mick Pletcher
		Filename:     	DellBIOS04.ps1
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
#PPI Bypass for TPM Clear
Set-Item -Path DellSMBIOS:\TPMSecurity\TpmPpiClearOverride Enabled -Password $Password
#Clear TPM
Clear-Tpm
