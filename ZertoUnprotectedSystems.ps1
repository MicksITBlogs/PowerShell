<#
	.SYNOPSIS
		Unprotected Systems Report
	
	.DESCRIPTION
		This script will retrieve a list of systems from the Zerto server that are not being backed up. Desktop operating systems and systems not in AD are excluded, as Zerto is typically used for server backup.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	5/19/2020 5:24 PM
		Created by:   	Mick Pletcher
		Filename:     	ZertoUnprotectedSystems.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()

Import-Module -Name zertoapiwrapper
Import-Module -Name activedirectory
$Cred = New-Object System.Management.Automation.PSCredential ("domain\username", $password)
Connect-ZertoServer -zertoServer prodzerto.wallerlaw.int -credential $Cred
$List = (Get-ZertoUnprotectedVm).VmName | Sort-Object
$UnprotectedServers = @()
Foreach ($System in $List) {
    Try {
        $ADComputer = Get-ADComputer $System -Properties OperatingSystem
        If (($ADComputer.OperatingSystem -notlike '*Windows 7 Enterprise') -and ($ADComputer.OperatingSystem -notlike '*Windows 10 Enterprise')) {
            $UnprotectedServers += $System
        }
    } catch {

    }
}
#Use this if the script is being used in Azure Automation or Orchestrator
Write-Output $UnprotectedServers
#Use this if the script is being executed manually, or as a scheduled task. 
#Send-MailMessage -From '' -To '' -Subject 'Zerto Unprotected Servers' -Body ($UnprotectedServers | Out-String) -Priority High -SmtpServer ''