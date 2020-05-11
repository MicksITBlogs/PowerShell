<#
	.SYNOPSIS
		A brief description of the DistributionPoints.ps1 file.
	
	.DESCRIPTION
		This script will query the VMware server for a list of machines. It will then query Configuration Manager to verify which of those machines are present. Finally, it adds the list of machines to a collection, which is assigned to a specific distribution point.
	
	.PARAMETER ServerCollection
		List of servers in Configuration Manager to compare with the list of servers from VMWare.
	
	.PARAMETER ConfigMgrSiteCode
		Three letter Configuration Manager site code
	
	.PARAMETER DistributionPointCollection
		Name of the collection containing a list of systems on the
	
	.PARAMETER VMWareServer
		Name of the VMWare server
	
	.PARAMETER ConfigMgrModule
		UNC path including file name of the configuration manager module
	
	.PARAMETER ConfigMgrServer
		FQDN of SCCM Server
	
	.PARAMETER ConfigMgrSiteDescription
		Description of the ConfigMgr Server
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	5/11/2020 9:50 AM
		Created by:   	Mick Pletcher
		Filename:     	DistributionPoints.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$AllServersCollection = '',
	[ValidateNotNullOrEmpty()]
	[string]$ConfigMgrSiteCode = '',
	[ValidateNotNullOrEmpty()]
	[string]$DistributionPointCollection = '',
	[ValidateNotNullOrEmpty()]
	[string]$VMWareServer = '',
	[ValidateNotNullOrEmpty()]
	[string]$ConfigMgrModule = '',
	[ValidateNotNullOrEmpty()]
	[string]$ConfigMgrServer = '',
	[ValidateNotNullOrEmpty()]
	[string]$ConfigMgrSiteDescription = ''
)

#Import PowerCLI module
Import-Module -Name VMWare.PowerCLI -ErrorAction SilentlyContinue | Out-Null
#Collection ID of the collection containing a list of all servers
$CollectionID = (Get-WmiObject -Namespace ("root\SMS\site_" + $ConfigMgrSiteCode) -Query ("select * from SMS_Collection Where SMS_Collection.Name=" + [char]39 + $AllServersCollection + [char]39) -ComputerName PRODCM).MemberClassName
#Retrieve the list of all servers
$MEMCMServerList = Get-WmiObject -Namespace ("root\SMS\site_" + $ConfigMgrSiteCode) -Query "select * FROM $CollectionID" -ComputerName PRODCM | Sort-Object -Property Name
#Establish a connection with teh VMWare server
Connect-VIServer -Server $VMWareServer | Out-Null
$VerifiedServers = @()
#Get the list of servers from the VMWare server that are also in Configuration Manager
(Get-VM).Name | Sort-Object | ForEach-Object {
	If ($_ -in $MEMCMServerList.Name) {
		$VerifiedServers += $_
	}
}
#CollectionID of the collection containing a list of all servers in VMWare
$CollectionID = (Get-WmiObject -Namespace ("root\SMS\site_" + $ConfigMgrSiteCode) -Query ("select * from SMS_Collection Where SMS_Collection.Name=" + [char]39 + $DistributionPointCollection + [char]39) -ComputerName PRODCM).MemberClassName
#Retrieve list of all servers in VMWare ConfigMgr collection
$MEMCMServerList = Get-WmiObject -Namespace ("root\SMS\site_" + $ConfigMgrSiteCode) -Query "select * FROM $CollectionID" -ComputerName PRODCM | Sort-Object -Property Name
$MissingSystems = @()
#Retrieve the list of servers that are not in the ConfigMgr collection
$VerifiedServers | ForEach-Object {
	If ($_ -notin $MEMCMServerList.Name) {
		$MissingSystems += $_
	}
}
If ($MissingSystems -ne $null) {
	#Import ConfigMgr PowerShell Module
	Import-Module -Name $ConfigMgrModule -Force
	#Map drive to ConfigMgr server
	New-PSDrive -Name $ConfigMgrSiteCode -PSProvider 'AdminUI.PS.Provider\CMSite' -Root $ConfigMgrServer -Description $ConfigMgrSiteDescription | Out-Null
	#Change current directory to ConfigMgr mapped drive
	Set-Location -Path ($ConfigMgrSiteCode + ':')
	#Add missing systems to the specified collection
	$MissingSystems | ForEach-Object {
		Add-CMDeviceCollectionDirectMembershipRule -CollectionName $DistributionPointCollection -ResourceID (Get-CMDevice -Name $_).ResourceID
	}
}