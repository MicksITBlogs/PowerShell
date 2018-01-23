<#
	.SYNOPSIS
		Install PowerShell Gallery
	
	.DESCRIPTION
		This script will install the necessary files and package provider necessary to access the Microsoft PowerShell Gallery.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
		Created on:   	1/23/2018 10:33 AM
		Created by:   	Mick Pletcher
		Filename:		InstallPowerShellGallery.ps1
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

function Install-MSIFile {
<#
	.SYNOPSIS
		Install Windows Update
	
	.DESCRIPTION
		This function installs windows update MSU files.
	
	.PARAMETER File
		A description of the File parameter.
	
	.PARAMETER Arguments
		List of MSI arguments
	
	.PARAMETER FileName
		Name of MSU file
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$File,
		[ValidateNotNullOrEmpty()][string]$Arguments
	)
	
	$RelativePath = Get-RelativePath
	$Executable = $env:windir + "\System32\msiexec.exe"
	$Parameters = "/i" + [char]32 + $File.Fullname + [char]32 + $Arguments
	Write-Host "Installing"($File.Name).Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
		Return $true
	} else {
		Write-Host "Failed" -ForegroundColor Red
		Return $false
	}
}

#Get machine architecture
$Architecture = Get-Architecture
#Get the path this script is executing from
$RelativePath = Get-RelativePath
#Determine the correct MSI package to execute
If ($Architecture -eq "32-bit") {
	$File = Get-ChildItem -Path $RelativePath -Filter *x86.msi
} else {
	$File = Get-ChildItem -Path $RelativePath -Filter *x64.msi
}
#Install the PackageManagement
$Results = Install-MSIFile -File $File -Arguments "/qb- /norestart"
If ($Results -eq $true) {
	#Install nuget to gain access to the PowerShell Gallery
	Install-PackageProvider nuget -Force -Verbose
	Exit 0
} else {
	Exit 1
}
