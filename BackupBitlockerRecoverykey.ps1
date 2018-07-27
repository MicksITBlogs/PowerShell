<#
	.SYNOPSIS
		Bitlocker Recovery Key
	
	.DESCRIPTION
		This script will delete active directory entries that contain the Bitlocker recovery keys which do not match to current one. It will then push up the new key to AD. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	7/24/2018 3:47 PM
		Created by:   	Mick Pletcher
		Filename:     	BackupBitlockerRecoveryKey.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()

cls
#Get the local bitlocker password
$LocalPassword = ((manage-bde -protectors -get ($env:ProgramFiles).split('\')[0] -id ((Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume').GetKeyProtectors(3).volumeKeyprotectorID)).trim() | Where-Object { $_.Trim() -ne '' })[-1]
$BitlockerID = (((manage-bde -protectors -get ($env:ProgramFiles).split('\')[0] -id ((Get-WmiObject -Namespace 'Root\cimv2\Security\MicrosoftVolumeEncryption' -Class 'Win32_EncryptableVolume').GetKeyProtectors(3).volumeKeyprotectorID)).trim() | Where-Object { $_.Trim() -ne '' })[-3]).split(":")[1].trim()
#Get all bitlocker entries from active directory
$ADEntries = (Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase (Get-ADComputer $env:COMPUTERNAME).DistinguishedName -Properties 'msFVE-RecoveryPassword')
#Number of recovery key entries stored in AD
$EntryCount = 0
#Parse through all active directory entries removing ones that do not contain local bitlocker password
foreach ($Item in $ADEntries) {
	If ($LocalPassword -ne $Item.'msFVE-RecoveryPassword') {
		Remove-ADObject -Identity $Item.DistinguishedName -Confirm:$false
	} else {
		$EntryCount += 1
		If ($EntryCount -gt 1) {
			Remove-ADObject -Identity $Item.DistinguishedName -Confirm:$false
		}
	}
}
$ADEntries = (Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase (Get-ADComputer $env:COMPUTERNAME).DistinguishedName -Properties 'msFVE-RecoveryPassword')
#Backup the bitlocker password to active directory if it is not in any AD entries
If ($LocalPassword -notin $ADEntries.'msFVE-RecoveryPassword') {
	#Backup recovery key to active directory
	$Switches = "-protectors -adbackup c: -id" + [char]32 + $BitlockerID
	Write-Host "Backing up to AD....." -NoNewline
	$ErrCode = (Start-Process -FilePath $env:windir'\system32\manage-bde.exe' -ArgumentList $Switches -PassThru -Wait).ExitCode
	If ($ErrCode -eq 0) {
		Write-Host "Success" -ForegroundColor Yellow
		$ADEntries = (Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase (Get-ADComputer $env:COMPUTERNAME).DistinguishedName -Properties 'msFVE-RecoveryPassword')
		Write-Host
		Write-Host "  Bitlocker ID:" -NoNewline
		Write-Host $BitlockerID -ForegroundColor Yellow
		Write-Host "Local Password:" -NoNewline
		Write-Host $LocalPassword -ForegroundColor Yellow
		Write-Host "   AD Password:" -NoNewline
		Write-Host $ADEntries.'msFVE-RecoveryPassword' -ForegroundColor Yellow
		If ($LocalPassword -eq $ADEntries.'msFVE-RecoveryPassword') {
			Exit 0
		}
	} elseif ($ErrCode -eq "-2147024809") {
		$Status = [string]((manage-bde.exe -status).replace(' ', '')).split(":")[16]
		If ($Status -eq "FullyDecrypted") {
			Write-Host "Failed. System is not Bitlockered"
			Exit 2
		} else {
			Write-Host "Unspecified error"
			Exit 3
		}
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
		Write-Host
		Write-Host "  Bitlocker ID:" -NoNewline
		Write-Host $BitlockerID -ForegroundColor Yellow
		Write-Host "Local Password:" -NoNewline
		Write-Host $LocalPassword -ForegroundColor Yellow
		Write-Host "   AD Password:" -NoNewline
		Write-Host $ADEntries.'msFVE-RecoveryPassword' -ForegroundColor Yellow
		Exit 1
	}
} else {
	Write-Host
	Write-Host "  Bitlocker ID:"$BitlockerID
	Write-Host "Local Password:"$LocalPassword
	Write-Host "   AD Password:"$ADEntries.'msFVE-RecoveryPassword'
	Exit 0
}
