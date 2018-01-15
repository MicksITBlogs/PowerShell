<#
	.SYNOPSIS
		BIOS Reporting Tool
	
	.DESCRIPTION
		This script will query the BIOS of Dell machines using the Dell Command | Configure to report the data to SCCM via WMI.
	
	.PARAMETER FilePath
		UNC path where to write the file output
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.141
		Created on:   	7/18/2017 9:31 AM 
		Created by:   	Mick Pletcher
		Filename:	DellBIOSReportingTool.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$FilePath
)

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
	
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
	#Returns 32-bit or 64-bit
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

function Get-CCTK {
<#
	.SYNOPSIS
		Find CCTK.EXE
	
	.DESCRIPTION
		Find the Dell CCTK.EXE file.
	
	.EXAMPLE
				PS C:\> Get-CCTK
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Architecture = Get-Architecture
	If ($Architecture -eq "64-bit") {
		$Directory = ${env:ProgramFiles(x86)} + "\Dell\"
		$File = Get-ChildItem -Path $Directory -Filter cctk.exe -Recurse | Where-Object { $_.Directory -like "*_64*" }
	} else {
		$Directory = $env:ProgramFiles + "\Dell\"
		$File = Get-ChildItem -Path $Directory -Filter cctk.exe -Recurse | Where-Object { $_.Directory -like "*x86" }
	}
	Return $File
}

function Get-ListOfBIOSSettings {
<#
	.SYNOPSIS
		Retrieve List of BIOS Settings
	
	.DESCRIPTION
		This will get a list of all BIOS settings
	
	.PARAMETER Executable
		CCTK.exe
	
	.EXAMPLE
		PS C:\> Get-ListOfBIOSSettings
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Executable
	)
	
	#Get the path this script is executing from
	$RelativePath = Get-RelativePath
	#Get list of exclusions to omit from list of BIOS settings
	$File = $RelativePath + "BIOSExclusions.txt"
	$BIOSExclusions = Get-Content -Path $File | Sort-Object
	#Rewrite list of sorted exclusion back to text file
	$BIOSExclusions | Out-File -FilePath $File -Force
	#Get list of BIOS settings -- Script must be executed on a local machine and not from a UNC path
	$Output = cmd.exe /c $Executable.FullName
	#Remove instructional information
	$Output = $Output | Where-Object { $_ -like "*--*" } | Where-Object { $_ -notlike "*cctk*" }
	#Format Data and sort it
	$Output = ($Output.split("--") | Where-Object { $_ -notlike "*or*" } | Where-Object{ $_.trim() -ne "" }).Trim() | Where-Object { $_ -notlike "*help*" } | Where-Object { $_ -notlike "*version*" } | Where-Object { $_ -notlike "*infile*" } | Where-Object { $_ -notlike "*logfile*" } | Where-Object { $_ -notlike "*outfile*" } | Where-Object { $_ -notlike "*ovrwrt*" } | Where-Object { $_ -notlike "*setuppwd*" } | Where-Object { $_ -notlike "*sysdefaults*" } | Where-Object { $_ -notlike "*syspwd*" } | ForEach-Object { $_.Split("*")[0] } | Where-Object { $_ -notin $BIOSExclusions }
	#Add bootorder back in as -- filtered it out since it does not have the -- in front of it
	$Output = $Output + "bootorder" | Sort-Object
	Return $Output
}

function Get-BIOSSettings {
<#
	.SYNOPSIS
		Retrieve BIOS Settings Values
	
	.DESCRIPTION
		This will retrieve the value associated with the BIOS Settings
	
	.PARAMETER Settings
		List of BIOS Settings
	
	.PARAMETER Executable
		CCTK.exe file
	
	.EXAMPLE
		PS C:\> Get-BIOSSettings
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Settings,
		[ValidateNotNullOrEmpty()]$Executable
	)
	
	#Create Array
	$BIOSArray = @()
	foreach ($Setting in $Settings) {
		switch ($Setting) {
			"advbatterychargecfg" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "--" + $Setting
				$Value = (cmd.exe /c $Arguments).split("=")[1]
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + "--" + $Setting
				$Description = (cmd.exe /c $Arguments | Where-Object { $_.trim() -ne "" }).split(":")[1].Trim()
			}
			"advsm" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object {$_.trim() -ne ""}).split(":")[1].Trim().split(".")[0]
			}
			"bootorder" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + $Setting
				$Output = (((((cmd.exe /c $Arguments | Where-Object { $_ -like "*Enabled*" } | Where-Object { $_ -notlike "*example*" }) -replace 'Enabled', '').Trim()) -replace '^\d+', '').Trim()) | ForEach-Object { ($_ -split ' {2,}')[1] }
				$Output2 = "bootorder="
				foreach ($item in $Output) {
					[string]$Output2 += [string]$item + ","
				}
				$Value = $Output2.Substring(0,$Output2.Length-1)
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object { $_.trim() -ne "" }).split(":")[1].Trim().split(".")[0]
			}
			"hddinfo" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object {$_.trim() -ne ""}).split(":")[1].trim().split(".")[0]
			}
			"hddpwd" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object {$_.trim() -ne ""}).split(":")[1].split(".")[0].trim()
			}
			"pci" {
				$Value = ""
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object { $_.trim() -ne "" }).split(":")[1].split(".")[0].trim()
			}
			"propowntag" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "--" + $Setting
				$Value = ((cmd.exe /c $Arguments).split("=")[1]).trim()
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object { $_.trim() -ne "" }).split(":")[1].trim()
			}
			"secureboot" {
				$Arguments = [char]34 + $Executable.FullName + [char]34 + " --" + $Setting
				$Output = cmd.exe /c $Arguments
				if ($Output -like "*not enabled*") {
					$Value = "disabled"
				} else {
					$Value = "enabled"
				}
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + $Setting
				$Description = ((cmd.exe /c $Arguments) | where-object { $_.trim() -ne "" }).split(":")[1].Trim().split(".")[0]
			}
			default {
				#Get BIOS setting
				$Output = $null
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "--" + $Setting
				$Output = cmd.exe /c $Arguments
				#Get BIOS Description
				$Arguments = [char]34 + $Executable.FullName + [char]34 + [char]32 + "-h" + [char]32 + "--" + $Setting
				$Description = ((cmd.exe /c $Arguments) | Where-Object { $_.trim() -ne "" }).split(":").Trim()[1]
				$Value = $Output.split("=")[1]
			}
		}
		#Add Items to object array
		$objBIOS = New-Object System.Object
		$objBIOS | Add-Member -MemberType NoteProperty -Name Setting -Value $Setting
		$objBIOS | Add-Member -MemberType NoteProperty -Name Value -Value $Value
		$objBIOS | Add-Member -MemberType NoteProperty -Name Description -Value $Description
		$BIOSArray += $objBIOS
	}
	Return $BIOSArray
}
#Find the CCTK.exe file
$CCTK = Get-CCTK
#Get List of BIOS settings
$BIOSList = Get-ListOfBIOSSettings -Executable $CCTK
#Get all BIOS settings
$BIOSSettings = Get-BIOSSettings -Executable $CCTK -Settings $BIOSList
#Add Computer Model to FileName
$FileName = ((Get-WmiObject -Class win32_computersystem -Namespace root\cimv2).Model).Trim()
#Add BIOS version and .CSV extension to computer name
$FileName += [char]32 + ((Get-WmiObject -Class win32_bios -Namespace root\cimv2).SMBIOSBIOSVersion).Trim() + ".CSV"
#Get full path to the output .CSV file
If ($FilePath[$FilePath.Length - 1] -ne "\") {
	$FileName = $FilePath + "\" + $FileName
} else {
	$FileName = $FilePath + $FileName
}
#Delete old .CSV if it exists
If ((Test-Path $FileName) -eq $true) {
	Remove-Item -Path $FileName -Force
}
#Screen output
$BIOSSettings
#File output
$BIOSSettings | Export-Csv -Path $FileName -NoTypeInformation -Force
