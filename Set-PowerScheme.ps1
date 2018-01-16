<#
	.SYNOPSIS
		Set the Power Options
	
	.DESCRIPTION
		This script will set the preferred plan. It can also customize specific settings within a plan. The is an option to use the script for generating a report on the currently selected plan, along with all of the plan settings that is written both to the screen and to a log file. The script will exit with an error code 5 if any power setting failed. This allows for an error flag when used during a build.
	
	.PARAMETER Balanced
		Selects the balanced plan
	
	.PARAMETER ConsoleTitle
		Name for the PowerShell Console Title
	
	.PARAMETER Custom
		Enter a name to create a custom Power Plan
	
	.PARAMETER HighPerformance
		Selects the High Performance Plan
	
	.PARAMETER ImportPowerSchemeFile
		Import a power scheme file
	
	.PARAMETER PowerSaver
		Selects the Power Saver Plan
	
	.PARAMETER PowerSchemeName
		Name to use when renaming an imported scheme
	
	.PARAMETER Report
		Select this switch to generate a report of the currently selected plan
	
	.PARAMETER SetPowerSchemeSetting
		Set individual power scheme setting
	
	.PARAMETER SetPowerSchemeSettingValue
		Value associated with the Power Scheme Setting
	
	.PARAMETER SetImportedPowerSchemeDefault
		This is used in conjunction with the ImportPowerSchemeFile parameter. This tells the script to set the imported power scheme as the default.
	
	.EXAMPLE
		Set Power Settings to Balanced
		powershell.exe -executionpolicy bypass -file Set-PowerScheme.ps1 -Balanced
		
		Set Power Settings to High Performance
		powershell.exe -executionpolicy bypass -file Set-PowerScheme.ps1 -HighPerformance
		
		Set Power Settings to Power Saver
		powershell.exe -executionpolicy bypass -file Set-PowerScheme.ps1 -PowerSaver
		
		Generate a report named PowerSchemeReport.txt that resides in the same directory as this script. It contains a list of all power settings.
		powershell.exe -executionpolicy bypass -file Set-PowerScheme.ps1 -Report
		
		Set individual power scheme setting
		powershell.exe -executionpolicy bypass -file Set-PowerScheme.ps1 -SetPowerSchemeSetting -MonitorTimeoutAC 120
		
		Import power scheme file that resides in the same directory as this script and renames the scheme to the name defined under PowerSchemeName
		powershell.exe -executionpolicy bypass -file Set-PowerScheme.ps1 -ImportPowerSchemeFile "CustomScheme.cfg" -PowerSchemeName "Custom"
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
		Created on:   	8/16/2016 10:13 AM
		Created by:   	Mick Pletcher
		Filename:     	Set-PowerScheme.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[switch]
	$Balanced,
	[string]
	$ConsoleTitle = 'PowerScheme',
	[string]
	$Custom,
	[switch]
	$HighPerformance,
	[string]
	$ImportPowerSchemeFile,
	[switch]
	$PowerSaver,
	[string]
	$PowerSchemeName,
	[switch]
	$Report,
	[ValidateSet('MonitorTimeoutAC', 'MonitorTimeoutDC', 'DiskTimeoutAC', 'DiskTimeoutDC', 'StandbyTimeoutAC', 'StandbyTimeoutDC', 'HibernateTimeoutAC', 'HibernateTimeoutDC')][string]
	$SetPowerSchemeSetting,
	[string]
	$SetPowerSchemeSettingValue,
	[switch]
	$SetImportedPowerSchemeDefault
)

function Get-PowerScheme {
<#
	.SYNOPSIS
		Get the currently active PowerScheme
	
	.DESCRIPTION
		This will query the current power scheme and return the GUID and user friendly name
	
	.EXAMPLE
		PS C:\> Get-PowerScheme
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	#Get the currently active power scheme
	$Query = powercfg.exe /getactivescheme
	#Get the alias name of the active power scheme
	$ActiveSchemeName = ($Query.Split("()").Trim())[1]
	#Get the GUID of the active power scheme
	$ActiveSchemeGUID = ($Query.Split(":(").Trim())[1]
	$Query = powercfg.exe /query $ActiveSchemeGUID
	$GUIDAlias = ($Query | where { $_.Contains("GUID Alias:") }).Split(":")[1].Trim()
	$Scheme = New-Object -TypeName PSObject
	$Scheme | Add-Member -Type NoteProperty -Name PowerScheme -Value $ActiveSchemeName
	$Scheme | Add-Member -Type NoteProperty -Name GUIDAlias -Value $GUIDAlias
	$Scheme | Add-Member -Type NoteProperty -Name GUID -Value $ActiveSchemeGUID
	Return $Scheme
}

function Get-PowerSchemeSubGroupSettings {
<#
	.SYNOPSIS
		Get the Power Scheme SubGroup Settings
	
	.DESCRIPTION
		Retrieve all Settings and values within a subgroup
	
	.PARAMETER Subgroup
		Name and GUID of desired subgroup
	
	.PARAMETER ActivePowerScheme
		GUID and name of the active ActivePowerScheme
	
	.EXAMPLE
		PS C:\> Get-PowerSchemeSubGroupSettings -Subgroup $value1
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Subgroup,
		[ValidateNotNullOrEmpty()][object]
		$ActivePowerScheme
	)
	
	$Query = powercfg.exe /query $ActivePowerScheme.GUID $Subgroup.GUID
	$Query = $Query | where { ((!($_.Contains($ActivePowerScheme.GUID))) -and (!($_.Contains($ActivePowerScheme.GUIDAlias)))) }
	$Settings = @()
	For ($i = 0; $i -lt $Query.Length; $i++) {
		If ($Query[$i] -like "*Power Setting GUID:*") {
			$Setting = New-Object System.Object
			#Get the friendly name of the Power Setting
			$SettingName = $Query[$i].Split("()").Trim()
			$SettingName = $SettingName[1]
			#Get the alias of the power setting
			If ($Query[$i + 1] -like "*GUID Alias:*") {
				$SettingAlias = $Query[$i + 1].Split(":").Trim()
				$SettingAlias = $SettingAlias[1]
			} else {
				$SettingAlias = $null
			}
			#Get the GUID of the power setting
			$SettingGUID = $Query[$i].Split(":(").Trim()
			$SettingGUID = $SettingGUID[1]
			#Get the AC and DC power settings
			$j = $i
			Do {
				$j++
			}
			while ($Query[$j] -notlike "*Current AC Power Setting*")
			$SettingAC = $Query[$j].Split(":").Trim()
			$SettingAC = [Convert]::ToInt32($SettingAC[1], 16)
			$SettingDC = $Query[$j + 1].Split(":").Trim()
			$SettingDC = [Convert]::ToInt32($SettingDC[1], 16)
			$Setting | Add-Member -Type NoteProperty -Name Subgroup -Value $Subgroup.Subgroup
			$Setting | Add-Member -Type NoteProperty -Name Name -Value $SettingName
			$Setting | Add-Member -Type NoteProperty -Name Alias -Value $SettingAlias
			$Setting | Add-Member -Type NoteProperty -Name GUID -Value $SettingGUID
			$Setting | Add-Member -Type NoteProperty -Name AC -Value $SettingAC
			$Setting | Add-Member -Type NoteProperty -Name DC -Value $SettingDC
			$Settings += $Setting
		}
	}
	Return $Settings
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

function Get-SubGroupsList {
<#
	.SYNOPSIS
		Generate a list of subgroups
	
	.DESCRIPTION
		This will generate a list of the subgroups within the designated power scheme
	
	.PARAMETER ActivePowerScheme
		GUID and name of the active ActivePowerScheme
	
	.EXAMPLE
		PS C:\> Get-SubGroupsList
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param
	(
		[ValidateNotNullOrEmpty()][object]
		$ActivePowerScheme
	)
	
	#Get all settings for the active power scheme
	$Query = powercfg.exe /query $ActivePowerScheme.GUID
	#Get a list of the subgroups
	$Subgroups = @()
	for ($i = 0; $i -lt $Query.Length; $i++) {
		If (($Query[$i] -like "*Subgroup GUID:*") -and ($Query[$i + 1] -notlike "*Subgroup GUID:*")) {
			$Subgroup = New-Object System.Object
			$SubgroupName = $Query[$i].Split("()").Trim()
			$SubgroupName = $SubgroupName[1]
			If ($Query[$i + 1] -like "*GUID Alias:*") {
				$SubgroupAlias = $Query[$i + 1].Split(":").Trim()
				$SubgroupAlias = $SubgroupAlias[1]
			} else {
				$SubgroupAlias = $null
			}
			$SubgroupGUID = $Query[$i].Split(":(").Trim()
			$SubgroupGUID = $SubgroupGUID[1]
			$Subgroup | Add-Member -Type NoteProperty -Name Subgroup -Value $SubgroupName
			$Subgroup | Add-Member -Type NoteProperty -Name Alias -Value $SubgroupAlias
			$Subgroup | Add-Member -Type NoteProperty -Name GUID -Value $SubgroupGUID
			$Subgroups += $Subgroup
		}
	}
	Return $Subgroups
}

function Import-PowerScheme {
<#
	.SYNOPSIS
		Import a Power Scheme
	
	.DESCRIPTION
		Imports a power scheme configuration file
	
	.PARAMETER File
		Name of the configuration file. This must reside in the same directory as this script.
	
	.PARAMETER PowerSchemeName
		Desired name for the imported power scheme
	
	.PARAMETER SetActive
		Set the imported scheme to active
	
	.EXAMPLE
		PS C:\> Import-PowerScheme -File 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$File,
		[ValidateNotNullOrEmpty()][string]
		$PowerSchemeName,
		[switch]
		$SetActive
	)
	
	$RelativePath = Get-RelativePath
	$File = $RelativePath + $File
	#Get list of all power schemes
	$OldPowerSchemes = powercfg.exe /l
	#Filter out all data except for the GUID
	$OldPowerSchemes = $OldPowerSchemes | where { $_ -like "*Power Scheme GUID*" } | ForEach-Object { $_ -replace "Power Scheme GUID: ", "" } | ForEach-Object { ($_.split("?("))[0] }
	Write-Host "Importing Power Scheme....." -NoNewline
	#Import Power Scheme
	$Output = powercfg.exe -import $File
	#Get list of all power schemes
	$NewPowerSchemes = powercfg.exe /l
	#Filter out all data except for the GUID
	$NewScheme = $NewPowerSchemes | where { $_ -like "*Power Scheme GUID*" } | ForEach-Object { $_ -replace "Power Scheme GUID: ", "" } | ForEach-Object { ($_.split("?("))[0] } | where { $OldPowerSchemes -notcontains $_ }
	If ($NewScheme -ne $null) {
		Write-Host "Success" -ForegroundColor Yellow
		$Error = $false
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Error = $true
	}
	#Rename imported power scheme
	Write-Host "Renaming imported power scheme to"$PowerSchemeName"....." -NoNewline
	$Switches = "/changename" + [char]32 + $NewScheme.Trim() + [char]32 + [char]34 + $PowerSchemeName + [char]34
	$ErrCode = (Start-Process -FilePath "powercfg.exe" -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
	$NewPowerSchemes = powercfg.exe /l
	If ($ErrCode -eq 0) {
		$Test = $NewPowerSchemes | where { $_ -like ("*" + $PowerSchemeName + "*") }
		If ($Test -ne $null) {
			Write-Host "Success" -ForegroundColor Yellow
			$Error = $false
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Error = $true
			Return $Error
		}
	}
	Write-Host "Setting"$PowerSchemeName" to default....." -NoNewline
	$Switches = "-setactive " + $NewScheme.Trim()
	$ErrCode = (Start-Process -FilePath "powercfg.exe" -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
	$Query = powercfg.exe /getactivescheme
	#Get the alias name of the active power scheme
	$ActiveSchemeName = (powercfg.exe /getactivescheme).Split("()").Trim()[1]
	If ($ActiveSchemeName -eq $PowerSchemeName) {
		Write-Host "Success" -ForegroundColor Yellow
		$Error = $false
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Error = $true
	}
	Return $Error
}

function Publish-Report {
<#
	.SYNOPSIS
		Publish a Power Scheme Report
	
	.DESCRIPTION
		This will publish a report of the currently active power scheme, a list of the power scheme subgroups, and a list of all subgroup settings.
	
	.EXAMPLE
		PS C:\> Publish-Report
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#Get the relative path this script is being executed from
	$RelativePath = Get-RelativePath
	#Get the currently enabled power scheme data
	$ActivePowerScheme = Get-PowerScheme
	#Get a list of all available subgroups
	$PowerSchemeSubGroups = Get-SubGroupsList -ActivePowerScheme $ActivePowerScheme
	#Get a list of all settings under each subgroup
	$PowerSchemeSettings = @()
	for ($i = 0; $i -lt $PowerSchemeSubGroups.Length; $i++) {
		$PowerSchemeSubGroupSettings = Get-PowerSchemeSubGroupSettings -ActivePowerScheme $ActivePowerScheme -Subgroup $PowerSchemeSubGroups[$i]
		$PowerSchemeSettings += $PowerSchemeSubGroupSettings
	}
	#Define the Report text file to write to
	$ReportFile = $RelativePath + "PowerSchemeReport.txt"
	#Remove old report if it exists
	If ((Test-Path $ReportFile) -eq $true) {
		Remove-Item -Path $ReportFile -Force
	}
	#Generate Header for Power Scheme Report
	$Header = "ACTIVE POWER SCHEME REPORT"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Header = "--------------------------------------------------------------------------------"
	$Header | Tee-Object -FilePath $ReportFile -Append
	#Get Active Power Scheme report
	$Output = $ActivePowerScheme | Format-Table
	#Write output to report screen and file
	$Output | Tee-Object -FilePath $ReportFile -Append
	#Generate Header for power scheme subgroups report
	$Header = "POWER SCHEME SUBGROUPS REPORT"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Header = "--------------------------------------------------------------------------------"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Output = $PowerSchemeSubgroups | Format-Table
	#Write output to report screen and file
	$Output | Tee-Object -FilePath $ReportFile -Append
	#Generate Header for power scheme subgroup settings report
	$Header = "POWER SCHEME SUBGROUP SETTINGS REPORT"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Header = "--------------------------------------------------------------------------------"
	$Header | Tee-Object -FilePath $ReportFile -Append
	$Output = $PowerSchemeSettings | Format-Table
	#Write output to report screen and file
	$Output | Tee-Object -FilePath $ReportFile -Append
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
		[Parameter(Mandatory = $true)][String]
		$Title
	)
	
	$host.ui.RawUI.WindowTitle = $Title
}

function Set-PowerScheme {
<#
	.SYNOPSIS
		Set the power scheme to the specified scheme
	
	.DESCRIPTION
		Sets the power scheme to the specified scheme
	
	.PARAMETER PowerScheme
		Friendly power scheme name
	
	.PARAMETER CustomPowerScheme
		Create a custom power scheme
	
	.EXAMPLE
		PS C:\> Set-PowerScheme -PowerScheme 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateSet('Balanced', 'High Performance', 'Power Saver')][string]
		$PowerScheme,
		[string]
		$CustomPowerScheme
	)
	
	#Get list of existing power schemes
	$PowerSchemes = powercfg.exe /l
	If ($PowerScheme -ne $null) {
		#Filter out all schemes except for $PowerScheme and return the GUID
		$PowerSchemes = ($PowerSchemes | where { $_ -like "*" + $PowerScheme + "*" }).Split(":(").Trim()[1]
		#Set power scheme
		$ActivePowerScheme = Get-PowerScheme
		$ActivePowerScheme.PowerScheme
		Write-Host "Setting Power Scheme from"$ActivePowerScheme.PowerScheme"to"$PowerScheme"....." -NoNewline
		$Output = powercfg.exe -setactive $PowerSchemes
		$ActivePowerScheme = Get-PowerScheme
		If ($PowerScheme -eq $ActivePowerScheme.PowerScheme) {
			Write-Host "Success" -ForegroundColor Yellow
			Return $false
		} else {
			Write-Host "Failed" -ForegroundColor Red
			Return $true
		}
	}
}

function Set-PowerSchemeSettings {
<#
	.SYNOPSIS
		Modify current power scheme
	
	.DESCRIPTION
		This will modify settings of the currently active power scheme.
	
	.PARAMETER MonitorTimeoutAC
		Modify the time until the screensaver turns on while plugged into AC outlet
	
	.PARAMETER MonitorTimeoutDC
		Modify the time until the screensaver turns on while on battery power
	
	.PARAMETER DiskTimeoutAC
		Time that windows will wait for a hard disk to respond to a command while plugged into AC outlet
	
	.PARAMETER DiskTimeoutDC
		Time that windows will wait for a hard disk to respond to a command while on battery power
	
	.PARAMETER StandbyTimeoutAC
		Amount of time before a computer is put on standby while plugged into AC outlet
	
	.PARAMETER StandbyTimeoutDC
		Amount of time before a computer is put on standby while on battery power
	
	.PARAMETER HibernateTimeoutAC
		Amount of time before a computer is put in hibernation while plugged into AC outlet
	
	.PARAMETER HibernateTimeoutDC
		Amount of time before a computer is put in hibernation while on battery power
	
	.EXAMPLE
		PS C:\> Set-PowerSchemeSettings -MonitorTimeoutAC $value1 -MonitorTimeoutDC $value2
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[string]
		$MonitorTimeoutAC,
		[string]
		$MonitorTimeoutDC,
		[string]
		$DiskTimeoutAC,
		[string]
		$DiskTimeoutDC,
		[string]
		$StandbyTimeoutAC,
		[string]
		$StandbyTimeoutDC,
		[string]
		$HibernateTimeoutAC,
		[string]
		$HibernateTimeoutDC
	)
	
	$Scheme = Get-PowerScheme
	If (($MonitorTimeoutAC -ne $null) -and ($MonitorTimeoutAC -ne "")) {
		Write-Host "Setting monitor timeout on AC to"$MonitorTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "monitor-timeout-ac" + [char]32 + $MonitorTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"
		$TestValue = $MonitorTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($MonitorTimeoutDC -ne $null) -and ($MonitorTimeoutDC -ne "")) {
		Write-Host "Setting monitor timeout on DC to"$MonitorTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "monitor-timeout-dc" + [char]32 + $MonitorTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\7516b95f-f776-4464-8c53-06167f40cc99\3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e"
		$TestValue = $MonitorTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	If (($DiskTimeoutAC -ne $null) -and ($DiskTimeoutAC -ne "")) {
		Write-Host "Setting disk timeout on AC to"$DiskTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "disk-timeout-ac" + [char]32 + $DiskTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e"
		$TestValue = $DiskTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($DiskTimeoutDC -ne $null) -and ($DiskTimeoutDC -ne "")) {
		Write-Host "Setting disk timeout on DC to"$DiskTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "disk-timeout-dc" + [char]32 + $DiskTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\0012ee47-9041-4b5d-9b77-535fba8b1442\6738e2c4-e8a5-4a42-b16a-e040e769756e"
		$TestValue = $DiskTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	If (($StandbyTimeoutAC -ne $null) -and ($StandbyTimeoutAC -ne "")) {
		Write-Host "Setting standby timeout on AC to"$StandbyTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "standby-timeout-ac" + [char]32 + $StandbyTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1f44da"
		$TestValue = $StandbyTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($StandbyTimeoutDC -ne $null) -and ($StandbyTimeoutDC -ne "")) {
		Write-Host "Setting standby timeout on DC to"$StandbyTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "standby-timeout-dc" + [char]32 + $StandbyTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1f44da"
		$TestValue = $StandbyTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	If (($HibernateTimeoutAC -ne $null) -and ($HibernateTimeoutAC -ne "")) {
		Write-Host "Setting hibernate timeout on AC to"$HibernateTimeoutAC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "hibernate-timeout-ac" + [char]32 + $HibernateTimeoutAC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\9d7815a6-7ee4-497e-8888-515a05f02364"
		[int]$TestValue = $HibernateTimeoutAC
		$PowerIndex = "ACSettingIndex"
	}
	If (($HibernateTimeoutDC -ne $null) -and ($HibernateTimeoutDC -ne "")) {
		Write-Host "Setting hibernate timeout on DC to"$HibernateTimeoutDC" minutes....." -NoNewline
		$Switches = "/change" + [char]32 + "hibernate-timeout-dc" + [char]32 + $HibernateTimeoutDC
		$TestKey = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\" + $Scheme.GUID + "\238c9fa8-0aad-41ed-83f4-97be242c8f20\9d7815a6-7ee4-497e-8888-515a05f02364"
		$TestValue = $HibernateTimeoutDC
		$PowerIndex = "DCSettingIndex"
	}
	$ErrCode = (Start-Process -FilePath "powercfg.exe" -ArgumentList $Switches -WindowStyle Minimized -Wait -Passthru).ExitCode
	$RegValue = (((Get-ItemProperty $TestKey).$PowerIndex) /60)
	#Round down to the nearest tenth due to hibernate values being 1 decimal off
	$RegValue = $RegValue - ($RegValue % 10)
	If (($RegValue -eq $TestValue) -and ($ErrCode -eq 0)) {
		Write-Host "Success" -ForegroundColor Yellow
		$Errors = $false
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Errors = $true
	}
	Return $Errors
}


cls
#Set Errors variable to false to begin the script with no errors
$Errors = $false
#Set the title of the PowerShell console
Set-ConsoleTitle -Title $ConsoleTitle

<#Hardcoded Power Scheme Settings
$Errors = Set-PowerSchemeSettings -MonitorTimeoutAC 120
$Errors = Set-PowerSchemeSettings -MonitorTimeoutDC 120
$Errors = Set-PowerSchemeSettings -DiskTimeOutAC 120
$Errors = Set-PowerSchemeSettings -DiskTimeOutDC 120
$Errors = Set-PowerSchemeSettings -StandbyTimeoutAC 120
$Errors = Set-PowerSchemeSettings -StandbyTimeoutDC 120
$Errors = Set-PowerSchemeSettings -HibernateTimeoutAC 60
$Errors = Set-PowerSchemeSettings -HibernateTimeoutDC 60
#>

#Generate a report if -Report is specified
If ($Report.IsPresent) {
	Publish-Report
}
#Set the Power Scheme to Balanced
If ($Balanced.IsPresent) {
	$Errors = Set-PowerScheme -PowerScheme 'Balanced'
}
#Set the Power Scheme to Power Saver
If ($PowerSaver.IsPresent) {
	$Errors = Set-PowerScheme -PowerScheme 'Power Saver'
}
#Set the Power Scheme to High Performance
If ($HighPerformance.IsPresent) {
	$Errors = Set-PowerScheme -PowerScheme 'High Performance'
}
#Set the Power Scheme to Custom
If (($Custom -ne $null) -and ($Custom -ne "")) {
	$Errors = Set-PowerScheme -PowerScheme $Custom
}
#Import a power scheme
If (($ImportPowerSchemeFile -ne $null) -and ($ImportPowerSchemeFile -ne "")) {
	If ($SetImportedPowerSchemeDefault.IsPresent) {
		$Errors = Import-PowerScheme -File $ImportPowerSchemeFile -PowerSchemeName $PowerSchemeName -SetActive
	} else {
		$Errors = Import-PowerScheme -File $ImportPowerSchemeFile -PowerSchemeName $PowerSchemeName
	}
}
#Set individual power scheme setting from command line
If (($SetPowerSchemeSetting -ne $null) -and ($SetPowerSchemeSetting -ne "")) {
	switch ($SetPowerSchemeSetting) {
		"MonitorTimeoutAC" { $Errors = Set-PowerSchemeSettings -MonitorTimeoutAC $SetPowerSchemeSettingValue }
		"MonitorTimeoutDC" { $Errors = Set-PowerSchemeSettings -MonitorTimeoutDC $SetPowerSchemeSettingValue }
		"DiskTimeOutAC" { $Errors = Set-PowerSchemeSettings -DiskTimeOutAC $SetPowerSchemeSettingValue }
		"DiskTimeOutDC" { $Errors = Set-PowerSchemeSettings -DiskTimeOutDC $SetPowerSchemeSettingValue }
		"StandbyTimeoutAC" { $Errors = Set-PowerSchemeSettings -StandbyTimeoutAC $SetPowerSchemeSettingValue }
		"StandbyTimeoutDC" { $Errors = Set-PowerSchemeSettings -StandbyTimeoutDC $SetPowerSchemeSettingValue }
		"HibernateTimeoutAC" { $Errors = Set-PowerSchemeSettings -HibernateTimeoutAC $SetPowerSchemeSettingValue }
		"HibernateTimeoutDC" { $Errors = Set-PowerSchemeSettings -HibernateTimeoutDC $SetPowerSchemeSettingValue }
	}
}
#Exit with an error code 5 if errors were encountered during any of the power settings
If ($Errors -eq $true) {
	Exit 5
}
