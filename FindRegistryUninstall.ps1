<#
	.SYNOPSIS
		Uninstall Finder
	
	.DESCRIPTION
		This script will retrieve the x86 and x64 uninstall registry key(s) for a specific applicaton. This is very helpful for Configuration Manager admins when needing to create packages, especially uninstall packages.
	
	.PARAMETER ApplicationName
		Name of the application as it appears in Add/Remove Programs
	
	.PARAMETER Like
		Select this if using a partial name or wanting multiple listings to appear
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.209
		Created on:   	8/3/2022 11:44 AM
		Created by:   	Mick Pletcher
		Filename:		FindRegistryUninstall.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$ApplicationName,
	[switch]$Like
)

If ($Like.IsPresent) {
	Get-ChildItem -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -like ('*' + $ApplicationName + '*') }
} else {
	Get-ChildItem -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty | Where-Object { $_.DisplayName -eq $ApplicationName }
}
