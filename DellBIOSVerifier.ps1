<#
	.SYNOPSIS
		BIOS Update Verifier
	
	.DESCRIPTION
		This script will be executed as the final task within the task sequence. It will query the BIOS to verify the patch was successful. If successful, it will return an error code 0 back to SCCM.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
		Created on:   	1/18/2018 2:05 PM
		Created by:   	Mick Pletcher
		Filename:		BIOSVerifier.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()
function Get-RelativePath {
<#
	.SYNOPSIS
		Get the relative path
	
	.DESCRIPTION
		Returns the location of the currently running PowerShell script
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

$RelativePath = Get-RelativePath
$InstalledVersion = [string]((Get-WmiObject Win32_BIOS).SMBIOSBIOSVersion)
$Model = ((Get-WmiObject Win32_ComputerSystem).Model).split(" ")[1]
[string]$BIOSVersion = (Get-ChildItem -Path $RelativePath | Where-Object { $_.Name -eq $Model } | Get-ChildItem -Filter *.exe)
$BIOSVersion = ($BIOSVersion.split("-")[1]).split(".")[0]
If ($BIOSVersion -eq $InstalledVersion) {
	Exit 0
} else {
	Exit 5
}
