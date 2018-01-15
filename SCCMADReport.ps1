<#
	.SYNOPSIS
		System Status Reporting Tool
	
	.DESCRIPTION
		This script will generate a report that pulls from the SCCM All Systems collection, active directory, and the DNS. The script will first get a list of All Systems that is typically populated by active directory. It will then iterate through the list getting the system name from SCCM, IP address from DNS, last logon time stamp from AD, if it is pingable from PowerShell, if the SCCM client is installed, if the client is active, and the last active time of the client. This information is put in a report form and written both to a CSV file and to the display. The report will show systems without the SCCM client, systems that have not been online for a long time, and systems that may have a corrupt client.
	
	.PARAMETER SiteCode
		SCCM site code needed to execute the configuration manager cmdlets.
	
	.PARAMETER SCCMModule
		Path to the configuration manager PowerShell module
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.136
		Created on:   	3/28/2017 9:54 AM
		Created by:   	Mick Pletcher
		Filename:	SCCMADReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$SiteCode,
	[ValidateNotNullOrEmpty()][string]$SCCMModule
)
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

Clear-Host
Import-Module DnsClient
Import-Module ActiveDirectory
Import-Module -Name $SCCMModule
#Format sitecode
If ($SiteCode[$SiteCode.Length - 1] -ne ":") {
	$SiteCode = $SiteCode + ":"
}
#Get location of current powershell connection
$Location = (get-location).Path.Split("\")[0]
#Change connection to configuration manager
Set-Location $SiteCode
#Get list of all systems in SCCM
Clear-Host
$RetrievalOutput = "Retrieving list of systems from SCCM....."
$Systems = Get-CMDevice -CollectionName "All Systems" | Where-Object { $_.Name -notlike "*Unknown Computer*" }
Clear-Host
If ($Systems -ne $null) {
	$RetrievalOutput += "Success"
} else {
	$RetrievalOutput += "Failed"
}
Write-Output $RetrievalOutput
#Create Reports array
$Report = @()
$Count = 1
foreach ($System in $Systems) {
	Clear-Host
	$ProcessingOutput = "Processing $Count of " + $Systems.Count + " systems"
	$SystemInfoOutput = "System Name: " + $System.Name
	Write-Output $RetrievalOutput
	Write-Output $ProcessingOutput
	Write-Output $SystemInfoOutput
	#Get SCCM info for $System
	$SCCMSystemInfo = $Systems | Where-Object { $_.Name -eq $System.Name }
	#Get the last logon timestamp from active directory
	Try {
		$LLTS = [datetime]::FromFileTime((get-adcomputer $System.Name -properties LastLogonTimeStamp -ErrorAction Stop).LastLogonTimeStamp).ToString('d MMMM yyyy')
	} Catch {
		$Output = $System.Name + " is not in active directory"
		Write-Output $Output
	}
	#Test if the system is pingable
	$Pingable = Test-Connection -ComputerName $System.Name -Count 2 -Quiet
	#Get the ipaddress for the system
	Try {
		$IPAddress = (Resolve-DnsName -Name $System.Name -ErrorAction Stop).IPAddress
	} Catch {
		$Output = $System.Name + " IP address cannot be resolved"
		Write-Output $Output
	}
	$Object = New-Object -TypeName System.Management.Automation.PSObject
	$Object | Add-Member -MemberType NoteProperty -Name Name -Value $System.Name
	$Object | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
	$Object | Add-Member -MemberType NoteProperty -Name ADLastLogon -Value $LLTS
	$Object | Add-Member -MemberType NoteProperty -Name Pingable -Value $Pingable
	$Object | Add-Member -MemberType NoteProperty -Name SCCMClient -Value $SCCMSystemInfo.IsClient
	$Object | Add-Member -MemberType NoteProperty -Name SCCMActive -Value $SCCMSystemInfo.IsActive
	$Object | Add-Member -MemberType NoteProperty -Name SCCMLastActiveTime -Value $SCCMSystemInfo.LastActiveTime
	$Report += $Object
	#Clear variables if they exist so previous data is not used for systems that have null values
	If ($IPAddress) {
		Remove-Variable -Name IPAddress -Force
	}
	If ($LLTS) {
		Remove-Variable -Name LLTS -Force
	}
	If ($Pingable) {
		Remove-Variable -Name Pingable -Force
	}
	If ($SCCMInfo) {
		Remove-Variable -Name SCCMInfo -Force
	}
	$Count++
}
#Change connection to local system
Set-Location $Location
Clear-Host
#Sort report by computer name
$Report = $Report | Sort-Object -Property Name
#Get the path this script is being executed from
$RelativePath = Get-RelativePath
#Path and filename to write the report to
$File = $RelativePath + "SCCMReport.csv"
#Delete old report file
If ((Test-Path $File) -eq $true) {
	Remove-Item -Path $File -Force
}
#Write report to CSV file
$Report | Export-Csv -Path $File -Encoding UTF8 -Force
#Write Report to screen
$Report | Format-Table
