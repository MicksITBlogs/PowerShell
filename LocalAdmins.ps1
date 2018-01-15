<#
	.SYNOPSIS
		Report Local administrators
	
	.DESCRIPTION
		Report a list of local administrators on machines to a designated text file, screen, and/or to SCCM via a WMI entry.
	
	.PARAMETER MemberExclusionsFile
		Text file containing a list of users to exclude
	
	.PARAMETER OutputFile
		Specifies if the output is to be written to a text file. The OutputFileLocation parameter also needs to be populated with the location to write the text file to.
	
	.PARAMETER OutputFileLocation
		Location where to write the output text files
	
	.PARAMETER SCCMReporting
		Report results to SCCM
	
	.PARAMETER SystemExclusionsFile
		Text file containing a list of systems to not generate a report on
	
	.EXAMPLE
		Get a list of local admins without reporting to SCCM or writing output to text file
		powershell.exe -file LocalAdmins.ps1
		
		Get a list of local admins and report to SCCM
		powershell.exe -file LocalAdmins.ps1 -SCCMReporting
		
		Get a list of local admins and write report to a text file at a specified location
		powershell.exe -file LocalAdmins.ps1 -OutputFile
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
		Created on:   	11/9/2016 12:47 PM
		Created by:   	Mick Pletcher
		Filename:     	LocalAdministrators.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[string]
	$MemberExclusionsFile = 'MemberExclusions.txt',
	[switch]
	$OutputFile,
	[string]
	$OutputFileLocation = '',
	[switch]
	$SCCMReporting,
	[string]
	$SystemExclusionsFile = 'SystemExclusions.txt'
)

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
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -ne $null) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "success"
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
	$newClass.Properties.Add("Domain", [System.Management.CimType]::String, $false)
	$newClass.Properties["Domain"].Qualifiers.Add("key", $true)
	$newClass.Properties["Domain"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("User", [System.Management.CimType]::String, $false)
	$newClass.Properties["User"].Qualifiers.Add("key", $false)
	$newClass.Properties["User"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "success"
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
		A detailed description of the New-WMIInstance function.
	
	.PARAMETER MappedDrives
		List of mapped drives
	
	.PARAMETER Class
		A description of the Class parameter.
	
	.EXAMPLE
		PS C:\> New-WMIInstance
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][array]
		$LocalAdministrators,
		[string]
		$Class
	)
	
	foreach ($LocalAdministrator in $LocalAdministrators) {
		$Output = "Writing" + [char]32 +$LocalAdministrator.User + [char]32 + "instance to" + [char]32 + $Class + [char]32 + "class....."
		$Return = Set-WmiInstance -Class $Class -Arguments @{ Domain = $LocalAdministrator.Domain; User = $LocalAdministrator.User }
		If ($Return -like "*" + $LocalAdministrator.User + "*") {
			$Output += "Success"
		} else {
			$Output += "Failed"
		}
		Write-Output $Output
	}
}

cls
#Get the path this script is being executed from
$RelativePath = Get-RelativePath
#Name of the computer this script is being executed on
$ComputerName = $Env:COMPUTERNAME
#Read the list of systems to exclude from reporting
$File = $RelativePath + $SystemExclusionsFile
$SystemExclusions = Get-Content $File
If ($SystemExclusions -notcontains $Env:COMPUTERNAME) {
	#Get list of users to exclude from reporting
	$File = $RelativePath + $MemberExclusionsFile
	$MemberExclusions = Get-Content $File
	#Get list of local administrators while excluding specified members
	$Members = net localgroup administrators | Where-Object { $_ -AND $_ -notmatch "command completed successfully" } | select -skip 4 | Where-Object { $MemberExclusions -notcontains $_ }
	$LocalAdmins = @()
	foreach ($Member in $Members) {
		#Create new object
		$Admin = New-Object -TypeName System.Management.Automation.PSObject
		$Member = $Member.Split("\")
		If ($Member.length -gt 1) {
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name Domain -Value $Member[0].Trim()
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name User -Value $Member[1].Trim()
		} else {
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name Domain -Value ""
			Add-Member -InputObject $Admin -MemberType NoteProperty -Name User -Value $Member.Trim()
		}
		$LocalAdmins += $Admin
	}
}
#Report output to WMI which will report up to SCCM
If ($SCCMReporting.IsPresent) {
	New-WMIClass -Class "Local_Administrators"
	New-WMIInstance -Class "Local_Administrators" -LocalAdministrators $LocalAdmins
	#Report WMI entry to SCCM
	Invoke-SCCMHardwareInventory
}
If ($OutputFile.IsPresent) {
	If ($OutputFileLocation[$OutputFileLocation.Length - 1] -ne "\") {
		$File = $OutputFileLocation + "\" + $ComputerName + ".log"
	} else {
		$File = $OutputFileLocation + $ComputerName + ".log"
	}
	#Delete old log file if it exists
	$Output = "Deleting $ComputerName.log....."
	If ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
	If ((Test-Path $File) -eq $false) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
	$Output = "Writing local admins to $ComputerName.log....."
	$LocalAdmins | Out-File $File
	If ((Test-Path $File) -eq $true) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}
#Display list of local administrators to screen
$LocalAdmins
