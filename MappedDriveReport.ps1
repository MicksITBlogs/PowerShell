<#
	.SYNOPSIS
		Get List of Mapped Drives
	
	.DESCRIPTION
		Scans each profile for a list of mapped drives. It will generate a screen report and can also write the output to the WMI for reporting to SCCM.
	
	.PARAMETER OutputFile
		Specifies if the output is to be written to a text file. The TextFileLocation parameter also needs to be populated with the location to write the text file to.
	
	.PARAMETER TextFileLocation
		Location where to write the text file to
	
	.PARAMETER UNCPathExclusionsFile
		Text file containing a list of UNC paths to exclude from reporting.
	
	.PARAMETER SCCMReporting
		Specifies to write the data to WMI so that SCCM can pickup the data.
	
	.PARAMETER TextFileName
		Write output to a text file

	.EXAMPLE
		Execute and write output to the reporting file location and also write output to WMI for reporting to SCCM. -TextFileLocation parameter is prepopulated below.
			powershell.exe -file MappedDriveReport.ps1 -OutputFile -SCCMReporting

		Execute and write output to WMI to report to SCCM.
			powershell.exe -file MappedDriveReport.ps1 -SCCMReporting
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.128
		Created on:   	10/7/2016 10:57 AM
		Created by:   	Mick Pletcher
		Organization:
		Filename:		MappedDriveReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[switch]
	$OutputFile,
	[string]
	$TextFileLocation,
	[string]
	$UNCPathExclusionsFile,
	[switch]
	$SCCMReporting
)

function Get-MappedDrives {
<#
	.SYNOPSIS
		Get list of Mapped Drives
	
	.DESCRIPTION
		Retrieve a list of mapped drives for each user that has logged onto the machine.
	
	.EXAMPLE
		PS C:\> Get-MappedDrives
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([array])]
	
	#Get UNC Exclusions from UNCPathExclusions.txt file
	$UNCExclusions = Get-Content $UNCPathExclusionsFile -Force
	#Get HKEY_Users Registry Keys
	[array]$UserSIDS = (Get-ChildItem -Path REGISTRY::HKEY_Users | Where-Object { ($_ -notlike "*Classes*") -and ($_ -like "*S-1-5-21*") }).Name
	#Get Profiles from HKLM
	[array]$ProfileList = (Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_ -like "*S-1-5-21*" }).Name
	$UserMappedDrives = @()
	#Iterate through each HKEY_USERS profile
	foreach ($UserSID in $UserSIDS) {
		#GET SID only
		[string]$UserSID = $UserSID.Split("\")[1].Trim()
		#Find the userprofile that matches the HKEY_USERS
		[string]$UserPROFILE = $ProfileList | Where-Object { $_ -like "*" + $UserSID + "*" }
		#Get the username associated with the SID
		$Username = ((Get-ItemProperty -Path REGISTRY::$UserPROFILE).ProfileImagePath).Split("\")[2].trim()
		#Define registry path to mapped drives
		[string]$MappedDrives = "HKEY_USERS\" + $UserSID + "\Network"
		#Get list of mapped drives
		[array]$MappedDrives = (Get-ChildItem REGISTRY::$MappedDrives | Select-Object name).name
		foreach ($MappedDrive in $MappedDrives) {
			$DriveLetter = (Get-ItemProperty -Path REGISTRY::$MappedDrive | select PSChildName).PSChildName
			$DrivePath = (Get-ItemProperty -Path REGISTRY::$MappedDrive | select RemotePath).RemotePath
			If ($DrivePath -notin $UNCExclusions) {
				$Drives = New-Object System.Management.Automation.PSObject
				$Drives | Add-Member -MemberType NoteProperty -Name Username -Value $Username
				$Drives | Add-Member -MemberType NoteProperty -Name Drive -Value $DriveLetter
				$Drives | Add-Member -MemberType NoteProperty -Name Path -Value $DrivePath
				$UserMappedDrives += $Drives
			}
		}
	}
	Return $UserMappedDrives
}

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

function Invoke-SCCMHardwareInventory {
<#
	.SYNOPSIS
		Initiate a Hardware Inventory
	
	.DESCRIPTION
		This will initiate a hardware inventory that does not include a full hardware inventory. This is enought to collect the WMI data.
	
	.EXAMPLE
				PS C:\> Invoke-SCCMHardwareInventory
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$ComputerName = $env:COMPUTERNAME
	$SMSCli = [wmiclass] "\\$ComputerName\root\ccm:SMS_Client"
	$SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}") | Out-Null
}

function New-WMIClass {
	[CmdletBinding()]
	param ()
	
	$WMITest = Get-WmiObject MappedDrives -ErrorAction SilentlyContinue
	If ($WMITest -ne $null) {
		Remove-WmiObject MappedDrives
	}
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [String]::Empty, $null);
	$newClass["__CLASS"] = "MappedDrives";
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("Letter", [System.Management.CimType]::String, $false)
	$newClass.Properties["Letter"].Qualifiers.Add("key", $true)
	$newClass.Properties["Letter"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("Path", [System.Management.CimType]::String, $false)
	$newClass.Properties["Path"].Qualifiers.Add("key", $true)
	$newClass.Properties["Path"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("user", [System.Management.CimType]::String, $false)
	$newClass.Properties["user"].Qualifiers.Add("key", $true)
	$newClass.Properties["user"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
}

function New-WMIInstance {
<#
	.SYNOPSIS
		Write new instance
	
	.DESCRIPTION
		A detailed description of the New-WMIInstance function.
	
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
		[ValidateNotNullOrEmpty()][array]
		$MappedDrives
	)
	
	foreach ($MappedDrive in $MappedDrives) {
		Set-WmiInstance -Class MappedDrives -Arguments @{ Letter = $MappedDrive.Drive; Path = $MappedDrive.Path; User=$MappedDrive.Username} | Out-Null
	}
}

#Get list of mapped drives for each user
$UserMappedDrives = Get-MappedDrives
#Display list of mapped drives for each user
$UserMappedDrives | Format-Table
#Write output to a text file if -OutputFile is specified
If ($OutputFile.IsPresent) {
	If (($TextFileLocation -ne $null) -and ($TextFileLocation -ne "")) {
		#Add backslash (\) to the end of the TextFileLocation if it is not present
		If ($TextFileLocation[$TextFileLocation.Length - 1] -ne "\") {
			$TextFileLocation += "\"
		}
		#Write list of mapped drives to the specified text file.
		[string]$OutputFile = [string]$TextFileLocation + $env:COMPUTERNAME + ".txt"
	} else {
		#Get the relative path this script was executed from
		$RelativePath = Get-RelativePath
		$OutputFile = $RelativePath + $env:COMPUTERNAME + ".txt"
	}
	If ((Test-Path $OutputFile) -eq $true) {
		Remove-Item $OutputFile -Force
	}
	If (($UserMappedDrives -ne $null) -and ($UserMappedDrives -ne "")) {
		$UserMappedDrives | Format-Table -AutoSize | Out-File $OutputFile -Width 255
	}
}
If ($SCCMReporting.IsPresent) {
#Create the new WMI class to write the output data to
New-WMIClass
#Write the output data as an instance to the WMI class
If ($UserMappedDrives -ne $null) {
	New-WMIInstance -MappedDrives $UserMappedDrives
}
#Invoke a hardware inventory to send the data to SCCM
Invoke-SCCMHardwareInventory
}
