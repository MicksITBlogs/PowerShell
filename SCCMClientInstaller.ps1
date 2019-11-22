<#
	.SYNOPSIS
		Install SCCM Client
	
	.DESCRIPTION
		Install the SCCM client from the client installation folder located on the SCCM server.
	
	.PARAMETER MP
		Management Point
	
	.PARAMETER FSP
		Fallback Status Point
	
	.PARAMETER SiteCode
		Three letter SiteCode
	
	.PARAMETER ClientPath
		Network location on the SCCM server where the client resides
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	11/21/2019 4:14 PM
		Created by:   	Mick Pletcher
		Filename:		SCCMClientInstaller.ps1
		===========================================================================
#>

[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$MP,
	[ValidateNotNullOrEmpty()]
	[string]$FSP,
	[ValidateNotNullOrEmpty()]
	[string]$SiteCode,
	[ValidateNotNullOrEmpty()]
	[string]$ClientPath
)

#Add backslash to end of $ClientPath if it does not exist
If ($ClientPath.Substring($ClientPath.Length - 1) -ne '\') {
	$ClientPath += '\'
}
Write-Host 'Initiating SCCM Client Installation.....'
#Execute the ccmsetup.exe file
$ExitCode=(Start-Process -FilePath ($ClientPath + 'ccmsetup.exe') -ArgumentList ('/mp:' + $MP + [char]32 + 'SMSSITECODE=' + $SiteCode + [char]32 + 'FSP=' + $FSP) -PassThru -WindowStyle Minimized -Wait).ExitCode
If ($ExitCode -eq 0) {
	Write-Host 'Waiting for installation to begin.....'
	$StartTime = Get-Date
	#Wait until the ccmsetup.exe appears in the task manager
    Do {
        $Process = (Get-Process -Name ccm*).Name
		$TimeSpan = New-TimeSpan -Start $StartTime -End (Get-Date)
		#Exit if it takes more than 300 seconds for the ccmsetup.exe to begin
        If ($TimeSpan.TotalSeconds -gt 300) {
            Exit 2
        }
    } While ($Process -notcontains 'ccmsetup')
	Write-Host 'Installing SCCM Client.....' -NoNewline
	$StartTime = Get-Date
	#Wait until ccmsetup.exe closes
    Do {
        $Process = (Get-Process -Name ccm*).Name
        $TimeSpan = New-TimeSpan -Start $StartTime -End (Get-Date)
		#Exit with error code 3 if the ccmsetup.exe runs longer than 600 seconds
		If ($TimeSpan.TotalSeconds -gt 600) {
            Exit 3
        }
    } While ($Process -contains 'ccmsetup')
} else {
    Exit 1
}
#Exit with error code 0 if ccmexec.exe is running in the task manager, otherwise exit with an error code 4
If ((Get-Process -Name CcmExec) -ne $null) {
	Write-Host 'SCCM Client Successfully installed' -ForegroundColor Yellow
}
else {
	Write-Host 'SCCM Client installation failed' -ForegroundColor Red
	Exit 4
}
