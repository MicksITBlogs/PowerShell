<#
	.SYNOPSIS
		Zero Touch Conditional Reboot
	
	.DESCRIPTION
		This script will check four flags on the system to see if a reboot is required. If one of the flags is tripped, then this script will initiate a reboot in MDT so that will come back up and start at the proceeding task. I have included the commented out SMSTSRetryRequested in the script so if you want to incorporate the code from this script into another one that will need to be rerun again once the reboot completes. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	7/12/2019 2:53 PM
		Created by:   	Mick Pletcher
		Organization: 	Waller Lansden Dortch & Davis, LLP.
		Filename:     	ZTIConditionalReboot.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()

function Enable-Reboot {
<#
	.SYNOPSIS
		Request MDT Reboot
	
	.DESCRIPTION
		A detailed description of the Enable-Reboot function.
#>
	
	[CmdletBinding()]
	param ()
	
	$TaskSequence = New-Object -ComObject Microsoft.SMS.TSEnvironment
	#Reboot the machine this command line task sequence finishes
	$TaskSequence.Value('SMSTSRebootRequested') = $true
	#Rerun this task when the reboot finishes
	#$TaskSequence.Value('SMSTSRetryRequested') = $true
}

#Component Based Reboot
If ((Get-ChildItem "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) -ne $null) {
	Enable-Reboot
#Windows Update Reboot
} elseif ((Get-Item -Path "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null) {
	Enable-Reboot
#Pending Files Rename Reboot
} elseif ((Get-ItemProperty -Path "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) -ne $null) {
	Enable-Reboot
#Pending SCCM Reboot
} elseif ((([wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending) -eq $true) {
	Enable-Reboot
} else {
	Exit 0
}
