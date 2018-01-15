<#
	.SYNOPSIS
		Install .Net Framework 4.7
	
	.DESCRIPTION
		This script will install .Net Framework 4.7 using the MSU file. It is written to accomidate both x86 and x64 versions. The script will also convert the WUSA.EXE return codes to standard SCCM return codes. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
		Created on:   	9/15/2017 10:45 AM
		Created by:   	Mick Pletcher 
		Filename:     	installDotNet47.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()
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

function Install-MSUFile {
<#
	.SYNOPSIS
		Install Windows Update
	
	.DESCRIPTION
		This function installs windows update MSU files.
	
	.PARAMETER FileName
		Name of MSU file
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$FileName
	)
	
	$RelativePath = Get-RelativePath
	$Executable = $env:windir + "\System32\wusa.exe"
	$Parameters = $RelativePath + $FileName + [char]32 + "/quiet /norestart"
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	Return $ErrCode
}

$Architecture = Get-Architecture
If ($Architecture -eq "32-Bit") {
	$ReturnCode = Install-MSUFile -FileName Windows6.1-KB4019990-x86.msu
} else {
	$ReturnCode = Install-MSUFile -FileName Windows6.1-KB4019990-x64.msu
}
#Exit Return Codes
#2359301 -- Reboot Required
#2359302 -- Already Installed
If ($ReturnCode -eq 2359301) {
	$ReturnCode = 3010
}
If ($ReturnCode -eq 2359302) {
	$ReturnCode = 0
}
$ReturnCode
Exit $ReturnCode
