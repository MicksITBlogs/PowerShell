<#
	.SYNOPSIS
		Update Dell drivers, Dell Applications, and Dell BIOS via Dell Command | Update
	
	.DESCRIPTION
		Uses Dell Command | Update to update all drivers, BIOS, and Dell applications. Everything can be entered through the parameters without the need to modify the code.
	
	.PARAMETER BIOSPassword
		If no BIOS Password is submitted, then the script will skip over clearing disabling the BIOS Password.
	
	.PARAMETER Policy
		Name of the custom policy file that configures what updates to install.
	
	.PARAMETER ConsoleTitle
		Title of the PowerShell Window

	.EXAMPLE
		powershell.exe -file Update.ps1 -ConsoleTitle "Dell Command | Update" -Policy "BIOS.xml" -BIOSPassword "Pwd"
		powershell.exe -file Update.ps1 -ConsoleTitle "Dell Command | Update" -Policy "BIOS.xml"
		powershell.exe -file Update.ps1 -ConsoleTitle "Dell Command | Update" -BIOSPassword "Pwd"
		powershell.exe -file Update.ps1 -ConsoleTitle "Dell Command | Update"
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.99
		Created on:   	1/29/2016 2:59 PM
		Created by:   	Mick Pletcher
		Filename:     	Update.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[string]$BIOSPassword,
		[string]$Policy,
		[string]$ConsoleTitle = " "
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

function Set-ConsoleTitle {
<#
	.SYNOPSIS
		Console Title
	
	.DESCRIPTION
		Sets the title of the PowerShell Console
	
	.PARAMETER Title
		Title of the PowerShell console
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][String]
		$Title
	)
	
	$host.ui.RawUI.WindowTitle = $Title
}

function Get-Architecture {
<#
	.SYNOPSIS
		System Architecture
	
	.DESCRIPTION
		Determine if the system is x86 or x64. It will then return "32-bit" or "64-bit"
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$Architecture = $Architecture.OSArchitecture
	#Returns 32-bit or 64-bit
	Return $Architecture
}

function Install-Updates {
<#
	.SYNOPSIS
		Install Dell Updates
	
	.DESCRIPTION
		This will install the Dell drivers, applications, and BIOS updates.
	
	.PARAMETER DisplayName
		Title to display in the PowerShell Output Console
	
	.PARAMETER Executable
		32-bit or 64-bit dcu-cli executable to execute
	
	.PARAMETER Switches
		Switches when executing the DCU-CLI executable
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[String]
		$DisplayName,
		[String]
		$Executable,
		[String]
		$Switches
	)
	
	Write-Host "Install"$DisplayName"....." -NoNewline
	If ((Test-Path $Executable) -eq $true) {
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 1) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
	
}

function Set-BIOSSetting {
<#
	.SYNOPSIS
		Configure BIOS Settings
	
	.DESCRIPTION
		Uses the CCTK.exe to configure Dell BIOS settings
	
	.PARAMETER Name
		Display name of the BIOS setting
	
	.PARAMETER Option
		Technical name of the BIOS setting
	
	.PARAMETER Setting
		Switches for the Option parameter
	
	.PARAMETER Drives
		Populated if the Set-BIOSSetting is being used to configure the drive boot sequences
	
	.PARAMETER Architecture
		Designates if the OS is x86 or x64
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[string]
		$Name,
		[string]
		$Option,
		[string]
		$Setting,
		[string]
		$Drives,
		[string]
		$Architecture
	)
	
	If ($Architecture -eq "32-bit") {
		$EXE = $Env:PROGRAMFILES + "\Dell\Command Configure\X86\cctk.exe"
	} else {
		$EXE = ${env:ProgramFiles(x86)} + "\Dell\Command Configure\X86_64\cctk.exe"
	}
	$Argument = "--" + $Option + "=" + $Setting
	Write-Host $Name"....." -NoNewline
	If ((Test-Path $EXE) -eq $true) {
		$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Argument -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 240) -or ($ErrCode -eq 241)) {
		Write-Host "Success" -ForegroundColor Yellow
	} elseIf ($ErrCode -eq 119) {
		Write-Host "Unavailable" -ForegroundColor Green
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
}

cls
Set-ConsoleTitle -Title $ConsoleTitle
$Architecture = Get-Architecture
If ($BIOSPassword -ne "") {
	Set-BIOSSetting -Name "Disable BIOS Password" -Option "valsetuppwd" -Setting $BIOSPassword" --setuppwd=" -Drives "" -Architecture $Architecture
}
If ($Architecture -eq "32-bit") {
	$EXE = $Env:PROGRAMFILES + "\Dell\CommandUpdate\dcu-cli.exe"
} else {
	$EXE = ${env:ProgramFiles(x86)} + "\Dell\CommandUpdate\dcu-cli.exe"
}
If ($Policy -eq "") {
	$Parameters = " "
} else {
	$RelativePath = Get-RelativePath
	$Parameters = "/policy " + [char]34 + $RelativePath + $Policy + [char]34
}
If ((Test-Path $EXE) -eq $true) {
	Install-Updates -DisplayName "Update Dell Components" -Executable $EXE -Switches $Parameters
} else {
	Exit 1
}