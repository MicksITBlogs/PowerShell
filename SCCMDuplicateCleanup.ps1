<#
	.SYNOPSIS
		SCCM Duplicate Cleanup
	
	.DESCRIPTION
		This script will query for a list of machines with error 120 when trying to install the SCCM client. This error indicates the system is a duplicate. 
	
	.PARAMETER SCCMModule
		UNC path including file name of the configuration manager module
	
	.PARAMETER SCCMServer
		FQDN of SCCM Server
	
	.PARAMETER SCCMSiteDescription
		Description of the SCCM Server
	
	.PARAMETER SiteCode
		Three letter SCCM Site Code
	
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
		Filename:		SCCMDuplicateCleanup.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SCCMModule,
	[ValidateNotNullOrEmpty()]
	[string]$SCCMServer,
	[ValidateNotNullOrEmpty()]
	[string]$SCCMSiteDescription,
	[ValidateNotNullOrEmpty()]
	[string]$SiteCode,
	[ValidateNotNullOrEmpty()]
	[string]$Collection,
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase
)

$List = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('SELECT Name, MachineID, CP_LastInstallationError FROM' + [char]32 + 'dbo.' + ((Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('Select ResultTableName FROM dbo.Collections WHERE CollectionName =' + [char]32 + [char]39 + $Collection + [char]39)).ResultTableName) + [char]32 + 'WHERE ClientVersion IS NULL AND CP_LastInstallationError = 120 Order By MachineID')
If ($List -ne '') {
	Import-Module -Name $SCCMModule -Force
	New-PSDrive -Name $SiteCode -PSProvider 'AdminUI.PS.Provider\CMSite' -Root $SCCMServer -Description $SCCMSiteDescription | Out-Null
	Set-Location -Path ($SiteCode + ':')
	#Test with output to screen before enabling the other line that also deletes each item
	#$List | ForEach-Object { (Get-CMDevice -ResourceId $_.MachineID -Fast).Name }
	$List | ForEach-Object { Get-CMDevice -ResourceId $_.MachineID -Fast | Remove-CMDevice -Confirm:$false -Force }
	Remove-PSDrive -Name $SiteCode -Force
	Write-Output ($List.Name | Sort-Object)
} else {
	Exit 1
}
