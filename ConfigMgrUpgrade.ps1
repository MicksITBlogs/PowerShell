<#
	.SYNOPSIS
		Configuration Manager Upgrade Prerequisite
	
	.DESCRIPTION
		This script will prepare configuration manager for the upgrade to the newest version. This is based off of Martin Bengtsson's Updating MEMCM (Microsoft Endpoint Manager Configuration Manager) to version 1910 on Christmas Eve. https://www.imab.dk/early-christmas-present-updating-memcm-microsoft-endpoint-manager-configuration-manager-to-version-1910-on-christmas-eve/
	
	.PARAMETER SCCMModule
		Name of the ConfigMgr PowerShell Module
	
	.PARAMETER SCCMServer
		FQDN Name of the Configuration Manager server
	
	.PARAMETER SCCMSiteDescription
		Arbitrary description of the configuration manager server
	
	.PARAMETER SiteCode
		Three letter ConfigMgr site code
	
	.PARAMETER BackupLocation
		Location for SQL and SCCM backups
	
	.PARAMETER SQLServer
		FQDN of the SQL server
	
	.PARAMETER SQLDatabase
		Name of the SQL database
	
	.PARAMETER ModuleName
		Name of the SQL PowerShell Module
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	12/26/2019 12:22 PM
		Created by:   	Mick Pletcher
		Filename:		ConfigMgrUpgrade.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SCCMModule = 'ConfigurationManager.psd1',
	[ValidateNotNullOrEmpty()]
	[string]$SCCMServer,
	[ValidateNotNullOrEmpty()]
	[string]$SCCMSiteDescription = 'MEMCM Site Server',
	[ValidateNotNullOrEmpty()]
	[string]$SiteCode,
	[ValidateNotNullOrEmpty()]
	[string]$BackupLocation,
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase,
	[ValidateNotNullOrEmpty()]
	[string]$ModuleName = 'SQLServer'
)

#Import SQL Server PowerShell Module
If ((Get-Module -Name ((Import-Module -Name $ModuleName -ErrorAction SilentlyContinue -Force -PassThru).Name)) -eq $null) {
	#Install module if it does not exist
	Install-Module -Name $ModuleName -Confirm:$false -Force
	#Verify module got installed. Exit the script if it failed
	If ((Get-Module -Name ((Import-Module -Name $ModuleName -ErrorAction SilentlyContinue -Force -PassThru).Name)) -eq $null) {
		Write-Host 'Failed'
		Exit 2
	} else {
		Import-Module -Name $ModuleName -ErrorAction SilentlyContinue -Force
	}
}
If ((Get-Module).Name -contains $ModuleName) {
    Write-Host ('Successfully imported' + [char]32 + $ModuleName + [char]32 + 'PowerShell module')
} else {
   Write-Host ('Failed to load' + [char]32 + $ModuleName + [char]32 + 'PowerShell module')
}
#Import ConfigMgr PowerShell Module
$Module = (Get-ChildItem ((Get-WmiObject -Class 'sms_site' -Namespace 'Root\sms\site_BNA').InstallDir) -Filter $SCCMModule -Recurse -ErrorAction SilentlyContinue)
Import-Module -Name $Module[0].FullName -Force
If ((Get-Module).Name -contains $Module[0].BaseName) {
    Write-Host ('Successfully imported' + [char]32 + $Module[0].BaseName + [char]32 + 'PowerShell module')
} else {
    Write-Host ('Failed to load' + [char]32 + $SCCMModule + [char]32 + 'PowerShell module')
}
#Import PSWindowsUpdate PowerShell Module
Import-Module -Name PSWindowsUpdate -Force
If ((Get-Module).Name -contains 'PSWindowsUpdate') {
    Write-host 'Successfully imported PSWindowsUpdate PowerShell module'
}
#Map ConfigMgr Drive
If ((Test-Path ($SiteCode + ':')) -eq $false) {
	New-PSDrive -Name $SiteCode -PSProvider 'AdminUI.PS.Provider\CMSite' -Root $SCCMServer -Description $SCCMSiteDescription | Out-Null
}
#Change directory to ConfigMgr drive
Set-Location -Path ($SiteCode + ':')
#Backup cd.latest directory
$DIR = Get-ChildItem -Path (Get-WmiObject -Class 'sms_site' -Namespace 'Root\sms\site_BNA').InstallDir -Filter 'cd.latest' -Directory -Recurse -ErrorAction SilentlyContinue
robocopy $DIR.FullName ($BackupLocation + '\cd.latest') /e /eta ('/log:' + $BackupLocation + '\Robocopy.log')
If ($LastExitCode -le 7) {
    Write-Host 'cd.latest backup succeeded' -ForegroundColor Yellow
} else {
    Write-Host 'cd.latest backup failed' -ForegroundColor Red
}
#Disable Maintenance tasks for upgrade
$Enabled = $false
Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -like 'backup* site server'} | Set-CMSiteMaintenanceTask -Enabled $Enabled
If (((Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -like 'backup* site server'}).Enabled) -eq $false) {
	$BackupSiteServer = $true
} else {
	$BackupSiteServer = $false
}
If ($BackupSiteServer -eq $true) {
	Write-Host 'Backup site server is disabled' -ForegroundColor Yellow
} else {
	Write-Host 'Backup site server is still enabled' -ForegroundColor Red
}
Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -eq 'delete aged client operations'} | Set-CMSiteMaintenanceTask -Enabled $Enabled
If (((Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -eq 'delete aged client operations'}).Enabled) -eq $false) {
	$AgedClientOperations = $true
} else {
	$AgedClientOperations = $false
}
If ($AgedClientOperations -eq $true) {
	Write-Host 'Delete aged client operations is disabled' -ForegroundColor Yellow
} else {
	Write-Host 'Delete aged client operations is still enabled' -ForegroundColor Red
}
Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -eq 'delete aged discovery data'} | Set-CMSiteMaintenanceTask -Enabled $Enabled
If (((Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -eq 'delete aged discovery data'}).Enabled) -eq $false) {
	$AgedDiscoveryData = $true
} else {
	$AgedDiscoveryData = $false
}
If ($AgedDiscoveryData -eq $true) {
	Write-Host 'Delete aged discovery data is disabled' -ForegroundColor Yellow
} else {
	Write-Host 'Delete aged discovery data is still enabled' -ForegroundColor Red
}
Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -eq 'delete aged log data'} | Set-CMSiteMaintenanceTask -Enabled $Enabled
If (((Get-CMSiteMaintenanceTask | Where-Object {$_.ItemName -eq 'delete aged log data'}).Enabled) -eq $false) {
	$AgedLogData = $true
} else {
	$AgedLogData = $false
}
If ($AgedLogData -eq $true) {
	Write-Host 'Delete aged log data is disabled' -ForegroundColor Yellow
} else {
	Write-Host 'Delete aged log data is still enabled' -ForegroundColor Red
}
#Verify all windows updates are applied
If ((Get-WindowsUpdate -WindowsUpdate) -eq $null) {
	$AppliedUpdates = $true
} else {
	$AppliedUpdates = $false
}
If ($AppliedUpdates -eq $true) {
	Write-Host ((Get-WmiObject -Class Win32_OperatingSystem).Caption + [char]32 + 'is fully patched') -ForegroundColor Yellow
} else {
	Write-Host ((Get-WmiObject -Class Win32_OperatingSystem).Caption + [char]32 + 'is not fully patched') -ForegroundColor Red
}

#Backup the Configuration Manager SQL Database
Backup-SqlDatabase -ServerInstance $SQLServer -Database $SQLDatabase -BackupFile ($BackupLocation + '\CM_SQL_Backup.bak') -Checksum
$Verbose = $($Verbose = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('RESTORE VERIFYONLY FROM DISK = N' + [char]39 + $BackupLocation + '\CM_SQL_Backup.bak' + [char]39) -QueryTimeout 0 -Verbose) 4>&1
If ($Verbose -like '*The backup set on file 1 is valid*') {
	$SQLBackup = $true
} else {
	$SQLBackup = $false
}
#Output the results
If ($SQLBackup -eq $true) {
	Write-Host 'SQL backup was successful' -ForegroundColor Yellow
} else {
	Write-Host 'SQL backup failed' -ForegroundColor Red
}
