<#
	.SYNOPSIS
		Configure PowerShell
	
	.DESCRIPTION
		Configure PowerShell execution policy and install PowerShell modules.
	
	.DESCRIPTION
		A description of the file.
	
	.PARAMETER PSConsoleTitle
		Title of the PowerShell Console
	
	.EXAMPLE
		powershell.exe -executionpolicy bypass -file ConfigurePowerShell.ps1
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	5/18/2016 12:12 PM
		Created by:   	Mick Pletcher
		Organization:
		Filename:     	ConfigurePowerShell.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[string]$PSConsoleTitle = 'PowerShell Configuration'
)

function Set-ConsoleTitle {
<#
	.SYNOPSIS
		Console Title
	
	.DESCRIPTION
		Sets the title of the PowerShell Console
	
	.PARAMETER ConsoleTitle
		Title of the PowerShell Console
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][String]$ConsoleTitle
	)
	
	$host.ui.RawUI.WindowTitle = $ConsoleTitle
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

function Set-RegistryKeyValue {
<#
	.SYNOPSIS
		Test if a registry value exists
	
	.DESCRIPTION
		This tests to see if a registry value exists by using the get-itemproperty and therefore returning a boolean value if the cmdlet executes successfully.
	
	.PARAMETER RegKeyName
		Registry key name
	
	.PARAMETER RegKeyValue
		Value within the registry key
	
	.PARAMETER RegKeyData
		The data pertaining to the registry key value
	
	.PARAMETER DisplayName
		Name to be used to display on the status window
	
#>
	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$RegKeyName,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$RegKeyValue,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()]$RegKeyData,
			[string]$DisplayName = $null
	)
	
	If ($DisplayName -ne $null) {
		Write-Host "Setting"$DisplayName"....." -NoNewline
	}
	$NoOutput = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
	$Key = Get-Item -LiteralPath $RegKeyName -ErrorAction SilentlyContinue
	If ($Key -ne $null) {
		If ($RegKeyValue -eq '(Default)') {
			$Value = Get-ItemProperty $RegKey '(Default)' | Select-Object -ExpandProperty '(Default)'
		} else {
			$Value = $Key.GetValue($RegKeyValue, $null)
		}
		If ($Value -ne $RegKeyData) {
			Set-ItemProperty -Path $RegKeyName -Name $RegKeyValue -Value $RegKeyData -Force
		}
		
	} else {
		$NoOutput = New-Item -Path $RegKeyName -Force
		$NoOutput = New-ItemProperty -Path $RegKeyName -Name $RegKeyValue -Value $RegKeyData -Force
	}
	If ($RegKeyValue -eq '(Default)') {
		$Value = Get-ItemProperty $RegKey '(Default)' | Select-Object -ExpandProperty '(Default)'
	} else {
		$Value = $Key.GetValue($RegKeyValue, $null)
	}
	If ($DisplayName -ne $null) {
		If ($Value -eq $RegKeyData) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			Write-Host $Value
			Write-Host $RegKeyData
		}
	}
}

function Copy-Files {
<#
	.SYNOPSIS
		Copy-Files
	
	.DESCRIPTION
		This will copy specified file(s)
	
	.PARAMETER SourceDirectory
		Directory containing the source file(s)
	
	.PARAMETER DestinationDirectory
		Directory where the source file(s) will be copied to
	
	.PARAMETER FileFilter
		Either a specific filename or a wildcard specifying what to copy
	
	.EXAMPLE
		Copy-Files -SourceDirectory 'c:\windows' -DestinationDirectory 'd:\windows' -FileFilter '*.exe'
		Copy-Files -SourceDirectory 'c:\windows' -DestinationDirectory 'd:\windows' -FileFilter 'INSTALL.LOG'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$SourceDirectory,
			[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][String]$DestinationDirectory,
			[ValidateNotNullOrEmpty()][String]$FileFilter
	)
	
	$Dest = $DestinationDirectory
	If ((Test-Path $DestinationDirectory) -eq $false) {
		$NoOutput = New-Item -Path $DestinationDirectory -ItemType Directory -Force
	}
	$Files = Get-ChildItem $SourceDirectory -Filter $FileFilter
	If ($Files.Count -eq $null) {
		Write-Host "Copy"$Files.Name"....." -NoNewline
		Copy-Item $Files.FullName -Destination $Dest -Force
		$Test = $Dest + "\" + $Files.Name
		If (Test-Path $Test) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} else {
		For ($i = 0; $i -lt $Files.Count; $i++) {
			$File = $Files[$i].FullName
			Write-Host "Copy"$Files[$i].Name"....." -NoNewline
			Copy-Item $File -Destination $Dest -Force
			$Test = $Dest + "\" + $Files[$i].Name
			If (Test-Path $Test) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
			}
		}
	}
}

Clear-Host
#Set the title of the PowerShell console
Set-ConsoleTitle -ConsoleTitle $PSConsoleTitle

#Define the relative path 
$RelativePath = Get-RelativePath

#Configure additional paths for PowerShell modules
$RegKey = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Environment'
$RegValue = $env:SystemRoot + '\system32\WindowsPowerShell\v1.0\Modules\;' + $env:ProgramFiles + '\windowspowershell\modules'
Set-RegistryKeyValue -DisplayName "PSModulePath" -RegKeyName $RegKey -RegKeyValue 'PSModulePath' -RegKeyData $RegValue

#Set the PowerShell execution policy
$RegKey = 'HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell'
Set-RegistryKeyValue -DisplayName "ExecutionPolicy" -RegKeyName $RegKey -RegKeyValue 'ExecutionPolicy' -RegKeyData 'RemoteSigned'

#Configure PowerShell RunAs Administrator
$RegKey = 'HKCR:\Microsoft.PowerShellScript.1\Shell\runas\command'
Set-RegistryKeyValue -DisplayName "RunAs Administrator" -RegKeyName $RegKey -RegKeyValue '(Default)' -RegKeyData '"c:\windows\system32\windowspowershell\v1.0\powershell.exe" -noexit "%1"'

#Copy PowerShell Modules
$ModuleFolder = $env:ProgramFiles + "\WindowsPowerShell\Modules\Deployment"
Copy-Files -SourceDirectory $RelativePath -DestinationDirectory $ModuleFolder -FileFilter "Deployment.psm1"
