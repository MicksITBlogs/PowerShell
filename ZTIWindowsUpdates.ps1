<#
	.SYNOPSIS
		Install Windows Updates
	
	.DESCRIPTION
		This script uses the PSWindowsUpdate module to install the latest windows updates. It also makes sure the latest version of the module is installed. It is designed to run in SCCM, MDT, and in a deployment.
	
	.PARAMETER SCCM
		This specifies for the script to use the Microsoft.SMS.TSEnvironment comobject for managing the reboot and re-execution of the Windows Update Task
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	8/29/2019 7:22 AM
		Created by:   	Mick Pletcher
		Filename:		InstallWindowsUpdates.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[switch]$SCCM
)
function Enable-Reboot {
<#
	.SYNOPSIS
		Reboot Machine
	
	.DESCRIPTION
		This function will reboot the machine. If the SCCM switch is defined, it will use the task sequence environmental variables to reboot the machine and restart the task sequence. 
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	If ($SCCM.IsPresent) {
		$TaskSequence = New-Object -ComObject Microsoft.SMS.TSEnvironment
		#Rerun this task when the reboot finishes  
		$TaskSequence.Value('SMSTSRetryRequested') = $true
		#Reboot the machine when this command line task sequence finishes  
		$TaskSequence.Value('SMSTSRebootRequested') = $true
	} else {
		Restart-Computer -Force
	}
}

Import-Module PowerShellGet
Import-Module -Name PSWindowsUpdate -ErrorAction SilentlyContinue
#Get the version of PSWindowsUpdate that is currently installed
$InstalledVersion = (Get-InstalledModule -Name PSWindowsUpdate).Version.ToString()
#Get the current version of PSWindowsUpdate that is available in the PSGallery
$PSGalleryVersion = (Find-Module -Name PSWindowsUpdate).Version.ToString()
#Uninstall and install PSWindowsUpdate module if the installed version does not match the version in PSGallery
If ($InstalledVersion -ne $PSGalleryVersion) {
	Install-Module -Name PSWindowsUpdate -Force
}
#Get the list of available windows updates
$Updates = Get-WindowsUpdate
If ($Updates -ne $null) {
	$NewUpdates = $true
	Do {
		#Add $AdminUser to Administrators group
		Add-LocalGroupMember -Group Administrators -Member ($env:USERDOMAIN + '\' + $env:USERNAME)
		#Install windows updates
		Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false
		#Remove $AdminUser from the Administrators group
		Remove-LocalGroupMember -Group Administrators -Member ($env:USERDOMAIN + '\' + $env:USERNAME)
		#Component Based Reboot  
		If ((Get-ChildItem "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) -ne $null) {
			Enable-Reboot
			$NewUpdates = $false
		#Windows Update Reboot  
		} elseif ((Get-Item -Path "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue) -ne $null) {
			Enable-Reboot
			$NewUpdates = $false
		#Pending Files Rename Reboot  
		} elseif ((Get-ItemProperty -Path "REGISTRY::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager" -Name PendingFileRenameOperations -ErrorAction SilentlyContinue) -ne $null) {
			Enable-Reboot
			$NewUpdates = $false
		#Pending SCCM Reboot  
		} elseif ((([wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities").DetermineIfRebootPending().RebootPending) -eq $true) {
			Enable-Reboot
			$NewUpdates = $false
		}
		#If no pending reboot, then check for new updates
		If ($NewUpdates -eq $true) {
			#Check for new windows updates
			$Updates = Get-WindowsUpdate
			#No reboot was required from last installed updates, so check if new updates are available and end loop if not
			If ($Updates -eq $null) {
				$NewUpdates -eq $false
			}
		}
	} While ($NewUpdates -eq $true)
} else {
	Exit 0
}
