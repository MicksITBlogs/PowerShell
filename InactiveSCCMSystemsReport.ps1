<#
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.91
		Created on:   	8/13/2015 1:36 PM
		Created by:	Mick Pletcher
		Filename:	InactiveSCCMSystemsReport.ps1
		Description:	This script will retrieve the SCCM inactive systems
						collection and search active directory to see if it 
						exists there. If so, it will retrieve the last 
						logon date and generate a UTF-8 formatted csv file.

						The powershell active directory module will need to be
						enabled on the SCCM server in order for this script to 
						work correctly. This script will also need to be executed
						on the SCCM server. You will also need to find the location
						of ConfigurationManager.psd1 module to import. 
		===========================================================================
#>
param
(
	[string]
	$OutputFile = 'InactiveSCCMSystemsReport.csv',
	[string]
	$Path = "\\drfs1\DesktopApplications\ProductionApplications\Waller\InactiveUserReport"
)
Import-Module ActiveDirectory


function ProcessTextFile {
	If ((Test-Path -Path $OutputFile) -eq $true) {
		Remove-Item -Path $OutputFile -Force
	}
}

function Get-SCCMInactiveSystems {
	#Declare Local Variables
	Set-Variable -Name Systems -Scope Local -Force
	
	$Systems = get-cmdevice -collectionid "BNA00093" | select name | Sort-Object Name
	Return $Systems
	
	#Cleanup Local Variables
	Remove-Variable -Name Systems -Scope Local -Force
}

function Find-SCCMInactiveSystemInAD {
	param ([string]
		$System)
	
	#Declare Local Variables
	Set-Variable -Name AD -Scope Local -Force
	$ErrorActionPreference = 'SilentlyContinue'
	$AD = Get-ADComputer $System
	$ErrorActionPreference = 'Continue'
	if ($AD -ne $null) {
		Return "X"
	} else {
		Return " "	
	}
	
	#Cleanup Local Variables
	Remove-Variable -Name AD -Scope Local -Force
}

function Get-LastLogonDate {
	param ([string]
		$System)
	
	#Declare Local Variables
	Set-Variable -Name AD -Scope Local -Force
	
	$AD = Get-ADComputer $System -ErrorAction SilentlyContinue
	$AD = $AD.SamAccountName
	$AD = $AD.Substring(0, $AD.Length - 1)
	$AD = Get-ADComputer -Identity $AD -Properties *
	$AD = $AD.LastLogonDate
	Return $AD
		
	#Cleanup Local Variables
	Remove-Variable -Name AD -Scope Local -Force
}

#Declare Variables
Set-Variable -Name ADEntry -Scope Local -Force
Set-Variable -Name Counter -Value 1 -Scope Local -Force
Set-Variable -Name LastLogon -Scope Local -Force
Set-Variable -Name Output -Scope Local -Force
Set-Variable -Name SCCMInactiveSystems -Scope Local -Force
Set-Variable -Name System -Scope Local -Force

cls
Import-Module -Name ActiveDirectory
Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" -Force -Scope Global
Set-Location BNA:
$SCCMInactiveSystems = Get-SCCMInactiveSystems
Set-Location c:
$OutputFile = $Path + "\" + $OutputFile
ProcessTextFile
$Output = "Computer Name" + [char]44+"Active Directory"+[char]44+"Last Logon"
Out-File -FilePath $OutputFile -InputObject $Output -Force -Encoding UTF8
foreach ($System in $SCCMInactiveSystems) {
	cls
	$Output = "Processing "+$System.Name+" -- "+$Counter+" of "+$SCCMInactiveSystems.Count
	Write-Host $Output
	$Counter++
	$ADEntry = Find-SCCMInactiveSystemInAD -System $System.Name
	If ($ADEntry -ne " ") {
		$LastLogon = Get-LastLogonDate -System $System.Name
	}
	$Output = $System.Name+[char]44+$ADEntry+[char]44+$LastLogon
	Out-File -FilePath $Global:OutputFile -InputObject $Output -Append -Force -Encoding UTF8
	$ADEntry = $null
	$LastLogon = $null
	$Output = $null
}

#Cleanup Variables
Remove-Variable -Name ADEntry -Scope Local -Force
Remove-Variable -Name Counter -Scope Local -Force
Remove-Variable -Name LastLogon -Scope Local -Force
Remove-Variable -Name Output -Scope Local -Force
Remove-Variable -Name SCCMInactiveSystems -Scope Local -Force
Remove-Variable -Name System -Scope Local -Force
