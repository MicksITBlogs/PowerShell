<#
	.SYNOPSIS
		Configuration Manager PowerShell Module
	
	.DESCRIPTION
		This will copy the files needed to the computer this script is being executed on. It must be run using an AD account that has priviledges to both the directory on the ConfigMgr server and to the program files directory on the local computer.
	
	.PARAMETER ModuleSource
		UNC path containing the Configuration Manager PowerShell module
	
	.PARAMETER ModuleDirectoryName
		Name of the directory under the PowerShell Modules directory where the module is copied to
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	12/27/2019 12:37 PM
		Created by:   	Mick Pletcher
		Filename:		InstallConfigMgrModule.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$ModuleSource,
	[ValidateNotNull()]
	[ValidateNotNullOrEmpty()]
	[string]$ModuleDirectoryName = 'ConfigurationManager'
)

#Location where to copy the module to
$ModuleDestination = $env:ProgramFiles + '\WindowsPowerShell\Modules\' + $ModuleDirectoryName
#Remove the module from memory if it has already been imported
Remove-Module -Name ConfigurationManager -Force -ErrorAction SilentlyContinue
#Remove ConfigurationManager directory if it already exists
Remove-item -Path $ModuleDestination -Recurse -Force
#Create the directories for the PowerShell module
New-Item -Path $ModuleDestination -ItemType Directory -Force | Out-Null
New-Item -Path ($ModuleDestination + '\en-US') -ItemType Directory -Force | Out-Null
#Copy all necessary files for the Configuration Manager PowerShell Module
Get-ChildItem -Path $ModuleSource -Filter 'adminui.ps.*' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'adminui.wqlqueryengine.dll' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'Microsoft.ConfigurationManagement.*' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter '*.ps1xml' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'AdminUI.*' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'ConfigurationManager.psd1' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'Dcm*' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'Microsoft.Diagnostics.*' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'Microsoft.ConfigurationManagement.*' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Get-ChildItem -Path $ModuleSource -Filter 'Microsoft.ConfigurationManager.*' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination $ModuleDestination; If ((Test-Path ($ModuleDestination + '\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
#Copy all help files to the module folder
Get-ChildItem -Path ($ModuleSource + '\en-US') -Filter '*.xml' | ForEach-Object {Write-Host ('Copying ' + $_.Name + '.....') -NoNewline; Copy-Item -Path $_.FullName -Destination ($ModuleDestination + '\en-US'); If ((Test-Path ($ModuleDestination + '\en-US\' + $_.Name)) -eq $true) {Write-Host 'Success' -ForegroundColor Yellow} else {Write-Host 'Failed' -ForegroundColor Red}}
Import-Module -Name $ModuleDirectoryName
Write-Host
If (Get-Module -ListAvailable -Name $ModuleDirectoryName) {
	Remove-Module -Name $ModuleDirectoryName -Force
	Write-Host ($ModuleDirectoryName + [char]32 + 'PowerShell module installed successfully') -ForegroundColor Yellow
} else {
	Write-Host ($ModuleDirectoryName + [char]32 + 'PowerShell module installation failed') -ForegroundColor Red
}
