<#
	.SYNOPSIS
		Check Boot Environment
	
	.DESCRIPTION
		This script reads the setupact.log file to determine if the system is configured for BIOS or UEFI. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	9/25/2020 11:59 AM
		Created by:   	Mick Pletcher
		Filename:		BootEnvironment.ps1
		===========================================================================
#>

Try {
	$Output = (Get-Content -Path (((Get-ChildItem -Path ($env:windir + '\Panther') -Recurse -Filter setupact.log -ErrorAction SilentlyContinue)[0]).FullName) -ErrorAction SilentlyContinue | Where-Object {$_ -like "*Detected boot environment*"}).Replace("Detected boot environment:", "~").Split("~")[1].Trim()
	If ($Output -eq 'BIOS') {
		Write-Output 'BIOS'
		Exit 0
	} elseif ($Output -eq 'UEFI') {
		Write-Output 'UEFI'
		Exit 1
	}
} Catch {
	Write-Output 'Unknown'
	Exit 2
}
