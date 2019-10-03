<#
	.SYNOPSIS
		PowerShell SCCM Connection
	
	.DESCRIPTION
		This script will connect to the SCCM server and return a list of all systems in SCCM. It is a demo on how to accomplish this task.
	
	.PARAMETER SCCMModule
		UNC path including file name of the configuration manager module
	
	.PARAMETER SCCMServer
		A description of the SCCMServer parameter.
	
	.PARAMETER SCCMSiteDescription
		Description of the SCCM Server
	
	.PARAMETER SiteCode
		Three letter SCCM Site Code
	
	.PARAMETER SCCMFQDN
		Fully Qualified Domain Name of the SCCM server
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	4/24/2019 9:56 AM
		Created by:   	Mick Pletcher
		Filename:		SCCMCleanup.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SCCMModule = '\\BNASCCM\D$\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1',
	[ValidateNotNullOrEmpty()]
	[string]$SCCMServer = 'BNASCCM.wallerlaw.int',
	[ValidateNotNullOrEmpty()]
	[string]$SCCMSiteDescription = 'Primary SCCM Site',
	[ValidateNotNullOrEmpty()]
	[string]$SiteCode = 'BNA'
)

Import-Module -Name $SCCMModule -Force
New-PSDrive -Name $SiteCode -PSProvider 'AdminUI.PS.Provider\CMSite' -Root $SCCMServer -Description $SCCMSiteDescription | Out-Null
Set-Location -Path ($SiteCode + ':')
$List = Get-CMCollectionMember -CollectionName 'All Systems'
Remove-PSDrive -Name $SiteCode -Force
Write-Output $List.Name
