<#
	.SYNOPSIS
		Install PowerShell Active Directory Module
	
	.DESCRIPTION
		Copies the PowerShell Active Directory Module to the WinPE environment. This allows the use of the PowerShell module without having to mount, inject the directories, and dismount a WIM everytime a new WIM is generated.
	
	.PARAMETER DomainUserName
		Username with domain access used to map drives
	
	.PARAMETER DomainPassword
		Domain password used to map network drives
	
	.PARAMETER NetworkPath
		Network path to map where the Active Directory PowerShell module exists
	
	.PARAMETER DriveLetter
		Drive letter mapping where the PowerShell Active Directory module files exists
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.119
		Created on:   	4/8/2016 12:41 PM
		Created by:     Mick Pletcher
		Filename:       InstallActiveDirectoryModule.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[string]
	$DomainUserName,
	[string]
	$DomainPassword,
	[string]
	$NetworkPath,
	[string]
	$DriveLetter
)

function Copy-Folder {
<#
	.SYNOPSIS
		Copy Folder
	
	.DESCRIPTION
		Copy folder to destination
	
	.PARAMETER SourceFolder
		A description of the SourceFolder parameter.
	
	.PARAMETER DestinationFolder
		A description of the DestinationFolder parameter.
	
	.EXAMPLE
				PS C:\> Copy-Folder -SourceFolder 'Value1' -DestinationFolder 'Value2'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[string]
		$SourceFolder,
		[string]
		$DestinationFolder
	)
	
	$Executable = $env:windir + "\system32\Robocopy.exe"
	$Switches = $SourceFolder + [char]32 + $DestinationFolder + [char]32 + "/e /eta /mir"
	Write-Host "Copying "$SourceFolder"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 1)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code"$ErrCode -ForegroundColor Red
	}
}

function Get-Architecture {
<#
	.SYNOPSIS
		Get-Architecture
	
	.DESCRIPTION
		Returns whether the system architecture is 32-bit or 64-bit
	
	.EXAMPLE
		Get-Architecture
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$OSArchitecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$OSArchitecture = $OSArchitecture.OSArchitecture
	Return $OSArchitecture
	#Returns 32-bit or 64-bit
}


function New-NetworkDrive {
<#
	.SYNOPSIS
		Map network drive
	
	.DESCRIPTION
		Map the network drive for copying down the PowerShell Active Directory files to the WinPE environment
	
	.EXAMPLE
		PS C:\> New-NetworkDrive
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Executable = $env:windir + "\system32\net.exe"
	$Switches = "use" + [char]32 + $DriveLetter + ":" + [char]32 + $NetworkPath + [char]32 + "/user:" + $DomainUserName + [char]32 + $DomainPassword
	Write-Host "Mapping"$DriveLetter":\ drive....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If ((Test-Path $DriveLetter":\") -eq $true) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Yellow
	}
}

function Remove-NetworkDrive {
<#
	.SYNOPSIS
		Delete the mapped network drive
	
	.DESCRIPTION
		Delete the mapped network drive
	
	.EXAMPLE
				PS C:\> Remove-NetworkDrive
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Executable = $env:windir + "\system32\net.exe"
	$Switches = "use" + [char]32 + $DriveLetter + ":" + [char]32 + "/delete"
	Write-Host "Deleting"$DriveLetter":\ drive....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If ((Test-Path $DriveLetter":\") -eq $true) {
		Write-Host "Failed" -ForegroundColor Yellow
	} else {
		Write-Host "Success" -ForegroundColor Yellow
	}
}

cls
#Get WinPE Architecture
$Architecture = Get-Architecture
#Map network drive to PowerShell active directory module
New-NetworkDrive
#Get msil_microsoft-windows-d..ivecenter.resources Directory Name
$MicrosoftWindowsIvecenterResources = Get-ChildItem $DriveLetter":\" | where { $_.Attributes -eq 'Directory' } | Where-Object { $_.FullName -like "*msil_microsoft-windows-d..ivecenter.resources*" }
#Get WinSxS x86_microsoft.activedirectory.management Name
$WinSxSMicrosoftActiveDirectoryManagementResources = Get-ChildItem $DriveLetter":\" | where { $_.Attributes -eq 'Directory' } | Where-Object { $_.FullName -like "*x86_microsoft.activedirectory.management*" }
#Get WinSxS amd64_microsoft.activedir..anagement.resources Name
$WinSxSMicrosoftActiveDirectoryManagementResources_x64 = Get-ChildItem $DriveLetter":\" | where { $_.Attributes -eq 'Directory' } | Where-Object { $_.FullName -like "*amd64_microsoft.activedir..anagement.resources*" }

#Copy ActiveDirectory Folder
Copy-Folder -SourceFolder $NetworkPath"\ActiveDirectory" -DestinationFolder $env:windir"\System32\WindowsPowerShell\v1.0\Modules\ActiveDirectory"
#Copy Microsoft.ActiveDirectory.Management Folder
Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_32\Microsoft.ActiveDirectory.Management"
#Copy Microsoft.ActiveDirectory.Management.Resources Folder
Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management.Resources" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_32\Microsoft.ActiveDirectory.Management.Resources"
#Copy msil_microsoft-windows-d..ivecenter.resources Folder
Copy-Folder -SourceFolder $NetworkPath"\"$MicrosoftWindowsIvecenterResources -DestinationFolder $env:windir"\WinSxS\"$MicrosoftWindowsIvecenterResources
#Copy x86_microsoft.activedirectory.management Folder
Copy-Folder -SourceFolder $NetworkPath"\"$WinSxSMicrosoftActiveDirectoryManagementResources -DestinationFolder $env:windir"WinSxS\"$WinSxSMicrosoftActiveDirectoryManagementResources

If ($Architecture -eq "64-bit") {
	#Copy ActiveDirectory x64 Folder
	Copy-Folder -SourceFolder $NetworkPath"\ActiveDirectory" -DestinationFolder $env:SystemDrive"\"
	#Copy Microsoft.ActiveDirectory.Management x64 Folder
	Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_64\Microsoft.ActiveDirectory.Management"
	#Copy Microsoft.ActiveDirectory.Management.Resources x64 Folder
	Copy-Folder -SourceFolder $NetworkPath"\Microsoft.ActiveDirectory.Management.Resources" -DestinationFolder $env:windir"\Microsoft.NET\assembly\GAC_64\Microsoft.ActiveDirectory.Management.Resources"
	#Copy amd64_microsoft.activedir..anagement.resources x64 Folder
	Copy-Folder -SourceFolder $NetworkPath"\"$WinSxSMicrosoftActiveDirectoryManagementResources_x64 -DestinationFolder $env:windir"\WinSxS\"$WinSxSMicrosoftActiveDirectoryManagementResources_x64
}

#Unmap Network Drive
Remove-NetworkDrive
