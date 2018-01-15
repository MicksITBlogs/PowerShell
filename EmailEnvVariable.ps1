<#
	.SYNOPSIS
		Email Address Environment Variable
	
	.DESCRIPTION
		This script will assign the user's email address to the environment variable EmailAddress.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.128
		Created on:   	10/12/2016 1:14 PM 
		Created by:	Mick Pletcher
		Filename:	EmailEnvVariable.ps1
		===========================================================================
	
	.PARAMETER
		A description of the  parameter.
#>
[CmdletBinding()]
param ()

Import-Module ActiveDirectory
#Delete Environment Variable
[System.Environment]::SetEnvironmentVariable("EmailAddress", $null, 'User')
#Get the email address associated with the username
$EmailAddress = (Get-ADUser $env:USERNAME -Properties mail).mail
#Create a user based environment variable called email address
[System.Environment]::SetEnvironmentVariable("EmailAddress", $EmailAddress, 'User')
