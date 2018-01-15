<#
	.SYNOPSIS
		Get Maximum Monitor Resolution
	
	.DESCRIPTION
		This script will retrieve the maximum possible resolution for monitors by identifying the associated driver. The driver INF file contains the maximum defined resolution for a monitor. This script is designed for Dell monitors only. It has not been tested on any other brand. Also, the monitors need to be installed in the device manager to get the correct association. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.139
		Created on:   	5/30/2017 12:37 PM 
		Created by:   	Mick Pletcher
		Filename:	MaxResolution.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()

function Get-MaximumResolution {
	#Create monitor array
	$Monitors = @()
	#Get associate monitor hardware ID for each monitor
	$HardwareIDs = (Get-WmiObject Win32_PNPEntity | where-object { $_.PNPClass -eq "Monitor" }).HardwareID | ForEach-Object { $_.Split("\")[1] }
	foreach ($Monitor in $HardwareIDs) {
		#Create object
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		#Get the location of the associated driver file
		$DriverFile = Get-ChildItem -path c:\windows\system32\driverstore -Filter *.inf -recurse | Where-Object { (Select-String -InputObject $_ -Pattern $Monitor -quiet) -eq $true }
		#Retrieve the maximum resolution from the INF file
		$MaxResolution = ((Get-Content -Path $DriverFile.FullName | Where-Object { $_ -like "*,,MaxResolution,,*" }).split('"')[1]).Split(",")
		#Write the Model to the object
		$Object | Add-Member -MemberType NoteProperty -Name Model -Value $DriverFile.BaseName.ToUpper()
		#Write the horizontal maximum resolution to the object
		$Object | Add-Member -MemberType NoteProperty -Name "Horizontal(X)" -Value $MaxResolution[0]
		#Write the vertical maximum resolution to the object
		$Object | Add-Member -MemberType NoteProperty -Name "Vertical(Y)" -Value $MaxResolution[1]
		#Write the object to the array
		$Monitors += $Object
	}
	Return $Monitors
}

#Display list of monitor with maximum available resolutions
$Monitors = Get-MaximumResolution
$Monitors
