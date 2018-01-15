<#
	.SYNOPSIS
		Update Dell Drivers
	
	.DESCRIPTION
		Update Dell drivers using the Dell Command Update.
	
	.PARAMETER Logging
		Specifies if logging is to take place
	
	.PARAMETER LogLocation
		Location where to write the driver logs
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.135
		Created on:   	2/3/2017 2:21 PM
		Created by:   	Mick Pletcher
		Filename:	DriverUpdate.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[switch]$Logging,
	[string]$LogLocation
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

function Get-DellCommandUpdateLocation {
<#
	.SYNOPSIS
		Find dcu-cli.exe
	
	.DESCRIPTION
		Locate dcu-cli.exe as it may reside in %PROGRAMFILES% or %PROGRAMFILES(X86)%
	
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Architecture = Get-Architecture
	If ($Architecture -eq "32-bit") {
		$File = Get-ChildItem -Path $env:ProgramFiles -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	} else {
		$File = Get-ChildItem -Path ${env:ProgramFiles(x86)} -Filter "dcu-cli.exe" -ErrorAction SilentlyContinue -Recurse
	}
	Return $File.FullName
}

function Invoke-DriverUpdate {
<#
	.SYNOPSIS
		Execute Dell Command Update
	
	.DESCRIPTION
		This will initiate the Dell Command Update using the dcu-cli.exe
	
	.PARAMETER Executable
		dcu-cli.exe
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Executable
	)
	
	If ($Logging.IsPresent) {
		$Model = (Get-WmiObject -Class Win32_ComputerSystem).Model
		If ($LogLocation[$LogLocation.Length - 1] -ne "\") {
			$Location = $LogLocation + "\" + $Model
		} else {
			$Location = $LogLocation + $Model
		}
		If ((Test-Path $LogLocation) -eq $false) {
			New-Item -Path $LogLocation -ItemType Directory -Force | Out-Null
		}
		If ((Test-Path $Location) -eq $false) {
			New-Item -Path $Location -ItemType Directory -Force | Out-Null
		}
		$Location += "\" + $env:COMPUTERNAME
		If ((Test-Path $Location) -eq $true) {
			Remove-Item -Path $Location -Recurse -Force
		}
		$Arguments = "/log" + [char]32 + [char]34 + $Location + [char]34
	} else {
		$Arguments = [char]32
	}
	Start-Process -FilePath $Executable -ArgumentList $Arguments -Wait -Passthru | Out-Null
}


Clear-Host
#Find dcu-cli.exe
$EXE = Get-DellCommandUpdateLocation
#Install Dell drivers
Invoke-DriverUpdate -Executable $EXE
