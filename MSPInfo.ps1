<#
	.SYNOPSIS
		Extract MSP information
	
	.DESCRIPTION
		This script will extract MSP file information from the metadata table. It has been written to be able to read data from a lot of different MSP files, including Microsoft Office updates and most application patches. There are some MSP files that were not populated with the metadata table, therefor no data is obtainable.
	
	.PARAMETER MSPFileName
		Name of the MSP File to call
	
	.PARAMETER MSPProperty
		Property to extract information
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	6/15/2016 4:07 PM
		Created by:   	Mick Pletcher
		Filename:	MSPInfo.ps1
		===========================================================================
#>
param
(
	[ValidateNotNullOrEmpty()]$MSPFileName = 'accessde-en-us.msp',
	[ValidateNotNullOrEmpty()]$MSPProperty = 'KBArticle Number'
)

function Get-MSPFileInfo {
	param
	(
		[Parameter(Mandatory = $true)][IO.FileInfo]$Path,
		[Parameter(Mandatory = $true)][ValidateSet('Classification', 'Description', 'DisplayName', 'KBArticle Number', 'ManufacturerName', 'ReleaseVersion', 'TargetProductName')][string]$Property
	)
	
	try {
		#Creating windows installer object
		$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
		#Loads the MSI database and specifies the mode to open it in by the last number on the line
		$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($Path.FullName, 32))
		#Specifies to query the MSIPatchMetadata table and get the value associated with the designated property
		$Query = "SELECT Value FROM MsiPatchMetadata WHERE Property = '$($Property)'"
		#Open up the property view
		$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
		$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
		#Retrieve the associate Property
		$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
		#Retrieve the associated value of the retrieved property
		$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
		return $Value
	} catch {
		Write-Output $_.Exception.Message
	}
}

Get-MSPFileInfo -Path $MSPFileName -Property $MSPProperty
