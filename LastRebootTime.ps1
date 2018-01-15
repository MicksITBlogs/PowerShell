<#
	.SYNOPSIS
		Report Last Reboot/Shutdown Time
	
	.DESCRIPTION
		This script will query the system logs for the last time the system was shutdown or rebooted. I have included four different logs that can be used for determining the last shutdown. I compiled this list from asking poling admins online on what methods they used to determine the last reboot/shutdown of a system. These methods were the most common responses. It will create a WMI class to record the date/time of the last reboot time. The script will then initiate an SCCM hardware inventory to push the data up to SCCM.
	
	.PARAMETER EventLogServiceStopped
		Specifies the use of event ID 6006 which is when the event log service was stopped, thereby signifying a system shutdown.
	
	.PARAMETER KernelBootType
		Specifies using the event ID 27 and looking for 'The boot type was 0x0' which is a full shutdown. This is a Windows 10 only feature.
	
	.PARAMETER MultiprocessorFree
		Specifies using event ID 6009 that is logged when a system starts up.
	
	.PARAMETER EventLogServiceStarted
		Specifies the use of event ID 6005 which is when the event log service was started, thereby signifying a system startup.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.135
		Created on:   	1/30/2017 1:45 PM
		Created by:   	Mick Pletcher
		Filename:	LastRebootTime.ps1
		===========================================================================
#>
param
(
	[switch]$EventLogServiceStopped,
	[switch]$KernelBootType,
	[switch]$MultiprocessorFree,
	[switch]$EventLogServiceStarted
)
function Initialize-HardwareInventory {
<#
	.SYNOPSIS
		Perform Hardware Inventory
	
	.DESCRIPTION
		Perform a hardware inventory via the SCCM client to report the WMI entry.
	
#>
	
	[CmdletBinding()]
	param ()
	
	$Output = "Initiate SCCM Hardware Inventory....."
	$SMSCli = [wmiclass] "\\localhost\root\ccm:SMS_Client"
	$ErrCode = ($SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")).ReturnValue
	If ($ErrCode -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function New-WMIClass {
<#
	.SYNOPSIS
		Create New WMI Class
	
	.DESCRIPTION
		This will delete the specified WMI class if it already exists and create/recreate the class.
	
	.PARAMETER Class
		A description of the Class parameter.
	
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
	$Output = "Creating " + $Class + " WMI class....."
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [string]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("LastRebootTime", [System.Management.CimType]::string, $false)
	$newClass.Properties["LastRebootTime"].Qualifiers.Add("key", $true)
	$newClass.Properties["LastRebootTime"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
		Exit 1
	}
	Write-Output $Output
}

function New-WMIInstance {
<#
	.SYNOPSIS
		Write new instance
	
	.DESCRIPTION
		Write a new instance reporting the last time the system was rebooted
	
	.PARAMETER LastRebootTime
		Date/time the system was last rebooted
	
	.PARAMETER Class
		WMI Class
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$LastRebootTime,
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$Output = "Writing Last Reboot information instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ LastRebootTime = $LastRebootTime }
	If ($Return -like "*" + $LastRebootTime + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

Clear-Host
#Get the log entry of the last time the Event Log service was stopped to determine a reboot
If ($KernelBootType.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 27 } -MaxEvents 1 | Where-Object { $_.Message -like "*boot type was 0x0*" }).TimeCreated
}
If ($EventLogServiceStarted.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 6005 } -MaxEvents 1 | Where-Object { $_.Message -like "*service was started*" }).TimeCreated
}
If ($EventLogServiceStopped.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 6006 } -MaxEvents 1 | Where-Object { $_.Message -like "*service was stopped*" }).TimeCreated
}
If ($MultiprocessorFree.IsPresent) {
	[string]$LastReboot = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 6009 } -MaxEvents 1 | Where-Object { $_.Message -like "*Multiprocessor Free*" }).TimeCreated
}

$Output = "Last reboot/shutdown: " + $LastReboot
Write-Output $Output
#Delete old WMI Class and create new one
New-WMIClass -Class "RebootInfo"
#Add last reboot date/time as WMI instance
New-WMIInstance -LastRebootTime $LastReboot -Class "RebootInfo"
#Initialize SCCM hardware inventory to report information back to SCCM
Initialize-HardwareInventory
