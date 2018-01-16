<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.98
	 Created on:   	11/23/2015 1:14 PM
	 Created by:   	Mick Pletcher
	 Filename:     	LocalAdministrators.ps1
	===========================================================================
	.DESCRIPTION
		This script will open query the local administrators group. It generates
		a log file if there are users in the local administrators group that are
		not in the exclusions group. A .log file is written to the local HDD. The
		script then returns a error code 0 back to SCCM, which will initiate a 
		software deployment. At that point, the secondary script will email
		the .log file to the appropriate users. That script then deletes the
		.log file which will then create a successful 
#>

#Declare Global Variables
Set-Variable -Name Body -Force
Set-Variable -Name EmailAddress -Force
Set-Variable -Name EmailAddresses -Force
Set-Variable -Name Exclusions -Force
Set-Variable -Name LocalAdmin -Force
Set-Variable -Name LocalAdmins -Force
Set-Variable -Name LogFile -Value $env:windir"\Logs\LocalAdministrators.log" -Force
Set-Variable -Name LogFileEmailed -Value $env:windir"\Logs\LocalAdministrators_Emailed.log" -Force
Set-Variable -Name Member -Force
Set-Variable -Name Members -Force
Set-Variable -Name Output -Force
Set-Variable -Name Prof -Force
Set-Variable -Name Profiles -Force
Set-Variable -Name RelativePath -Force

cls
$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
$Body = "Local Administrator(s)" + [char]13 + "---------------------------" + [char]13
$EmailAddresses = @()
$EmailAddresses = Get-Content -Path $RelativePath"EmailAddresses.txt"
$LocalAdmins = @()
$Members = net localgroup administrators | where { $_ -AND $_ -notmatch "command completed successfully" } | select -skip 4
$Profiles = Get-ChildItem -Path $env:SystemDrive"\users" -Force
$Exclusions = Get-Content -Path $RelativePath"Exclusions.txt"
Foreach ($Member in $Members) {
	$Member = $Member.Split("\")
	If ($Member.Count -gt 1) {
		[string]$Member = $Member[1]
		If ($Member -notin $Exclusions) {
			Foreach ($Prof in $Profiles) {
				If ($Member -eq $Prof) {
					$LocalAdmins += $Member
				}
			}
		}
	}
	Remove-Variable -Name Member
}
if ((Test-Path $LogFileEmailed) -eq $true) {
	Remove-Item -Path $LogFileEmailed -Force
}
if ((Test-Path $LogFile) -eq $true) {
	Remove-Item -Path $LogFile -Force
}
if ($LocalAdmins.Count -gt 0) {
	if ((Test-Path $LogFile) -eq $false) {
		New-Item -Path $LogFile -ItemType file -Force
	}
	foreach ($LocalAdmin in $LocalAdmins) {
		Add-Content -Path $LogFile -Value $LocalAdmin -Force
		$Body = $Body + $LocalAdmin + [char]13
	}
}
If ($LocalAdmins.count -eq 1) {
	$Output = $LocalAdmin + [char]32 + "is a local administrator on" + [char]32 + $env:COMPUTERNAME
	foreach ($EmailAddress in $EmailAddresses) {
		Send-MailMessage -To $EmailAddress -From "IT@acme.com" -Subject "Local Administrator Report" -Body $Output -SmtpServer "smtp.acme.com"
	}
	Rename-Item -Path $LogFile -NewName $LogFileEmailed -Force
} else {
	$Output = "The attached file lists all local administrators on" + [char]32 + $env:COMPUTERNAME
	foreach ($EmailAddress in $EmailAddresses) {
		Send-MailMessage -To $EmailAddress -From "IT@acme.com" -Subject "Local Administrator Report" -Body $Output -Attachments $LogFile -SmtpServer "smtp.acme.com"
	}
	Rename-Item -Path $LogFile -NewName $LogFileEmailed -Force
}
$LocalAdmins = $null

#Cleanup Global Variables
Remove-Variable -Name Body -Force
Remove-Variable -Name EmailAddress -Force
Remove-Variable -Name EmailAddresses -Force
Remove-Variable -Name Exclusions -Force
Remove-Variable -Name LocalAdmin -Force
Remove-Variable -Name LocalAdmins -Force
Remove-Variable -Name LogFile -Force
Remove-Variable -Name LogFileEmailed -Force
Remove-Variable -Name Members -Force
Remove-Variable -Name Output -Force
Remove-Variable -Name Prof -Force
Remove-Variable -Name Profiles -Force
