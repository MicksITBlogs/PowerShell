<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.99
	 Created on:   	1/18/2016 1:41 PM
	 Created by:   	Mick Pletcher
	 Filename:     	InstallOnlineUpdates.ps1
	===========================================================================
	.DESCRIPTION
		This script will install both exe updates and msu updates. It is
		intended to be used during the generation of a reference image. Not
		all updates can be injected offline into the OS. This script takes
		care of those by running post-OS install.
#>


function Install-EXEUpdates {
	#Declare Variables
	Set-Variable -Name Arguments -Scope Local -Force
	Set-Variable -Name ErrCode -Scope Local -Force
	Set-Variable -Name File -Scope Local -Force
	Set-Variable -Name EXEFiles -Scope Local -Force
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	$EXEFiles = Get-ChildItem -Path $RelativePath -Force | where { $_.Name -like "*.exe*" }
	If ($EXEFiles.Count -ge 1) {
		$EXEFiles | Sort-Object
		cls
		foreach ($File in $EXEFiles) {
			$Arguments = "/passive /norestart"
			Write-Host "Installing"$File.Name"....." -NoNewline
			$ErrCode = (Start-Process -FilePath $File.Fullname -ArgumentList $Arguments -Wait -Passthru).ExitCode
			If ($ErrCode -eq 0) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
			}
		}
	}

	#Cleanup Local Variables
	Remove-Variable -Name Arguments -Scope Local -Force
	Remove-Variable -Name ErrCode -Scope Local -Force
	Remove-Variable -Name File -Scope Local -Force
	Remove-Variable -Name EXEFiles -Scope Local -Force
	Remove-Variable -Name RelativePath -Scope Local -Force
}

function Install-MSUUpdates {
	#Declare Variables
	Set-Variable -Name Arguments -Scope Local -Force
	Set-Variable -Name ErrCode -Scope Local -Force
	Set-Variable -Name Executable -Value $env:windir"\System32\wusa.exe" -Scope Local -Force
	Set-Variable -Name File -Scope Local -Force
	Set-Variable -Name MSUFiles -Scope Local -Force
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	$MSUFiles = Get-ChildItem -Path $RelativePath -Force | where { $_.Name -like "*.msu*" }
	If ($MSUFiles.Count -ge 1) {
		$MSUFiles | Sort-Object
		cls
		foreach ($File in $MSUFiles) {
			$Arguments = $File.FullName + [char]32 + "/quiet /norestart"
			Write-Host "Installing"$File.Name"....." -NoNewline
			$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Arguments -Wait -Passthru).ExitCode
			If (($ErrCode -eq 0) -or ($ErrCode -eq 2359302)) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
			}
		}
	}
	
	#Cleanup Local Variables
	Remove-Variable -Name Arguments -Scope Local -Force
	Remove-Variable -Name ErrCode -Scope Local -Force
	Remove-Variable -Name Executable -Scope Local -Force
	Remove-Variable -Name File -Scope Local -Force
	Remove-Variable -Name MSUFiles -Scope Local -Force
	Remove-Variable -Name RelativePath -Scope Local -Force
}

cls
Install-EXEUpdates
Install-MSUUpdates
Start-Sleep -Seconds 5
