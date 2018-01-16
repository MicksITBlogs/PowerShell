<#
	.SYNOPSIS
		Install Dell Command | Update and Update the BIOS
	
	.DESCRIPTION
		Copy over the Dell Command | Update and install the BIOS
	
	.PARAMETER Source
		Source folder containing the Dell Command | Update files
	
	.PARAMETER Destination
		Location to copy the Dell Command | Update files to
	
	.PARAMETER XMLFile
		XML file that limits the Dell Command | Update to only scan for a BIOS update
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.120
		Created on:   	4/27/2016 10:17 AM
		Created by:	Mick Pletcher
		Filename:	UpdateBIOSWinPE.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[string]$Source = 't:\',
		[string]$Destination = 'x:\DCU',
		[string]$XMLFile
)

function Copy-Folder {
<#
	.SYNOPSIS
		Copy Folder
	
	.DESCRIPTION
		Copy folder to destination
	
	.PARAMETER SourceFolder
		Folder to copy contents from
	
	.PARAMETER DestinationFolder
		Folder to copy contents to
	
	.PARAMETER Subfolders
		Include all subfolders
	
	.PARAMETER Mirror
		Mirror the destination folder with the source folder. Contents that exist in the destination folder, but not in the source folder, will be deleted.
	
	.EXAMPLE
		PS C:\> Copy-Folder -SourceFolder 'Value1' -DestinationFolder 'Value2'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[string]$SourceFolder,
			[string]$DestinationFolder,
			[ValidateSet($true, $false)][boolean]$Subfolders = $false,
			[ValidateSet($true, $false)][boolean]$Mirror = $false
	)
	
	$Executable = $env:windir + "\system32\Robocopy.exe"
	$Switches = $SourceFolder + [char]32 + $DestinationFolder + [char]32 + "/eta"
	If ($Subfolders -eq $true) {
		$Switches = $Switches + [char]32 + "/e"
	}
	If ($Mirror -eq $true) {
		$Switches = $Switches + [char]32 + "/mir"
	}
	Write-Host "Copying "$SourceFolder"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 1)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
	}
}

function Update-BIOS {
<#
	.SYNOPSIS
		Update to the latest BIOS Version
	
	.DESCRIPTION
		Execute the DCU-CLI.exe to query Dell for the latest BIOS version
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Executable = $Destination + "\dcu-cli.exe"
	If ($XMLFile -eq "") {
		$Switches = " "
	} else {
		$XMLFile = $Destination + "\" + $XMLFile
		$Switches = "/policy" + [char]32 + $XMLFile
	}
	#$Switches = " "
	Write-Host "Updating BIOS....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If ($ErrCode -eq 0) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
	}
}

#Copy contents of the Dell Command | Update folder to the WinPE directory
Copy-Folder -SourceFolder $Source -DestinationFolder $Destination -Subfolders $true -Mirror $true
#Copy msi.dll to the WinPE system32 folder to make msiexec.exe functional
Copy-Item -Path $Destination"\msi.dll" -Destination "x:\windows\system32" -Force
#Execute the dcu-cli.exe to update the BIOS
Update-BIOS
