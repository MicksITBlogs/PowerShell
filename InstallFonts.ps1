<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.93
	 Created on:   	9/18/2015 9:44 AM
	 Created by:   	Mick Pletcher
	 Filename:     	install.ps1
	===========================================================================
	.DESCRIPTION
		This script will install all fonts of the specified font type from
		the specified directory location. All of the fonts you want installed
		are to be placed in the specified directory location. The script will
		then read all files in that location and filter out for the specified
		font type. It will then install each font individually and output
		the status on whether it installed or not. 
#>

function Get-RelativePath {
	<#
	.SYNOPSIS
		Get-RelativePath
	.DESCRIPTION
		Defines the path which this script is being executed from
	.EXAMPLE
		$RelativePath = Get-RelativePath
	#>
	
	#Declare Local Variables
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $RelativePath
	
	#Cleanup Local Variables
	Remove-Variable -Name RelativePath -Scope Local -Force
}

Function Install-Fonts {
	<#
	.SYNOPSIS
		Install-Fonts
	.DESCRIPTION
		Installs all fonts in the designated source directory.
	.EXAMPLE
		Install-Fonts -SourceDirectory "c:\Fonts" -FontType "ttf"
	#>
	
	Param ([String]
		$SourceDirectory,
		[String]
		$FontType)
	
	#Define Local Variables
	Set-Variable -Name File -Scope Local -Force
	Set-Variable -Name Files -Scope Local -Force
	Set-Variable -Name Fonts -Scope Local -Force
	Set-Variable -Name i -Scope Local -Force
	Set-Variable -Name sa -Scope Local -Force
	
	$FontType = "*." + $FontType
	$sa = new-object -comobject shell.application
	$Fonts = $sa.NameSpace(0x14)
	$Files = Get-ChildItem $SourceDirectory -Filter $FontType
	For ($i = 0; $i -lt $Files.Count; $i++) {
		$Output = $Files[$i].Name + "....."
		Write-Host $Files[$i].Name"....." -NoNewline
		$File = $Env:windir + "\Fonts\" + $Files[$i].Name
		If ((Test-Path $File) -eq $false) {
			$Fonts.CopyHere($Files[$i].FullName)
			If ((Test-Path $File) -eq $true) {
				Write-Host "Installed" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
			}
		} else {
			Write-Host "Installed" -ForegroundColor Yellow
		}
	}
	
	#Cleanup Local Variables
	Remove-Variable -Name File -Scope Local -Force
	Remove-Variable -Name Files -Scope Local -Force
	Remove-Variable -Name Fonts -Scope Local -Force
	Remove-Variable -Name i -Scope Local -Force
	Remove-Variable -Name sa -Scope Local -Force
}

#Declare Local Variables
Set-Variable -Name RelativePath -Scope Local -Force

cls
$RelativePath = Get-RelativePath
Install-Fonts -SourceDirectory $RelativePath -FontType "ttf"
Install-Fonts -SourceDirectory $RelativePath -FontType "otf"

#Cleanup Local Variables
Remove-Variable -Name RelativePath -Scope Local -Force