<#
	.SYNOPSIS
		ConfigMgr Cleanup
	
	.DESCRIPTION
		This script will compare the All Systems list in ConfigMgr to systems in AD and delete systems from ConfigMgr that are disabled in AD. It will also report a list of systems that are greater than 30 days old since the last activity in AD.
	
	.PARAMETER SQLServer
		A description of the SQLServer parameter.
	
	.PARAMETER SQLDatabase
		A description of the SQLDatabase parameter.
	
	.PARAMETER PSHCfgMgrModule
		Path to ConfigurationManager.psd1 module
	
	.PARAMETER Sitecode
		Three character ConfigMgr site code
	
	.PARAMETER SiteServer
		FQDN of the Configuration Manager server
	
	.PARAMETER DeleteSystems
		Select to automatically delete systems from Configuration Manager
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2022 v5.8.208
		Created on:   	7/26/2022 8:00 AM
		Created by:   	Mick Pletcher
		Filename:		MECMADCleanup.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase,
	[string]$PSHCfgMgrModule,
	[string]$SiteCode,
	[string]$SiteServer,
	[switch]$DeleteSystems
)

function Get-PSHModule {
<#
	.SYNOPSIS
		Import Module
	
	.DESCRIPTION
		Import specified module
	
	.PARAMETER Module
		Name of PowerShell Module
	
	.PARAMETER NoInstall
		Import only. Typically used for modules that are not in the PowerShell Gallery
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[string]$Module,
		[switch]$NoInstall
	)
	If ($NoInstall.IsPresent) {
		Import-Module -Name $Module
	}
	else {
		Try {
			Import-Module -Name $Module
		}
		Catch {
			Find-Module -Name $Module | Install-Module -Force
			Import-Module -Name $Module
		}
	}
}

#Import SQL Server PowerShell Module
Get-PSHModule -Module "SqlServer"
#Import AD PowerShell module
Get-PSHModule -Module "ActiveDirectory"
$Systems = @()
#Get All Systems list from ConfigMgr
$List = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query "SELECT NAME FROM dbo._RES_COLL_SMS00001 ORDER BY Name"
foreach ($System in $List) {
	#Filter out built-in accounts
	If (($System.Name -notlike '*Unknown*') -and ($System.Name -notlike '*Provisioning*')) {
		#Return a list of all systems either not in AD or that have been disabled
		Try {
			$AD = Get-ADComputer $System.Name
			If ($AD.Enabled -eq $false) {
				$Systems += $AD.Name
			}
		} catch {
			$Systems += $System.Name
		}
	}
}
$Systems
$Systems.Count
If ($Systems.Count -ne 0) {
	If ($DeleteSystems.IsPresent) {
		#Import ConfigMgr Module
		Get-PSHModule -Module $PSHCfgMgrModule -NoInstall
		If ((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
			New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $SiteServer
		}
		Set-Location "$($SiteCode):\"
		$Systems | ForEach-Object {
			Write-Host ('Deleting ' + $_ + '.....') -NoNewline
			Remove-CMDevice -Name $_ -Force
			If ((Get-CMDevice -Name $_) -eq $null) {
				Write-Host 'Success' -ForegroundColor Yellow
			} else {
				Write-Host 'Failed' -ForegroundColor Red
			}
		}
	}
}
	