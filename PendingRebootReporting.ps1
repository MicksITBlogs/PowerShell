<#
	.SYNOPSIS
		Reboot Pending Detection
	
	.DESCRIPTION
		This script will the four reboot pending flags to verify if a system is pending a reboot. The flags include Windows patches, component based servicing, session manager, and finally configuration manager client. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
		Created on:   	7/11/2017 1:10 PM
		Created by:   	Mick Pletcher
		Filename:		PendingRebootReporting.ps1
		===========================================================================
#>

#Checks if the registry key RebootRequired is present. It is created when Windows Updates are applied and require a reboot to take place
$PatchReboot = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue
#Checks if the RebootPending key is present. It is created when changes are made to the component store that require a reboot to take place
$ComponentBasedReboot = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue
#Checks if File rename operations are taking place and require a reboot for the operation to take effect
$PendingFileRenameOperations = (Get-ItemProperty -Path REGISTRY::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" -ErrorAction SilentlyContinue).PendingFileRenameOperations
#Performs a WMI query of the configuration manager service to check if a reboot is pending
$ConfigurationManagerReboot = Invoke-WmiMethod -Namespace "ROOT\ccm\ClientSDK" -Class CCM_ClientUtilities -Name DetermineIfRebootPending | select-object -ExpandProperty "RebootPending"
If (($PatchReboot -eq $null) -and ($ComponentBasedReboot -eq $null) -and ($PendingFileRenameOperations -eq $null) -and ($ConfigurationManagerReboot -eq $false)) {
	Return $false
} else {
	Return $true
}
