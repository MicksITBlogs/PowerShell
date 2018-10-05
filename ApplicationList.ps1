<#
	.SYNOPSIS
		Optional Application Report
	
	.DESCRIPTION
		This script will query the MDT reference and production task sequences for a list of applications that are installed in the build. It will then query the system's add/remove programs list removing the build apps. This provides the build team with a list of apps to install in addition to the ones included in the build.
	
	.PARAMETER ReferenceTS
		Link to the reference task sequence
	
	.PARAMETER ProductionTS
		Link to the production task sequence
	
	.PARAMETER ARPExclusionsFile
		A description of the ARPExclusionsFile parameter.
	
	.PARAMETER TSExclusionsFile
		File containing list of exclusions for task sequence items
	
	.PARAMETER OutputDIR
		Directory to output the text file containing the list of applications
	
	.PARAMETER ExclusionsFile
		A description of the ExclusionsFile parameter.
	
	.PARAMETER Exclusions
		Text file containing a list of applications to exclude
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	9/18/2018 10:38 AM
		Created by:   	Mick Pletcher
		Filename:		OptionalApplicationReport.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$ReferenceTS = '\\DeploymentShare\Control\WIN10REF\ts.xml',
	[ValidateNotNullOrEmpty()][string]$ProductionTS = '\\DeploymentShareTST\Control\WINDOWS10PROD\ts.xml',
	[string]$ARPExclusionsFile = "\\InstalledApplications\ARPExclusions.txt",
	[string]$TSExclusionsFile = "\\InstalledApplications\TSExclusions.txt",
	[string]$OutputDIR = '\\NAS\ApplicationLists\'
)

$Applications = @()
$TSExclusions = Get-Content -Path $TSExclusionsFile
$ARPExclusions = Get-Content -Path $ARPExclusionsFile
$Installed = (Get-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*, REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*).DisplayName | Where-Object { ($_ -notlike '*Update for*') -and ($_ -notlike '*MUI*') -and ($_ -notlike '*Intel(R)*') } | ForEach-Object { If ($_ -notin $ARPExclusions) { $_ } } | Sort-Object -Unique
$TS = Get-Content -Path $ReferenceTS, $ProductionTS | Where-Object { $_ -like '*BDD_InstallApplication*' } | ForEach-Object { $_.split('=')[2].Replace('description', '').Replace('"', '').Trim() } | ForEach-Object { If ($_ -notin $TSExclusions) { $_ } } | Sort-Object
foreach ($App in $Installed) {
	If ($App -notin $TS) {
		$Applications += $App
	}
}
$Applications | Sort-Object -Unique | Out-file -FilePath ($OutputDIR + $env:COMPUTERNAME + '.txt')
