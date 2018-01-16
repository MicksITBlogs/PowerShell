<#
	.SYNOPSIS
		A brief description of the ApplicationShortcutsWindows10.ps1 file.
	
	.DESCRIPTION
		This script will add shortcuts to the taskbar.
	
	.PARAMETER AppsFile
		Name of the text file that contains a list of the applications to be added or removed
	
	.PARAMETER ConsoleTitle
		ConsoleTitle assigned to the PowerShell console
	
	.PARAMETER OutputToTextFile
		Select if output needs to go to a text file
	
	.PARAMETER GetApplicationList
		Get a list of applications with the specific name needed to use or pinning and unpinning
	
	.EXAMPLE
		Read apps from within a text file that resides in the same directory as this script
			powershell.exe -executionpolicy bypass -file ApplicationShortcutsWin10.ps1 -AppsFile 'Applications.txt'

		Get an official list of applications with the exact names that need to be used for pinning/unpinning
			powershell.exe -executionpolicy bypass -file ApplicationShortcutsWin10.ps1 -GetApplicationList

		Get an official list of applications with the exact names that need to be used for pinning/unpinning and write to the text file ApplicationList.csv residing in the same directory as this script
			powershell.exe -executionpolicy bypass -file ApplicationShortcutsWin10.ps1 -GetApplicationList -OutputToTextFile

		Near the bottom of the script are commented out lines that give examples of how to hardcode apps inside this script

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.123
		Created on:   	6/29/2016 10:33 AM
		Created by:   	Mick Pletcher
		Filename:     	ApplicationShortcutsWindows10.ps1
		===========================================================================
#>

[CmdletBinding()]
param
(
		[string]$AppsFile = 'Applications.txt',
		[ValidateNotNullOrEmpty()][string]$ConsoleTitle = 'Application Shortcuts',
		[switch]$OutputToTextFile,
		[switch]$GetApplicationList
)

function Add-AppToStartMenu {
<#
	.SYNOPSIS
		Pins an application to the start menu
	
	.DESCRIPTION
		Add an application to the start menu
	
	.PARAMETER Application
		Name of the application. This can be left blank and the function will use the file description metadata instead.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	$Status = Remove-AppFromStartMenu -Application $Application
	If ($Status -eq $false) {
		$Success = $false
	}
	Write-Host 'Pinning'$Application' to start menu.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Pin to Start' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Add-AppToTaskbar {
<#
	.SYNOPSIS
		Pins an application to the taskbar
	
	.DESCRIPTION
		Add an application to the taskbar
	
	.PARAMETER Application
		Name of the application. This can be left blank and the function will use the file description metadata instead.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	$Status = Remove-AppFromTaskbar -Application $Application
	If ($Status -eq $false) {
		$Success = $false
	}
	Write-Host 'Pinning'$Application' to start menu.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Pin to taskbar' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Get-ApplicationList {
<#
	.SYNOPSIS
		Get list of Applications
	
	.DESCRIPTION
		Get a list of available applications with the precise name to use when pinning or unpinning to the taskbar and/or start menu
	
	.PARAMETER SaveOutput
		Save output to a text file
	
	.EXAMPLE
		PS C:\> Get-ApplicationList
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[switch]$SaveOutput
	)
	
	$RelativePath = Get-RelativePath
	$OutputFile = $RelativePath + "ApplicationList.csv"
	$Applications = (New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items()
	$Applications = $Applications | Sort-Object -Property name -Unique
	If ($SaveOutput.IsPresent) {
		If ((Test-Path -Path $OutputFile) -eq $true) {
			Remove-Item -Path $OutputFile -Force
		}
		"Applications" | Out-File -FilePath $OutputFile -Encoding UTF8 -Force
		$Applications.Name | Out-File -FilePath $OutputFile -Encoding UTF8 -Append -Force
	}
	$Applications.Name
}

function Get-Applications {
<#
	.SYNOPSIS
		Get Application List
	
	.DESCRIPTION
		Get the list of applications to add or remove
	
	.EXAMPLE
		PS C:\> Get-Applications
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	$RelativePath = Get-RelativePath
	$File = $RelativePath + $AppsFile
	$Contents = Get-Content -Path $File -Force
	Return $Contents
}

function Get-RelativePath {
<#
	.SYNOPSIS
		Get the relative path
	
	.DESCRIPTION
		Returns the location of the currently running PowerShell script
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$Path = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $Path
}

function Invoke-PinActions {
<#
	.SYNOPSIS
		Process the application list
	
	.DESCRIPTION
		Add or remove applications within the text file to/from the taskbar and start menu.
	
	.PARAMETER AppList
		List of applications
	
	.EXAMPLE
		PS C:\> Invoke-PinActions -AppList 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $false)][ValidateNotNullOrEmpty()][object]$AppList
	)
	
	$Success = $true
	foreach ($App in $AppList) {
		$Entry = $App.Split(',')
		If ($Entry[1] -eq 'startmenu') {
			If ($Entry[2] -eq 'add') {
				$Status = Add-AppToStartMenu -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} elseif ($Entry[2] -eq 'remove') {
				$Status = Remove-AppFromStartMenu -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} else {
				Write-Host $Entry[0]" was entered incorrectly"
			}
		} elseif ($Entry[1] -eq 'taskbar') {
			If ($Entry[2] -eq 'add') {
				$Status = Add-AppToTaskbar -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} elseif ($Entry[2] -eq 'remove') {
				$Status = Remove-AppFromTaskbar -Application $Entry[0]
				If ($Status -eq $false) {
					$Success = $false
				}
			} else {
				Write-Host $Entry[0]" was entered incorrectly"
			}
		}
	}
	Return $Success
}

function Remove-AppFromStartMenu {
<#
	.SYNOPSIS
		Remove the pinned application from the start menu
	
	.DESCRIPTION
		A detailed description of the Remove-AppFromStartMenu function.
	
	.PARAMETER Application
		Name of the application. This can be left blank and the function will use the file description metadata instead.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	Write-Host 'Unpinning'$Application' from start menu.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Unpin from Start' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Remove-AppFromTaskbar {
<#
	.SYNOPSIS
		Unpins an application to the taskbar
	
	.DESCRIPTION
		Remove the pinned application from the taskbar
	
	.PARAMETER Application
		Name of the application. This can be left blank and the function will use the file description metadata instead.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
			[Parameter(Mandatory = $true)][string]$Application
	)
	
	$Success = $true
	Write-Host 'Unpinning'$Application' from task bar.....' -NoNewline
	((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{ $_.Name -eq $Application }).verbs() | Where-Object{ $_.Name.replace('&', '') -match 'Unpin from taskbar' } | ForEach-Object{ $_.DoIt() }
	If ($? -eq $true) {
		Write-Host 'Success' -ForegroundColor Yellow
	} else {
		Write-Host 'Failed' -ForegroundColor Red
		$Success = $false
	}
	Return $Success
}

function Set-ConsoleTitle {
<#
	.SYNOPSIS
		Console Title
	
	.DESCRIPTION
		Sets the title of the PowerShell Console
	
	.PARAMETER Title
		Title of the PowerShell Console
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$Title
	)
	
	$host.ui.RawUI.WindowTitle = $Title
}

Clear-Host
$Success = $true
Set-ConsoleTitle -Title $ConsoleTitle
If ($GetApplicationList.IsPresent) {
	If ($OutputToTextFile.IsPresent) {
		Get-ApplicationList -SaveOutput
	} else {
		Get-ApplicationList
	}
}
If (($AppsFile -ne $null) -or ($AppsFile -ne "")) {
	$ApplicationList = Get-Applications
	$Success = Invoke-PinActions -AppList $ApplicationList
}

#Hardcoded applications
<#
$Success = Add-AppToStartMenu -Application 'Microsoft Outlook 2010'
$Success = Add-AppToTaskbar -Application 'Microsoft Outlook 2010'
#>

If ($Success -eq $false) {
	Exit 1
}
