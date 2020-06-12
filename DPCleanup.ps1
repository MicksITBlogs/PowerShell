<#
	.SYNOPSIS
		ConfigMgr Distribution Point Cleanup
	
	.DESCRIPTION
		This script will cleanup the remnants of a distribution point after it has been deleted in Configuration Manager. This is sometimes necessary when needing to repush a distribution point to the same server. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	6/12/2020 2:01 PM
		Created by:   	Mick Pletcher
		Filename:     	DPCleanup.ps1
		===========================================================================
#>

[CmdletBinding()]
param ()

#Uninstall ConfigMgr Client
If ((Test-Path ($env:windir + '\ccmsetup\ccmsetup.exe')) -eq $true) {
    Start-Process ($env:windir + '\ccmsetup\ccmsetup.exe') -ArgumentList "/uninstall" -Wait
}
#Retrieve the path to the distribution point directories
If ((Test-Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\DP') -eq $true) {
    $ContentLibraryPath = ((Get-ItemProperty -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS\DP').ContentLibraryPath).split('\')[0] + '\'
} else {
    Write-Host 'Cannot find path to distribution point content'
    Exit 1
}
#Delete the distribution point directories
(Get-ChildItem -Path $ContentLibraryPath | Where-Object {($_.Name -like 'SMS*') -or ($_.Name -like 'SCCM*')}) | ForEach-Object {Remove-item -Path $_.FullName -Recurse -Force}
#Delete registry keys associated with ConfigMgr
If ((Test-Path "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS") -eq $true) {
    Remove-Item -Path "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\SMS" -Recurse -Force -ErrorAction SilentlyContinue
}
