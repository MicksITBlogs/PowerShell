<#
	.SYNOPSIS
		Uninstall Build-In Apps
	
	.DESCRIPTION
		This script will uninstall built-in apps in Windows 10. The script can uninstall a single app by defining it at the command line. A list of apps can be read in from a text file and iterated through for uninstallation. Finally, they can also be hardcoded into the script.
	
	.PARAMETER AppsFile
		Text file to be read in by the script which contains a list of apps to uninstall.
	
	.PARAMETER AppName
		Name of the app to uninstall. This is defined when there is only one app to uninstall.
	
	.PARAMETER GetAppList
		True or false on generating a list of Built-in apps
	
	.PARAMETER Log
		Specify true or false on whether to generate a log file in the same directory as the script containing a list of all the built-in apps by their official name
	
	.EXAMPLE
		Generate a formatted list of all installed built-in apps
			powershell.exe -executionpolicy bypass -command "UninstallBuilt-InApps.ps1 -GetAppList $true

		Generate a list of all installed built-in apps and write the output to a log file
			powershell.exe -executionpolicy bypass -command "UninstallBuilt-InApps.ps1 -GetAppList $true -Log $true

		Uninstall a single built-in app by specifying its name at the command prompt. You do need to use the official name. You can get that by generating a formatted list.
			powershell.exe -executionpolicy bypass -command "UninstallBuilt-InApps.ps1" -AppName "Microsoft.WindowsCamera"
		
		Uninstall multiple built-in apps from a list inside a text file
			powershell.exe -executionpolicy bypass -command "UninstallBuilt-InApps.ps1" -AppsFile "AppsUninstall.txt

		Harcode the uninstall at the bottom of this script
			Uninstall-BuiltInApp -AppName "Microsoft.WindowsCamera"

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	6/1/2016 3:21 PM
		Created by:   	Mick Pletcher
		Filename:     	UninstallBuilt-InApps.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[string]
	$AppsFile = $null,
	[string]
	$AppName = $null,
	[ValidateNotNullOrEmpty()][boolean]
	$GetAppList = $false,
	[ValidateNotNullOrEmpty()][boolean]
	$Log = $false
)
Import-Module Appx

function Get-AppName {
<#
	.SYNOPSIS
		Format App name
	
	.DESCRIPTION
		This will format a built-in app name for proper display
	
	.PARAMETER Name
		Name of the application
	
	.EXAMPLE
				PS C:\> Get-AppName -Name 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]
		$Name
	)
	
	$Temp = $Name.Split('.')
	For ($j = 0; $j -lt $Temp.Count; $j++) {
		$Numeric = [bool]($Temp[$j] -as [double])
		If ($Temp[$j] -eq 'Net') {
			$Temp[$j] = "." + $Temp[$j]
		}
		If ($Numeric -eq $true) {
			If ($Temp[$j + 1] -ne $null) {
				$Temp[$j] = $Temp[$j] + '.'
			}
			$FormattedName = $FormattedName + $Temp[$j]
		} else {
			$FormattedName = $FormattedName + $Temp[$j] + [char]32
		}
	}
	Return $FormattedName
}


function Get-BuiltInAppsList {
<#
	.SYNOPSIS
		List all Built-In Apps
	
	.DESCRIPTION
		Query for a list of all Build-In Apps
	
	.EXAMPLE
		PS C:\> Get-BuiltInAppsList
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Apps = Get-AppxPackage
	$Apps = $Apps.Name
	$Apps = $Apps | Sort-Object
	If ($Log -eq $true) {
		$RelativePath = Get-RelativePath
		$Apps | Out-File -FilePath $RelativePath"AllAppslist.txt" -Encoding UTF8
	}
	For ($i = 0; $i -lt $Apps.count; $i++) {
		$Temp = Get-AppName -Name $Apps[$i]
		$Apps[$i] = $Temp
	}
	$Apps
}

function Get-RelativePath {
<#
	.SYNOPSIS
		Get the relative path of the PowerShell script
	
	.DESCRIPTION
		Returns the path location of the PowerShell script being executed
	
	.EXAMPLE
		PS C:\> Get-RelativePath
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $RelativePath
}

function Uninstall-BuiltInApp {
<#
	.SYNOPSIS
		Uninstall Windows 10 Built In App
	
	.DESCRIPTION
		This will uninstall a built-in app by passing the name of the app in.
	
	.PARAMETER AppName
		Name of the App
	
	.EXAMPLE
		PS C:\> Uninstall-BuiltInApp -AppName 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]
		$AppName
	)
	
	$App = Get-AppName -Name $AppName
	Write-Host "Uninstalling"$App"....." -NoNewline
	$Output = Get-AppxPackage $AppName
	If ($Output -eq $null) {
		Write-Host "Not Installed" -ForegroundColor Yellow
	} else {
		$Output = Get-AppxPackage $AppName | Remove-AppxPackage
		$Output = Get-AppxPackage $AppName
		If ($Output -eq $null) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
}

function Uninstall-BuiltInApps {
<#
	.SYNOPSIS
		Uninstall Windows 10 Built In Apps
	
	.DESCRIPTION
		This will uninstall a list of built-in apps by reading the app names from a text file located in the same directory as this script.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$RelativePath = Get-RelativePath
	$AppsFile = $RelativePath + $AppsFile
	$List = Get-Content -Path $AppsFile
	foreach ($App in $List) {
		Uninstall-BuiltInApp -AppName $App
	}
}

cls
#Generate list of all Build-In apps
If ($GetAppList -eq $true) {
	Get-BuiltInAppsList
}
#Uninstall a single app
If (($AppName -ne $null) -and ($AppName -ne "")) {
	Uninstall-BuiltInApp -AppName $AppName
}
#Read list of apps to uninstall from text file and uninstall all on the list
If (($GetAppList -ne $null) -and ($GetAppList -ne "")) {
	Uninstall-BuiltInApps
}
