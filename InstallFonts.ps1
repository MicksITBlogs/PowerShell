<#
	.SYNOPSIS
		Install Fonts
	
	.DESCRIPTION
		Install all designated fonts that reside in the same directory as this script. By designated, this means TTF, OTF, and such defined in the -FontType parameter for the InstallFonts function. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	2/14/2018 2:39 PM
		Created by:   	Mick Pletcher
		Filename:     	InstallFonts.ps1
		===========================================================================
#>
[CmdletBinding()]
param ()

function Get-RelativePath {
<#
	.SYNOPSIS
		Get the relative path
	
	.DESCRIPTION
		Returns the location of the currently running PowerShell script
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
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
	
	Param ([String]$SourceDirectory,
		[String]$FontType)
	
	$FontType = "*." + $FontType
	$sa = new-object -comobject shell.application
	$Fonts = $sa.NameSpace(0x14)
	$Files = Get-ChildItem $SourceDirectory -Filter $FontType
	For ($i = 0; $i -lt $Files.Count; $i++) {
		$FontName = $Files[$i].Name.ToString().Trim()
		Write-Host "Installing"$FontName"....." -NoNewline
		$File = $Env:windir + "\Fonts\" + $Files[$i].Name
		If ((Test-Path $File) -eq $false) {
			$Fonts.CopyHere($Files[$i].FullName)
			If ((Test-Path $File) -eq $true) {
				Write-Host "Installed" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
				Exit 1
			}
		} else {
			Write-Host "Already Installed" -ForegroundColor Yellow
		}
	}
}

Clear-Host
$RelativePath = Get-RelativePath
$Success = Install-Fonts -SourceDirectory $RelativePath -FontType "ttf"
