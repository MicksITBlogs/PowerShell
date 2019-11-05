<#
	.SYNOPSIS
		SCCM Reboot Report
	
	.DESCRIPTION
		This script will query SCCM for a list of machines that are waiting for a reboot.
	
	.PARAMETER Collection
		Name of the collection to query
	
	.PARAMETER SQLServer
		Name of the SQL server
	
	.PARAMETER SQLDatabase
		A description of the SQLDatabase parameter
	
	.PARAMETER SQLInstance
		Name of the SQL Database
	
	.PARAMETER SCCMFQDN
		Fully Qualified Domain Name of the SCCM server
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	10/3/2019 12:04 PM
		Created by:   	Mick Pletcher
		Filename:		SCCMRebootReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$Collection,
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase
)

$RebootList = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query 'SELECT * FROM dbo.vSMS_CombinedDeviceResources WHERE ClientState <> 0' | Sort-Object
$CollectionQuery = 'SELECT * FROM' + [char]32 + 'dbo.' + ((Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('SELECT ResultTableName FROM dbo.v_Collections WHERE CollectionName = ' + [char]39 + $Collection + [char]39)).ResultTableName)
$CollectionList = (Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query $CollectionQuery).Name | Sort-Object
$List = @()
$RebootList | ForEach-Object {
	If ($_.Name -in $CollectionList) {
		switch ($_.ClientState) {
			1 {$State = 'Configuration Manager'}
			2 {$State = 'File Rename'}
			3 {$State = 'Configuration Manager, File Rename'}
			4 {$State = 'Windows Update'}
			5 {$State = 'Configuration Manager, Windows Update'}
			6 {$State = 'File Rename, Windows Update'}
			7 {$State = 'Configuration Manager, File Rename, Windows Update'}
			8 {$State = 'Add or Remove Feature'}
			9 {$State = 'Configuration Manager, Add or Remove Feature'}
			10 {$State = 'File Rename, Add or Remove Feature'}
			11 {$State = 'Configuration Manager, File Rename, Add or Remove Feature'}
			12 {$State = 'Windows Update, Add or Remove Feature'}
			13 {$State = 'Configuration Manager, Windows Update, Add or Remove Feature'}
			14 {$State = 'File Rename, Windows Update, Add or Remove Feature'}
			15 {$State = 'Configuration Manager, File Rename, Windows Update, Add or Remove Feature'}
		}
		$objItem = New-Object -TypeName System.Management.Automation.PSObject
		$objItem | Add-Member -MemberType NoteProperty -Name System -Value $_.Name
		$objItem | Add-Member -MemberType NoteProperty -Name State -Value $State
		$List += $objItem
	}
}
If ($List -ne '') {
	Write-Output $List
} else {
	Exit 1
}
