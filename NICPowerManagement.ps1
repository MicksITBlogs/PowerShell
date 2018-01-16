<#
	.SYNOPSIS
		NIC Power Management
	
	.DESCRIPTION
		Configure NIC Power Management settings
	
	.PARAMETER ConsoleTitle
		Title displayed in the PowerShell Console
	
	.PARAMETER TurnOffDevice
		Allow the computer to turn off this device to save power. Select true to check this or false to uncheck it.
	
	.PARAMETER WakeComputer
		Allow this device to wake the computer. Select true to check this or false to uncheck it.
	
	.PARAMETER AllowMagicPacketsOnly
		Only allow a magic packet to wake the computer. Select true to check this or false to uncheck it.
	
	.EXAMPLE
		powershell.exe -executionpolicy bypass -file NICPowerManagement.ps1 -ConsoleTitle "NIC Power Management" -TurnOffDevice $true -WakeComputer $true -AllowMagicPacketsOnly $true
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.119
		Created on:   	4/20/2016 11:20 AM
		Created by:   	Mick Pletcher
		Filename:     	NICPowerManagement.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[Parameter(Mandatory = $false)][string]$ConsoleTitle = 'NIC Power Management',
		[bool]$TurnOffDevice = $true,
		[bool]$WakeComputer = $true,
		[bool]$AllowMagicPacketsOnly = $true
)

function Exit-PowerShell {
<#
	.SYNOPSIS
		Exit PowerShell
	
	.DESCRIPTION
		Exit out of the PowerShell script and return an error code 1 if errors were encountered
	
	.PARAMETER Errors
		True or false if errors were encountered
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[bool]$Errors
	)
	
	If ($Errors -eq $true) {
		Exit 1
	}
}

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

function Get-PhysicalNICs {
<#
	.SYNOPSIS
		Retrieve the Physical NICs
	
	.DESCRIPTION
		Find the physical NICs that are currently being used and return the information from the function
	
	.EXAMPLE
		PS C:\> Get-PhysicalNICs
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	# Get all physical ethernet adaptors
	$NICs = Get-WmiObject Win32_NetworkAdapter -filter "AdapterTypeID = '0' `
	AND PhysicalAdapter = 'true' `
	AND NOT Description LIKE '%Centrino%' `
	AND NOT Description LIKE '%wireless%' `
	AND NOT Description LIKE '%virtual%' `
	AND NOT Description LIKE '%WiFi%' `
	AND NOT Description LIKE '%Bluetooth%'"
	Return $NICs
}

function Set-ConsoleTitle {
<#
	.SYNOPSIS
		Console Title
	
	.DESCRIPTION
		Sets the title of the PowerShell Console
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
}

function Set-NICPowerManagement {
<#
	.SYNOPSIS
		Enable NIC Power Management
	
	.DESCRIPTION
		A detailed description of the Set-NICPowerManagement function.
	
	.PARAMETER NICs
		Physical NICs
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([bool])]
	param
	(
			$NICs
	)
	
	foreach ($NIC in $NICs) {
		$Errors = $false
		Write-Host "NIC:"$NIC.Name
		#Allow the computer to turn off this device
		Write-Host "Allow the computer to turn off this device....." -NoNewline
		$NICPowerManage = Get-WmiObject MSPower_DeviceEnable -Namespace root\wmi | Where-Object { $_.instancename -match [regex]::escape($nic.PNPDeviceID) }
		If ($NICPowerManage.Enable -ne $TurnOffDevice) {
			$NICPowerManage.Enable = $TurnOffDevice
			$HideOutput = $NICPowerManage.psbase.Put()
		}
		If ($NICPowerManage.Enable -eq $TurnOffDevice) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Errors = $true
		}
		# Allow this device to wake the computer
		Write-Host "Allow this device to wake the computer....." -NoNewline
		$NICPowerManage = Get-WmiObject MSPower_DeviceWakeEnable -Namespace root\wmi | Where-Object { $_.instancename -match [regex]::escape($nic.PNPDeviceID) }
		If ($NICPowerManage.Enable -ne $WakeComputer) {
			$NICPowerManage.Enable = $WakeComputer
			$HideOutput = $NICPowerManage.psbase.Put()
		}
		If ($NICPowerManage.Enable -eq $WakeComputer) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Errors = $true
		}
		# Only allow a magic packet to wake the computer
		Write-Host "Only allow a magic packet to wake the computer....." -NoNewline
		$NICPowerManage = Get-WmiObject MSNdis_DeviceWakeOnMagicPacketOnly -Namespace root\wmi | Where-Object { $_.instancename -match [regex]::escape($nic.PNPDeviceID) }
		If ($NICPowerManage.EnableWakeOnMagicPacketOnly -ne $AllowMagicPacketsOnly) {
			$NICPowerManage.EnableWakeOnMagicPacketOnly = $AllowMagicPacketsOnly
			$HideOutput = $NICPowerManage.psbase.Put()
		}
		If ($NICPowerManage.EnableWakeOnMagicPacketOnly -eq $AllowMagicPacketsOnly) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Errors = $true
		}
	}
	Return $Errors
}

Clear-Host
Set-ConsoleTitle
$PhysicalNICs = Get-PhysicalNICs
$Errors = Set-NICPowerManagement -NICs $PhysicalNICs
Start-Sleep -Seconds 5
Exit-PowerShell -Errors $Errors
