<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.125
	 Created on:   	7/22/2016 2:56 PM
	 Created by:   	Mick Pletcher
	 Filename:     	Invoke-MSI.ps1
	===========================================================================
#>

function Invoke-MSI {
<#
	.SYNOPSIS
		Invoke-MSIFileName
	
	.DESCRIPTION
		Installs or Uninstalls an MSIFileName packaged application
	
	.PARAMETER DisplayName
		A description of the DisplayName parameter.
	
	.PARAMETER LogDirectory
		Directory where the log file is to be written to
	
	.PARAMETER Logging
		Designates if logging will take place. The logs are written to the temporary directory of the profile in which this PowerShell script is executed under.
	
	.PARAMETER MSIFileName
		name of the MSIFileName to install
	
	.PARAMETER MSIFilePath
		Directory where the MSIFileName file resides. If this is left blank, the relative MSIFilePath of the script will be used.
	
	.PARAMETER Switches
		MSIFileName switches to use during the installation
	
	.PARAMETER GUID
		Product code associated with the currently installed application that used an MSIFileName for installation
	
	.PARAMETER UninstallByName
		Uninstall the application by its Application name. The add/remove programs will be searched in the registry for a DisplayName to match the UninstallByName. It gets the associated GUID to initiate an uninstall.
	
	.PARAMETER Install
		Install the MSI
	
	.PARAMETER Uninstall
		Uninstall the MSI
	
	.PARAMETER Repair
		Repair the application
	
	.EXAMPLE
		Install application when it resides within the same directory as this script
			Invoke-MSI -Install -MSIFileName "ndOfficeSetup.msi" -Switches "ADDLOCAL=Word,Excel,PowerPoint,Outlook,AdobeAcrobatIntegration,AdobeReaderIntegration /qb- /norestart"

		Install application using a different directory
			Invoke-MSI -Install -MSIFileName "ndOfficeSetup.msi" -MSIFilePath "\\Netdocuments\ndoffice" -Switches "ADDLOCAL=Word,Excel,PowerPoint,Outlook,AdobeAcrobatIntegration,AdobeReaderIntegration /qb- /norestart"
	
		Repair application by its GUID
			Invoke-MSI -Repair -GUID "{A67CA551-ADAE-4C9B-B09D-38D84044FAB8}"
	
		Repair application by its msi when it resides in the same directory as this script
			Invoke-MSI -Repair -MSIFileName "ndOfficeSetup.msi"

		Uninstall application by name as it appears in add/remove programs without logging
			Invoke-MSI -UninstallByName "ndOffice"
	
		Uninstall application by name as it appears in add/remove programs with logging
			Invoke-MSI -UninstallByName "ndOffice" -Logging
	
		Uninstall application by GUID
			Invoke-MSI -Uninstall -GUID "{0F3FBC9C-A8DC-4C7A-A888-730F14CC7D05}"
	
		Uninstall application using the MSI installer file located in the same directory as this script
			Invoke-MSI -Uninstall -MSIFileName "ndOfficeSetup.msi"

	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[string]
		$DisplayName,
		[switch]
		$Install,
		[string]
		$LogDirectory,
		[switch]
		$Logging,
		[ValidateNotNullOrEmpty()][String]
		$MSIFileName,
		[string]
		$MSIFilePath,
		[ValidateNotNullOrEmpty()][String]
		$Switches = '/qb- /norestart',
		[string]
		$GUID,
		[switch]
		$Repair,
		[switch]
		$Uninstall,
		[switch]
		$UninstallByName
	)
	
	function Get-MSIDatabase {
	<#
		.SYNOPSIS
			Retrieve Data from MSIDatabase
		
		.DESCRIPTION
			Query the MSI database to retrieve the specified information from the Property table
		
		.PARAMETER Property
			Property to retrieve
		
		.PARAMETER MSI
			Name of the MSI installer
		
		.PARAMETER Path
			Directory where the MSI resides
		
		.EXAMPLE
			PS C:\> Get-MSIDatabase
		
		.NOTES
			Additional information about the function.
	#>
		
		[CmdletBinding()][OutputType([string])]
		param
		(
			[ValidateNotNullOrEmpty()][string]
			$Property,
			[ValidateNotNullOrEmpty()][string]
			$MSI,
			[ValidateNotNullOrEmpty()][string]
			$Path
		)
		
		#Get the MSI file info
		$MSIFile = Get-Item $Path$MSI
		#Specify the ProductName field to retrieve from the MSI database
		try {
			#Load the windows installer object for viewing the MSI database
			$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
			#Get the MSI database of the specified MSI file
			$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIFile.FullName, 0))
			#Define the query for the ProductName withing the Property table
			$Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"
			#Query the property table within the MSI database
			$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
			$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
			$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
			#Assign the ProductName to the $DisplayName variable
			$DataField = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
			Return $DataField
		} catch {
			Write-Output $_.Exception.Message
			Exit 1
		}
	}
	
	function Get-DisplayNameFromRegistry {
	<#
		.SYNOPSIS
			Get Registry DisplayName
		
		.DESCRIPTION
			Retrieve the DisplayName of the application from the registry
		
		.PARAMETER GUID
			Product code associated with the currently installed application that used an MSIFileName for installation
		
		.EXAMPLE
			PS C:\> Get-DisplayNameFromRegistry
		
		.NOTES
			Additional information about the function.
	#>
		
		[CmdletBinding()][OutputType([string])]
		param
		(
			[ValidateNotNullOrEmpty()][string]
			$GUID
		)
		
		#Get system architecture -- 32-bit or 64-Bit
		$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
		#Get the add/remove program entries from the registry
		$Registry = Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
		If ($OSArchitecture.OSArchitecture -eq "64-bit") {
			$Registry += Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
		}
		#Find the add/remove program entry for the specific GUID
		$Registry = $Registry | Where-Object { $_.PSChildName -eq $GUID }
		#Format the Registry name for the Get-ItemProperty
		$Registry = "Registry::" + $Registry.Name
		#Get the registry values for the GUID registry entry
		$Registry = Get-ItemProperty $Registry -ErrorAction SilentlyContinue
		#Retrieve the application display name
		$DisplayName = $Registry.DisplayName
		Return $DisplayName
	}
	
	#Get the system architecture -- 32-bit or 64-bit
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	#Path to msiexec.exe
	$Executable = $Env:windir + "\system32\msiexec.exe"
	#Unless $Path is assigned a value, use the relative path of this PowerShell script where the MSI is located
	If ($MSIFilePath -eq "") {
		If (($GUID -eq $null) -or ($GUID -eq "")) {
			$MSIFilePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
		}
	} else {
		If ($MSIFilePath[$MSIFilePath.Length - 1] -ne '\') {
			$MSIFilePath += '\'
		}
	}
	If ($Install.IsPresent) {
		$Parameters = "/i" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
		$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		Write-Host "Installing"$DisplayName"....." -NoNewline
	} elseif ($Uninstall.IsPresent) {
		If ($GUID -ne "") {
			$Parameters = "/x" + [char]32 + $GUID
			$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		} else {
			$Parameters = "/x" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
			$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		}
		If ($DisplayName -ne "") {
			Write-Host "Uninstalling"$DisplayName"....." -NoNewline
		} else {
			Write-Host "Uninstalling"$GUID"....." -NoNewline
		}
	} elseif ($UninstallByName.IsPresent) {
		$Uninstaller = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse -ErrorAction SilentlyContinue
		If ($OSArchitecture.OSArchitecture -eq "64-Bit") {
			$Uninstaller += Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse -ErrorAction SilentlyContinue
		}
		$SearchName = "*" + $DisplayName + "*"
		$IdentifyingNumber = get-wmiobject win32_product | where-object { $_.Name -like $SearchName }
		[string]$GUID = $IdentifyingNumber.IdentifyingNumber
		$Parameters = "/x" + [char]32 + $GUID
		$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		If ($DisplayName -ne "") {
			Write-Host "Uninstalling"$DisplayName"....." -NoNewline
		} else {
			Write-Host "Uninstalling"$GUID"....." -NoNewline
		}
	} elseif ($Repair.IsPresent) {
		If ($GUID -ne "") {
			$Parameters = "/faumsv" + [char]32 + $GUID
			$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		} else {
			$Parameters = "/faumsv" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
			$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		}
		Write-Host "Repairing"$DisplayName"....." -NoNewline
	} else {
		Write-Host "Specify to install, repair, or uninstall the MSI" -ForegroundColor Red
		Exit 1
	}
	#Add verbose logging to the parameters
	If ($Logging.IsPresent) {
		If ($LogDirectory -eq "") {
			$Parameters += [char]32 + "/lvx " + [char]34 + $env:TEMP + "\" + $DisplayName + ".log" + [char]34
		} else {
			If ($LogDirectory[$LogDirectory.count - 1] -ne "\") {
				$LogDirectory += "\"
			}
			$Parameters += [char]32 + "/lvx " + [char]34 + $LogDirectory + $DisplayName + ".log" + [char]34
		}
	}
	#Add Switches to MSIEXEC parameters
	$Parameters += [char]32 + $Switches
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -WindowStyle Minimized -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		If ($GUID -eq "") {
			[string]$ProductCode = Get-MSIDatabase -Property "ProductCode" -MSI $MSIFileName -Path $MSIFilePath
		} else {
			[string]$ProductCode = $GUID
		}
		$ProductCode = $ProductCode.Trim()
		$Registry = Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
		If ($OSArchitecture.OSArchitecture -eq "64-bit") {
			$Registry += Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
		}
		If (($Install.IsPresent) -or ($Repair.IsPresent)) {
			If ($ProductCode -in $Registry.PSChildName) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
			}
		} elseif (($Uninstall.IsPresent) -or ($UninstallByName.IsPresent)) {
			If ($ProductCode -in $Registry.PSChildName) {
				Write-Host "Failed" -ForegroundColor Red
			} else {
				Write-Host "Success" -ForegroundColor Yellow
			}
		}
	} elseif ($ErrCode -eq 1605) {
		Write-Host "Application already uninstalled" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
}

Invoke-MSI -Install -MSIFileName "ndOfficeSetup.msi" -Switches "ADDLOCAL=Word,Excel,PowerPoint,Outlook,AdobeAcrobatIntegration,AdobeReaderIntegration /qb- /norestart"
Invoke-MSI -Repair -GUID "{A67CA551-ADAE-4C9B-B09D-38D84044FAB8}"
Invoke-MSI -UninstallByName "ndOffice" -Logging
