<#
	.SYNOPSIS
		Logon Detail
	
	.DESCRIPTION
		This will report all logons to a centralized CSV file
	
	.PARAMETER FileName
		Name of CSV file
	
	.PARAMETER ReportPath
		UNC path where report is generated
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	10/11/2018 3:27 PM
		Created by:   	Mick Pletcher
		Filename:		LogonReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$FileName = 'LogonReport.csv',
	[ValidateNotNullOrEmpty()]
	[string]$ReportPath = 'UNC Path'
)


$Events = @()
$Logons = (Get-WinEvent -FilterHashtable @{logname  = 'security'; ID = 4624}) | Where-Object {(($_.Message -notlike "*S-1-5-18*"))}
foreach ($Logon in $Logons)
{
	$object = New-Object -TypeName System.Management.Automation.PSObject
	$AccountName = ((((($Logon.Message -split 'Account Domain:')[1]).Trim()) -split "Logon ID:")[0].Trim()) + '\' + ((((($Logon.Message -split 'Account Name:')[1].Trim())) -split 'Account Domain:')[0].Trim())
	$SecurityID = (((($Logon.Message -split 'Security ID:')[1].Trim()) -split 'Account Name:')[0]).Trim()
	$LogonType = (((($Logon.Message -split 'Logon Type:')[1].Trim()) -split 'Restricted Admin Mode:')[0]).Trim()
	switch ($LogonType) {
		'2' { $LogonType = 'Keyboard Logon'}
		'3' { $LogonType = 'Remote File Share Logon' }
		'4' { $LogonType = 'Scheduled Task Logon' }
		'5' { $LogonType = 'Service Account Logon' }
		'7' { $LogonType = 'Unlock Workstation' }
		'8' { $LogonType = 'Network Clear Text Logon' }
		'9' { $LogonType = 'Application RunAs Different Credentials' }
		'10' { $LogonType = 'Remote Interactive Logon' }
		'11' { $LogonType = 'Cached Credential Logon' }
		default { $LogonType = 'Unknown Logon Type'}
	}
	If ($LogonType -ne 'Unknown Logon Type') {
		$object | Add-Member -MemberType NoteProperty -Name ComputerName -Value ($Logon.MachineName).Split('.')[0]
		$object | Add-Member -MemberType NoteProperty -Name UserName -Value $AccountName
		$object | Add-Member -MemberType NoteProperty -Name TimeStamp -Value $Logon.TimeCreated
		$object | Add-Member -MemberType NoteProperty -Name SecurityID -Value $SecurityID
		$object | Add-Member -MemberType NoteProperty -Name LogonType -Value $LogonType
		$Events += $object
	}
}
$Events
If ($ReportPath.Substring($ReportPath.Length - 1) -ne '\') {
	$ReportPath += '\'
}
$File = $ReportPath + $FileName
Do {
	Try {
		$Events | ConvertTo-Csv -NoTypeInformation | select -Skip 1 | Out-File -FilePath $File -Encoding UTF8 -Append
		$Success = $true
	} Catch {
		Start-Sleep -Seconds 2
		$Success = $false
	}
} while ($Success -eq $false)
