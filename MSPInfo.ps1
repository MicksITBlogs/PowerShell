<#
	.SYNOPSIS
		Extract MSP information
	
	.DESCRIPTION
		This script will extract MSP file information from the metadata table. It has been written to be able to read data from a lot of different MSP files, including Microsoft Office updates and most application patches. There are some MSP files that were not populated with the metadata table, therefor no data is obtainable. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	6/15/2016 4:07 PM
		Created by:   	Mick Pletcher
		Organization:
		Filename:		MSPInfo.ps1
		===========================================================================
#>


function Get-MSPFileInfo {
	param
	(
			[Parameter(Mandatory = $true)][IO.FileInfo]$Path,
			[Parameter(Mandatory = $true)][ValidateSet('Classification', 'Description', 'DisplayName', 'KBArticle Number', 'ManufacturerName', 'ReleaseVersion', 'TargetProductName')][string]$Property
	)
	
	try {
		$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
		$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($Path.FullName, 32))
		$Query = "SELECT Value FROM MsiPatchMetadata WHERE Property = '$($Property)'"
		$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
		$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
		$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
		$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
		return $Value
	} catch {
		Write-Output $_.Exception.Message
	}
}

Get-MSPFileInfo -Path "mstore-x-none.msp" -Property 'KBArticle Number'
