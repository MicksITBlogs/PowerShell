<#
	.SYNOPSIS
		Install Open Text and True Type Fonts
	
	.DESCRIPTION
		This script will install OTF and TTF fonts that exist in the same directory as the script.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.187
		Created on:   	6/24/2021 9:36 AM
		Created by:   	Mick Pletcher
		Filename:     	InstallFonts.ps1
		===========================================================================
#>

<#
	.SYNOPSIS
		Install the font
	
	.DESCRIPTION
		This function will attempt to install the font by copying it to the c:\windows\fonts directory and then registering it in the registry. This also outputs the status of each step for easy tracking. 
	
	.PARAMETER FontFile
		Name of the Font File to install
	
	.EXAMPLE
				PS C:\> Install-Font -FontFile $value1
	
	.NOTES
		Additional information about the function.
#>
function Install-Font {
	param
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][System.IO.FileInfo]$FontFile
	)
	
	#Get Font Name from the File's Extended Attributes
	$oShell = new-object -com shell.application
	$Folder = $oShell.namespace($FontFile.DirectoryName)
	$Item = $Folder.Items().Item($FontFile.Name)
	$FontName = $Folder.GetDetailsOf($Item, 21)
	try {
		switch ($FontFile.Extension) {
			".ttf" {$FontName = $FontName + [char]32 + '(TrueType)'}
			".otf" {$FontName = $FontName + [char]32 + '(OpenType)'}
		}
		$fontTarget = $env:windir + "\Fonts\" + $FontFile.Name
		$regPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
		$regValue = $FontFile.Name
		$regName = $FontName

		$Copy = $true
		Write-Host ("Copying $($FontFile.Name).....") -NoNewline
		Copy-Item -Path $fontFile.FullName -Destination ($fontTarget) -Force
		# Test if font is copied over
		If ((Test-Path ($fontTarget)) -eq $true) {
			Write-Host ('Success') -Foreground Yellow
		} else {
			Write-Host ('Failed to copy file') -ForegroundColor Red
		}
		$Copy = $false

		# Create Registry item for font
		Write-Host ("Adding $FontName to the registry.....") -NoNewline
		If (!(Test-Path $regPath)) {
			New-Item -Path $regPath -Force | Out-Null
		}
		New-ItemProperty -Path $regPath -Name $regName -Value $regValue -PropertyType string -Force -ErrorAction SilentlyContinue| Out-Null

		$AddKey = $true
		If ((Get-ItemPropertyValue -Name $regName -Path $regPath) -eq $regValue) {
			Write-Host ('Success') -ForegroundColor Yellow
		} else {
			Write-Host ('Failed to set registry key') -ForegroundColor Red
		}
		$AddKey = $false
		
	} catch {
		If ($Copy -eq $true) {
			Write-Host ('Font file copy Failed') -ForegroundColor Red
			$Copy = $false
		}
		If ($AddKey -eq $true) {
			Write-Host ('Registry Key Creation Failed') -ForegroundColor Red
			$AddKey = $false
		}
		write-warning $_.exception.message
	}
	Write-Host
}

#Get a list of all font files relative to this script and parse through the list
foreach ($FontItem in (Get-ChildItem -Path $PSScriptRoot | Where-Object {
			($_.Name -like '*.ttf') -or ($_.Name -like '*.OTF')
		})) {
	Install-Font -FontFile $FontItem
}
