<#
	.SYNOPSIS
		ConfigMgr Reboot Report
	
	.DESCRIPTION
		This script will query ConfigMgr for a list of machines that are waiting for a reboot.
	
	.PARAMETER Collection
		Name of the collection to query
	
	.PARAMETER SQLServer
		Name of the SQL server
	
	.PARAMETER SQLDatabase
		A description of the SQLDatabase parameter.
	
	.PARAMETER SQLInstance
		Name of the SQL Database
	
	.PARAMETER SCCMFQDN
		Fully Qualified Domain Name of the ConfigMgr server
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	05/01/2020 09:39 AM
		Created by:   	Mick Pletcher
		Filename:		ConfigMgrRebootReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$Collection = '',
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer = '',
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase = ''
)

$RebootListQuery = 'SELECT * FROM dbo.vSMS_CombinedDeviceResources WHERE ClientState <> 0'
$RebootList = (Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query $RebootListQuery).Name | Sort-Object
$CollectionQuery = 'SELECT * FROM' + [char]32 + 'dbo.' + ((Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('SELECT ResultTableName FROM dbo.v_Collections WHERE CollectionName = ' + [char]39 + $Collection + [char]39)).ResultTableName)
$CollectionList = (Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query $CollectionQuery).Name | Sort-Object
$List = @()
$RebootList | ForEach-Object { If ($_ -in $CollectionList) { $List += $_ } }
If ($List -ne '') {
	Write-Output $List
} else {
	Exit 1
}
