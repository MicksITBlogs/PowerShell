<#
	.SYNOPSIS
		Dell Driver Update
	
	.DESCRIPTION
		This script executes the Dell Command | Update and reboots MDT or SCCM up to five times when new updates are available. The reason for the 5 reboot limit is because some Dell updates have been know to not leave markers and will cause the Dell Command | Update to rerun indefinitely.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	7/18/2019 1:57 PM
		Created by:   	Mick Pletcher
		Filename:		ZTIDellDriverUpdate.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()

#Verify Dell Command | Update exists
If ((Test-Path -Path (Get-ChildItem -Path $env:ProgramFiles, ${env:ProgramFiles(x86)} -filter dcu-cli.exe -Recurse -ErrorAction SilentlyContinue).FullName) -eq $true) {
	#Delete old logs if they exist
	Remove-Item -Path ($env:windir + '\temp\ActivityLog.xml') -ErrorAction SilentlyContinue -Force
	Remove-Item -Path ($env:windir + '\temp\inventory.xml') -ErrorAction SilentlyContinue -Force
	#Update the system with the latest drivers while also writing log files to the %windir%\temp directory
	$ErrCode = (Start-Process -FilePath ((Get-ChildItem -Path $env:ProgramFiles, ${env:ProgramFiles(x86)} -Filter 'dcu-cli.exe' -Recurse).FullName) -ArgumentList ('/log ' + $env:windir + '\temp') -Wait).ExitCode
	#Read the ActivityLog.xml file
	$File = (Get-Content -Path ($env:windir + '\temp\ActivityLog.xml')).Trim()
	#if no updates were found or updates were applied and no required reboot is necessary, then delete the log files
	If (('<message>CLI: No application component updates found.</message>' -in $File) -and (('<message>CLI: No available updates can be installed.</message>' -in $File) -or ('<message>CLI: No updates are available.</message>' -in $File)))
	{
		Remove-Item -Path ($env:windir + '\temp\ActivityLog.xml') -ErrorAction SilentlyContinue -Force
		Remove-Item -Path ($env:windir + '\temp\inventory.xml') -ErrorAction SilentlyContinue -Force
		Remove-Item -Path ($env:TEMP + '\RebootCount.log') -ErrorAction SilentlyContinue -Force
	}
	else
	{
		#Create the file containing number of times this script has rerun if it does not exist
		If ((Test-Path ($env:TEMP + '\RebootCount.log')) -eq $false)
		{
			New-Item -Path ($env:TEMP + '\RebootCount.log') -ItemType File -Value 0 -Force
		}
		#Reboot the machine and rerun the Dell Driver Updates
		If (([int](Get-Content -Path ($env:TEMP + '\RebootCount.log'))) -lt 5)
		{
			#Microsoft SCCM/MDT environmental variables
			$TSEnv = New-Object -ComObject Microsoft.SMS.TSEnvironment
			#Reboot the machine once this task is completed and restart the task sequence
			$TSEnv.Value('SMSTSRebootRequested') = $true
			#Rerun the same task
			$TSEnv.Value('SMSTSRetryRequested') = $true
			#increment the reboot counter
			New-Item -Path ($env:TEMP + '\RebootCount.log') -ItemType File -Value ([int](Get-Content -Path ($env:TEMP + '\RebootCount.log')) + 1) -Force
			#End the update process if run 5 or more times, delete all associated log files, and proceed to the next task
		}
		else
		{
			Remove-Item -Path ($env:windir + '\temp\ActivityLog.xml') -ErrorAction SilentlyContinue -Force
			Remove-Item -Path ($env:windir + '\temp\inventory.xml') -ErrorAction SilentlyContinue -Force
			Remove-Item -Path ($env:TEMP + '\RebootCount.log') -ErrorAction SilentlyContinue -Force
		}
	}
}
else {
	Write-Output 'Dell Command | Update is not installed'
	Exit 1
}