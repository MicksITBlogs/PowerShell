<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.99
	 Created on:   	1/28/2016 1:55 PM
	 Created by:   	Mick Pletcher 
	 Organization: 	 
	 Filename:     	BitlockerSAK_CheckTPM.ps1
	===========================================================================
	.DESCRIPTION
		This script will test if bitlocker is turned on, cleared, and 
		activated. It uses the BitLockerSAK function wirtten by Stéphane vg to
		check the ownership of Bitlocker. It also uses CCTK for testing
		the status of TPM.
#>

Function BitLockerSAK {
<#
.SYNOPSIS
	Get and set Bitlocker related information.
   
.DESCRIPTION
	Based on WMI classes, this function can achiev the following tasks :

    --TPM operations---
        -TPM activation state.
        -If the TPM is enabled or not.
        -If a TPM OwnerShip is Allowed.
        -If the TPM is currently owned.
        -The possibility to take the ownerShip

    --Encryption possibilities ---
        - Retrieves the current encryption method.
        - Get the current protection status.
        - The current protection state.
        - The possibility to encrypt a Drive.
        - The possibility to Resume an encryption that has been paused.
        - Possibility to return the current protector ID's.
        - Possibility to return the current protector type(s).
        - Retrieves the Volume key protector Passwords
   

.PARAMETER isTPMActivated
	Returns activation state of the TPM:
    Returns true if activated and false if not.

.PARAMETER isTPMEnabled
	Returns the enabled state of the TPM:
    Returns true if activated and false if not.

.PARAMETER IsTPMOwnerShipAllowed
    Returns if the TPM ownership is allowed.
    Returns true if allowed, false if not.

.PARAMETER ResumeEncryption
   Will resume an paused encryption.

.PARAMETER GetEncryptionState
    Returns the current encurrent state in an object as wolled : 

.PARAMETER GetProtectionStatus
    Returns the current protection status. It will return "Protected" if the drive is 100% encrypted, and "Unprotected" if anything else then "100% encrypted".

.PARAMETER Encrypt
    Will encrypt a drive.

.PARAMETER TakeTPMOwnerShip
    Returns true if allowed, false if not

.PARAMETER pin
    Is needed in order to take the ownership and to encrypt the drive.

.PARAMETER IsTPMOwned
    Returns true if owned, false if not

.PARAMETER GetKeyProtectorIds
    Returns all the protector id's available on the machine.

.PARAMETER GetKeyProtectorType
    Returns the type of protector that is currently in use.

.PARAMETER GetEncryptionMethod
    REturns the current encryption method that is in use.

.PARAMETER GetKeyProtectorNumericalPassword
    Returns a given numerical password based on a Protector ID value.
    The ProtectorID value is mandatory, and must be passed using the parameter VolumeKeyProtectorID.  

.PARAMETER VolumeKeyProtectorID
    This parameter will work only in conjunction with GetKeyProtectorNumericalPassword switch.
    It must contain the ProtectorID from which the desired Numerical Password will be returned.
		
.PARAMETER GetKeyProtectorTypeAndID
    The GetKeyProtectorTypeAndID switch will return all the existing key protector ID's and their type of the Keys existing on the machine.


.PARAMETER Whatif
	Permits to launch this script in "draft" mode. This means it will only show the results without really making generating the files.

.PARAMETER Verbose
	Allow to run the script in verbose mode for debbuging purposes.
   
.EXAMPLE

BitLockerSAK

Returns the current status of the drives.

IsTPMOwned                  : True
EncryptionMethod            : AES_128
IsTPMOwnerShipAllowed       : True
IsTPMActivated              : True
IsTPMEnabled                : True
CurrentEncryptionPercentage : 100
EncryptionState             : FullyEncrypted
ProtectorIds                : {{FFC19381-6E75-4D1E-94E9-D6E0D3E681FA}, {65AF5A93-9846-47AC-B3B1-D8DE6F06B780}}
KeyProtectorType            : {Numerical password, Trusted Platform Module (TPM)}

.EXAMPLE
 
BitLockerSAK -GetProtectionStatus

Returns the current protection status : Protected or unprotected

.EXAMPLE
 
BitLockerSAK -GetEncryptionState

CurrentEncryptionProgress is express in percentage. 

CurrentEncryptionProgress EncryptionState                                                                                      
------------------------- ---------------                                                                                      
                      100 FullyEncrypted
   
.EXAMPLE

Get all the key protectors and their respective ID's and protector types from the current machine.

BitLockerSAK -GetKeyProtectorTypeAndID

KeyProtectorID                                                                                      KeyProtectorType                                                                                   
--------------                                                                                      ----------------                                                                                   
{AB1535D4-ECB3-49D6-8AB1-E334A4F60579}                                                              Numerical password                                                                                 
{B1BDF8CD-55F2-4532-A93F-4B1AF4F22B55}                                                              Trusted Platform Module (TPM)

.EXAMPLE

Get the numerical password from a specefic Key using the ID.

BitLockerSAK -GetKeyProtectorNumericalPassword -VolumeKeyProtectorID "{AB1535D4-ECB3-49D6-8AB1-E334A4F60579}"

Message                                                            KeyProtectorNumericalPassword                                      VolumeKeyProtectorID                                             
-------                                                            -----------------------------                                      --------------------                                             
The method was successful.                                         242968-693319-295251-477840-704451-214225-550055-383229            {AB1535D4-ECB3-49D6-8AB1-E334A4F60579} 

.NOTES
	-Author: Stephane van Gulick
	-Email : 
	-CreationDate: 13-01-2014
	-LastModifiedDate: 11.06.2015
	-Version: 1.5
	-History:
    #0.1 : Created function
    #1.1 : 20140901 Added GetProtectorIds
    #1.2 : 20140909 Rewrote function
                    Added GetKeyprotectorType
                    Added EncryptionMethod
	#1.3 : 20141003 Added TPM conditions.
    #1.4 : Possiblity to select drive letter, added RemoveKeyProtectors.
       --> GetKeyProtectorTypeAndID,
        --> DeleteKeyProtectors,
        --> ProtectorIDs,
        --> DeleteKeyProtector,
        --> PauseEncryption,
        --> PauseDecryption,
        --> Decrytp
    #1.4.1 --> updated help with GetKeyPRotectedID instead of KeyProtectedID parameter
    #1.5 Added GetKeyProtectorNumericalPassword and VolumeKeyProtectorID parameters.

.LINK
    www.PowerShellDistrict.com

#>
	[cmdletBinding()]
	Param (
		[Switch]$IsTPMActivated,
		[Switch]$IsTPMEnabled,
		[Switch]$IsTPMOwnerShipAllowed,
		[Switch]$ResumeEncryption,
		[Switch]$GetEncryptionState,
		[Switch]$GetProtectionStatus,
		[switch]$Encrypt,
		[Parameter(ParameterSetName = 'OwnerShip')][switch]$TakeTPMOwnerShip,
		[Parameter(ParameterSetName = 'OwnerShip')][int]$pin,
		[switch]$IsTPMOwned,
		[Switch]$GetKeyProtectorIds,
		[switch]$GetEncryptionMethod,
		[ValidateScript({
			if ($_ -match '^[A-Z]{1}[:]') {
				return $true
			} else {
				Write-Warning 'The drive letter parameter has to respect the following case: DriverLetter+Colomn EG: --> C: --> D: --> E: '
				return $false
			}
		})][string]$DriveLetter = 'C:',
		[switch]$GetKeyProtectorTypeAndID,
		[switch]$DeleteKeyProtectors,
		#Acceptvaluefrompipelinebyname
		[String[]]$ProtectorIDs,
		[switch]$DeleteKeyProtector,
		[switch]$PauseEncryption,
		[switch]$PauseDecryption,
		[switch]$Decrytp,
		[Parameter(ParameterSetName = 'NumericalPassword')][Switch]$GetKeyProtectorNumericalPassword,
		[Parameter(ParameterSetName = 'NumericalPassword', Mandatory = $true)][String]$VolumeKeyProtectorID
		
	)
	Begin {
		try {
			$Tpm = Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm -ErrorAction Stop
		} catch [System.Management.ManagementException]{
			
			write-warning 'Could not access the WMI methods. Verify that you run the script with elevated rights and try again.'
			continue
			
			
		}
	}
	Process {
		##Add switch to verify if enough place is present on HD (6gig are need, 10 recommended).
		
		
		switch ($PSBoundParameters.keys) {
			
			'IsTPMActivated'{ $return = if ($Tpm) { $tpm.IsActivated().isactivated }; break }
			'IsTPMEnabled'{ $return = if ($Tpm) { $tpm.IsEnabled().isenabled }; break }
			'IsTPMOwnerShipAllowed'{ $return = if ($Tpm) { $tpm.IsOwnerShipAllowed().IsOwnerShipAllowed }; break }
			'IsTPMOwned'{ $return = if ($Tpm) { $Tpm.isowned().isowned }; break }
			'GetEncryptionState'{
				write-verbose "Getting the encryptionstate of drive $($driveletter)"
				#http://msdn.microsoft.com/en-us/library/aa376433(VS.85).aspx
				#We only want to work on the C: drive.
				$EncryptionData = Get-WmiObject -Namespace ROOT\CIMV2\Security\Microsoftvolumeencryption -Class Win32_encryptablevolume -Filter "DriveLetter = '$DriveLetter'"
				$protectionState = $EncryptionData.GetConversionStatus()
				$CurrentEncryptionProgress = $protectionState.EncryptionPercentage
				
				switch ($ProtectionState.Conversionstatus) {
					
					'0' {
						
						$Properties = @{ 'EncryptionState' = 'FullyDecrypted'; 'CurrentEncryptionProgress' = $CurrentEncryptionProgress }
						$Return = New-Object psobject -Property $Properties
						
					}
					
					'1' {
						
						$Properties = @{ 'EncryptionState' = 'FullyEncrypted'; 'CurrentEncryptionProgress' = $CurrentEncryptionProgress }
						$Return = New-Object psobject -Property $Properties
						
					}
					'2' {
						
						$Properties = @{ 'EncryptionState' = 'EncryptionInProgress'; 'CurrentEncryptionProgress' = $CurrentEncryptionProgress }
						$Return = New-Object psobject -Property $Properties
					}
					'3' {
						
						$Properties = @{ 'EncryptionState' = 'DecryptionInProgress'; 'CurrentEncryptionProgress' = $CurrentEncryptionProgress }
						$Return = New-Object psobject -Property $Properties
					}
					'4' {
						
						$Properties = @{ 'EncryptionState' = 'EncryptionPaused'; 'CurrentEncryptionProgress' = $CurrentEncryptionProgress }
						$Return = New-Object psobject -Property $Properties
					}
					'5' {
						
						$Properties = @{ 'EncryptionState' = 'DecryptionPaused'; 'CurrentEncryptionProgress' = $CurrentEncryptionProgress }
						$Return = New-Object psobject -Property $Properties
					}
					default {
						write-verbose "Couldn't retrieve an encryption state."
						$Properties = @{ 'EncryptionState' = $false; 'CurrentEncryptionProgress' = $false }
						$Return = New-Object psobject -Property $Properties
					}
				}
			}
			'ResumeEncryption'{
				write-verbose 'Resuming encryption'
				$ProtectionState = Get-WmiObject -Namespace ROOT\CIMV2\Security\Microsoftvolumeencryption -Class Win32_encryptablevolume -Filter "DriveLetter = '$DriveLetter'"
				
				$Ret = $protectionState.ResumeConversion()
				$ReturnCode = $ret.ReturnValue
				
				switch ($ReturnCode) {
					
					('0') { $Message = 'The Method Resume Conversion was called succesfully.' }
					('2150694912') { $message = 'The volume is locked' }
					default { $message = 'The resume operation failed with an uknowned return code.' }
				}
				
				$Properties = @{ 'ReturnCode' = $ReturnCode; 'ErrorMessage' = $message }
				$Return = New-Object psobject -Property $Properties
			} #EndResumeEncryption   
			'GetProtectionStatus'{
				#http://msdn.microsoft.com/en-us/library/windows/desktop/aa376448(v=vs.85).aspx
				$ProtectionState = Get-WmiObject -Namespace ROOT\CIMV2\Security\Microsoftvolumeencryption -Class Win32_encryptablevolume -Filter "DriveLetter = '$DriveLetter'"
				write-verbose 'Gathering BitLocker protection status infos.'
				
				switch ($ProtectionState.GetProtectionStatus().protectionStatus) {
					
					('0') { $return = 'Unprotected' }
					('1') { $return = 'Protected' }
					('2') { $return = 'Uknowned' }
					default { $return = 'NoReturn' }
				} #EndSwitch
			} #EndGetProtection
			'Encrypt'{
				#http://msdn.microsoft.com/en-us/library/windows/desktop/aa376432(v=vs.85).aspx
				$ProtectionState = Get-WmiObject -Namespace ROOT\CIMV2\Security\Microsoftvolumeencryption -Class Win32_encryptablevolume -Filter "DriveLetter = '$DriveLetter'"
				write-verbose 'Launching drive encryption.'
				
				$ProtectorKey = $protectionState.ProtectKeyWithTPMAndPIN('ProtectKeyWithTPMAndPin', '', $pin)
				Start-Sleep -Seconds 3
				$NumericalPasswordReturn = $protectionState.ProtectKeyWithNumericalPassword()
				
				$Return = $protectionState.Encrypt()
				$returnCode = $return.returnvalue
				switch ($ReturnCode) {
					
					('0') { $message = 'Operation successfully started.' }
					('2147942487') { $message = 'The EncryptionMethod parameter is provided but is not within the known range or does not match the current Group Policy setting.' }
					('2150694958') { $message = 'No encryption key exists for the volume' }
					('2150694957') { $message = 'The provided encryption method does not match that of the partially or fully encrypted volume.' }
					('2150694942') { $message = 'The volume cannot be encrypted because this computer is configured to be part of a server cluster.' }
					('2150694956') { $message = 'No key protectors of the type Numerical Password are specified. The Group Policy requires a backup of recovery information to Active Directory Domain Services' }
					default {
						$message = 'An unknown status was returned by the Encryption action.'
						
					}
				}
				
				$Properties = @{ 'ReturnCode' = $ReturnCode; 'ErrorMessage' = $message }
				$Return = New-Object psobject -Property $Properties
			}
			'GetKeyProtectorIds'{
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$return = $BitLocker.GetKeyProtectors('0').VolumeKeyProtectorID
			}
			'GetEncryptionMethod'{
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$EncryptMethod = $BitLocker.GetEncryptionMethod().encryptionmethod
				switch ($EncryptMethod) {
					'0'{ $Return = 'None'; break }
					'1'{ $Return = 'AES_128_WITH_DIFFUSER'; break }
					'2'{ $Return = 'AES_256_WITH_DIFFUSER'; break }
					'3'{ $Return = 'AES_128'; break }
					'4'{ $Return = 'AES_256'; break }
					'5'{ $Return = 'HARDWARE_ENCRYPTION'; break }
					default { $Return = 'UNKNOWN'; break }
				}
				
			}
			'GetKeyProtectorTypeAndID'{
				
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$ProtectorIds = $BitLocker.GetKeyProtectors('0').volumekeyprotectorID
				
				$return = @()
				
				foreach ($ProtectorID in $ProtectorIds) {
					
					$KeyProtectorType = $BitLocker.GetKeyProtectorType($ProtectorID).KeyProtectorType
					$keyType = ''
					switch ($KeyProtectorType) {
						
						'0'{ $Keytype = 'Unknown or other protector type'; break }
						'1'{ $Keytype = 'Trusted Platform Module (TPM)'; break }
						'2'{ $Keytype = 'External key'; break }
						'3'{ $Keytype = 'Numerical password'; break }
						'4'{ $Keytype = 'TPM And PIN'; break }
						'5'{ $Keytype = 'TPM And Startup Key'; break }
						'6'{ $Keytype = 'TPM And PIN And Startup Key'; break }
						'7'{ $Keytype = 'Public Key'; break }
						'8'{ $Keytype = 'Passphrase'; break }
						'9'{ $Keytype = 'TPM Certificate'; break }
						'10'{ $Keytype = 'CryptoAPI Next Generation (CNG) Protector'; break }
						
					} #endSwitch
					
					$Properties = @{ 'KeyProtectorID' = $ProtectorID; 'KeyProtectorType' = $Keytype }
					$Return += New-Object -TypeName psobject -Property $Properties
				} #EndForeach
				
			} #EndGetKeyProtectorType
			'DeleteKeyProtectors'{
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$Return = $BitLocker.DeleteKeyProtectors()
				
			}
			'TakeTPMOwnerShip'{
				$Tpm.takeOwnership()
			}
			'DeleteKeyProtector'{
				
				if ($PSBoundParameters.ContainsKey('ProtectorIDs')) {
					$Return = @()
					$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
					
					foreach ($ProtID in $ProtectorIDs) {
						$Return += $BitLocker.DeleteKeyProtector($ProtID)
					}
				} else {
					write-warning 'Could not delete the key protector. Missing ProtectorID parameter.'
					$Return = 'Could not delete the key protector. Missing ProtectorID parameter.'
					
				}
			}
			'PauseEncryption'{
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$ReturnCode = $BitLocker.PauseConversion()
				
				switch ($ReturnCode.ReturnValue) {
					'0'{ $Return = 'Paused sucessfully.'; break }
					'2150694912'{ $Return = 'The volume is locked.'; Break }
					default { $Return = 'Uknown return code.'; break }
				}
			}
			'PauseDecryption'{
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$ReturnCode = $BitLocker.PauseConversion()
				
				switch ($ReturnCode.ReturnValue) {
					'0'{ $Return = 'Paused sucessfully.'; break }
					'2150694912'{ $Return = 'The volume is locked.'; Break }
					default { $Return = 'Uknown return code.'; break }
				}
			}
			'Decrytp'{
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$ReturnCode = $BitLocker.Decrypt()
				
				switch ($ReturnCode.ReturnValue) {
					'0'{ $Return = 'Uncryption started successfully.'; break }
					'2150694912'{ $Return = 'The volume is locked.'; Break }
					'2150694953' { $Return = 'This volume cannot be decrypted because keys used to automatically unlock data volumes are available.'; Break }
					default { $Return = 'Uknown return code.'; break }
				}
				
			}
			'GetKeyProtectorNumericalPassword'{
				$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
				$Return = @()
				
				
				$KeyProtectorReturn = $BitLocker.GetKeyProtectorNumericalPassword($VolumeKeyProtectorID)
				
				switch ($KeyProtectorReturn.ReturnValue) {
					'0'  { $msg = 'The method was successful.' }
					'2150694912' { $msg = 'The volume is locked.'; Break }
					'2147942487' { $msg = "The VolumeKeyProtectorID parameter does not refer to a key protector of the type 'Numerical Password'."; Break }
					'2150694920' { $msg = 'BitLocker is not enabled on the volume. Add a key protector to enable BitLocker.'; Break }
					default { $msg = "Unknown return value: $($KeyProtectorReturn.ReturnValue)" }
				} #EndSwitch
				
				$Properties = @{ 'KeyProtectorNumericalPassword' = $KeyProtectorReturn.NumericalPassword; 'VolumeKeyProtectorID' = $VolumeKeyProtectorID; 'Message' = $msg }
				$Return += New-Object -TypeName psobject -Property $Properties
				
				
			}
		} #endSwitch
		
		
		if ($PSBoundParameters.Keys.Count -eq 0) {
			#Returning info on all drives.
			write-verbose 'Returning bitlocker main status'
			$Tpm = Get-WmiObject -Namespace ROOT\CIMV2\Security\MicrosoftTpm -Class Win32_Tpm
			$BitLocker = Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume' -Filter "DriveLetter = '$DriveLetter'"
			
			#If no TPM module is present
			if ($tpm) {
				$TpmActivated = $tpm.IsActivated().isactivated
				$TPMEnabled = $tpm.IsEnabled().isenabled
				$TPMOwnerShipAllowed = $Tpm.IsOwnershipAllowed().IsOwnerShipAllowed
				$TPMOwned = $Tpm.isowned().isowned
				
			}
			
			$ProtectorIds = $BitLocker.GetKeyProtectors('0').volumekeyprotectorID
			$CurrentEncryptionState = BitLockerSAK -GetEncryptionState
			$EncryptionMethod = BitLockerSAK -GetEncryptionMethod
			$KeyProtectorTypeAndID = BitLockerSAK -GetKeyProtectorTypeAndID
			
			$properties = @{
				'IsTPMActivated' = $TpmActivated;`
				'IsTPMEnabled' = $TPMEnabled;`
				'IsTPMOwnerShipAllowed' = $TPMOwnerShipAllowed;`
				'IsTPMOwned' = $TPMOwned;`
				'CurrentEncryptionPercentage' = $CurrentEncryptionState.CurrentEncryptionProgress;`
				'EncryptionState' = $CurrentEncryptionState.encryptionState; `
				'EncryptionMethod' = $EncryptionMethod;`
				'KeyProtectorTypesAndIDs' = $KeyProtectorTypeAndID
			}
			
			$Return = New-Object psobject -Property $Properties
		}
		
	}
	End {
		return $return
	}
	
}

function Get-BiosStatus {
	param ([String]$Option)
	
	#Declare Local Variables
	Set-Variable -Name Argument -Scope Local -Force
	Set-Variable -Name CCTK -Value "x:\cctk\cctk.exe" -Scope Local -Force
	Set-Variable -Name Output -Scope Local -Force
	
	$Argument = "--" + $Option
	$Output = [string] (& $CCTK $Argument)
	$Output = $Output.Split('=')
	Return $Output[1]
	
	#Cleanup Local Variables
	Remove-Variable -Name Argument -Scope Local -Force
	Remove-Variable -Name CCTK -Scope Local -Force
	Remove-Variable -Name Output -Scope Local -Force
}

#Declare Local Variables
Set-Variable -Name oShell -Scope Local -Force
Set-Variable -Name TPMActivated -Scope Local -Force
Set-Variable -Name TPMEnabled -Scope Local -Force
Set-Variable -Name TPMOwned -Scope Local -Force
Set-Variable -Name TPMOwnershipAllowed -Scope Local -Force

cls

$TPMEnabled = Get-BiosStatus -Option "tpm"
Write-Host "TPM Enabled:"$TPMEnabled
$TPMActivated = Get-BiosStatus -Option "tpmactivation"
Write-Host "TPM Activated:"$TPMActivated
$TPMOwnershipAllowed = BitLockerSAK -IsTPMOwnerShipAllowed
Write-Host "TPM Ownership Allowed:"$TPMOwnershipAllowed
$TPMOwned = BitLockerSAK -IsTPMOwned
Write-Host "TPM Owned:"$TPMOwned
Write-Host
If (($TPMEnabled -eq "on") -and ($TPMActivated -eq "activate") -and ($TPMOwnershipAllowed -eq $true) -and ($TPMOwned -eq $false)) {
	Write-Host "TPM Ready for Bitlocker"
	Exit 0
} else {
	Write-Host "TPM Not Ready for Bitlocker"
	$oShell = New-Object -ComObject Wscript.Shell
	$oShell.Popup("TPM Not Ready for Bitlocker." + [char]13 + [char]13 + "Turn On, Clear, and Activate TPM, then restart image.", 0, "TPM Failure", 0x0)
	Exit 1
}

#Cleanup Local Variables
Remove-Variable -Name oShell -Scope Local -Force
Remove-Variable -Name TPMActivated -Scope Local -Force
Remove-Variable -Name TPMEnabled -Scope Local -Force
Remove-Variable -Name TPMOwned -Scope Local -Force
Remove-Variable -Name TPMOwnershipAllowed -Scope Local -Force
