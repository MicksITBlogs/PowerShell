<#
	.SYNOPSIS
		Trusted Sites Report
	
	.DESCRIPTION
		This script will retrieve a list of trusted sites pushed out via GPO and write the list to a text file in the same directory as the script.
	
	.PARAMETER FileOutput
		Specifies to write output to a file
	
	.PARAMETER FileName
		Name of the file to write the output to
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.143
		Created on:   	10/3/2017 2:23 PM
		Created by:   	Mick Pletcher
		Filename:     	TrustedSitesReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[switch]$FileOutput,
	[ValidateNotNullOrEmpty()][string]$FileName = 'TrustedSitesReport.txt'
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

#User based trusted sites
$HKCU = $(get-item "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey" -ErrorAction SilentlyContinue).property | Sort-Object
#Local machines based trusted sites
$HKLM = $(get-item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMapKey" -ErrorAction SilentlyContinue).property | Sort-Object
#Get the location where this script is being executed from
$RelativePath = Get-RelativePath
#Define the path to the output file
$File = $RelativePath + "TrustedSitesReport.txt"
#Delete the output file if it exists
If ((Test-Path $File) -eq $true) {
	Remove-Item -Path $File -Force
}
#Create output file
New-Item -Path $File -ItemType File -Force
#Add HKCU trusted sites to the output file if they exist
If ($HKCU -ne $null) {
	#Create Screen Header
	"HKEY_CURRENT_USERS" | Out-File -FilePath $File -Append
	#Display to the screen
	$HKCU
	If ($FileOutput.IsPresent) {
		$HKCU | Out-File -FilePath $File -Append
	}
	#Input seperator" 
	" "| Out-File -FilePath $File -Append
}
#Add HKLM trusted sites to the output file if they exist
If ($HKLM -ne $null) {
	#Create Screen Header
	"HKEY_LOCAL_MACHINE" | Out-File -FilePath $File -Append
	#Display to the screen
	$HKLM
	If ($FileOutput.IsPresent) {
		$HKLM | Out-File -FilePath $File -Append
	}
}
