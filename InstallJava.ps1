<#
	.SYNOPSIS
		Install Oracle Java
	
	.DESCRIPTION
		Uninstall the old version of Java and then install the new version.
	
	.PARAMETER Parameters
		Java installation parameters
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	2/20/2018 10:53 AM
		Created by:   	Mick Pletcher
		Filename:		InstallJava.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[string]$Parameters = 'INSTALL_SILENT=Enable AUTO_UPDATE=Disable WEB_JAVA=Enable WEB_ANALYTICS=Disable EULA=Disable REBOOT=Disable'
)

function Get-Architecture {
<#
	.SYNOPSIS
		Get-Architecture
	
	.DESCRIPTION
		Returns whether the system architecture is 32-bit or 64-bit
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
		[ValidateNotNullOrEmpty()][String]$ApplicationName,
		[ValidateNotNullOrEmpty()][String]$Switches
	)
	
	#MSIEXEC.EXE
	$Executable = $Env:windir + "\system32\msiexec.exe"
	Do {
		#Get list of all Add/Remove Programs for 32-Bit and 64-Bit
		$Uninstall =  Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue -Force
		$Uninstall += Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
		#Find the registry containing the application name specified in $ApplicationName
		$Key = $uninstall | foreach-object { Get-ItemProperty REGISTRY::$_ -ErrorAction SilentlyContinue} | where-object { $_.DisplayName -like "*$ApplicationName*" }
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

$Architecture = Get-Architecture
$RelativePath = Get-RelativePath
#Uninstall previous version(s) of Java
Uninstall-MSIByName -ApplicationName "Java 6" -Switches "/qb- /norestart"
Uninstall-MSIByName -ApplicationName "Java 7" -Switches "/qb- /norestart"
Uninstall-MSIByName -ApplicationName "Java 8" -Switches "/qb- /norestart"
$Javax86 = $RelativePath + (Get-ChildItem -Path $RelativePath -Filter "*i586*").Name
$Javax64 = $RelativePath + (Get-ChildItem -Path $RelativePath -Filter "*x64*").Name
If ($Architecture -eq "32-Bit") {
	Install-EXE -DisplayName "Java Runtime Environment x86" -Executable $Javax86 -Switches $Parameters
} else {
	Install-EXE -DisplayName "Java Runtime Environment x86" -Executable $Javax86 -Switches $Parameters
	Install-EXE -DisplayName "Java Runtime Environment x64" -Executable $Javax64 -Switches $Parameters
	
}
