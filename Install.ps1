<#
	.SYNOPSIS
		Install NetDocuments
	
	.DESCRIPTION
		This script will install NetDocuments. It is setup so that it can be used to install a new copy of NetDocuments, or be used to upgrade a single component of NetDocuments.
	
	.PARAMETER ConsoleTitle
		Title of the PowerShell console
	
	.PARAMETER Build
		Specifies a fresh installation
	
	.PARAMETER Install
		Install NetDocuments
	
	.PARAMETER Uninstall
		Uninstall NetDocuments
	
	.PARAMETER Upgrade
		Uninstall applications that do not match applications being deployed and install the latest version
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
		Created on:   	9/8/2016 10:41 AM
		Created by:
		Organization:
		Filename:
		===========================================================================
#>
[CmdletBinding()]
param
(
	[string]
	$ConsoleTitle = 'NetDocuments Installation',
	[switch]
	$Build,
	[switch]
	$Install,
	[switch]
	$Uninstall,
	[switch]
	$Upgrade
)

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

function Invoke-EXE {
<#
	.SYNOPSIS
		Install or Uninstall Executable
	
	.DESCRIPTION
		A detailed description of the Invoke-EXE function.
	
	.PARAMETER InstallerMetaData
		The metadata extracted from the executable
	
	.PARAMETER Install
		Specify to Install the application
	
	.PARAMETER Uninstall
		Specify to uninstall the application
	
	.PARAMETER Executable
		The installation file for installing the application
	
	.PARAMETER Switches
		Switches to control the executable file
	
	.PARAMETER DisplayName
		Name to be displayed while installing or uninstalling the application
	
	.PARAMETER ReturnSuccessFailure
		Specifies if the function should return a true/false on the success of the task.
	
	.EXAMPLE
		PS C:\> Invoke-EXE
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[object]
		$InstallerMetaData,
		[switch]
		$Install,
		[switch]
		$Uninstall,
		[ValidateNotNullOrEmpty()][string]
		$Executable,
		[string]
		$Switches,
		[string]
		$DisplayName,
		[switch]
		$ReturnSuccessFailure
	)
	
	$Success = $true
	If ($Install.IsPresent) {
		$Output = "Installing $DisplayName....."
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			$Success = $false
		}
	} elseif ($Uninstall.IsPresent) {
		$Output = "Uninstalling $DisplayName....."
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			$Success = $false
		}
	}
	Write-ToDisplay -Output $Output
	If ($ReturnSuccessFailure.IsPresent) {
		Return $Success
	}
}

function Invoke-MSI {
<#
	.SYNOPSIS
		Invoke-MSIFileName
	
	.DESCRIPTION
		Installs or Uninstalls an MSIFileName packaged application
	
	.PARAMETER DisplayName
		A description of the DisplayName parameter.
	
	.PARAMETER Install
		Install the MSI
	
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
	
	.PARAMETER Repair
		Repair the application
	
	.PARAMETER Uninstall
		Uninstall the MSI
	
	.PARAMETER UninstallByName
		Uninstall the application by its Application name. The add/remove programs will be searched in the registry for a DisplayName to match the UninstallByName. It gets the associated GUID to initiate an uninstall.
	
	.PARAMETER ReturnSuccessFailure
		Specifies if the function should return a true/false on the success of the task
	
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
		$UninstallByName,
		[switch]
		$ReturnSuccessFailure
	)
	
	##############################################################################
	##############################################################################
	
	$Success = $true
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
		$Output = "Installing$DisplayName....."
	} elseif ($Uninstall.IsPresent) {
		If ($GUID -ne "") {
			$Parameters = "/x" + [char]32 + $GUID
			$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		} else {
			$Parameters = "/x" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
			$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		}
		If ($DisplayName -ne "") {
			$Output = "Uninstalling$DisplayName....."
		} else {
			$Output = "Uninstalling $GUID....."
		}
	} elseif ($UninstallByName.IsPresent) {
		$Uninstaller = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse -ErrorAction SilentlyContinue
		If ($OSArchitecture.OSArchitecture -eq "64-Bit") {
			$Uninstaller += Get-ChildItem "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Recurse -ErrorAction SilentlyContinue
		}
		$SearchName = "*" + $DisplayName + "*"
#		[String]$GUID = ($Uninstaller | ForEach-Object { Get-ItemProperty REGISTRY::$_ } | Where-Object { $_.DisplayName -like $SearchName }).PSChildName
		$GUID = (($Uninstaller | ForEach-Object { Get-ItemProperty REGISTRY::$_ } | Where-Object { $_.DisplayName -like $SearchName }).PSChildName).Trim()
		If ($GUID -like "*} {*") {
			[array]$GUID = $GUID.Split(" ")
		}
		If ($GUID -ne "") {
			foreach ($Item in $GUID) {
				$Parameters = "/x" + [char]32 + $Item
				$DisplayName = Get-DisplayNameFromRegistry -GUID $Item
				If ($DisplayName -ne "") {
					$Output = "Uninstalling $DisplayName....."
				} else {
					$Output = "Uninstalling $GUID....."
				}
			}
		} else {
			Return $Success
		}
	} elseif ($Repair.IsPresent) {
		If ($GUID -ne "") {
			$Parameters = "/faumsv" + [char]32 + $GUID
			$DisplayName = Get-DisplayNameFromRegistry -GUID $GUID
		} else {
			$Parameters = "/faumsv" + [char]32 + [char]34 + $MSIFilePath + $MSIFileName + [char]34
			$DisplayName = Get-MSIDatabase -Property "ProductName" -MSI $MSIFileName -Path $MSIFilePath
		}
		$Output = "Repairing $DisplayName....."
	} else {
		$Output = "Specify to install, repair, or uninstall the MSI"
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
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
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
				$Output += "Success"
			} else {
				$Output += "Failed"
				$Success = $false
			}
		} elseif (($Uninstall.IsPresent) -or ($UninstallByName.IsPresent)) {
			If ($ProductCode -in $Registry.PSChildName) {
				$Output += "Failed"
				$Success = $false
			} else {
				$Output += "Success"
			}
		}
	} else {
		$Output += "Failed"
		$Success = $false
	}
	Write-ToDisplay -Output $Output
	If ($ReturnSuccessFailure.IsPresent) {
		Return $Success
	}
}

function Invoke-MSIEXEC {
	[CmdletBinding()]
	param
	(
		[switch]
		$Logging,
		[string]
		$Parameters,
		[string]
		$DisplayName
	)
	
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
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
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
				$Output += "Success"
			} else {
				$Output += "Failed"
				$Success = $false
			}
		} elseif (($Uninstall.IsPresent) -or ($UninstallByName.IsPresent)) {
			If ($ProductCode -in $Registry.PSChildName) {
				$Output += "Failed"
				$Success = $false
			} else {
				$Output += "Success"
			}
		}
	} else {
		$Output += "Failed"
		$Success = $false
	}
	Write-ToDisplay -Output $Output
	If ($ReturnSuccessFailure.IsPresent) {
		Return $Success
	}
}

function Set-ConsoleTitle {
<#
	.SYNOPSIS
		Console Title
	
	.DESCRIPTION
		Sets the title of the PowerShell Console
	
	.PARAMETER Title
		Title of the PowerShell Console
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][String]
		$Title
	)
	
	$host.ui.RawUI.WindowTitle = $Title
}

function Remove-File {
<#
	.SYNOPSIS
		Remove-File
	
	.DESCRIPTION
		Deletes a specific file
	
	.PARAMETER File
		Name and location of the file to delete
	
	.EXAMPLE
		Remove-File "c:\temp\Test.ps1"
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$File
	)
	
	If ((Test-Path $File) -eq $true) {
		$File = Get-Item $File
		$Output = "Delete" + [char]32 + $File.Name + "....."
		Remove-Item $File.FullName -Force
		$File = Get-Item $File -ErrorAction SilentlyContinue
		If ($File -eq $null) {
			$Output += "Success"
		} else {
			$Output += "Failed"
		}
		Write-ToDisplay -Output $Output
	} else {
		$File = $File.Split("\")
		$Output = $File[$File.Length-1] + [char]32 + "not present"
		Write-Output -InputObject $Output
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
	
	.EXAMPLE
		Stop-ProcessName "outlook"
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[ValidateNotNullOrEmpty()][String]$ProcessName
	)
	
	$Processes = Get-Process $ProcessName -ErrorAction SilentlyContinue
	If ($Processes -ne $null) {
		Do {
			foreach ($Process in $Processes) {
				If ($Process.Product -ne $null) {
					Write-Host "Killing"(($Process.Product).ToString()).Trim()"Process ID"(($Process.Id).ToString()).Trim()"....." -NoNewline
					Stop-Process -Id $Process.Id -Force -ErrorAction SilentlyContinue
					Start-Sleep -Seconds 2
					$Process = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
					If ($Process -eq $null) {
						Write-Host "Success" -ForegroundColor Yellow
					} else {
						Write-Host "Failed" -ForegroundColor Red
					}
				}
			}
			$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
		}
		While ($Process -ne $null)
	}
}

function Write-ToDisplay {
<#
	.SYNOPSIS
		Output Success/Failure to Display
	
	.DESCRIPTION
		Write the output to the Display color coded yellow for success and red for failure
	
	.PARAMETER Output
		Data to display to the screen
	
	.EXAMPLE
				PS C:\> Write-ToDisplay -Output 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Output
	)
	
	$OutputSplit = (($Output.Replace(".", " ")).Replace("     ", ".")).Split(".")
	Write-Host $OutputSplit[0]"....." -NoNewline
	If ($OutputSplit[1] -like "*Success*") {
		Write-Host $OutputSplit[1] -ForegroundColor Yellow
	} elseif ($OutputSplit[1] -like "*Fail*") {
		Write-Host $OutputSplit[1] -ForegroundColor Red
	}
}

function Read-Status {
<#
	.SYNOPSIS
		Process Return Status
	
	.DESCRIPTION
		Exit out of script if the return status of a function is false
	
	.PARAMETER ReturnStatus
		Boolean return status
	
	.PARAMETER ExitCode
		Exit code value to return when the script is exited
	
	.EXAMPLE
		PS C:\> Read-Status -ReturnStatus $value1
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][boolean]
		$ReturnStatus,
		[ValidateNotNullOrEmpty()][int]
		$ExitCode
	)
	
	If ($ReturnStatus -eq $false) {
		Exit $ExitCode
	}
}

function Compare-MSIWithInstalledApps {
<#
	.SYNOPSIS
		Compare MSI with Installed Apps
	
	.DESCRIPTION
		This finds the corresponding Add/Remove programs registry entry with the metadata of the MSI file to verify if they match.
	
	.PARAMETER AppName
		The name to search the registry for. The name can be partial so that it can search across versions so long as they have a commonality.
	
	.PARAMETER MSIFile
		Name of the MSI file to extract metadata from
	
	.EXAMPLE
		PS C:\> Compare-MSIWithInstalledApps -AppName 'Value1' -MSIFile 'Value2'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$AppName,
		[ValidateNotNullOrEmpty()][string]
		$MSIFile
	)
	
	$Architecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	$Registry = Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
	If ($Architecture -eq "64-bit") {
		$Registry += Get-ChildItem Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall
	}
	$SearchName = "*" + $AppName + "*"
	$Application = $Registry | ForEach-Object { Get-ItemProperty REGISTRY::$_ } | Where-Object { $_.DisplayName -like $SearchName }
	$MSIVersion = ([string](Get-MSIDatabase -MSI $MSIFile -Property "ProductVersion")).Trim()
	If ($MSIVersion -notin $Application.DisplayVersion) {
		$Status = Invoke-MSI -Uninstall -GUID $Application.PSChildName -Switches "/qb- /norestart" -ReturnSuccessFailure
		Read-Status -ReturnStatus $Status -ExitCode 5
		Return $false
	} else {
		Return $true
	}
}

cls
#Set the PowerShell console title
Set-ConsoleTitle -Title $ConsoleTitle
#Get Relative Path of this script
$RelativePath = Get-RelativePath
$Architecture = Get-Architecture
If ($Architecture -eq "32-Bit") {
	$ProgramFiles = $env:ProgramFiles
} else {
	$ProgramFiles = ${env:ProgramFiles(x86)}
}
#Stop processes
Stop-Processes -ProcessName Acrobat
Stop-Processes -ProcessName AcroRd32
Stop-Processes -ProcessName Chrome
Stop-Processes -ProcessName Excel
Stop-Processes -ProcessName Firefox
Stop-Processes -ProcessName Iexplore
Stop-Processes -ProcessName msiexec
Stop-Processes -ProcessName ndOffice
Stop-Processes -ProcessName Outlook
Stop-Processes -ProcessName Powerpnt
Stop-Processes -ProcessName Winword
#Build Installation
If ($Build.IsPresent) {
	#Install Microsoft Visual Studio Tools for Office Runtime 2010
	$Status = Invoke-EXE -DisplayName "Microsoft Visual Studio Tools for Office Runtime 2010" -Install -Executable $RelativePath"vstor_redist.exe" -Switches "/passive /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install Document Activation
	$Status = Invoke-MSI -Install -MSIFileName "newebcl.msi" -MSIFilePath $RelativePath"DocumentActivation" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install EMS Profiler
	$Status = Invoke-MSI -Install -MSIFileName "emsProfSetup.msi" -MSIFilePath $RelativePath"emsProfiler" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install EMS Folders
	$Status = Invoke-MSI -Install -MSIFileName "emssetup.msi" -MSIFilePath $RelativePath"emsFolders" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install ndOffice
	$Status = Invoke-MSI -Install -MSIFileName "ndOfficeAdministrativeSetup.msi" -MSIFilePath $RelativePath"ndOffice" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
}
If ($Install.IsPresent) {
	#Delete Acrobat and Reader ndOffice plugins
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 10.0\Acrobat\plug_ins\ndAcrobat.api"
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 10.0\Acrobat\plug_ins\ndAcrobat.api.config"
	Remove-File -File "$ProgramFiles\Adobe\Reader 10.0\Reader\plug_ins\ndReader.api"
	Remove-File -File "$ProgramFiles\Adobe\Reader 10.0\Reader\plug_ins\ndReader.api.config"
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 11.0\Acrobat\plug_ins\ndAcrobat.api"
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 11.0\Acrobat\plug_ins\ndAcrobat.api.config"
	Remove-File -File "$ProgramFiles\Adobe\Reader 11.0\Reader\plug_ins\ndReader.api"
	Remove-File -File "$ProgramFiles\Adobe\Reader 11.0\Reader\plug_ins\ndReader.api.config"
	#Uninstall NetDocuments Application Integrations
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments Application Integrations" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall Document Activation
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments Document Activation" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall EMS Folders
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments EMS Folders" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall EMS Profiler
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments EMS Profiler" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall ndOffice
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments ndOffice" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install Microsoft Visual Studio Tools for Office Runtime 2010
	$Status = Invoke-EXE -DisplayName "Microsoft Visual Studio Tools for Office Runtime 2010" -Install -Executable $RelativePath"vstor_redist.exe" -Switches "/passive /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install Document Activation
	$Status = Invoke-MSI -Install -MSIFileName "newebcl.msi" -MSIFilePath $RelativePath"DocumentActivation" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install EMS Profiler
	$Status = Invoke-MSI -Install -MSIFileName "emsProfSetup.msi" -MSIFilePath $RelativePath"emsProfiler" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install EMS Folders
	$Status = Invoke-MSI -Install -MSIFileName "emssetup.msi" -MSIFilePath $RelativePath"emsFolders" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Install ndOffice
	$Status = Invoke-MSI -Install -MSIFileName "ndOfficeAdministrativeSetup.msi" -MSIFilePath $RelativePath"ndOffice" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
}
If ($Uninstall.IsPresent) {
	#Delete Acrobat and Reader ndOffice plugins
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 10.0\Acrobat\plug_ins\ndAcrobat.api"
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 10.0\Acrobat\plug_ins\ndAcrobat.api.config"
	Remove-File -File "$ProgramFiles\Adobe\Reader 10.0\Reader\plug_ins\ndReader.api"
	Remove-File -File "$ProgramFiles\Adobe\Reader 10.0\Reader\plug_ins\ndReader.api.config"
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 11.0\Acrobat\plug_ins\ndAcrobat.api"
	Remove-File -File "$ProgramFiles\Adobe\Acrobat 11.0\Acrobat\plug_ins\ndAcrobat.api.config"
	Remove-File -File "$ProgramFiles\Adobe\Reader 11.0\Reader\plug_ins\ndReader.api"
	Remove-File -File "$ProgramFiles\Adobe\Reader 11.0\Reader\plug_ins\ndReader.api.config"
	#Uninstall NetDocuments Application Integrations
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments Application Integrations" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall Document Activation
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments Document Activation" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall EMS Folders
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments EMS Folders" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall EMS Profiler
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments EMS Profiler" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
	#Uninstall ndOffice
	$Status = Invoke-MSI -UninstallByName -DisplayName "NetDocuments ndOffice" -Switches "/qb- /norestart" -ReturnSuccessFailure
	Read-Status -ReturnStatus $Status -ExitCode 5
}
If ($Upgrade.IsPresent) {
	#Upgrade Document Activation
	$Installed = Compare-MSIWithInstalledApps -AppName "NetDocuments Document Activation" -MSIFile $RelativePath"\DocumentActivation\newebcl.msi"
	If ($Installed -eq $false) {
		$Status = Invoke-MSI -Install -MSIFileName "newebcl.msi" -MSIFilePath $RelativePath"DocumentActivation" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
		Read-Status -ReturnStatus $Status -ExitCode 5
	}
	#Upgrade EMS Folders
	$Installed = Compare-MSIWithInstalledApps -AppName "NetDocuments EMS Folders" -MSIFile $RelativePath"\emsFolders\emssetup.msi"
	If ($Installed -eq $false) {
		$Status = Invoke-MSI -Install -MSIFileName "emssetup.msi" -MSIFilePath $RelativePath"emsFolders" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
		Read-Status -ReturnStatus $Status -ExitCode 5
	}
	#Upgrade EMS Profiler
	$Installed = Compare-MSIWithInstalledApps -AppName "NetDocuments EMS Profiler" -MSIFile $RelativePath"\emsProfiler\emsprofsetup.msi"
	If ($Installed -eq $false) {
		$Status = Invoke-MSI -Install -MSIFileName "emsProfSetup.msi" -MSIFilePath $RelativePath"emsProfiler" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
		Read-Status -ReturnStatus $Status -ExitCode 5
	}
	#Upgrade ndOffice
	$Installed = Compare-MSIWithInstalledApps -AppName "NetDocuments ndOffice" -MSIFile $RelativePath"\ndOffice\ndOfficeAdministrativeSetup.msi"
	If ($Installed -eq $false) {
		$Status = Invoke-MSI -Install -MSIFileName "ndOfficeAdministrativeSetup.msi" -MSIFilePath $RelativePath"ndOffice" -Switches "/qb- /norestart ALLUSERS=1" -ReturnSuccessFailure
		Read-Status -ReturnStatus $Status -ExitCode 5
	}
}
#Perform Group Policy Update
If (($Install.IsPresent) -or ($Upgrade.IsPresent) -or ($Build.IsPresent)) {
	Invoke-EXE -Install -DisplayName "Group Policy Update" -Executable $env:windir"\System32\gpupdate.exe" -Switches " "
}
