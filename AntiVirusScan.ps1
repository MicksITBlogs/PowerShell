<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.98
	 Created on:   	11/19/2015 3:26 PM
	 Created by:   	Mick Pletcher
	 Filename:     	AntiVirusScan.ps1
	===========================================================================
	.DESCRIPTION
		This script will initiate a full or quick scan, whichever one is uncommented
		out below. It will then write a log to the event viewer logs showing the 
		scan was executed. The final step is to execute a machine policy update so
		the SCCM server is updated on the status of the system.
#>

Import-Module $env:ProgramFiles"\Microsoft Security Client\MpProvider"
<#Full Scan#>
Start-MProtScan -ScanType "FullScan"
New-EventLog –LogName System –Source "Antimalware Full Scan"
Write-EventLog -LogName System -Source "Antimalware Full Scan" -EntryType Information -EventId 1118 -Message "Antimalware full system scan was performed" -Category ""

<#Quick Scan
Start-MProtScan -ScanType "QuickScan"
New-EventLog –LogName System –Source "Antimalware Quick Scan"
Write-EventLog -LogName System -Source "Antimalware Quick Scan" -EntryType Information -EventId 1118 -Message "Antimalware quick system scan was performed" -Category ""
#>

$WMIPath = "\\" + $env:COMPUTERNAME + "\root\ccm:SMS_Client"
$SMSwmi = [wmiclass]$WMIPath
$strAction = "{00000000-0000-0000-0000-000000000021}"
[Void]$SMSwmi.TriggerSchedule($strAction)
Exit 0
