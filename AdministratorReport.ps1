<#
	.SYNOPSIS
		Administrator Report
	
	.DESCRIPTION
		This tool is intended to keep staff informed of new administrator accounts. This script queries for a list of users in the specified administrator group(s). It then produces a list of the administrator users that got created within the specified number of days. 
	
	.PARAMETER Days
		Number of days since the administrator account was created
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.195
		Created on:   	11/9/2021 1:37 PM
		Created by:   	Mick Pletcher
		Filename:		AdministratorReport.ps1
		===========================================================================
#>
Param
(
	[ValidateNotNullOrEmpty()][int]$Days = 1
)

#Retrieves a list of users from AD and filters them by association with the specied security groups. The match can be associated with multiple groups separated with a pipe
#Example: Where-Object {$_.MemberOf -match '|Domain Admins|System Admins|'}
$Users = Get-ADUser -Filter * -Properties MemberOf | Where-Object {$_.MemberOf -match 'Super Admins|Domain Admins'}
#Filter out all accounts that are older than the specified $Days
$Users | ForEach-Object {
	If ((New-TimeSpan -Start ((Get-ADUser -Identity $_.SamAccountName -Properties whenCreated).whenCreated) -End (Get-Date)).Days -le $Days) {
		$NewUsers += $_.Name
	}
	
}
If (($NewUsers -ne $null) -and ($NewUsers -ne '')) {
	Write-Output $NewUsers
} Else {
	Exit 1
}
Exit 0
