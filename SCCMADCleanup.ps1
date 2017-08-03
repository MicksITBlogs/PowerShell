<#
	.SYNOPSIS
		SCCM AD Cleanup
	
	.DESCRIPTION
		This script removes systems from SCCM that are populated via active directory, but have been disabled in AD.
	
	.PARAMETER SCCMServer
		Name of the SCCM server
	
	.PARAMETER SCCMDrive
		SCCM Drive
	
	.PARAMETER SCCMCollection
		SCCM collection to query for cleanup
	
	.PARAMETER ReportOnly
		Produce a report only
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
		Created on:   	8/3/2017 9:07 AM
		Created by:   	Mick Pletcher
		Filename:		SCCMADCleanup.ps1

		.EXAMPLE
			powershell.exe -file SCCMADCleanup.ps1 -SCCMServer AtlantaSCCM -SCCMDrive ATL
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$SCCMServer,
	[ValidateNotNullOrEmpty()][string]$SCCMDrive,
	[ValidateNotNullOrEmpty()][string]$SCCMCollection = 'All Systems',
	[switch]$ReportOnly
)

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

function Get-SCCMCollectionList {
<#
	.SYNOPSIS
		Retrieve Collection List
	
	.DESCRIPTION
		Query the specifies collection in SCCM for a list of all systems residing in that collection.
	
	.PARAMETER CollectionName
		Name of SCCM collection to query
	
	.EXAMPLE
				PS C:\> Get-SCCMCollectionList
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$CollectionName
	)
	
	#Add colon at end of SCCMDrive if it does not exist
	If ($SCCMDrive[$SCCMDrive.Length - 1] -ne ":") {
		$SCCMDrive = $SCCMDrive + ":"
	}
	#Change to SCCM drive
	Set-Location $SCCMDrive
	#Get the collection ID for retrieving the list of systems
	$CollectionID = (Get-CMDeviceCollection | Where-Object { $_.Name -eq $SCCMCollection }).CollectionID
	#Get list of systems from the specified collection
	$CollectionSystems = (Get-CMDevice -CollectionId $CollectionID).Name | Where-Object { $_ -notlike "*Unknown Computer*" } | Sort-Object
	#Change location to the local drive
	Set-Location $env:HOMEDRIVE
	#Create Collection array
	$Collection = @()
	foreach ($System in $CollectionSystems) {
		try {
			$ADSystem = (Get-ADComputer $System).Enabled
		} catch {
			$ADSystem = $false
		}
		$objSystem = New-Object System.Object
		$objSystem | Add-Member -MemberType NoteProperty -Name Name -Value $System
		$objSystem | Add-Member -MemberType NoteProperty -Name Enabled -Value $ADSystem
		$Collection += $objSystem
}
	Return $Collection
}

function Remove-Systems {
<#
	.SYNOPSIS
		Remove Disabled Systems
	
	.DESCRIPTION
		Remove disabled active directory systems from SCCM
	
	.PARAMETER Collection
		List of all machines in the $SCCMCollection
	
	.EXAMPLE
		PS C:\> Remove-Systems
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Collection
	)
	
	#Add colon at end of SCCMDrive if it does not exist
	If ($SCCMDrive[$SCCMDrive.Length - 1] -ne ":") {
		$SCCMDrive = $SCCMDrive + ":"
	}
	#Change to SCCM drive
	Set-Location $SCCMDrive
	#Parse through list and delete systems from SCCM
	foreach ($System in $Collection) {
		If ($System.Enabled -eq $False) {
			Remove-CMDevice -Name $System.Name -Force
		}
	}
	#Change location to the local drive
	Set-Location $env:HOMEDRIVE
}

Clear-Host
Import-Module ActiveDirectory
Import-SCCMModule -SCCMServer BNASCCM
$Collection = Get-SCCMCollectionList -CollectionName "All Systems"
If (!($ReportOnly.IsPresent)) {
	Remove-Systems -Collection $Collection
	$Collection
	$Collection | Out-File -FilePath $File -Encoding UTF8 -NoClobber -force
} else {
	#Get execution path of this script
	$RelativePath = Get-RelativePath
	#Location and name of .CSV to write the output to
	$File = $RelativePath + "DisabledSystems.csv"
	#Delete file if it exists
	If ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
	$Collection
	$Collection | Out-File -FilePath $File -Encoding UTF8 -NoClobber -force
}
