<#
	.SYNOPSIS
		Logon Reporting
	
	.DESCRIPTION
		This script will report the computername, username, IP address, and date/time to a central log file.
	
	.PARAMETER LogFile
		A description of the LogFile parameter.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	10/22/2018 10:13 AM
		Created by:   	Mick Pletcher
		Filename:		LogonReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$LogFile = 'LogonReport.csv'
)

$Entries = @()
$IPv4 = foreach ($ip in (ipconfig) -like '*IPv4*') {($ip -split ' : ')[-1]}
$DT = Get-Date
foreach ($IP in $IPv4) {
	$object = New-Object -TypeName System.Management.Automation.PSObject
	$object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $env:COMPUTERNAME
	$object | Add-Member -MemberType NoteProperty -Name UserName -Value $env:USERNAME
	$object | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IP
	$object | Add-Member -MemberType NoteProperty -Name DateTime -Value (Get-Date)
	$object
	$Entries += $object
}
foreach ($Entry in $Entries) {
	Do {
		Try {
			Export-Csv -InputObject $Entry -Path $LogFile -Encoding UTF8 -NoTypeInformation -NoClobber -Append
			$Success = $true
		} Catch {
			$Success = $false
			Start-Sleep -Seconds 1
		}
	} while ($Success -eq $false)
}
