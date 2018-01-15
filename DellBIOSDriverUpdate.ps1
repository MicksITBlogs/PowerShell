<#
	.SYNOPSIS
		Update the BIOS and Drivers
	
	.DESCRIPTION
		This script will update the BIOS, Applications, and Drivers. It can detect if it is running within the WinPE or Windows environments. If it is running within WinPE, it will only update the BIOS, otherwise it will run all updates.
	
	.PARAMETER WindowsRepository
		UNC path to the updates Windows Repository that is accessible if the operating system is present
	
	.PARAMETER BIOSPassword
		Password for the BIOS
	
	.PARAMETER BIOS
		Perform BIOS updates only
	
	.PARAMETER Drivers
		Perform drivers updates only
	
	.PARAMETER Applications
		Perform applications updates only
	
	.PARAMETER WinPERepository
		Path to the updates Windows Repository that is accessible if running within WinPE
	
	.EXAMPLE
		Running in Windows only and applying all updates
			powershell.exe -file DellBIOSDriverUpdate.ps1 -WindowsRepository "\\UNCPath2Repository"

		Running in WinPE Only
			powershell.exe -file DellBIOSDriverUpdate.ps1 -WinPERepository "t:"

		Running in both Windows and WinPE
			powershell.exe -file DellBIOSDriverUpdate.ps1 -WindowsRepository "\\UNCPath2Repository" -WinPERepository "t:"

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.140
		Created on:   	6/21/2017 3:16 PM
		Created by:   	Mick Pletcher 
		Filename:     	DellBIOSDriverUpdate.ps1
		===========================================================================
#>

param
(
	[string]$WindowsRepository,
	[string]$BIOSPassword,
	[switch]$BIOS,
	[switch]$Drivers,
	[switch]$Applications,
	[string]$WinPERepository
)

function Get-Architecture {
<#
	.SYNOPSIS
		Get-Architecture
	
	.DESCRIPTION
		Returns 32-bit or 64-bit
	
	.EXAMPLE
		Get-Architecture
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = (Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture).OSArchitecture
	Return $OSArchitecture
}

function Get-WindowsUpdateReport {
<#
	.SYNOPSIS
		Get list of updates to install
	
	.DESCRIPTION
		Execute the dcu-cli.exe to get a list of updates to install.
	
	.EXAMPLE
		PS C:\> Get-WindowsUpdateReport
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([xml])]
	param ()
	
	#Test if this is running in the WinPE environment
	If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
		$Executable = Get-ChildItem -Path "x:\DCU" -Filter dcu-cli.exe
		$ReportFile = "x:\DCU\DriverReport.xml"
	} else {
		$Architecture = Get-Architecture
		If ($Architecture -eq "32-Bit") {
			$Executable = Get-ChildItem -Path $env:ProgramFiles"\Dell\CommandUpdate" -Filter dcu-cli.exe
		} else {
			$Executable = Get-ChildItem -Path ${env:ProgramFiles(x86)}"\Dell\CommandUpdate" -Filter dcu-cli.exe
		}
		#Name and location of the report file
		If ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
			$ReportFile = $WindowsRepository + "\" + "DriverReport.xml"
		} else {
			$ReportFile = $WindowsRepository + "DriverReport.xml"
		}
	}
	#Delete XML report file if it exists
	If ((Test-Path -Path $ReportFile) -eq $true) {
		Remove-Item -Path $ReportFile -Force -ErrorAction SilentlyContinue
	}
	#Define location where to write the report
	$Switches = "/report" + [char]32 + $ReportFile
	#Get dcu-cli.exe report
	$ErrCode = (Start-Process -FilePath $Executable.FullName -ArgumentList $Switches -Wait -Passthru).ExitCode
	#Retrieve list of drivers if XML file exists
	If ((Test-Path -Path $ReportFile) -eq $true) {
		#Get the contents of the XML file
		[xml]$DriverList = Get-Content -Path $ReportFile
		Return $DriverList
	} else {
		Return $null
	}
}

function Get-WinPEUpdateReport {
<#
	.SYNOPSIS
		Get Dell Client Update Report
	
	.DESCRIPTION
		Execute the Dell Client | Update to generate the XML file listing available updates
	
	.EXAMPLE
		PS C:\> Get-WinPEUpdateReport
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#Define XML Report File
	$ReportFile = $env:SystemDrive + "\DCU\DriversReport.xml"
	#Delete XML Report file
	If ((Test-Path $ReportFile) -eq $true) {
		Remove-Item -Path $ReportFile -Force | Out-Null
	}
	#Define Dell Client | Update commandline executable
	$Executable = $env:SystemDrive + "\DCU\dcu-cli.exe"
	#Define switches for Dell Client | Update
	$Switches = "/report" + [char]32 + $ReportFile
	#Execute Dell Client | Update
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	#Retrieve list of drivers if XML file exists
	If ((Test-Path -Path $ReportFile) -eq $true) {
		#Get the contents of the XML file
		[xml]$DriverList = Get-Content -Path $ReportFile
		Return $DriverList
	} else {
		Return $null
	}
}

function Update-Repository {
<#
	.SYNOPSIS
		Update the repository
	
	.DESCRIPTION
		This function reads the list of items to be installed and checks the repository to make sure the item is present. If it is not, the item is downloaded to the repository.
	
	.PARAMETER Updates
		List of Updates to be installed
	
	.EXAMPLE
		PS C:\> Update-Repository
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	#Set the variable to the to the repository
	If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
		If ($WinPERepository[$WinPERepository.Length - 1] -ne "\") {
			$Repository = $WinPERepository + "\"
		} else {
			$Repository = $WinPERepository
		}
	} elseif ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		#Define the storage location of this driver
		$UpdateRepository = $Repository + $Update.Release
		#Get the URI to download the file from
		$DownloadURI = $Update.file
		$DownloadFileName = $UpdateRepository + "\" + ($DownloadURI.split("/")[-1])
		#Create the new directory if it does not exist
		If ((Test-Path $UpdateRepository) -eq $false) {
			New-Item -Path $UpdateRepository -ItemType Directory -Force | Out-Null
		}
		#Download file if it does not exist
		If ((Test-Path $DownloadFileName) -eq $false) {
			Invoke-WebRequest -Uri $DownloadURI -OutFile $DownloadFileName
		}
	}
}

function Update-Applicatons {
<#
	.SYNOPSIS
		Update Dell Applications
	
	.DESCRIPTION
		This function only updates Dell Applications
	
	.PARAMETER Updates
		List of updates to install
	
	.EXAMPLE
		PS C:\> Update-Applicatons
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	if ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		#Check if update is a application update
		If ($Update.type -eq "Application") {
			#Get application update file
			$UpdateFile = $Repository + $Update.Release + "\" + (($Update.file).split("/")[-1])
			#Verify application update file exists
			If ((Test-Path $UpdateFile) -eq $true) {
				$Output = "Installing " + $Update.name + "....."
				Write-Host $Output -NoNewline
				# /s to suppress user interface
				$Switches = "/s"
				$ErrCode = (Start-Process -FilePath $UpdateFile -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
				If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
					Write-Host "Success" -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
	}
}

function Update-BIOS {
<#
	.SYNOPSIS
		Update the BIOS
	
	.DESCRIPTION
		This function will update the BIOS on the system
	
	.PARAMETER Updates
		List of updates to install
	
	.PARAMETER Update
		XML info of the BIOS update
	
	.EXAMPLE
		PS C:\> Update-BIOS
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	#Set the variable to the to the repository
	If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
		If ($WinPERepository[$WinPERepository.Length - 1] -ne "\") {
			$Repository = $WinPERepository + "\"
		} else {
			$Repository = $WinPERepository
		}
	} elseif ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		#Check if update is a BIOS update
		If ($Update.type -eq "BIOS") {
			#Get BIOS update file
			$UpdateFile = $Repository + $Update.Release + "\" + (($Update.file).split("/")[-1])
			#Verify BIOS update file exists
			If ((Test-Path $UpdateFile) -eq $true) {
				$Output = "Installing " + $Update.name + "....."
				Write-Host $Output -NoNewline
				# /s to suppress user interface
				$Switches = "/s /p=" + $BIOSPassword
				$ErrCode = (Start-Process -FilePath $UpdateFile -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
				If (($ErrCode -eq 0) -or ($ErrCode -eq 2) -or ($ErrCode -eq 3010)) {
					Write-Host "Success" -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
	}
}

function Update-Drivers {
<#
	.SYNOPSIS
		Update Dell Drivers
	
	.DESCRIPTION
		This function only updates Dell drivers
	
	.PARAMETER Updates
		List of updates to install
	
	.EXAMPLE
		PS C:\> Update-Drivers
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Updates
	)
	
	if ($WindowsRepository[$WindowsRepository.Length - 1] -ne "\") {
		$Repository = $WindowsRepository + "\"
	} else {
		$Repository = $WindowsRepository
	}
	foreach ($Update in $Updates.Updates.Update) {
		#Check if update is a application update
		If ($Update.type -eq "Driver") {
			#Get driver update file
			$UpdateFile = $Repository + $Update.Release + "\" + (($Update.file).split("/")[-1])
			$UpdateFile = Get-ChildItem -Path $UpdateFile
			#Verify driver update file exists
			If ((Test-Path $UpdateFile) -eq $true) {
				$Output = "Installing " + $Update.name + "....."
				Write-Host $Output -NoNewline
				# /s to suppress user interface
				$Switches = "/s"
				$ErrCode = (Start-Process -FilePath $UpdateFile.Fullname -ArgumentList $Switches -WindowStyle Minimized -Passthru).ExitCode
				$Start = Get-Date
				Do {
					$Process = (Get-Process | Where-Object { $_.ProcessName -eq $UpdateFile.BaseName }).ProcessName
					$Duration = (Get-Date - $Start).TotalMinutes
				} While (($Process -eq $UpdateFile.BaseName) -and ($Duration -lt 10))
				If (($ErrCode -eq 0) -or ($ErrCode -eq 2) -or ($ErrCode -eq 3010)) {
					Write-Host "Success" -ForegroundColor Yellow
				} else {
					Write-Host "Failed with error code $ErrCode" -ForegroundColor Red
				}
			}
		}
	}
}


Clear-Host
#Check if running in WinPE environment and get Windows Updates Report
If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
	$Updates = Get-WinPEUpdateReport
} Else {
	#Get list of drivers
	$Updates = Get-WindowsUpdateReport
}
$Updates.Updates.Update.Name
#Process drivers if there is a list
If ($Updates -ne $null) {
	Update-Repository -Updates $Updates
}
#Check if running in WinPE environment
If ((test-path -Path 'REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WinPE\') -eq $true) {
	#Perform BIOS Update
	Update-BIOS -Updates $Updates
} Else {
	#Install Applications (APP)
	If (($Applications.IsPresent) -or ((!($Applications.IsPresent)) -and (!($BIOS.IsPresent)) -and (!($Drivers.IsPresent)))) {
		Update-Applicatons -Updates $Updates
	}
	#Install BIOS (BIOS)
	If (($BIOS.IsPresent) -or ((!($Applications.IsPresent)) -and (!($BIOS.IsPresent)) -and (!($Drivers.IsPresent)))) {
		Update-BIOS -Updates $Updates
	}
	#Install Bundle (SBDL)
	#Install Drivers (DRVR)
	If (($Drivers.IsPresent) -or ((!($Applications.IsPresent)) -and (!($BIOS.IsPresent)) -and (!($Drivers.IsPresent)))) {
		Update-Drivers -Updates $Updates
	}
	#Install Firmware (FRMW)
	#Install ISV Driver (ISVDRVR)
}
