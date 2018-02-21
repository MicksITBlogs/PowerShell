<#
	.SYNOPSIS
		Uninstall MSI Application by its Name
	
	.DESCRIPTION
		Here is a function that will uninstall an MSI installed application by the name of the app. You do not need to input the entire name either. For instance, say you are uninstalling all previous versions of Adobe Reader. Adobe Reader is always labeled Adobe Reader X, Adobe Reader XI, and so forth. This script allows you to do this without having to find out every version that is installed throughout a network and then enter an uninstaller line for each version. You just need to enter Adobe Reader as the application name and the desired switches. It will then search the name fields in the 32 and 64 bit uninstall registry keys to find the associated GUID. Finally, it will execute an msiexec.exe /x {GUID} to uninstall that version. This revision allows for the function to uninstall more than one app if multiple versions are installed. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	2/21/2018 1:20 PM
		Created by:   	Mick Pletcher
		Filename:     	UninstallMSIByName.ps1
		===========================================================================
#>

[CmdletBinding()]
param ()

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
		$Uninstall = Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue -Force
		$Uninstall += Get-ChildItem REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ErrorAction SilentlyContinue
		#Find the registry containing the application name specified in $ApplicationName
		$Key = $uninstall | foreach-object { Get-ItemProperty REGISTRY::$_ } | where-object { $_.DisplayName -like "*$ApplicationName*" }
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

#Example where there might be both x86 and x64 versions of Java installed and you need both uninstalled
Uninstall-MSIByName -ApplicationName "Java 8" -Switches "/qb- /norestart"
