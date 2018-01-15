<#
	.SYNOPSIS
		EndPoint Virus Scan
	
	.DESCRIPTION
		This script will initiate a full or quick scan, whichever switch is selected at the command line. Once the scan is completed, it will check the event viewer logs for a scan completed entry to verify the scan successfully completed. If the Email switch is designated at the command line, then an email is sent to the specified recipient. It is suggested the $EmailRecipient, $EmailSender, and $SMTPServer be predefined in the parameter field. I have also included a trigger of the application deployment evaluation cycle to expedite the process.
	
	.PARAMETER FullScan
		Initiate a full system scan
	
	.PARAMETER QuickScan
		Initiate a quick scan
	
	.PARAMETER Email
		Select if you want an email report sent to the specified email address
	
	.PARAMETER EmailRecipient
		Receipient's email address
	
	.PARAMETER EmailSender
		Sender's email address
	
	.PARAMETER SMTPServer
		SMTP server address
	
	.EXAMPLE
		Initiate a Quickscan
		powershell.exe -executionpolicy bypass -file AntiVirusScanEmail.ps1 -QuickScan
		
		Initiate a Fullscan
		powershell.exe -executionpolicy bypass -file AntiVirusScanEmail.ps1 -FullScan
		
		Initiate a Fullscan and send email report. To, From, and SMTP parameters are pre-defined
		powershell.exe -executionpolicy bypass -file AntiVirusScanEmail.ps1 -FullScan -Email
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
		Created on:   	8/5/2016 11:11 AM
		Created by:   	Mick Pletcher 
		Filename:     	AntiVirusScanEmail.ps1
		===========================================================================
#>
param
(
	[switch]
	$FullScan,
	[switch]
	$QuickScan,
	[switch]
	$Email,
	[string]
	$EmailRecipient = '',
	[string]
	$EmailSender = '',
	[string]
	$SMTPServer = ''
)

#Import the Endpoint Provider module
Import-Module $env:ProgramFiles"\Microsoft Security Client\MpProvider\MpProvider.psd1"
#Get the relative execution path of this script
$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
#Find the last infection entry in the event viewer logs
$LastInfection = get-winevent -filterhashtable @{ logname = 'system'; ID = 1116 } -maxevents 1 -ErrorAction SilentlyContinue
#Full Scan
If ($FullScan.IsPresent) {
	#Initiate a full system scan
	Start-MProtScan -ScanType "FullScan"
	#Commented area only there if you want to manually execute this script to watch it execute
<#	cls
	Write-Warning "Error: $_"
	Write-Host $_.Exception.ErrorCode
#>	
	#Get the last event viewer log written by Endpoint to check if the full system scan has finished
	$LastScan = Get-WinEvent -FilterHashtable @{ logname = 'system'; ProviderName = 'Microsoft Antimalware'; ID = 1001 } -MaxEvents 1
	#
	If ($LastScan.Message -like '*Microsoft Antimalware scan has finished*') {
		$EmailBody = "An Endpoint antimalware full system scan has been performed on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	} else {
		$EmailBody = "An Endpoint antimalware full system scan did not complete on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	}
}
#Quick Scan
If ($QuickScan.IsPresent) {
	#Initiate a quick system scan
	Start-MProtScan -ScanType "QuickScan"
	#Commented area only there if you want to manually execute this script to watch it execute
<#	cls
	Write-Warning "Error: $_"
	Write-Host $_.Exception.ErrorCode
#>	
	#Get the last event viewer log written by Endpoint to check if the quick system scan has finished
	$LastScan = Get-WinEvent -FilterHashtable @{ logname = 'system'; ProviderName = 'Microsoft Antimalware'; ID = 1001 } -MaxEvents 1
	#
	If ($LastScan.Message -like '*Microsoft Antimalware scan has finished*') {
		$EmailBody = "An Endpoint antimalware quick system scan has been performed on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	} else {
		$EmailBody = "An Endpoint antimalware quick system scan did not complete on" + [char]32 + $env:COMPUTERNAME + [char]32 + "due to the virus detection listed below." + [char]13 + [char]13 + $LastInfection.Message
	}
}
#Email Infection Report
If ($Email.IsPresent) {
	$Subject = "Microsoft Endpoint Infection Report"
	$EmailSubject = "Virus Detection Report for" + [char]32 + $env:COMPUTERNAME
	Send-MailMessage -To $EmailRecipient -From $EmailSender -Subject $Subject -Body $EmailBody -SmtpServer $SMTPServer
}
#Initiate Application Deployment Evaluation Cycle
$WMIPath = "\\" + $env:COMPUTERNAME + "\root\ccm:SMS_Client"
$SMSwmi = [wmiclass]$WMIPath
$strAction = "{00000000-0000-0000-0000-000000000121}"
[Void]$SMSwmi.TriggerSchedule($strAction)
