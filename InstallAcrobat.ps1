<#
	.SYNOPSIS
		Adobe Acrobat
	
	.DESCRIPTION
		Install Acrobat
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	3/22/2018 2:26 PM
		Created by:   	Mick Pletcher
		Filename:     	InstallAcrobat.ps1
		===========================================================================
#>

[CmdletBinding()]
param ()


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
	
	.EXAMPLE
		PS C:\> Get-MSIInformation
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][System.IO.FileInfo]$MSI,
		[ValidateSet('ProductCode', 'ProductVersion', 'ProductName', 'Manufacturer', 'ProductLanguage', 'FullVersion')][string]$Property
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
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Install-EXE {
<#
	.SYNOPSIS
		Install Executable file
	
	.DESCRIPTION
		This function will install an executable file
	
	.PARAMETER Executable
		UNC path and name of executable to install
	
	.PARAMETER Switches
		Executable switches
	
	.PARAMETER DisplayName
		Application Name to display
	#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$DisplayName,
		[ValidateNotNullOrEmpty()][string]$Executable,
		[ValidateNotNullOrEmpty()][string]$Switches
	)
	
	Write-Host "Install"$DisplayName.Trim()"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		Exit $ErrCode
	}
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
		[ValidateNotNullOrEmpty()][string]$MSI,
		[ValidateNotNullOrEmpty()][string]$Switches
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
        
      .EXAMPLE  
           Uninstall-MSIByName "Adobe Reader" "/qb- /norestart"  
        
      .NOTES  
           Additional information about the function.  
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
	#Get list of all Add/Remove Programs for 32-Bit and 64-Bit  
	$Uninstall = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	If (((Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture) -eq "64-Bit") {
		$Uninstall += Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
	}
	#Find the registry containing the application name specified in $ApplicationName  
	$Key = $uninstall | foreach-object {
		Get-ItemProperty REGISTRY::$_
	} | where-object {
		$_.DisplayName -like "*$ApplicationName*"
	}
	If ($Key -ne $null) {
		Write-Host "Uninstall"$Key.DisplayName"....." -NoNewline
		#Define msiexec.exe parameters to use with the uninstall  
		$Parameters = "/x " + $Key.PSChildName + [char]32 + $Switches
		#Execute the uninstall of the MSI  
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
		#Return the success/failure to the display  
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		}
	}
}

$RelativePath = Get-RelativePath
Stop-Process -Name 'acrobat' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'Chrome' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'Excel' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'Firefox' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'iexplore' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'outlook' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'MicrosoftEdge' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'MicrosoftEdgeCP' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'MicrosoftEdgeSH' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'MicrosoftEdgeUpdateCrashHandler' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'MicrosoftEdgeUpdateCrashHandler64' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'powerpnt' -Force -ErrorAction SilentlyContinue
Stop-Process -Name 'winword' -Force -ErrorAction SilentlyContinue
If ((Test-Path ($env:HOMEDRIVE + '\MININT')) -eq $false) {
	#Uninstall Adobe Acrobat DC
	Uninstall-MSIByName -ApplicationName 'Adobe Acrobat DC' -Switches '/qb- /norestart'
}
#Install Adobe Acrobat DC
Install-EXE -DisplayName "Adobe Acrobat Professional DC" -Executable $RelativePath'Setup.exe' -Switches ' '
If ((Test-Path ($env:HOMEDRIVE + '\MININT')) -eq $false) {
	#Disable ndOffice Adobe Reader Integration
	Install-MSI -MSI ($RelativePath + 'Updates\ndOfficeSetup.msi') -Switches 'REMOVE=AdobeReaderIntegration /qb- /norestart'
	#Disable ndOffice Adobe Acrobat Integration
	Install-MSI -MSI ($RelativePath + 'Updates\ndOfficeSetup.msi') -Switches 'REMOVE=AdobeAcrobatIntegration /qb- /norestart'
	#Enable ndOffice Adobe Acrobat Integration
	Install-MSI -MSI ($RelativePath + 'Updates\ndOfficeSetup.msi') -Switches 'ADDLOCAL=AdobeAcrobatIntegration /qb- /norestart'
}
Install-EXE -DisplayName "GP Update" -Executable $env:windir"\System32\gpupdate.exe" -Switches " "
If ((Test-Path ($env:HOMEDRIVE + '\MININT')) -eq $false) {
	#Reboot System
	#Restart-Computer -Force
}
