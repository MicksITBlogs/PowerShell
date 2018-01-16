<#
	.SYNOPSIS
		Installed Applications
	
	.DESCRIPTION
		This will retrieve the list of installed applications from add/remove programs and write the list to a .CSV file. The tool is executed on machines once a week via an SCCM Application deployment. It's purpose is to provide a custom report to a build team for when they need to rebuild systems without having to comb through the typical SCCM Add/Remove Programs report. The reports are customized by excluding applications that are written to the ExclusionList.txt file.
	
	.PARAMETER ReportFile
		Name of the report file to be created. The report file should have the extension .CSV since this script writes to the file using UTF8 and in Excel format
	
	.PARAMETER ReportFileLocation
		The directory where the report file is located
	
	.EXAMPLE
		powershell.exe -executionpolicy bypass -file InstalledApplications.ps1
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.124
		Created on:   	7/8/2016 1:29 AM
		Created by:   	Mick Pletcher
		Organization:
		Filename:     	InstalledApplications.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[ValidateNotNullOrEmpty()][string]$ReportFile = 'Applications.csv',
		[ValidateNotNullOrEmpty()][string]$ReportFileLocation = 'c:\windows\waller'
)


function Get-AddRemovePrograms {
<#
	.SYNOPSIS
		Retrieve a list of the Add/Remove Programs
	
	.DESCRIPTION
		Retrieves the Add/Remove Programs list from the registry
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Architecture = Get-Architecture
	if ($Architecture -eq "32-bit") {
		$Applications = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" | ForEach-Object -Process { $_.GetValue("DisplayName") }
	} else {
		$Applicationsx86 = Get-ChildItem -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | ForEach-Object -Process { $_.GetValue("DisplayName") }
		$Applicationsx64 = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" | ForEach-Object -Process { $_.GetValue("DisplayName") }
		$Applications = $Applicationsx86 + $Applicationsx64
	}
	$Applications = $Applications | Sort-Object
	$Applications = $Applications | Select-Object -Unique
	Return $Applications
}

function Get-Architecture {
<#
	.SYNOPSIS
		Get-Architecture
	
	.DESCRIPTION
		Returns whether the system architecture is 32-bit or 64-bit
	
	.EXAMPLE
		Get-Architecture
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$OSArchitecture = $OSArchitecture.OSArchitecture
	Return $OSArchitecture
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

function New-LogFile {
<#
	.SYNOPSIS
		Create a new log file
	
	.DESCRIPTION
		Delete the old log file if it exists and/or create a new one
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	If ($ReportFileLocation[$ReportFileLocation.Count - 1] -eq '\') {
		$File = $ReportFileLocation + $ReportFile
	} else {
		$File = $ReportFileLocation + '\' + $ReportFile
	}
	if ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force | Out-Null
	}
	if ((Test-Path $File) -eq $false) {
		New-Item -Path $File -ItemType file -Force | Out-Null
	}
}

function New-Report {
<#
	.SYNOPSIS
		Generate a new Add/Remove programs report
	
	.DESCRIPTION
		This will generate the list of Add/Remove programs and write to the .CSV file.
	
	.PARAMETER Applications
		List of Add/Remove programs applications
	
	.NOTES
		Additional information about the function.
#>
	
	param
	(
			[ValidateNotNullOrEmpty()][object]$Applications
	)
	
	If ($ReportFileLocation[$ReportFileLocation.Count - 1] -eq '\') {
		$File = $ReportFileLocation + $ReportFile
	} else {
		$File = $ReportFileLocation + '\' + $ReportFile
	}
	If ((Test-Path $File) -eq $true) {
		$Applications
		Out-File -FilePath $File -InputObject $Applications -Append -Force -Encoding UTF8
	} else {
		Write-Host "Report File not present to generate report" -ForegroundColor Red
	}
}

function Update-AppList {
<#
	.SYNOPSIS
		Generate updated list of Apps
	
	.DESCRIPTION
		Generate an updated list of apps by removing the apps listed in the exclusions.txt file. This function also sorts and rewrites the exclusion list back to the exclusion.txt file in the event new exclusions have been added.
	
	.PARAMETER Applications
		List of Add/Remove programs applications
	
	.EXAMPLE
		PS C:\> Update-AppList
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param
	(
			[ValidateNotNullOrEmpty()][object]$Applications
	)
	
	$RelativePath = Get-RelativePath
	$File = $RelativePath + "ExclusionList.txt"
	If ((Test-Path $File) -eq $true) {
		$Exclusions = Get-Content -Path $File
		$SortedExclusions = $Exclusions | Sort-Object
		$SortedExclusions = $SortedExclusions | Select-Object -Unique
		$Sorted = !(Compare-Object $Exclusions $SortedExclusions -SyncWindow 0)
		If ($Sorted -eq $false) {
			Do {
				Try {
					$Exclusions = Get-Content -Path $File
					$SortedExclusions = $Exclusions | Sort-Object
					$SortedExclusions = $SortedExclusions | Select-Object -Unique
					$Sorted = !(Compare-Object $Exclusions $SortedExclusions -SyncWindow 0)
					If ($Sorted -eq $false) {
						Out-File -FilePath $File -InputObject $SortedExclusions -Force -Encoding UTF8 -ErrorAction SilentlyContinue
					}
					$Success = $true
				} Catch {
					$Success = $false
				}
			}
			while ($Success -eq $false)
		}
		$Applications = $Applications | Where-Object { ($_ -notin $SortedExclusions) -and ($_ -ne "") -and ($_ -ne $null) }
	}
	Return $Applications
}

Clear-Host
New-LogFile
$Apps = Get-AddRemovePrograms
$Apps = Update-AppList -Applications $Apps
New-Report -Applications $Apps
