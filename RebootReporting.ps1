<#
	.SYNOPSIS
		Reboot Report
	
	.DESCRIPTION
		This script will query SCCM for a list of machines pending a reboot. It will then write the list to a .CSV file.
	
	.PARAMETER CollectionName
		Name of the collection to query for a list of machines
	
	.PARAMETER SCCMServer
		Name of the SCCM Server
	
	.PARAMETER SCCMDrive
		Drive of the SCCM server
	
	.PARAMETER ReportFile
		Name of the file to write the list of systems pending a reboot.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.139
		Created on:   	5/22/2017 2:42 PM
		Created by:   	Mick Pletcher
		Filename:     	RebootReporting.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$CollectionName = 'TSTBLD Systems',
	[ValidateNotNullOrEmpty()][string]$SCCMServer = 'BNASCCM',
	[ValidateNotNullOrEmpty()][string]$SCCMDrive = 'BNA',
	[ValidateNotNullOrEmpty()][string]$ReportFile = 'PendingRebootReport.csv'
)

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

function Get-RebootPendingSystems {
<#
	.SYNOPSIS
		Reboot Pending Systems
	
	.DESCRIPTION
		This function connects to SCCM and retrieves the list of systems pending a reboot.
	
	.EXAMPLE
				PS C:\> Get-RebootPendingSystems
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#Create Report array
	$Report = @()
	#If the SCCM drive does not have a colon at the end, add it
	If ($SCCMDrive[$SCCMDrive.Length - 1] -ne ":") {
		$SCCMDrive = $SCCMDrive + ":"
	}
	#Change the location to the SCCM drive
	Set-Location $SCCMDrive
	#Get list of systems in the SCCM collection that are pending a reboot
	$Systems = (Get-CMDevice -collectionname $CollectionName).Name | Sort-object
	foreach ($System in $Systems) {
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		$Object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $System.ToUpper()
		$Report += $Object
	}
	#Change location back to the system homedrive
	Set-Location $env:HOMEDRIVE
	#Return the list of systems
	Return $Report
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

Clear-Host
#Find and import the PowerShell SCCM Module
Import-SCCMModule -SCCMServer $SCCMServer
#Get a list of systems pending a reboot
$Report = Get-RebootPendingSystems
#Get the path this script is being executed from
$RelativePath = Get-RelativePath
#Add the relative path to the filename
$ReportFile = $RelativePath + $ReportFile
#Delete Report File if it exists
If ((Test-Path $ReportFile) -eq $true) {
	Remove-Item -Path $ReportFile -Force
}
#Display the list of systems to the screen
$Report
#Export the list of systems to a CSV file
$Report | Export-Csv -Path $ReportFile -Encoding UTF8 -Force -NoTypeInformation
