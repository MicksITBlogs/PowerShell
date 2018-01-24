<#
	.SYNOPSIS
		BIOS Update
	
	.DESCRIPTION
		This is intended for Dell systems. The script will query if the system is a laptop, is it docked if specified, is it BitLockered, and is the BIOS password set. These steps are taken as a cautious measure so end-users do not brick their laptops out of impatience. If it is bitlockered, the script will suspend Bitlocker. If a BIOS password is set, the system will use the password for flashing. If all tests pass, the script will execute the BIOS patch and then exit with a return code of 3010. If any of those parameters are not met, the script will exit with a return code of 1 or 2, thereby killing the task sequence.
	
	.PARAMETER BIOSPassword
		BIOS Password
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
		Created on:   	1/9/2018 1:46 PM
		Created by:   	Mick Pletcher
		Filename:		DellBIOSUpdater.ps1
		===========================================================================
		
		Exitcode 0 : Success
		Exitcode 1 : BIOS file is missing
#>
[CmdletBinding()]
param
(
	[string]$BIOSPassword = $null
)

function Get-Architecture {
<#
	.SYNOPSIS
		Get-Architecture
	
	.DESCRIPTION
		Returns whether the system architecture is 32-bit or 64-bit
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	#Returns 32-bit or 64-bit
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
}

function Get-BIOSPasswordStatus {
<#
	.SYNOPSIS
		Check BIOS Password Status
	
	.DESCRIPTION
		Check if the BIOS password is set
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param ()
	
	$Architecture = Get-Architecture
	#Find Dell CCTK
	If ($Architecture -eq "32-Bit") {
		$File = Get-ChildItem ${Env:ProgramFiles(x86)}"\Dell\" -Filter cctk.exe -Recurse | Where-Object { $_.Directory -notlike "*x86_64*" }
	} else {
		$File = Get-ChildItem ${Env:ProgramFiles(x86)}"\Dell\" -Filter cctk.exe -Recurse | Where-Object { $_.Directory -like "*x86_64*" }
	}
	$cmd = [char]38 + [char]32 + [char]34 + $file.FullName + [char]34 + [char]32 + "--setuppwd=" + $BIOSPassword
	$Output = Invoke-Expression $cmd
	#BIOS Password is set
	If ($Output -like "*The old password must be provided to set a new password using*") {
		Return $true
	}
	#BIOS Password was not set, so remove newly set password and return $false
	If ($Output -like "*Password is set successfully*") {
		$cmd = [char]38 + [char]32 + [char]34 + $file.FullName + [char]34 + [char]32 + "--setuppwd=" + [char]32 + "--valsetuppwd=" + $BIOSPassword
		$Output = Invoke-Expression $cmd
		Return $false
	}
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

function Install-BIOSUpdate {
<#
	.SYNOPSIS
		Install BIOS Update
	
	.DESCRIPTION
		A detailed description of the Install-BIOSUpdate function.
	
	.NOTES
		Addition possible exit codes for dell update are outlined here:
		http://en.community.dell.com/techcenter/enterprise-client/w/wiki/3462.dup-bios-updates
#>
	
	[CmdletBinding()]
	param ()
	
	$BIOSLocation = Get-RelativePath
	$Model = ((Get-WmiObject Win32_ComputerSystem).Model).split(" ")[1]
	$File = Get-ChildItem -Path $BIOSLocation | Where-Object { $_.Name -like "*"+$Model+"*" } | Get-ChildItem -Filter *.exe
	#If the BIOS file does not exist, then exit program with error code 3
	If ($File -ne $null) {
		#Backup test to make sure BIOS file matches system model
		If ($File -like "*"+$Model+"*") {
			#Determine if BIOS password is set
			$BIOSPasswordSet = Get-BIOSPasswordStatus
			If ($BIOSPasswordSet -eq $false) {
				$Arguments = "/f /s /l=" + $env:windir + "\waller\Logs\ApplicationLogs\BIOS.log"
			} else {
				$Arguments = "/f /s /p=" + $BIOSPassword + [char]32 + "/l=" + $env:windir + "\waller\Logs\ApplicationLogs\BIOS.log"
			}
			#Apply BIOS update
			$ErrCode = (Start-Process -FilePath $File.FullName -ArgumentList $Arguments -Wait -PassThru).ExitCode
			If (($ErrCode -eq 0) -or ($ErrCode -eq 2)) {
				Exit 3010
			} else {
				Exit $ErrCode
			}
		} else {
			Exit 1
		}
	} else {
		Exit 1
	}
}

#****************************************************************************************
#****************************************************************************************

Install-BIOSUpdate
