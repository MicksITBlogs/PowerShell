<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.98
	 Created on:   	11/23/2015 1:14 PM
	 Created by:   	Mick Pletcher
	 Filename:     	LocalAdministratorsDetectionMethod.ps1
	===========================================================================
	.DESCRIPTION
		This script will query the local administrators group. It will return a
		success to SCCM if there are no members in the local administrators 
		group or if a system is in the SystemExclusions array or a user is 
		in the MemberExclusions variable. 
#>

#Declare Global Variables
Set-Variable -Name LocalAdmins -Force
Set-Variable -Name LogFile -Value $env:windir"\Logs\LocalAdministrators_Emailed.log" -Force
Set-Variable -Name Member -Force
Set-Variable -Name MemberExclusions -Force
Set-Variable -Name Members -Force
Set-Variable -Name SystemExclusions -Force

cls
$MemberExclusions = @("Domain Admins","Workstation Admins")
$SystemExclusions = @("SYSTEM01")
$LocalAdmins = @()
$Members = net localgroup administrators | where { $_ -AND $_ -notmatch "command completed successfully" } | select -skip 4
$Profiles = Get-ChildItem -Path $env:SystemDrive"\users" -Force
Foreach ($Member in $Members) {
	$Member = $Member.Split("\")
	If ($Member.Count -gt 1) {
		[string]$Member = $Member[1]
		If ($Member -notin $MemberExclusions) {
			$LocalAdmins += $Member
		}
	}
	Remove-Variable -Name Member
}
if (($LocalAdmins.Count -eq 0) -and ((Test-Path -Path $LogFile) -eq $true)) {
	Remove-Item -Path $LogFile -Force
}
if (($LocalAdmins.Count -gt 0) -and ($env:COMPUTERNAME -notin $SystemExclusions) -and ((Test-Path -Path $LogFile) -eq $false )) {
	Start-Sleep -Seconds 5
	exit 0
} else {
	Write-Host "No Local Administrators"
	Start-Sleep -Seconds 5
	exit 0
}
$LocalAdmins = $null

#Cleanup Global Variables
Remove-Variable -Name LocalAdmins -Force
Remove-Variable -Name LogFile -Force
Remove-Variable -Name Member -Force
Remove-Variable -Name MemberExclusions -Force
Remove-Variable -Name Members -Force
Remove-Variable -Name SystemExclusions -Force
