<#
	.SYNOPSIS
		Install SCCM Client
	
	.DESCRIPTION
		Uninstall any old client and install the new SCCM client
	
	.PARAMETER Build
		Select if this is being executed while building a reference image
	
	.PARAMETER ClientInstallationDirectory
		Directory where the client ClientInstallationFile is located
	
	.PARAMETER ClientInstallationFile
		SCCM ClientInstallationFile
	
	.PARAMETER Install
		A description of the Install parameter.
	
	.PARAMETER ManagementPoint
		SCCM Management Point
	
	.PARAMETER SMSSiteCode
		SMS Site Code
	
	.PARAMETER Uninstall
		A description of the Uninstall parameter.
	
	.PARAMETER UsePKICert
		Specifies whether clients use PKI certificate when available
	
	.PARAMETER NOCRLCheck
		Specifies that clients do not check the certificate revocation list (CRL) for site systems
	
	.PARAMETER Source
		Specifies the source location from which to download installation files. This can  be a local or UNC path.
	
	.EXAMPLE
		New installation
		powershell.exe -executionpolicy bypass -file SCCMClient.ps1 -Install
		
		Uninstall
		powershell.exe -executionpolicy bypass -file SCCMClient.ps1 -Uninstall
		
		SCCM/MDT/Sysprep
		powershell.exe -executionpolicy bypass -file SCCMClient.ps1 -Build
		powershell.exe -executionpolicy bypass -file SCCMClient.ps1 -Install -Build
	
	.NOTES
		The above examples do not include the $ClientInstallationDirectory and
		the $ClientInsallationFile. I prepopulated the data within the parameter
		definitions below. I also define the $ManagementPoint and $SMSSiteCode. I
		have not tested the $UsePKICert, $NOCRLCheck, or $Source fields as we do
		not use those where I work, therefore I cannot verify if they are valid.

		===========================================================================
		 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
		 Created on:   	8/2/2016 2:50 PM
 		 Created by:   	Mick Pletcher
 		 Organization: 	 
 		 Filename:     	SCCMClientInstaller.ps1
		===========================================================================

#>
[CmdletBinding()]
param
(
	[switch]
	$Build,
	[ValidateNotNullOrEmpty()][string]
	$ClientInstallationDirectory = '',
	[ValidateNotNullOrEmpty()][string]
	$ClientInstallationFile = 'ccmsetup.exe',
	[switch]
	$Install,
	[string]
	$ManagementPoint = '',
	[string]
	$SMSSiteCode = '',
	[switch]
	$Uninstall,
	[switch]
	$UsePKICert,
	[switch]
	$NOCRLCheck,
	[string]
	$Source
)


function Get-MetaData {
<#
	.SYNOPSIS
		Get File MetaData
	
	.DESCRIPTION
		A detailed description of the Get-MetaData function.
	
	.PARAMETER FileName
		Name of File
	
	.EXAMPLE
		PS C:\> Get-MetaData -FileName 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$FileName
	)
	
	Write-Host "Retrieving File Description Data....." -NoNewline
	$MetaDataObject = New-Object System.Object
	$shell = New-Object -COMObject Shell.Application
	$folder = Split-Path $FileName
	$file = Split-Path $FileName -Leaf
	$shellfolder = $shell.Namespace($folder)
	$shellfile = $shellfolder.ParseName($file)
	$MetaDataProperties = 0..287 | Foreach-Object { '{0} = {1}' -f $_, $shellfolder.GetDetailsOf($null, $_) }
	For ($i = 0; $i -le 287; $i++) {
		$Property = ($MetaDataProperties[$i].split("="))[1].Trim()
		$Property = (Get-Culture).TextInfo.ToTitleCase($Property).Replace(' ', '')
		$Value = $shellfolder.GetDetailsOf($shellfile, $i)
		If ($Property -eq 'Attributes') {
			switch ($Value) {
				'A' {
					$Value = 'Archive (A)'
				}
				'D' {
					$Value = 'Directory (D)'
				}
				'H' {
					$Value = 'Hidden (H)'
				}
				'L' {
					$Value = 'Symlink (L)'
				}
				'R' {
					$Value = 'Read-Only (R)'
				}
				'S' {
					$Value = 'System (S)'
				}
			}
		}
		#Do not add metadata fields which have no information
		If (($Value -ne $null) -and ($Value -ne '')) {
			$MetaDataObject | Add-Member -MemberType NoteProperty -Name $Property -Value $Value
		}
	}
	[string]$FileVersionInfo = (Get-ItemProperty $FileName).VersionInfo
	$SplitInfo = $FileVersionInfo.Split([char]13)
	foreach ($Item in $SplitInfo) {
		$Property = $Item.Split(":").Trim()
		switch ($Property[0]) {
			"InternalName" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name InternalName -Value $Property[1]
			}
			"OriginalFileName" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name OriginalFileName -Value $Property[1]
			}
			"Product" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Product -Value $Property[1]
			}
			"Debug" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Debug -Value $Property[1]
			}
			"Patched" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name Patched -Value $Property[1]
			}
			"PreRelease" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name PreRelease -Value $Property[1]
			}
			"PrivateBuild" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name PrivateBuild -Value $Property[1]
			}
			"SpecialBuild" {
				$MetaDataObject | Add-Member -MemberType NoteProperty -Name SpecialBuild -Value $Property[1]
			}
		}
	}
	
	#Check if file is read-only
	$ReadOnly = (Get-ChildItem $FileName) | Select-Object IsReadOnly
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name ReadOnly -Value $ReadOnly.IsReadOnly
	#Get digital file signature information
	$DigitalSignature = get-authenticodesignature -filepath $FileName
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateSubject -Value $DigitalSignature.SignerCertificate.Subject
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateIssuer -Value $DigitalSignature.SignerCertificate.Issuer
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateSerialNumber -Value $DigitalSignature.SignerCertificate.SerialNumber
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateNotBefore -Value $DigitalSignature.SignerCertificate.NotBefore
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateNotAfter -Value $DigitalSignature.SignerCertificate.NotAfter
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureCertificateThumbprint -Value $DigitalSignature.SignerCertificate.Thumbprint
	$MetaDataObject | Add-Member -MemberType NoteProperty -Name SignatureStatus -Value $DigitalSignature.Status
	If (($MetaDataObject -ne "") -and ($MetaDataObject -ne $null)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
	Return $MetaDataObject
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
		$DisplayName
	)
	
	If ($Install.IsPresent) {
		Write-Host "Initiating Installation of"$DisplayName"....." -NoNewline
		$File = $env:windir + "\ccmsetup\ccmsetup.exe"
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
		If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
			Write-Host "Success" -ForegroundColor Yellow
			If ((Test-Path $File) -eq $true) {
				Wait-ProcessEnd -ProcessName ccmsetup
			} else {
				Write-Host "Failed" -ForegroundColor Red
				$Failed = $true
			}
		} else {
			Write-Host "Failed with error"$ErrCode -ForegroundColor Red
		}
	} elseif ($Uninstall.IsPresent) {
		Write-Host "Uninstalling"$DisplayName"....." -NoNewline
		$File = $env:windir + "\ccmsetup\ccmsetup.exe"
		If ((Test-Path $File) -eq $true) {
			$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
			If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
				Write-Host "Success" -ForegroundColor Yellow
				If ((Test-Path $File) -eq $true) {
					Wait-ProcessEnd -ProcessName ccmsetup
				}
			} else {
				$Failed = $true
				Write-Host "Failed with error"$ErrCode -ForegroundColor Red
			}
		} else {
			Write-Host "Not Present" -ForegroundColor Green
		}
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Remove-File {
<#
	.SYNOPSIS
		Delete a file with verification
	
	.DESCRIPTION
		Delete a file and verify the file no longer exists
	
	.PARAMETER Filename
		Name of the file to delete
	
	.EXAMPLE
		PS C:\> Remove-File -Filename 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Filename
	)
	
	If ((Test-Path $Filename) -eq $false) {
		Write-Host $Filename" already deleted"
	} else {
		$File = Get-Item $Filename -Force
		Write-Host "Deleting"$File.Name"....." -NoNewline
		If (Test-Path $File) {
			Remove-Item $File -Force -WarningAction SilentlyContinue -ErrorAction SilentlyContinue | Out-Null
			If ((Test-Path $Filename) -eq $False) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				$Failed = $true
				Write-Host "Failed" -ForegroundColor Red
			}
		} else {
			Write-Host "Not Present" -ForegroundColor Green
		}
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Remove-RegistryKey {
<#
	.SYNOPSIS
		Delete registry key
	
	.DESCRIPTION
		Delete a registry key. If recurse is selected, all subkeys and values are deleted
	
	.PARAMETER RegistryKey
		Registry key to delete
	
	.PARAMETER Recurse
		Include all subkeys when deleting the registry key
	
	.EXAMPLE
		PS C:\> Remove-RegistryKey -RegistryKey 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$RegistryKey,
		[switch]
		$Recurse
	)
	
	$RegKey = "Registry::" + $RegistryKey
	If ((Test-Path $RegKey) -eq $false) {
		Write-Host $RegKey" already deleted"
	} else {
		$RegKeyItem = Get-Item $RegKey
		If ($Recurse.IsPresent) {
			Write-Host "Recursive Deletion of"$RegKeyItem.PSChildName"....." -NoNewline
			Remove-Item $RegKey -Recurse -Force | Out-Null
		} else {
			Write-Host "Deleting"$RegKeyItem.PSChildName"....." -NoNewline
			Remove-Item $RegKey -Force | Out-Null
		}
		If ((Test-Path $RegKey) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			$Failed = $true
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Set-ConsoleTitle {
<#
	.SYNOPSIS
		Console Title
	
	.DESCRIPTION
		Sets the title of the PowerShell Console
	
	.PARAMETER ConsoleTitle
		Title of the PowerShell Console
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][String]
		$ConsoleTitle
	)
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

function Suspend-Service {
<#
	.SYNOPSIS
		Stop specified service
	
	.DESCRIPTION
		Stop a specified service and verify it is stopped
	
	.PARAMETER Service
		Name of the service
	
	.EXAMPLE
		PS C:\> Suspend-Service -Service 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$Service
	)
	
	$ServiceStatus = Get-Service $Service -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
	If ($ServiceStatus -ne $null) {
		Write-Host "Stopping"$ServiceStatus.DisplayName"....." -NoNewline
		If ($ServiceStatus.Status -ne 'Stopped') {
			Stop-Service -Name $Service -WarningAction SilentlyContinue -ErrorAction SilentlyContinue -Force
			$ServiceStatus = Get-Service $Service -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
			If ($ServiceStatus.Status -eq 'Stopped') {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				$Failed = $true
				Write-Host "Failed" -ForegroundColor Red
			}
		} else {
			Write-Host "Service already stopped" -ForegroundColor Yellow
		}
	} else {
		Write-Host $Service"service does not exist"
	}
	If ($Failed -eq $true) {
		Return $false
	} else {
		Return $true
	}
}

function Wait-ProcessEnd {
<#
	.SYNOPSIS
		Wait for a process to end
	
	.DESCRIPTION
		Pause the script until a process no longer exists
	
	.PARAMETER ProcessName
		Name of the process
	
	.EXAMPLE
				PS C:\> Wait-ProcessEnd -ProcessName 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$ProcessName
	)
	
	$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
	$Process = $Process | Where-Object { $_.ProcessName -eq $ProcessName }
	Write-Host "Waiting for"$Process.Product"to complete....." -NoNewline
	If ($Process -ne $null) {
		Do {
			Start-Sleep -Seconds 2
			$Process = Get-Process $ProcessName -ErrorAction SilentlyContinue
			$Process = $Process | Where-Object { $_.ProcessName -eq $ProcessName }
		}
		While ($Process -ne $null)
		Write-Host "Completed" -ForegroundColor Yellow
	} else {
		Write-Host "Process already completed" -ForegroundColor Yellow
	}
}

cls
#Set the name of the powershell console
Set-ConsoleTitle -ConsoleTitle "SCCM Client"
#Skip over if the install directory and installer file are not defined
If ($ClientInstallationDirectory -ne $null) {
	If ($ClientInstallationFile -ne $null) {
		If ($ClientInstallationDirectory[$ClientInstallationDirectory.Length - 1] -ne '\') {
			$ClientInstallationDirectory += '\'
		}
		#Set the location and filename of the SCCM client installer
		$File = $ClientInstallationDirectory + $ClientInstallationFile
		#Get metadata from the SCCM client installer file
		$FileMetaData = Get-MetaData -FileName $File
	}
}
#Install parameter is defined
If ($Install.IsPresent) {
	#Uninstall the SCCM client
	$Parameters = "/uninstall"
	$InstallStatus = Invoke-EXE -Uninstall -DisplayName $FileMetaData.Product -Executable $File -Switches $Parameters
	If ($InstallStatus = $false) {
		$Failed = $true
	}
	#Install the SCCM client
	$Parameters = ""
	If (($ManagementPoint -ne $null) -and ($ManagementPoint -ne "")) {
		$Parameters += "/mp:" + $ManagementPoint
	}
	If (($SMSSiteCode -ne $null) -and ($SMSSiteCode -ne "")) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "SMSSITECODE=" + $SMSSiteCode
	}
	If ($UsePKICert.IsPresent) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "/UsePKICert"
	}
	If ($NOCRLCheck.IsPresent) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "/NOCRLCheck"
	}
	If (($Source -ne $null) -and ($Source -ne "")) {
		If ($Parameters -ne "") {
			$Parameters += [char]32
		}
		$Parameters += "/source:" + [char]34 + $Source + [char]34
	}
	$InstallStatus = Invoke-EXE -Install -DisplayName $FileMetaData.Product -Executable $File -Switches $Parameters
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
	#Uninstall parameter is defined
} elseif ($Uninstall.IsPresent) {
	#Uninstall the SCCM client
	$Parameters = "/Uninstall"
	$InstallStatus = Invoke-EXE -Uninstall -DisplayName $FileMetaData.Product -Executable $File -Switches $Parameters
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
}
#Build parameter is defined
If ($Build.IsPresent) {
	#Stop the configuration manager client service
	$InstallStatus = Suspend-Service -Service ccmexec
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
	#Delete the smscfg.ini file
	$InstallStatus = Remove-File -Filename $env:windir"\smscfg.ini"
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
	#Delete the SCCM certificates from the registry
	$InstallStatus = Remove-RegistryKey -RegistryKey "HKEY_LOCAL_MACHINE\Software\Microsoft\SystemCertificates\SMS\Certificates" -Recurse
	If ($InstallStatus -eq $false) {
		$Failed = $true
	}
}
If ($Failed -eq $true) {
	$wshell = New-Object -ComObject Wscript.Shell
	$wshell.Popup("Installation Failed", 0, "Installation Failed", 0x0)
	Exit 1
} else {
	Exit 0
}
