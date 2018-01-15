<#
	.SYNOPSIS
		SMART Reporting
	
	.DESCRIPTION
		This script will query the event viewer logs for event ID 51. Event 51 is generated when a drive is in the beginning stages of failing. This script will is to be deployed to machines to generate a WMI entry if event 51 is read. If no event 51 exists, no WMI entry is generated to be read by SCCM.
	
	.PARAMETER SCCM
		Select this switch to write the results to WMI for reporting to SCCM.
	
	.PARAMETER NetworkShare
		Select this switch to write the results to a text file located on the specified network share inside a file named after the machine this script was executed on.
	
	.PARAMETER NetworkSharePath
		UNC path to write output reporting to
	
	.PARAMETER SCCMImport
		This is used to create a fake WMI entry so that it can be imported into SCCM.
	
	.EXAMPLE
		Setting up the initial import of the WMI Class to SCCM
			powershell.exe -file SMARTReporting.ps1 -SCCMImport

		Reporting to SCCM
			powershell.exe -file SMARTReporting.ps1 -SCCM

		Reporting to a Network Share
			powershell.exe -file SMARTReporting.ps1 -NetworkShare -NetworkSharePath "\\server\path\Reporting"

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
		Created on:   	8/12/2016 11:02 AM 
		Created by:	Mick Pletcher
		Filename:	SMARTReporting.ps1
		===========================================================================
#>
param
(
	[switch]$SCCM,
	[switch]$NetworkShare,
	[string]$NetworkSharePath,
	[switch]$SCCMImport
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
	$newClass.Properties.Add("Error51", [System.Management.CimType]::string, $false)
	$newClass.Properties["Error51"].Qualifiers.Add("key", $true)
	$newClass.Properties["Error51"].Qualifiers.Add("read", $true)
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
		[ValidateNotNullOrEmpty()][string]$Error51,
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$Output = "Writing Error 51 information instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ Error51 = $Error51 }
	If ($Return -like "*" + $Error51 + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Remove-WMIClass {
<#
	.SYNOPSIS
		Delete WMIClass
	
	.DESCRIPTION
		Delete the WMI class from system
	
	.PARAMETER Class
		Name of WMI class to delete
	
	.EXAMPLE
				PS C:\> Remove-WMIClass
	
	.NOTES
		Additional information about the function.
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
}

Clear-Host
#Retrieve number of times error 51 has been logged in the event viewer logs
[int]$Count = (Get-WinEvent -FilterHashtable @{ logname = 'system'; ID = 51 } -ErrorAction SilentlyContinue).Count
If ($SCCMImport.IsPresent) {
	#Create WMI Class
	New-WMIClass -Class DriveReporting
	#Write a new WMI instance to the WMI class with a report of how many error 51 events were detected
	New-WMIInstance -Class DriveReporting -Error51 5
} else {
	If ($Count -gt 0) {
		$Output = "Event 51 disk error has occurred $Count times."
		Write-Output $Output
		#Write error reporting to SCCM
		If ($SCCM.IsPresent) {
			#Delete the specified WMI class and recreate it for clean reporting
			New-WMIClass -Class DriveReporting
			#Write a new WMI instance to the WMI class with a report of how many error 51 events were detected
			New-WMIInstance -Class DriveReporting -Error51 $Count
			#Trigger an SCCM hardware inventory to report the errors to SCCM
			Initialize-HardwareInventory
		}
		#Write error reporting to a network share
		If ($NetworkShare.IsPresent) {
			#Add a backslash to the end of the defined network share path if it does not exist
			If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
				$NetworkSharePath += "\"
			}
			#Define the log file to write the output to
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".log"
			#Delete the log file if it already exists so a clean one will be written to
			If ((Test-Path $File) -eq $true) {
				$Output = "Deleting " + $env:COMPUTERNAME + ".log....."
				Remove-Item -Path $File -Force | Out-Null
				If ((Test-Path $File) -eq $false) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
				Write-Output $Output
			}
			#Create a new log file and write number of event 51 logs to it
			$Output = "Creating " + $env:COMPUTERNAME + ".log....."
			New-Item -Path $File -ItemType File -Force | Out-Null
			Add-Content -Path $File -Value "Event 51 Count: $Count" -Force
			If ((Test-Path $File) -eq $true) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		}
	} else {
		$Output = "No event 51 disk errors detected."
		Write-Output $Output
		#Delete the WMI class if it exists on the system since no errors were detected
		If ($SCCM.IsPresent) {
			Remove-WMIClass -Class DriveReporting
		}
		#Delete log file if it exists since no errors were detected
		If ($NetworkShare.IsPresent) {
			If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
				$NetworkSharePath += "\"
			}
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".log"
			If ((Test-Path $File) -eq $true) {
				$Output = "Deleting " + $env:COMPUTERNAME + ".log....."
				Remove-Item -Path $File -Force | Out-Null
				If ((Test-Path $File) -eq $false) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
				Write-Output $Output
			}
		}
	}
}
