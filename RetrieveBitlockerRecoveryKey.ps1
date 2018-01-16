<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.92
	 Created on:   	8/25/2015 1:25 PM
	 Created by:   	Mick Pletcher
	 Filename:     	RetrieveBitlockerRecoveryKey.ps1
	===========================================================================
	.DESCRIPTION
		This script will prompt for the computer name. It will then display the
        bitlocker recovery key. In order for this to work correctly, you will 
        need to install Remote Server Administration Tools and active the
        following feature: Remote Server Administration Tools-->
        Role Administration Tools-->AD DS and AD LDS Tools-->
        Active Directory Module for Windows PowerShell. 
#>

Function Get-ComputerName {
    #Declare Local Variables
    Set-Variable -Name ComputerName -Scope Local -Force

    $ComputerName = Read-Host "Enter the computer name"
    Return $ComputerName

    #Cleanup Local Variables
    Remove-Variable -Name ComputerName -Scope Local -Force
}

Function Get-BitlockeredRecoveryKey {
    param ([String]$ComputerName)

    #Declare Local Variables
    Set-Variable -Name BitLockerObjects -Scope Local -Force
    Set-Variable -Name BitLockerRecoveryKey -Scope Local -Force
    Set-Variable -Name Computer -Scope Local -Value $null -Force
    Set-Variable -Name System -Scope Local -Force

    $BitLockerObjects = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' }
    foreach ($System in $BitLockerObjects) {
        $System = $System.DistinguishedName
        $System = $System.Split(',')
        $System = $System[1]
        $System = $System.Split('=')
        $System = $System[1]
        If ($System -eq $ComputerName) {
            $Computer = Get-ADComputer -Filter {Name -eq $System}
            $BitLockerRecoveryKey = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' } -SearchBase $Computer.DistinguishedName -Properties 'msFVE-RecoveryPassword'
            Write-Host "Computer Name:"$System
            Write-Host "Bitlocker Recovery Key:"$BitLockerRecoveryKey.'msFVE-RecoveryPassword'
        }
    }
    If ($Computer -eq $null) {
        Write-Host "No recovery key exists" -ForegroundColor Red
    }

    #Cleanup Local Variables
    Remove-Variable -Name BitLockerObjects -Scope Local -Force
    Remove-Variable -Name BitLockerRecoveryKey -Scope Local -Force
    Remove-Variable -Name Computer -Scope Local -Force
    Remove-Variable -Name System -Scope Local -Force
}

#Declare Local Variables
Set-Variable -Name SystemName -Scope Local -Force

cls
Import-Module ActiveDirectory -Scope Global -Force
$SystemName = Get-ComputerName
Get-BitlockeredRecoveryKey -ComputerName $SystemName

#Cleanup Local Variables
Remove-Variable -Name SystemName -Scope Local -Force
