<#
	.SYNOPSIS
		Bitlocker Recovery Key
	
	.DESCRIPTION
		This script gives the ability to backup the bitlocker recovery key to active directory, SCCM, and/or a network share. If AD is selected, it will query active directory for the latest bitlocker recovery key. Next, it will retrieve the bitlocker recovery key from the local system and then compare the keys to make sure it is backed up to active directory. If SCCM is selected, it will publish the status if the key is backed up to AD and if -SCCMBitlocker Password is selected, it will backup that password to SCCM. It can also backup to a network share if -NetworkShare is selected for admins that do not have SCCM. 
	
	.PARAMETER ActiveDirectory
		Select this to specify the backing up the recovery password to active directory
	
	.PARAMETER NetworkShare
		Specifies to create a text file (<Computer Name>.txt) on the network share specified in parameter -NetworkSharePath. -NetworkShare is intended for admins who do not have SCCM.
	
	.PARAMETER NetworkSharePath
		UNC path where to store the text files containing the bitlocker recovery keys.
	
	.PARAMETER SCCMBitlockerPassword
		Select this switch if you want the bitlocker password reported to SCCM
	
	.PARAMETER SCCMReporting
		Report bitlocker recovery key to SCCM
	
	.EXAMPLE
		Backup recovery password to active directory
			powershell.exe -file BitlockerRecoveryKey.ps1 -ActiveDirectory

		Backup recovery password to active directory and SCCM
			powershell.exe -file BitlockerRecoveryKey.ps1 -ActiveDirectory -SCCMReporting -SCCMBitlockerPassword

		Backup recovery password to active directory and report AD backup status to SCCM
			powershell.exe -file BitlockerRecoveryKey.ps1 -ActiveDirectory -SCCMReporting

		Backup recovery password to network share
			powershell.exe -file BitlockerRecoveryKey.ps1 -NetworkShare -NetworkSharePath "\\UNC Path\Directory"

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.129
		Created on:   	11/14/2016 1:18 PM
		Created by:	Mick Pletcher
		Organization:
		Filename:	BitlockerRecoveryKey.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[switch]$ActiveDirectory,
	[switch]$NetworkShare,
	[string]$NetworkSharePath,
	[switch]$SCCMBitlockerPassword,
	[switch]$SCCMReporting
)
Import-Module ActiveDirectory

Function Get-BitLockerRecoveryKeyId {
	
	<#
	.SYNOPSIS
	This returns the Bitlocker key protector id.
	
	.DESCRIPTION
	The key protectorID is retrived either according to the protector type, or simply all of them.
	
	.PARAMETER KeyProtectorType
	
	The key protector type can have one of the following values :
	*TPM
	*ExternalKey
	*NumericPassword
	*TPMAndPin
	*TPMAndStartUpdKey
	*TPMAndPinAndStartUpKey
	*PublicKey
	*PassPhrase
	*TpmCertificate
	*SID
	
	
	.EXAMPLE
	
	Get-BitLockerRecoveryKeyId
	Returns all the ID's available from all the different protectors.

    .EXAMPLE

        Get-BitLockerRecoveryKeyId -KeyProtectorType NumericPassword
        Returns the ID(s) of type NumericPassword


	.NOTES
		Version: 1.0
        Author: Stephane van Gulick
        Creation date:12.08.2014
        Last modification date: 12.08.2014

	.LINK
		www.powershellDistrict.com

	.LINK
		http://social.technet.microsoft.com/profile/st%C3%A9phane%20vg/

    .LINK
        #http://msdn.microsoft.com/en-us/library/windows/desktop/aa376441(v=vs.85).aspx
#>	
	
	[cmdletBinding()]
	Param (
			[Parameter(Mandatory = $false, ValueFromPipeLine = $false)][ValidateSet("Alltypes", "TPM", "ExternalKey", "NumericPassword", "TPMAndPin", "TPMAndStartUpdKey", "TPMAndPinAndStartUpKey", "PublicKey", "PassPhrase", "TpmCertificate", "SID")]$KeyProtectorType
	)
	
	$BitLocker = Get-WmiObject -Namespace "Root\cimv2\Security\MicrosoftVolumeEncryption" -Class "Win32_EncryptableVolume"
	switch ($KeyProtectorType) {
		("Alltypes") { $Value = "0" }
		("TPM") { $Value = "1" }
		("ExternalKey") { $Value = "2" }
		("NumericPassword") { $Value = "3" }
		("TPMAndPin") { $Value = "4" }
		("TPMAndStartUpdKey") { $Value = "5" }
		("TPMAndPinAndStartUpKey") { $Value = "6" }
		("PublicKey") { $Value = "7" }
		("PassPhrase") { $Value = "8" }
		("TpmCertificate") { $Value = "9" }
		("SID") { $Value = "10" }
		default { $Value = "0" }
	}
	$Ids = $BitLocker.GetKeyProtectors($Value).volumekeyprotectorID
	return $ids
}

function Get-ADBitlockerRecoveryKeys {
<#
	.SYNOPSIS
		Retrieve Active Directory Recovery Keys
	
	.DESCRIPTION
		Get a list of all bitlocker recovery keys in active directory.
	
	.EXAMPLE
		PS C:\> Get-ADBitlockerRecoveryKeys
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#Get Active Directory computer information
	$ComputerName = $env:COMPUTERNAME
	$ADComputer = Get-ADComputer -Filter { Name -eq $ComputerName }
	#Get Bitlocker recovery keys
	$ADBitLockerRecoveryKeys = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase $ADComputer.DistinguishedName -Properties 'msFVE-RecoveryPassword'
	Return $ADBitLockerRecoveryKeys
}

function Get-BitlockerPassword {
<#
	.SYNOPSIS
		Get Bitlocker Password
	
	.DESCRIPTION
		Retrieve the bitlocker password of the specified protector ID
	
	.PARAMETER ProtectorID
		Key protector ID
	
	.EXAMPLE
		PS C:\> Get-BitlockerPassword -ProtectorID 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$ProtectorID
	)
	
	$Password = manage-bde -protectors -get ($env:ProgramFiles).split("\")[0] -id $ProtectorID | Where-Object { $_.trim() -ne "" }
	$Password = $Password[$Password.Length - 1].Trim()
	Return $Password
}

function Initialize-HardwareInventory {
<#
	.SYNOPSIS
		Perform Hardware Inventory
	
	.DESCRIPTION
		Perform a hardware inventory via the SCCM client to report the WMI entry.
	
#>
	
	[CmdletBinding()]
	param ()
	
	$Output = "Initiate SCCM Hardware Inventory....."
	$SMSCli = [wmiclass] "\\localhost\root\ccm:SMS_Client"
	$ErrCode = ($SMSCli.TriggerSchedule("{00000000-0000-0000-0000-000000000001}")).ReturnValue
	If ($ErrCode -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Invoke-ADBitlockerRecoveryPasswordCleanup {
<#
	.SYNOPSIS
		Cleanup Active Directory Bitlocker Recovery Passwords
	
	.DESCRIPTION
		This function will cleanup bitlocker recovery passwords that are no longer valid.
	
	.PARAMETER LocalPassword
		Bitlocker password of the local machine
	
	.PARAMETER ADPassword
		Bitlocker Passwords stored in active directory
	
	.EXAMPLE
		PS C:\> Invoke-ADBitlockerRecoveryPasswordCleanup
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$LocalPassword,
		[ValidateNotNullOrEmpty()]$ADPassword
	)
	
	foreach ($Password in $ADPassword) {
		If ($LocalPassword -ne $Password.'msFVE-RecoveryPassword') {
			Remove-ADObject -Identity $Password.DistinguishedName -Confirm:$false
		}
	}
}

function Invoke-EXE {
<#
	.SYNOPSIS
		Execute the executable
	
	.DESCRIPTION
		Execute the executable
	
	.PARAMETER DisplayName
		A description of the DisplayName parameter.
	
	.PARAMETER Executable
		A description of the Executable parameter.
	
	.PARAMETER Switches
		A description of the Switches parameter.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[String]$DisplayName,
		[String]$Executable,
		[String]$Switches
	)
	
	Write-Host "Uploading"$DisplayName"....." -NoNewline
	#Test if executable is present
	If ((Test-Path $Executable) -eq $true) {
		#Execute the executable
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}
}

function New-WMIClass {
<#
	.SYNOPSIS
		Create New WMI Class
	
	.DESCRIPTION
		This will delete the specified WMI class if it already exists and create/recreate the class.
	
	.PARAMETER Class
		A description of the Class parameter.
	
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
	$Output = "Creating " + $Class + " WMI class....."
	$newClass = New-Object System.Management.ManagementClass("root\cimv2", [string]::Empty, $null);
	$newClass["__CLASS"] = $Class;
	$newClass.Qualifiers.Add("Static", $true)
	$newClass.Properties.Add("ADBackup", [System.Management.CimType]::Boolean, $false)
	$newClass.Properties["ADBackup"].Qualifiers.Add("key", $true)
	$newClass.Properties["ADBackup"].Qualifiers.Add("read", $true)
	$newClass.Properties.Add("RecoveryPassword", [System.Management.CimType]::string, $false)
	$newClass.Properties["RecoveryPassword"].Qualifiers.Add("key", $true)
	$newClass.Properties["RecoveryPassword"].Qualifiers.Add("read", $true)
	$newClass.Put() | Out-Null
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If ($WMITest -eq $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
		Exit 1
	}
	Write-Output $Output
}

function New-WMIInstance {
<#
	.SYNOPSIS
		Write new instance
	
	.DESCRIPTION
		Write a new instance reporting the last time the system was rebooted
	
	.PARAMETER ADBackup
		Boolean value specifying if the bitlocker recovery key is backed up to active directory
	
	.PARAMETER Class
		WMI Class
	
	.PARAMETER RecoveryPassword
		Bitlocker recovery password
	
	.PARAMETER LastRebootTime
		Date/time the system was last rebooted
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][boolean]$ADBackup,
		[ValidateNotNullOrEmpty()][string]$Class,
		[ValidateNotNullOrEmpty()][string]$RecoveryPassword
	)
	
	$Output = "Writing Bitlocker instance to" + [char]32 + $Class + [char]32 + "class....."
	$Return = Set-WmiInstance -Class $Class -Arguments @{ ADBackup = $ADBackup; RecoveryPassword = $RecoveryPassword }
	If ($Return -like "*" + $ADBackup + "*") {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Publish-RecoveryPasswordToActiveDirectory {
<#
	.SYNOPSIS
		Publish Bitlocker Recovery Password
	
	.DESCRIPTION
		Publish Bitlocker recovery password to active directory.
	
	.PARAMETER BitlockerID
		Bitlocker Recovery ID that contains the Bitlocker recovery password
	
	.EXAMPLE
		PS C:\> Publish-RecoveryPasswordToActiveDirectory
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$BitlockerID
	)
	
	#Define location of manage-bde.exe
	$ManageBDE = $env:windir + "\System32\manage-bde.exe"
	#Define the ManageBDE parameters to backup the Bitlocker recovery password to
	$Switches = "-protectors -adbackup" + [char]32 + ($env:ProgramFiles).split("\")[0] + [char]32 + "-id" + [char]32 + $BitlockerID
	Invoke-EXE -DisplayName "Backup Recovery Key to AD" -Executable $ManageBDE -Switches $Switches
}

function Remove-WMIClass {
<#
	.SYNOPSIS
		Delete WMIClass
	
	.DESCRIPTION
		Delete the WMI class from system
	
	.PARAMETER Class
		Name of WMI class to delete
	
	.EXAMPLE
				PS C:\> Remove-WMIClass
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Class
	)
	
	$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
	If (($WMITest -ne "") -and ($WMITest -ne $null)) {
		$Output = "Deleting " + $Class + " WMI class....."
		Remove-WmiObject $Class
		$WMITest = Get-WmiObject $Class -ErrorAction SilentlyContinue
		If ($WMITest -eq $null) {
			$Output += "Success"
		} else {
			$Output += "Failed"
			Exit 1
		}
		Write-Output $Output
	}
}

Clear-Host
#Retrieve numerical password ID
[string]$BitlockerID = Get-BitLockerRecoveryKeyId -KeyProtectorType NumericPassword
#Retrieve Bitlocker recovery password from the local system
[string]$BitlockerPassword = Get-BitlockerPassword -ProtectorID $BitlockerID
#Backup bitlocker password to active directory is parameter is selected
If ($ActiveDirectory.IsPresent) {
	#Retrieve the bitlocker recovery password(s) from active directory
	$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
	#Check if bitlocker password exists. If not, push to active directory
	If ($ADBitlockerPassword -ne $null) {
		#Check if it is a single password which the AD backup does not match the password on the system, or an array of passwords
		If ((($ADBitlockerPassword -is [Microsoft.ActiveDirectory.Management.ADObject]) -and ($ADBitlockerPassword.'msFVE-RecoveryPassword' -ne $BitlockerPassword)) -or ($ADBitlockerPassword -isnot [Microsoft.ActiveDirectory.Management.ADObject])) {
			#Delete all bitlocker recovery passwords that do not match the password on the local machine
			Invoke-ADBitlockerRecoveryPasswordCleanup -LocalPassword $BitlockerPassword -ADPassword $ADBitlockerPassword
			#Get the password stored in AD after the cleanup
			$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
			#If the AD password does not exist, or does not match the local password, publish the new AD Bitlocker password
			If (($ADBitlockerPassword.'msFVE-RecoveryPassword' -ne $BitlockerPassword) -or ($ADBitlockerPassword -eq $null)) {
				#Push the local bitlocker password to AD
				Publish-RecoveryPasswordToActiveDirectory -BitlockerID $BitlockerID
				#Retrieve the bitlocker recovery password from active directory
				$ADBitlockerPassword = $null
				$Count = 1
				#Wait until the bitlocker password is in active directory
				Do {
					$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
					Start-Sleep -Seconds 1
					$Count += 1
				} while (($ADBitlockerPassword -eq $null) -or ($Count -lt 30))
			}
		}
	} else {
		Publish-RecoveryPasswordToActiveDirectory -BitlockerID $BitlockerID
		#Retrieve the bitlocker recovery password from active directory
		$ADBitlockerPassword = $null
		$Count = 1
		#Wait until the bitlocker password is in active directory
		Do {
			$ADBitlockerPassword = Get-ADBitlockerRecoveryKeys
			Start-Sleep -Seconds 1
			$Count += 1
		} while (($ADBitlockerPassword -eq $null) -and ($Count -lt 30))
	}
}
#Publish data to SCCM
If ($SCCMReporting.IsPresent) {
	New-WMIClass -Class Bitlocker_Reporting
	If ($ADBitlockerPassword.'msFVE-RecoveryPassword' -eq $BitlockerPassword) {
		If ($SCCMBitlockerPassword.IsPresent) {
			New-WMIInstance -ADBackup $true -Class Bitlocker_Reporting -RecoveryPassword $BitlockerPassword
		} else {
			New-WMIInstance -ADBackup $true -Class Bitlocker_Reporting -RecoveryPassword " "
		}
	} else {
		If ($SCCMBitlockerPassword.IsPresent) {
			New-WMIInstance -ADBackup $false -Class Bitlocker_Reporting -RecoveryPassword $BitlockerPassword
		} else {
			New-WMIInstance -ADBackup $false -Class Bitlocker_Reporting -RecoveryPassword " "
		}
	}
	#Initialize SCCM hardware inventory to force a reporting of the Bitlocker_Reporting class to SCCM
	Initialize-HardwareInventory
} else {
	Remove-WMIClass -Class Bitlocker_Reporting
}
#Publish data to Network Share
If ($NetworkShare.IsPresent) {
	#Test if the $NetworkSharePath is defined and available
	If ((Test-Path $NetworkSharePath) -eq $true) {
		#Define the file to write the recovery key to
		If ($NetworkSharePath[$NetworkSharePath.Length - 1] -ne "\") {
			$File = $NetworkSharePath + "\" + $env:COMPUTERNAME + ".txt"
		} else {
			$File = $NetworkSharePath + $env:COMPUTERNAME + ".txt"
		}
		#Delete the file containing the recovery key if it exists
		If ((Test-Path $File) -eq $true) {
			$Output = "Deleting $env:COMPUTERNAME.txt file....."
			Remove-Item -Path $File -Force
			If ((Test-Path $File) -eq $false) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		}
		#Create new text file
		If ((Test-Path $File) -eq $false) {
			$Output = "Creating $env:COMPUTERNAME.txt file....."
			New-Item -Path $File -ItemType File -Force | Out-Null
			If ((Test-Path $File) -eq $true) {
				Add-Content -Path $File -Value $BitlockerPassword
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
			Write-Output $Output
		}
	}
}
#Display output to the screen
Write-Output " "
$Output = "                  Bitlocker ID: " + $BitlockerID
Write-Output $Output
$Output = "   Bitlocker Recovery Password: " + $BitlockerPassword
Write-Output $Output
$Output = "AD Bitlocker Recovery Password: " + $ADBitlockerPassword.'msFVE-RecoveryPassword' + [char]13
Write-Output $Output
