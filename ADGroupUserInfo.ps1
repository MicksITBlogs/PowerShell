<#
	.SYNOPSIS
		AD Security Group User Additions
	
	.DESCRIPTION
		This script retrieves a list of users added to a specified AD security group, which includes the date it was last modified. This info can be used to track whether a new user has been recently added to a security group, especially a group that elevates priviledges. This can be used as a tool to help fight cyber-crime.
	
	.PARAMETER NumberOfDays
		Number of days to look back for users having been added to the designated AD security group
	
	.PARAMETER SecurityGroup
		Name of the AD security group
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	9/1/2020 11:03 AM
		Created by:   	Mick Pletcher
		Filename:     	ADGroupUserInfo.ps1
		===========================================================================
#>

[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[int]$NumberOfDays,
	[ValidateNotNullOrEmpty()]
	[string]$SecurityGroup
)

Function Get-ADGroupMemberDate {
	
	[cmdletbinding()]
	Param (
		[parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, Mandatory = $True)]
		[string]$Group
		
	)
	
	Begin {
		[regex]$pattern = '^(?<State>\w+)\s+member(?:\s(?<DateTime>\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\s+(?:.*\\)?(?<DC>\w+|(?:(?:\w{8}-(?:\w{4}-){3}\w{12})))\s+(?:\d+)\s+(?:\d+)\s+(?<Modified>\d+))?'
		$DomainController = ($env:LOGONSERVER -replace "\\\\")
		If (!$DomainController) {
			Throw "Computer from which script is run is not joined to domain and domain controller can not be identified."
			Break
		}
	}
	Process {
		Write-Verbose "Checking distinguished name of the group $Group"
		Try {
			$distinguishedName = (Get-ADGroup -Identity $Group).DistinguishedName
		} Catch {
			Write-Warning "$group can not be found!"
			Break
		}
		$RepadminMetaData = (repadmin /showobjmeta $DomainController $distinguishedName | Select-String "^\w+\s+member" -Context 2)
		$Array = @()
		ForEach ($rep in $RepadminMetaData) {
			If ($rep.line -match $pattern) {
				$object = New-Object PSObject -Property @{
					Username  = [regex]::Matches($rep.context.postcontext, "CN=(?<Username>.*?),.*") | ForEach-Object {
						$_.Groups['Username'].Value
					}
					LastModified = If ($matches.DateTime) {
						[datetime]$matches.DateTime
					} Else {
						$Null
					}
					DomainController = $matches.dc
					Group	  = $group
					State	  = $matches.state
					ModifiedCounter = $matches.modified
				}
				$Array += $object
			}
		}
        Return $Array
	}
	End {
	}
}

$Users = Get-ADGroupMemberDate -Group $SecurityGroup | Select Username, LastModified
$NewUsers = @()
#Find users added to the AD Group within the designated number of days
Foreach ($User in $Users) {
    If ((New-TimeSpan -Start $User.LastModified -End (Get-Date)).Days -lt $NumberOfDays) {
        $NewUsers += $User
    }
}
If ($NewUsers.Count -gt 0) {
    Write-Output $NewUsers
} else {
    Exit 1
}
