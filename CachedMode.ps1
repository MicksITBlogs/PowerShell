<#
	.SYNOPSIS
		Cached Exchange Mode Report
	
	.DESCRIPTION
		This script is to be executed on a machine to report if Microsoft Outlook is in cached exchange mode or not. It will report a status of on/off/unknown. The status was tracked down to registry key 00036601. The script queries under HKEY_USERS\%SID%\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles to find which key contains 00036601. The key under the above listed key is the name of the outlook profile and the key that contains 00036601 is a GUID key. Neither of those are standard across different systems, so the script has to find the actual key path. The script can then write the data to either a log file located at a centralized network path, or it can write it to the WMI so that it can be reported back to SCCM. The script was written so that it can be used in an environment that either has SCCM or does not. This script has not been written for Office 365 or Office 2013 as the firm I work at never used that version. If you need include Office 2013, you will need to add Office 15 to the Find-Registry Function
	
	.PARAMETER SCCM
		Write output to WMI for reporting to SCCM
	
	.PARAMETER TextFile
		Write output to a text file stored at a centralized repository
	
	.PARAMETER TextFileLocation
		Location to write the text file to
	
	.EXAMPLE
		Write output to WMI entry for reporting to SCCM
			powershell.exe -file CachedMode.ps1 -SCCM

		Write output to a text file at a centralized location NOTE: -TextFileLocation can be prepopulated
			powershell.exe -file CachedMode.ps1 -TextFile -TextFileLocation '\\mick\Systems'

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.3.131
		Created on:   	12/29/2016 12:45 PM
		Created by:   	Mick Pletcher
		Organization:
		Filename:     	CachedModeReporting.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[Switch]$SCCM,
	[switch]$TextFile,
	[string]$TextFileLocation
)

function Find-RegistryKey {
<#
	.SYNOPSIS
		Find Registry Key Value
	
	.DESCRIPTION
		Find the registry key that contains the specified value entry
	
	.PARAMETER Value
		Value to search registry key for
	
	.PARAMETER SID
		HKEY_USERS SID
	
	.EXAMPLE
		PS C:\> Find-RegistryKey
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Value,
		[ValidateNotNullOrEmpty()][string]$SID
	)
	
	$Version = Get-OfficeVersion
	switch ($Version) {
		"Office 14" { $Key = "HKEY_USERS\" + $SID + "\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows Messaging Subsystem\Profiles" }
		"Office 16" { $Key = "HKEY_USERS\" + $SID + "\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles" }
	}
	If ((Test-Path REGISTRY::$Key) -eq $true) {
		[string]$CachedMode = get-childitem REGISTRY::$Key -recurse -ErrorAction SilentlyContinue | where-object { $_.property -eq "00036601" }
		If ($CachedMode -ne $null) {
			[string]$CachedModeValue = (Get-ItemProperty REGISTRY::$CachedMode).'00036601'
			switch ($Version) {
				"Office 14" {
					switch ($CachedModeValue) {
						#Values below are converted to decimal from the registry hex value commented to the right
						'128 25 0 0' { Return "Enabled" } #'80 19 0 0'
						'0 16 0 0' { Return "Disabled" } #'0 10 0 0'
						default { Return "Unknown" }
					}
				}
				"Office 16" {
					switch ($CachedModeValue) {
						#Values below are converted to decimal from the registry hex value commented to the right
						'132 25 0 0' { Return "Enabled" } #'84 19 0 0'
						'4 16 0 0' { Return "Disabled" } #'4 10 0 0'
						default { Return "Unknown" }
					}
				}
			}
			Return $CachedModeValue
		} else {
			Return $null
		}
	} else {
		Return $null
	}
}

function Get-HKEY_USERS_List {
<#
	.SYNOPSIS
		Retrieve list of HKEY_Users
	
	.DESCRIPTION
		Retrieve list of HKEY_Users while excluding the built-in and administrator accounts
	
	.EXAMPLE
				PS C:\> Get-HKEY_USERS_List
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([array])]
	param ()
	
	#Get list of HKEY_USERS registry keys filtering out built-in users
	$HKEY_USERS = Get-ChildItem REGISTRY::HKEY_USERS | where-object { ($_.Name -like "*S-1-5-21*") -and ($_.Name -notlike "*_Classes") }
	$Users = @()
	foreach ($User in $HKEY_USERS) {
		#Get the SID of the first profile
		$PROFILESID = Get-ChildItem REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.name -like "*" + $USER.PSChildName + "*" }
		$SID = $PROFILESID.PSChildName
		#Determine if cached mode is on or off
		$CachedMode = Find-RegistryKey -Value "00036601" -SID $SID
		If ($CachedMode -ne $null) {
			#Get the username associated with the SID
			$ProfileName = ((Get-ItemProperty REGISTRY::$PROFILESID).ProfileImagePath).Split("\")[2]
			#Write username and sid to object
			$SystemInfo = New-Object -TypeName System.Management.Automation.PSObject
			Add-Member -InputObject $SystemInfo -MemberType NoteProperty -Name Profile -Value $ProfileName
			Add-Member -InputObject $SystemInfo -MemberType NoteProperty -Name Status -Value $CachedMode
			$Users += $SystemInfo
		}
	}
	Return $Users
}

function New-WMIClass {
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -ne "") {
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
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("Profile", [System.Management.CimType]::String, $false)
	$newClass.Properties["Profile"].Qualifiers.Add("key", $true)
	$newClass.Properties["Profile"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("Status", [System.Management.CimType]::String, $false)
	$newClass.Properties["Status"].Qualifiers.Add("key", $true)
	$newClass.Properties["Status"].Qualifiers.Add("read", $true)
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
		Write a new instance for each profile along with its cached mode status
	
	.PARAMETER Username
		Username
	
	.PARAMETER CachedModeStatus
		Status of exchange cached mode
	
	.PARAMETER Class
		WMI Class to write information to
	
	.PARAMETER MappedDrives
		List of mapped drives
	
	.EXAMPLE
		PS C:\> New-WMIInstance
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Username,
		[ValidateNotNullOrEmpty()][string]$CachedModeStatus,
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$Output = "Writing Cached Exchange information instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ Profile = $Username; Status = $CachedModeStatus }
	If ($Return -like "*" + $Username + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Get-OfficeVersion {
<#
	.SYNOPSIS
		Get Microsoft Office Version
	
	.DESCRIPTION
		Execute the OSPP.vbs to display the license information, which also contains the current version of Microsoft Office.
	
	.EXAMPLE
				PS C:\> Get-OfficeVersion
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	If ((Test-Path $env:ProgramFiles"\Microsoft Office") -eq $true) {
		$File = get-childitem -path $env:ProgramFiles"\Microsoft Office" -filter ospp.vbs -recurse
	}
	If ((Test-Path ${env:ProgramFiles(x86)}"\Microsoft Office") -eq $true) {
		$File = get-childitem -path ${env:ProgramFiles(x86)}"\Microsoft Office" -filter ospp.vbs -recurse
	}
	#Get current version of office
	$Version = (cscript.exe $File.Fullname /dstatus | where-object { $_ -like "LICENSE NAME:*" }).split(":")[1].Trim().Split(",")[0]
	Return $Version
}

function Initialize-HardwareInventory {
<#
	.SYNOPSIS
		Perform Hardware Inventory
	
	.DESCRIPTION
		Perform a hardware inventory via the SCCM client to report the WMI entry.
	
	.EXAMPLE
				PS C:\> Initialize-HardwareInventory
	
	.NOTES
		Additional information about the function.
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

Clear-Host
#Get list of users and report if they are running Outlook in cached exchange mode
$Users = Get-HKEY_USERS_List
If ($SCCM.IsPresent) {
	#Create new WMI Class to report status to
	New-WMIClass -Class "Cached_Exchange_Mode"
	#Write Cached Mode Status reports to WMI instances
	foreach ($User in $Users) {
		New-WMIInstance -Username $User.Profile -CachedModeStatus $User.Status -Class "Cached_Exchange_Mode"
	}
	Initialize-HardwareInventory
}
If ($TextFile.IsPresent) {
	#Check if $TextFileLocation is populated
	If (($TextFileLocation -ne "") -and ($TextFileLocation -ne $null)) {
		#Check if $TextFileLocation exists
		If ((Test-Path $TextFileLocation) -eq $true) {
			#Insert backslash at the end of the $TextFileLocation and define the name of the text file
			If ($TextFileLocation.Length - 1 -ne '\') {
				$File = $TextFileLocation + '\' + $env:COMPUTERNAME + ".log"
			} else {
				$File = $TextFileLocation + $env:COMPUTERNAME + ".log"
			}
			#Delete the old log file if it exists
			If ((Test-Path $File) -eq $true) {
				Remove-Item $File -Force
			}
			#Write the results to the log file
			$Users | Out-File $File -Encoding UTF8 -Force
		} else {
			Write-Host "Text file location does not exist"
		}
	} else {
		Write-Host "No text file location was defined."
	}
}
#Display Results to Screen
$Users