<#
	.SYNOPSIS
		A brief description of the ImportADExtensions.ps1 file.
	
	.DESCRIPTION
		This script will import data from a CSV file to be written to the desired extension attributes in active directory
	
	.PARAMETER DataFile
		Name of the csv file that contains the data to import into active directory
	
	.PARAMETER LogFile
		Name of the log file to write the status of each change to
	
	.PARAMETER ProcessDelay
		This will pause the script for XX number of seconds before processing the next AD user. This is intended as a safety measure in the event that wrong data is being written to each AD profile. This allows for not all profile to be affected at once.
	
	.EXAMPLE
		Run with no logging and no delays between entry changes
			powershell.exe -executionpolicy bypass -file ImportADExtensions.ps1 -DataFile Data.csv

		Run with logging and no delays between entry changes
			powershell.exe -executionpolicy bypass -file ImportADExtensions.ps1 -DataFile Data.csv -LogFile ADExtensions.log

		Run with logging and 10 second delay between entry changes
			powershell.exe -executionpolicy bypass -file ImportADExtensions.ps1 -DataFile Data.csv -LogFile ADExtensions.log -ProcessDelay 10

		You can also pre-populate the parameters within the Param fields inside the script.

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.126
		Created on:   	7/28/2016 8:55 AM
		Created by:		Mick Pletcher
		Organization:
		Filename:		ImportADExtensions.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]
	$DataFile,
	[string]
	$LogFile,
	[int]
	$ProcessDelay
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

function Import-DataFile {
<#
	.SYNOPSIS
		Import data file
	
	.DESCRIPTION
		Import the data from a csv file
	
	.EXAMPLE
		PS C:\> Import-DataFile
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	#Get the path this script is being executed from
	$RelativePath = Get-RelativePath
	#Associate the relative path with the data file to be imported
	$File = $RelativePath + $DataFile
	#Read the data file to a variable
	$FileData = Get-Content -Path $File -Force
	#Get the attribute fields
	$Fields = ($FileData[0]).Split(",")
	$ImportedRecords = @()
	foreach ($Record in $FileData) {
		If ($Record -notlike "*extensionattribute*") {
			$SplitRecord = $Record.Split(",")
			$objRecord = New-Object System.Management.Automation.PSObject
			for ($i = 0; $i -lt $Fields.Length; $i++) {
				$objRecord | Add-Member -type NoteProperty -Name $Fields[$i] -Value $SplitRecord[$i]
			}
			$ImportedRecords += $objRecord
		}
	}
	Return $ImportedRecords
}

function New-Logfile {
<#
	.SYNOPSIS
		Create a new log file
	
	.DESCRIPTION
		This will create a new log file. If an old one exists, it will delete it.
	
	.EXAMPLE
				PS C:\> New-Logfile
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$RelativePath = Get-RelativePath
	$Logs = $RelativePath + $LogFile
	If ((Test-Path $Logs) -eq $true) {
		$Output = "Deleting old log file....."
		Remove-Item -Path $Logs -Force | Out-Null
		If ((Test-Path $Logs) -eq $false) {
			$Output += "Success" + "`n"
		} else {
			$Output += "Failed" + "`n"
		}
	}
	If (($LogFile -ne "") -and ($LogFile -ne $null)) {
		$Output += "Creating new log file....."
		New-Item -Path $Logs -ItemType File -Force | Out-Null
		If ((Test-Path $Logs) -eq $true) {
			$Output += "Success"
		} else {
			$Output += "Failed"
		}
		Write-Output $Output
	}
}

function Write-ExtensionAttributes {
<#
	.SYNOPSIS
		Write Extension Attributes to Active Directory
	
	.DESCRIPTION
		This script will write the extension attributes to active directory. It reads the name of the object field to associate with the correct extension attribute in AD.
	
	.PARAMETER Records
		List of imported objects
	
	.EXAMPLE
		PS C:\> Write-ExtensionAttributes -Records $value1
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][object]
		$Records
	)
	
	#Get all member of $Records
	$Fields = $Records | Get-Member
	#Filter for just the extension attribute properties
	$Fields = ($Fields | Where-Object { (($_.MemberType -eq "NoteProperty") -and ($_.Name -like "*extensionattribute*")) }).name
	for ($i = 0; $i -lt @($Records).Count; $i++) {
		#Get all active directory properties for specified user
		$User = Get-ADUser $Records[$i].Username -Properties *
		$Output += "User " + ($i+1) + " of " + @($Records).Count + "`n"
		$Output += "Username: " + $Records[$i].Username + "`n"
		foreach ($Field in $Fields) {
			$Output += $Field + ": " + $Records[$i].$Field + "`n"
			If ((($Records[$i].$Field -eq "Clear") -or ($Records[$i].$Field -eq "") -or ($Records[$i].$Field -eq $null)) -and ($Records[$i].$Field -ne "NO CLEAR")) {
				$Output += "Clearing " + $Field + "....."
				Set-ADUser -Identity $Records[$i].Username -Clear $Field
				#Get the field that was change from active directory
				$Test = Get-ADUser $Records[$i].Username -Properties * | select $Field
				#Test if the data in the AD field matches the data from the imported file
				if ($Test.$Field -eq $null) {
					$Output += "Success" + "`n"
				} else {
					$Output += "Failed" + "`n"
				}
			} elseif ($Records[$i].$Field -ne "NO CLEAR") {
				$User.$Field = $Records[$i].$Field
				$Output += "Setting " + $Field + "....."
				#Write change to active directory
				Set-ADUser -Instance $User
				#Get the field that was change from active directory
				$Test = Get-ADUser $Records[$i].Username -Properties * | select $Field
				#Test if the data in the AD field matches the data from the imported file
				if ($Test.$Field -eq $Records[$i].$Field) {
					$Output += "Success" + "`n"
				} else {
					$Output += "Failed" + "`n"
				}
			}
		}
		Write-Output $Output
		#If the Logfile parameter is populated, then write the output to a logfile
		If (($LogFile -ne "") -and ($LogFile -ne $null)) {
			#Get the path where this script is being executed from
			$RelativePath = Get-RelativePath
			#Define the log file path
			$Logs = $RelativePath + $LogFile
			#Write the output to the log file
			Add-Content -Value $Output -Path $Logs -Encoding UTF8 -Force
		}
		$Output = $null
		If (($ProcessDelay -ne $null) -and ($ProcessDelay -ne "")) {
			Start-Sleep -Seconds $ProcessDelay
		}
		cls
	}
}

Import-Module -Name ActiveDirectory
#Delete old log file and create a new one
New-Logfile
#Import all records from the csv file
$Records = Import-DataFile
#Apply changes to active directory
Write-ExtensionAttributes -Records $Records
