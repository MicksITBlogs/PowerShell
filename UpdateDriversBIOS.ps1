<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.99
	 Created on:   	1/29/2016 2:59 PM
	 Created by:   	Mick Pletcher
	 Filename:     	UpdateDriversBIOS.ps1
	===========================================================================
	.DESCRIPTION
		Uses Dell Command | Update to update all drivers and BIOS versions.
#>

Function Set-ConsoleTitle {
	Param ([String]$Title)
	$host.ui.RawUI.WindowTitle = $Title
}

Function Get-Architecture {
	#Declare Local Variables
	Set-Variable -Name Architecture -Scope Local -Force
	
	$Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$Architecture = $Global:Architecture.OSArchitecture
	#Returns 32-bit or 64-bit
	Return $Architecture
	
	#Cleanup Local Variables
	Remove-Variable -Name Architecture -Scope Local -Force
}

Function Install-Updates {
	Param ([String]$DisplayName,
		[String]$Executable,
		[String]$Switches)
	
	#Declare Local Variables
	Set-Variable -Name ErrCode -Scope Local -Force
	
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
	
	#Cleanup Local Variables
	Remove-Variable -Name ErrCode -Scope Local -Force
}


Function CCTKSetting {
	param ($Name,
		$Option,
		$Setting,
		$Drives,
		$Architecture)
	
	#Declare Local Variables
	Set-Variable -Name Argument -Scope Local -Force
	Set-Variable -Name ErrCode -Scope Local -Force
	Set-Variable -Name EXE -Scope Local -Force
	
	If ($Architecture -eq "32-bit") {
		$EXE = $Env:PROGRAMFILES + "\Dell\Command Configure\X86\cctk.exe"
	} else {
		$EXE = ${env:ProgramFiles(x86)} + "\Dell\Command Configure\X86_64\cctk.exe"
	}
	If ($Option -ne "bootorder") {
		$Argument = "--" + $Option + "=" + $Setting
	} else {
		$Argument = "bootorder" + [char]32 + "--" + $Setting + "=" + $Drives
	}
	Write-Host $Name"....." -NoNewline
	If ((Test-Path $EXE) -eq $true) {
		$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Argument -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 240) -or ($ErrCode -eq 241)) {
		If ($Drives -eq "") {
			Write-Host $Setting -ForegroundColor Yellow
		} else {
			Write-Host $Drives -ForegroundColor Yellow
		}
	} elseIf ($ErrCode -eq 119) {
		Write-Host "Unavailable" -ForegroundColor Green
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
	
	#Cleanup Local Variables
	Remove-Variable -Name Argument -Scope Local -Force
	Remove-Variable -Name ErrCode -Scope Local -Force
	Remove-Variable -Name EXE -Scope Local -Force
}

#Declare Local Variables
Set-Variable -Name Architecture -Scope Local -Force
Set-Variable -Name EXE -Scope Local -Force

cls
Set-ConsoleTitle -Title "Dell Client Update"
$Architecture = Get-Architecture
CCTKSetting -Name "Disable BIOS Password" -Option "valsetuppwd" -Setting "<BIOS Password> --setuppwd=" -Drives "" -Architecture $Architecture
If ($Architecture -eq "32-bit") {
	$EXE = $Env:PROGRAMFILES + "\Dell\CommandUpdate\dcu-cli.exe"
} else {
	$EXE = ${env:ProgramFiles(x86)} + "\Dell\CommandUpdate\dcu-cli.exe"
}
Install-Updates -DisplayName "Update All Hardware Components" -Executable $EXE -Switches " "

#Cleanup Local Variables
Remove-Variable -Name Architecture -Scope Local -Force
Remove-Variable -Name EXE -Scope Local -Force
