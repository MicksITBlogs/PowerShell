<#
	.SYNOPSIS
		Imports the SCCM PowerShell Module
	
	.DESCRIPTION
		This function will import the SCCM PowerShell module without the need of knowing the location. The only thing that needs to be specified is the name of the SCCM server. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.139
		Created on:   	4/26/2017 3:56 PM
		Created by:   	Mick Pletcher
		Filename:		ImportSCCMModule.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()

function Import-SCCMModule {
<#
	.SYNOPSIS
		Import SCCM Module
	
	.DESCRIPTION
		Locate the ConfigurationManager.psd1 file and import it.
	
	.PARAMETER SCCMServer
		Name of the SCCM server to connect to.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$SCCMServer
	)
	
	#Get the architecture of the specified SCCM server
	$Architecture = (get-wmiobject win32_operatingsystem -computername $SCCMServer).OSArchitecture
	#Get list of installed applications
	$Uninstall = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	If ($Architecture -eq "64-bit") {
		$Uninstall += Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	}
	#Get the registry key that specifies the location of the SCCM installation drive and directory
	$RegKey = ($Uninstall | Where-Object { $_ -like "*SMS Primary Site*" }) -replace 'HKEY_LOCAL_MACHINE', 'HKLM:'
	$Reg = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ItemProperty -Path $args[0] } -ArgumentList $RegKey
	#Parse the directory listing
	$Directory = (($Reg.UninstallString).Split("\", 4) | Select-Object -Index 0, 1, 2) -join "\"
	#Locate the location of the SCCM module
	$Module = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path $args[0] -Filter "ConfigurationManager.psd1" -Recurse } -ArgumentList $Directory
	#If more than one module is present, use the latest one
	If ($Module.Length -gt 1) {
		foreach ($Item in $Module) {
			If (($NewModule -eq $null) -or ($Item.CreationTime -gt $NewModule.CreationTime)) {
				$NewModule = $Item
			}
		}
		$Module = $NewModule
	}
	#format the $Module unc path
	[string]$Module = "\\" + $SCCMServer + "\" + ($Module.Fullname -replace ":", "$")
	#Import the SCCM module
	Import-Module -Name $Module
}

Import-SCCMModule -SCCMServer "SCCMServer"
