<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.90
	 Created on:   	8/7/2015 9:54 AM
	 Created by:   	Mick Pletcher
	 Filename:     	WindowsUpdatesReport.ps1
	===========================================================================
	.DESCRIPTION
		This script will extract the list of windows updates installed 
		during an MDT installation.
	.EXAMPLE
		powershell.exe -executionpolicy bypass -file WindowsUpdatesReport.ps1 -OutputFile BaseBuild.csv -Path \\NetworkLocation\Directory
#>

param ([string]$OutputFile, [string]$Path)

function Get-RelativePath {
	#Declare Local Variables
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $RelativePath
	
	#Cleanup Local Variables
	Remove-Variable -Name RelativePath -Scope Local -Force
}

function ProcessTextFile {
	#Declare Local Variables  
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = Get-RelativePath
	If ((Test-Path -Path $RelativePath$OutputFile) -eq $true) {
		Remove-Item -Path $RelativePath$OutputFile -Force
	}
	
	#Cleanup Local Variables  
	Remove-Variable -Name RelativePath -Scope Local -Force
}

function Get-Updates {
	#Declare Local Variables
	Set-Variable -Name File -Scope Local -Force
	Set-Variable -Name Line -Scope Local -Force
	Set-Variable -Name LogFile -Scope Local -Value $env:SystemDrive"\MININT\SMSOSD\OSDLOGS\ZTIWindowsUpdate.log" -Force
	Set-Variable -Name Name -Scope Local -Force
	Set-Variable -Name Output -Scope Local -Force
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$OutputArray = @()
	$RelativePath = Get-RelativePath
	$File = Get-Content -Path $LogFile
	$Global:OutputFile = $RelativePath + $Global:OutputFile
	$Output = "KB Article" + "," + "Description"
	Out-File -FilePath $Global:OutputFile -InputObject $Output -Append -Force -Encoding UTF8
	If ($File -ne $null) {
		foreach ($Line in $File) {
			Set-Variable -Name KB -Scope Local -Force
			If ($Line -like "*INSTALL - *") {
				$Name = $Line
				$Name = $Name -replace 'x64-based', 'x64 based'
				$Name = $Name -replace '32-Bit', '32 Bit'
				$Name = $Name.split('-')
				If ($Name[7] -like "*Definition*") {
					$KB = $Name[7]
					$KB = $KB.Trim()
					$KB = $KB.split(' ')
					$KB = $KB.Trim()
					[string]$KB = $KB[0]
					$Name = $Name[6]
					$Name = $Name.Trim()
				} else {
					$KB = $Name[6]
					$KB = $KB.split('(')
					$KB = $KB.split(')')
					$KB = $KB.Trim()
					$KB = $KB[1]
					$Name = $Name[6]
					$Name = $Name.split('(')
					$Name = $Name[0]
					$Name = $Name.Trim()
				}
				$Output = $KB + "," + $Name
				$OutputArray = $OutputArray + $Output
				Remove-Variable -Name KB -Scope Local -Force
			}
		}
		$Line = $null
		$OutputArray = $OutputArray | select -Unique
		foreach ($Line in $OutputArray) {
			Out-File -FilePath $Global:OutputFile -InputObject $Line -Append -Force -Encoding UTF8
		}
	} else {
		$Output = "No User Input Properties Exist"
		Write-Host $Output
		Out-File -FilePath $Global:OutputFile -InputObject $Output -Append -Force -Encoding UTF8
	}
	
	#Cleanup Local Variables
	Remove-Variable -Name File -Scope Local -Force
	Remove-Variable -Name KB -Scope Local -Force
	Remove-Variable -Name Line -Scope Local -Force
	Remove-Variable -Name Name -Scope Local -Force
	Remove-Variable -Name Output -Scope Local -Force
	Remove-Variable -Name RelativePath -Scope Local -Force
}

cls
ProcessTextFile
Get-Updates
