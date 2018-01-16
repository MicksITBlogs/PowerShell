<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.98
	 Created on:   	05 November 2015 10:37 AM
	 Created by:   	Mick Pletcher
	 Filename:     	InstallEndPoint_build.ps1
	===========================================================================
	.DESCRIPTION
		Install endpoint during the generation of a golden image. This will
		also remove all necessary registry keys required in preparation of 
		generating a golden image.
#>

#Declare Global Memory
$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"

Function Wait-ProcessEnd {
	<#
	.SYNOPSIS
		Wait-Process
	.DESCRIPTION
		Waits for a Process to end before continuing.
	#>
	
	Param ([String]$Process)
	$Proc = Get-Process $Process -ErrorAction SilentlyContinue
	If ($Proc -ne $null) {
		Do {
			Start-Sleep -Seconds 5
			$Proc = Get-Process $Process -ErrorAction SilentlyContinue
		} While ($Proc -ne $null)
	}
}

Function Install-EXE {
	<#
	.SYNOPSIS
		Install-EXE
	.DESCRIPTION
		Installs an EXE file
	#>
	
	Param ([String]$DisplayName,
		[String]$Executable,
		[String]$Switches)
	Write-Host "Install"$DisplayName"....." -NoNewline
	If ((Test-Path $Executable) -eq $true) {
		Start-Process -FilePath $Executable -ArgumentList $Switches
		Wait-ProcessEnd -Process "scepinstall"
	} else {
		$ErrCode = 1
	}
	$Process = Get-Process -ProcessName MsMpEng -ErrorAction SilentlyContinue
	If ($Process.ProcessName -eq "MsMpEng") {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
}

Function Uninstall-EXE {
	<#
	.SYNOPSIS
		Uninstall-EXE
	.DESCRIPTION
		Uninstalls an EXE file
	#>
	
	Param ([String]$DisplayName,
		[String]$Executable,
		[String]$Switches)
	Write-Host "Uninstall"$DisplayName"....." -NoNewline
	If ((Test-Path $Executable) -eq $true) {
		Start-Process -FilePath $Executable -ArgumentList $Switches
		Wait-ProcessEnd -Process "scepinstall"
	}
	$Process = Get-Process -ProcessName MsMpEng -ErrorAction SilentlyContinue
	If ($Process -eq $null) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
}

Function Remove-RegistryValue {
	<#
	.SYNOPSIS
		Remove-RegistryValue
	.DESCRIPTION
		Deletes a specific registry value
	.EXAMPLE
		Remove-RegistryValue "HKEY_LOCAL_MACHINE\SOFTWARE\Hummingbird"
	#>
	
	Param ([String]$RegistryKey,
		[String]$Value)
	$tempdrive = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
	$RegistryKey1 = $RegistryKey.split("\")
	switch ($RegistryKey1[0]) {
		"HKEY_CLASSES_ROOT" { $RegistryKey1[0] = "HKCR" }
		"HKEY_CURRENT_USER" { $RegistryKey1[0] = "HKCU" }
		"HKEY_LOCAL_MACHINE" { $RegistryKey1[0] = "HKLM" }
		"HKEY_USERS" { $RegistryKey1[0] = "HKU" }
		"HKEY_CURRENT_CONFIG" { $RegistryKey1[0] = "HKCC" }
	}
	For ($i = 0; $i -lt $RegistryKey1.Count; $i++) {
		$RegKey = $RegKey + $RegistryKey1[$i]
		If ($i -eq 0) {
			$RegKey = $RegKey + ":\"
		} elseif ($i -ne $RegistryKey1.Count - 1) {
			$RegKey = $RegKey + "\"
		} else {
			$RegKey = $RegKey
		}
	}
	Write-Host "Delete"$RegKey"\"$Value"....." -NoNewline
	$exists = Get-ItemProperty -Path $RegKey -Name $Value -ErrorAction SilentlyContinue
	If (($exists -ne $null) -and ($exists.Length -ne 0)) {
		Remove-ItemProperty -Path $RegKey -Name $Value -Force
	}
	$exists = Get-ItemProperty -Path $RegKey -Name $Value -ErrorAction SilentlyContinue
	If ($exists -eq $null) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Yellow
	}
}

cls
Uninstall-EXE -DisplayName "Microsoft Endpoint" -Executable $global:RelativePath"scepinstall.exe" -Switches "/u /s"
$Parameters = "/s /policy " + $global:RelativePath + "EndpointPolicies.xml"
Install-EXE -DisplayName "Microsoft Endpoint" -Executable $global:RelativePath"scepinstall.exe" -Switches $Parameters
Remove-RegistryValue -RegistryKey "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Antimalware" -Value "InstallTime"
Remove-RegistryValue -RegistryKey "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Antimalware\Scan" -Value "LastScanRun"
Remove-RegistryValue -RegistryKey "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Antimalware\Scan" -Value "LastScanType"
Remove-RegistryValue -RegistryKey "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Antimalware\Scan" -Value "LastQuickScanID"
Remove-RegistryValue -RegistryKey "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Microsoft Antimalware\Scan" -Value "LastFullScanID"
Remove-RegistryValue -RegistryKey "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RemovalTools\MRT" -Value "GUID"
