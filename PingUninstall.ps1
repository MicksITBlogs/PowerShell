<#
	.SYNOPSIS
		Uninstall Ping Automated Timekeeping for Lawyers
	
	.DESCRIPTION
		This script will kill all Office and Ping applications, and Uninstall old versions of Ping.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	1/30/2019 3:30 PM
		Created by:   	Mick Pletcher
		Filename:		PingUninstall.ps1
		===========================================================================
#>

function Get-MSIInformation {
<#
	.SYNOPSIS
		Retrieve MSI Information
	
	.DESCRIPTION
		This will query the MSI database for information
	
	.PARAMETER MSI
		Name of MSI file
	
	.PARAMETER Property
		MSI property to retrieve
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[System.IO.FileInfo]$MSI,
		[ValidateSet('ProductCode', 'ProductVersion', 'ProductName', 'Manufacturer', 'ProductLanguage', 'FullVersion')]
		[string]$Property
	)
	
	# Read property from MSI database
	$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
	$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $WindowsInstaller, @($MSI.FullName, 0))
	$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
	$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
	$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
	$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
	$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
	
	# Commit database and close view
	$MSIDatabase.GetType().InvokeMember("Commit", "InvokeMethod", $null, $MSIDatabase, $null)
	$View.GetType().InvokeMember("Close", "InvokeMethod", $null, $View, $null)
	$MSIDatabase = $null
	$View = $null
	
	# Return the value
	return $Value
}

function Get-RelativePath {
<#
	.SYNOPSIS
		Get the relative path
	
	.DESCRIPTION
		Returns the location of the currently running PowerShell script
#>
	
	[CmdletBinding()]
	[OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-MSI {
<#
	.SYNOPSIS
		Install MSI file
	
	.DESCRIPTION
		This function will install an MSI file
	
	.PARAMETER MSI
		UNC path and name of MSI to install
	
	.PARAMETER Switches
		MSI switches
	
	.EXAMPLE
		PS C:\> Install-MSI
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[string]$MSI,
		[ValidateNotNullOrEmpty()]
		[string]$Switches
	)
	
	[string]$DisplayName = Get-MSIInformation -MSI $MSI -Property 'ProductName'
	$Executable = $Env:windir + "\system32\msiexec.exe"
	$Parameters = "/i" + [char]32 + [char]34 + $MSI + [char]34 + [char]32 + $Switches
	Write-Host "Install"$DisplayName.Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		Exit $ErrCode
	}
}

function Stop-Processes {
<#
	.SYNOPSIS
		Stops a process or processes
	
	.DESCRIPTION
		Will close all processes with the name specified in the ProcessName parameter
	
	.PARAMETER ProcessName
		Name of the Process to close. Do not include the file extension.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[String]$ProcessName
	)
	
	$Processes = Get-Process $ProcessName -ErrorAction SilentlyContinue
	If ($Processes -ne $null) {
		Do {
			foreach ($Process in $Processes) {
				If ($Process.Product -ne $null) {
					Write-Host "Killing"(($Process.Product).ToString()).Trim()"Process ID"(($Process.Id).ToString()).Trim()"....." -NoNewline
					Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
					Start-Sleep -Milliseconds 250
					$Process = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
					If ($Process -eq $null) {
						Write-Host "Success" -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
			$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
		} While ($Process -ne $null)
	}
}

function Uninstall-MSIByName {
<#
	.SYNOPSIS
		Uninstall-MSIByName
	
	.DESCRIPTION
		Uninstalls an MSI application using the MSI file
	
	.PARAMETER ApplicationName
		Display Name of the application. This can be part of the name or all of it. By using the full name as displayed in Add/Remove programs, there is far less chance the function will find more than one instance.
	
	.PARAMETER Switches
		MSI switches to control the behavior of msiexec.exe when uninstalling the application.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[String]$ApplicationName,
		[ValidateNotNullOrEmpty()]
		[String]$Switches
	)
	
	#MSIEXEC.EXE
	$Executable = $Env:windir + "\system32\msiexec.exe"
	Do {
		#Get list of all Add/Remove Programs for 32-Bit and 64-Bit
		$Uninstall = Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue -Force
		$Uninstall += Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
		#Find the registry containing the application name specified in $ApplicationName
		$Key = $uninstall | foreach-object {
			Get-ItemProperty REGISTRY::$_
		} | where-object {
			$_.DisplayName -like "*$ApplicationName*"
		}
		If ($Key -ne $null) {
			Write-Host "Uninstall"$Key[0].DisplayName"....." -NoNewline
			#Define msiexec.exe parameters to use with the uninstall
			$Parameters = "/x " + $Key[0].PSChildName + [char]32 + $Switches
			#Execute the uninstall of the MSI
			$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
			#Return the success/failure to the display
			If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
			}
		}
	} While ($Key -ne $null)
}

#Get the relative path this script is being executed from
$RelativePath = Get-RelativePath
#Kill all necessay processes
Stop-Processes -ProcessName 'DesktopApp'
Stop-Processes -ProcessName 'winword'
Stop-Processes -ProcessName 'excel'
Stop-Processes -ProcessName 'outlook'
Stop-Processes -ProcessName 'powerpnt'
#Uninstall Applications
Uninstall-MSIByName -ApplicationName 'OutlookAddInInstaller' -Switches '/qb- /norestart'
Uninstall-MSIByName -ApplicationName 'PingDesktopApp' -Switches '/qb- /norestart'
