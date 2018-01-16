<#
.SYNOPSIS
   PowerShell Deployment Module
.DESCRIPTION
   This module contains all of the functions necessary for deploying software
.Author
   Mick Pletcher
.Creation Date
   19 October 2014
.Last Edited Date
   08 December 2014
#>

Function Copy-Files {
	<#
	.SYNOPSIS
		Copy-Files
	.DESCRIPTION
		This will copy specified file(s)
	.EXAMPLE
		Copy-Files -SourceDirectory "c:\windows" -DestinationDirectory "d:\windows" -FileFilter "*.exe"
	#>

	Param([String]$SourceDirectory, [String]$DestinationDirectory, [String]$FileFilter)
	$Dest = $DestinationDirectory
	$Files = Get-ChildItem $SourceDirectory -Filter $FileFilter
	If ($Files.Count -eq $null) {
		$Output = "Copy "+$Files.Name+"....."
		Write-Host "Copy"$Files.Name"....." -NoNewline
		Copy-Item $Files.FullName -Destination $Dest -Force
		$Test = $Dest + "\"+$Files.Name
		If (Test-Path $Test) {
			$Output = $Output+"Success"
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			$Output = $Output+"Failed"
			Write-Host "Failed" -ForegroundColor Red
			$Global:Errors++
		}
		Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
	} else {
		For ($i = 0; $i -lt $Files.Count; $i++) {
			$File = $Files[$i].FullName
			$Output = "Copy "+$Files[$i].Name+"....."
			Write-Host "Copy"$Files[$i].Name"....." -NoNewline
			Copy-Item $File -Destination $Dest -Force
			$Test = $Dest + "\"+$Files[$i].Name
			If (Test-Path $Test) {
				$Output = $Output+"Success"
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				$Output = $Output+"Failed"
				Write-Host "Failed" -ForegroundColor Red
				$Global:Errors++
			}
			Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
		}
	}
}

Function Disable-WindowsFeature {
	<#
	.SYNOPSIS
		Disable-WindowsFeature
	.DESCRIPTION
		Disable Windows Feature
	.EXAMPLE
		Disable-WindowsFeature -DisplayName "Volume Activation" -Status online -Feature "RemoteServerAdministrationTools-Roles-VA"
	#>

	Param([String]$DisplayName, [String]$Status, [String]$FeatureName)
	$Executable = $env:windir+"\system32\dism.exe"
	$Output = "Disable "+$DisplayName+"....."
	Write-Host "Disable"$DisplayName"....." -NoNewline
	$Task = "disable-feature"
	$Parameters = "/"+$Status+[char]32+"/"+$Task+[char]32+"/featurename:"+$FeatureName
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Enable-WindowsFeature {
	<#
	.SYNOPSIS
		Enable-WindowsFeature
	.DESCRIPTION
		Enable Windows Feature
	.EXAMPLE
		Enable-WindowsFeature -DisplayName "Volume Activation" -Status online -Feature "RemoteServerAdministrationTools-Roles-VA"
	#>

	Param([String]$DisplayName, [String]$Status, [String]$FeatureName)
	$Executable = $env:windir+"\system32\dism.exe"
	$Output = "Enable "+$DisplayName+"....."
	Write-Host "Enable"$DisplayName"....." -NoNewline
	$Task = "enable-feature"
	$Parameters = "/"+$Status+[char]32+"/"+$Task+[char]32+"/featurename:"+$FeatureName
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Exit-PowerShell {
	<#
	.SYNOPSIS
		Exit-PowerShell
	.DESCRIPTION
		Exit PowerShell if there was an error
	.EXAMPLE
		Exit-PowerShell
	#>
	
	If (($Global:Errors -ne $null) -and ($Global:Errors -ne 0)) {
		Start-Sleep -Seconds 5
		Exit $Global:Errors
	} else {
		Start-Sleep -Seconds 5
	}
}

Function Get-Architecture {
	<#
	.SYNOPSIS
		Get-Architecture
	.DESCRIPTION
		Returns whether the system architecture is 32-bit or 64-bit
	.EXAMPLE
		Get-Architecture
	#>
	
	$Global:Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture
	$Global:Architecture = $Global:Architecture.OSArchitecture
	#Returns 32-bit or 64-bit
}

Function Get-OSVersion  {
	<#
	.SYNOPSIS
		Get-OSVersion
	.DESCRIPTION
		Gets the version of the Operating System
	.EXAMPLE
		Get-OSVersion
	#>

	$Global:OSVersion = (Get-CimInstance Win32_OperatingSystem).version
}

Function Import-RegistryFile {
	<#
	.SYNOPSIS
		Import-RegistryFile
	.DESCRIPTION
		This will import a .reg file
	.EXAMPLE
		Import-RegistryFile "PowerShell Execution Policy" "c:\temp\PowerShell.reg"
	#>
	
	Param([String]$DisplayName, [String]$RegFile)
	$Executable = $Env:windir+"\regedit.exe"
	$Switches = "/s "+$RegFile
	$Output = "Import "+$DisplayName+" key....."
	Write-Host "Import"$DisplayName" key....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If ($ErrCode -eq 0) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Install-EXE {
	<#
	.SYNOPSIS
		Install-EXE
	.DESCRIPTION
		Installs an EXE file
	.EXAMPLE
		Install-EXE "Microsoft Office 2013" "c:\temp\install.exe" "/passive /norestart"
	#>
	
	Param([String]$DisplayName, [String]$Executable, [String]$Switches)
	$Output = "Install "+$DisplayName+"....."
	Write-Host "Install"$DisplayName"....." -NoNewline
	If ((Test-Path $Executable) -eq $true) {
		$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	} else {
		$ErrCode = 1
	}
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Install-Fonts {
	<#
	.SYNOPSIS
		Install-Fonts
	.DESCRIPTION
		Installs all fonts in the designated source directory
	.EXAMPLE
		Install-Fonts $Env:windir"\Fonts" "*.ttf"
	#>
	
	Param([String]$SourceDirectory, [String]$FontType)
	$sa =  new-object -comobject shell.application
	$Fonts =  $sa.NameSpace(0x14)
	#$Files = Get-ChildItem $Env:windir"\Waller\Fonts" -Filter *.ttf
	$Files = Get-ChildItem $SourceDirectory -Filter $FontType
	For ($i = 0; $i -lt $Files.Count; $i++) {
		$Output = $Files[$i].Name+"....."
		Write-Host $Files[$i].Name"....." -NoNewline
		$File = $Env:windir+"\Fonts\"+$Files[$i].Name
		If ((Test-Path $File) -eq $false) {
			$Fonts.CopyHere($Files[$i].FullName)
			If ((Test-Path $File) -eq $true) {
				$Output = $Output+"Installed"
				Write-Host "Installed" -ForegroundColor Yellow
			} else {
				$Output = $Output+"Failed"
				Write-Host "Failed" -ForegroundColor Red
				$Global:Errors++
			}
		} else {
			$Output = $Output+"Installed"
			Write-Host "Installed" -ForegroundColor Yellow
		}
		Out-File -FilePath $LogFile -InputObject $Output -Append -Force
	}
}

Function Install-MSI {
	<#
	.SYNOPSIS
		Install-MSI
	.DESCRIPTION
		Installs an MSI patch
	.EXAMPLE
		Install-MSI "Java Runtime Environment" $Global:RelativePath"jre1.8.0_25.msi" "/qb- /norestart"
	#>
	
	Param([String]$DisplayName, [String]$MSI, [String]$Switches)
	$Executable = $Env:windir+"\system32\msiexec.exe"
	$Parameters = "/i "+[char]34+$MSI+[char]34+[char]32+$Switches+[char]32+"/lvx "+[char]34+$Env:windir+"\waller\Logs\ApplicationLogs\"+$DisplayName+".log"+[char]34
	$Output = "Install"+$DisplayName+"....."
	Write-Host "Install"$DisplayName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Install-MSP {
	<#
	.SYNOPSIS
		Install-MSP
	.DESCRIPTION
		Installs an MSP patch
	.EXAMPLE
		Install-MSP "KB977203" $Global:RelativePath"i386\sccm2007ac-sp2-kb977203-x86.msp" "/qb- /norestart"
	#>
	
	Param([String]$DisplayName, [String]$MSP, [String]$Switches)
	$Executable = $Env:windir+"\system32\msiexec.exe"
	$Parameters = "/p "+[char]34+$MSP+[char]34+[char]32+$Switches
	$Output = "Install "+$DisplayName+"....."
	Write-Host "Install"$DisplayName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Install-MSU {
	<#
	.SYNOPSIS
		Install-MSU
	.DESCRIPTION
		Installs a Microsoft Update
	.EXAMPLE
		Install-MSU "KB2964358" "IE9-Windows6.1-KB2964358-x86.msu" "/quiet /norestart"
	#>

	Param([String]$DisplayName, [String]$MSU, [String]$Switches)
	$Executable = $Env:windir+"\system32\wusa.exe"
	$Parameters = [char]34+$MSU+[char]34+[char]32+$Switches
	$Output = "Install "+$DisplayName+"....."
	Write-Host "Install"$DisplayName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} elseIf ($ErrCode -eq 2359302) {
		$Output = $Output+"Already Installed"
		Write-Host "Already Installed" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function New-Directory {
	<#
	.SYNOPSIS
		New-Directory
	.DESCRIPTION
		This will create a directory
	.EXAMPLE
		New-Directory "c:\temp"
	#>

	Param([String]$Directory)
	$Output = "Create "+$Directory+"....."
	$Temp = $Directory.split("\\")
	Write-Host "Create"$Temp[$Temp.Count-1]"....." -NoNewline
	#Write-Host "Create"$Directory"....." -NoNewline
	If ((Test-Path $Directory) -eq $false) {
		$Temp = New-Item -Path $Directory -ItemType Directory
		If (Test-Path $Directory) {
			$Output = $Output+"Success"
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			$Output = $Output+"Failed"
			Write-Host "Failed" -ForegroundColor Red
			$Global:Errors++
		}
	} else {
		$Output = $Output+"Already Created"
		Write-Host "Success" -ForegroundColor Yellow
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function New-FileShortcut {
	<#
	.SYNOPSIS
		New-FileShortcut
	.DESCRIPTION
		Create shortcut to files
	.EXAMPLE
		New-FileShortcut $Env:Public"\desktop" "Google" "notepad.exe" "" "notepad.exe" "Google" "c:\windows\system32"
	#>
	
	Param([String]$ShortcutDestination, [String]$ShortcutName, [String]$TargetFile, [String]$HotKey, [String]$IconFile, [String]$Description, [String]$WorkingDirectory)
	$ShortcutFile = $ShortcutDestination+"\"+$ShortcutName+".lnk"
	$Output = "Install "+$ShortcutName+" Shortcut....."
	Write-Host "Install"$ShortcutName" Shortcut....." -NoNewline
	$WshShell = New-Object -com Wscript.Shell 
	$Desktop = $WshShell.SpecialFolders.item("AllUsersDesktop") 
	$ShellLink = $WshShell.CreateShortcut($ShortcutFile) 
	$ShellLink.TargetPath = $TargetFile
	$ShellLink.WindowStyle = 1 
	If ($HotKey -ne "") {
		$ShellLink.Hotkey = $HotKey
	}
	If ($IconFile -ne "") {
		$ShellLink.IconLocation = $IconFile
	}
	If ($Description -ne "") {
		$ShellLink.Description = $Description
	}
	If ($WorkingDirectory -ne "") {
		$ShellLink.WorkingDirectory = $WorkingDirectory
	}
	$ShellLink.Save()
	If (Test-Path $ShortcutFile)  {
		Write-Host "Success" -ForegroundColor Yellow
		$Output = $Output + "Success"
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Output = $Output + "Failed"
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function New-LogFile {
	<#
	.SYNOPSIS
		New-LogFile
	.DESCRIPTION
		This will delete the logfile in the beginning of the script
	.EXAMPLE
		New-LogFile
	#>

	If ((Test-Path $Env:windir"\waller") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\waller"
	}
	If ((Test-Path $Env:windir"\waller\Logs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\waller\Logs"
	}
	If ((Test-Path $Env:windir"\waller\Logs\ApplicationLogs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\waller\Logs\ApplicationLogs"
	}
	If ((Test-Path $Env:windir"\waller\Logs\BuildLogs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\waller\Logs\BuildLogs"
	}
	If ((Test-Path $Global:LogFile) -eq $true) {
		Remove-Item $Global:LogFile -Force
	}
	$ErrorLog = $Global:LogFile
	$ErrorLog = $ErrorLog -replace "\.log", "_ERROR.log"
	If ((Test-Path $ErrorLog) -eq $true) {
		Remove-Item $ErrorLog -Force
	}
	$temp = New-Item $Global:LogFile -ItemType file -Force
}

Function New-StartMenuShortcut {
	<#
	.SYNOPSIS
		New-StartMenuShortcut
	.DESCRIPTION
		Pin application shortcut to start menu
	.EXAMPLE
		New-StartMenuShortcut -ApplicationName "Outlook" -PinnedApplicationShortcut $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" -Executable "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"
	#>
	
	Param([String]$ApplicationName, [String]$PinnedApplicationShortcut, [String]$Executable)
	Write-Host "Pin"$ApplicationName" on Start Menu....." -NoNewline
	If ((Test-Path $Executable) -eq $true) {
		If ((Test-Path $PinnedApplicationShortcut) -eq $false) {
			$sa = new-object -c shell.application
			$AppSplit = $Executable.split("\")
			$AppSplitCount = $AppSplit.Count
			$Filename = $AppSplit[$AppSplitCount-1]
			For ($i=0; $i -lt $AppSplitCount-1) {
				$DirectoryPath = $DirectoryPath+$AppSplit[$i]
				If ($i -ne $AppSplitCount-2) {
					$DirectoryPath = $DirectoryPath+"\"
				}
				$i++
			}
			$pn = $sa.namespace($DirectoryPath).parsename($Filename)
			$pn.invokeverb('startpin')
			If ((Test-Path $PinnedApplicationShortcut) -eq $true) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed " -ForegroundColor Red
			}
		} else {
			Write-Host "Already Present" -ForegroundColor Yellow
		}
	} else {
		Write-Host "Application not installed" -ForegroundColor Green
	}
}

Function New-TaskbarShortcut {
	<#
	.SYNOPSIS
		New-TaskbarShortcut
	.DESCRIPTION
		Pin application shortcut to the Taskbar
	.EXAMPLE
		New-TaskbarShortcut -ApplicationName "Outlook" -PinnedApplicationShortcut $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" -Executable "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"
	#>
	
	Param([String]$ApplicationName, [String]$PinnedApplicationShortcut, [String]$Executable)
	Write-Host "Pin"$ApplicationName" to Taskbar....." -NoNewline
	If ((Test-Path $Executable) -eq $true) {
		If ((Test-Path $PinnedApplicationShortcut) -eq $false) {
			$sa = new-object -c shell.application
			$AppSplit = $Executable.split("\")
			$AppSplitCount = $AppSplit.Count
			$Filename = $AppSplit[$AppSplitCount-1]
			For ($i=0; $i -lt $AppSplitCount-1) {
				$DirectoryPath = $DirectoryPath+$AppSplit[$i]
				If ($i -ne $AppSplitCount-2) {
					$DirectoryPath = $DirectoryPath+"\"
				}
				$i++
			}
			$pn = $sa.namespace($DirectoryPath).parsename($Filename)
			$pn.invokeverb('taskbarpin')
			If ((Test-Path $PinnedApplicationShortcut) -eq $true) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed " -ForegroundColor Red
			}
		} else {
			Write-Host "Already Present" -ForegroundColor Yellow
		}
	} else {
		Write-Host "Application not installed" -ForegroundColor Green
	}
}

Function New-URLShortcut {
	<#
	.SYNOPSIS
		New-URLShortcut
	.DESCRIPTION
		Creates a URL shortcut
	.EXAMPLE
		New-URLShortcut "Security Training Quiz" "http://172.18.30.51/quiz" "c:\users\public\Desktop\" "C:\Windows\waller\Icons\Waller.ico"
	#>
	
	Param([String]$DisplayName, [String]$URL, [String]$Directory, [String]$IconFile)
	$Output = "Install "+$DisplayName+" Shortcut....."
	Write-Host "Install"$DisplayName" Shortcut....." -NoNewline
	$shortcut_name = $DisplayName
	$shortcut_target = $URL
	$oShell = new-object -com "WScript.Shell" 
	$lnk = $oShell.CreateShortcut( (join-path $Directory $shortcut_name) + ".lnk" ) 
	$lnk.TargetPath = $shortcut_target 
	$lnk.IconLocation = $IconFile
	$lnk.Save()
	If (Test-Path ((join-path $Directory $shortcut_name) + ".lnk" )) {
		Write-Host "Successful" -ForegroundColor Yellow
		$Output = $Output+"Successful"
	} else {
		Write-Host "Failed" -ForegroundColor Red
		$Output = $Output+"Failed"
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Remove-Directory {
	<#
	.SYNOPSIS
		Remove-Directory
	.DESCRIPTION
		Deletes specified directory
	.EXAMPLE
		Remove-Directory "c:\Program Files\Open Text\DM Extensions", 0
	#>
	
	Param([String]$Directory, [String]$Recurse)
	$Output = "Delete "+$Directory+"....."
	Write-Host "Delete"$Directory"....." -NoNewline
	If (Test-Path $Directory) {
		If (($Recurse -eq 0) -or ($Recurse -eq $null)) {
			$directoryInfo = Get-ChildItem $Directory | Measure-Object
			If ($directoryInfo.count -eq 0) {
				Remove-Item $Directory -Force
			} 
		} elseIf ($Recurse -eq 1) {
			Remove-Item $Directory -Recurse -Force
		}
		If ((Test-Path $Directory) -eq $False) {
			Write-Host "Success" -ForegroundColor Yellow
			$Output = $Output + "Success"
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Output = $Output + "Failed"
			$Global:Errors++
		}
	} else {
		$Output = $Output + "Not Present"
		Write-Host "Not Present" -ForegroundColor Green
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Remove-DirectoryFromUserProfiles {
	<#
	.SYNOPSIS
		Remove Directory From User Profiles
	.DESCRIPTION
		Delete directory from all User Profiles
	.EXAMPLE
		Remove-DirectoryFromUserProfiles "AppData\Roaming\OpenText"
	#>
	
	Param([String]$Directory)
	$Users = Get-ChildItem "c:\users" -ErrorAction SilentlyContinue
	Foreach ($User in $Users) {
		$UserDir = "c:\users\"+$User+"\"+$Directory
		Remove-Directory $UserDir 1
	}
}

Function Remove-File {
	<#
	.SYNOPSIS
		Remove-File
	.DESCRIPTION
		Deletes a specific file
	.EXAMPLE
		Remove-File "c:\temp\Test.ps1"
	#>
	
	Param([String]$File)
	$Output = "Delete "+$File+"....."
	Write-Host "Delete"$File"....." -NoNewline
	If (Test-Path $File) {
		Remove-Item $File -Force
		If ((Test-Path $File) -eq $False) {
			$Output = $Output + "Success"
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			$Output = $Output + "Failed"
			Write-Host "Failed" -ForegroundColor Red
			$Global:Errors++
		}
	} else {
		$Output = $Output + "Not Present"
		Write-Host "Not Present" -ForegroundColor Green
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Remove-FileFromUserProfiles {
	<#
	.SYNOPSIS
		Remove-FileFromUserProfiles
	.DESCRIPTION
		Delete specified file from all user profiles
	.EXAMPLE
		Remove-FileFromUserProfiles "AppData\Roaming\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\DMMarkEmail.lnk"
	#>

	Param([String]$File)
	$Users = Get-ChildItem "c:\users" -ErrorAction SilentlyContinue
	Foreach ($User in $Users) {
		$UserDir = "c:\users\"+$User+"\"+$File
		Remove-File $UserDir
	}
}

Function Remove-HKUKey {
	<#
	.SYNOPSIS
		Remove-HKUKey
	.DESCRIPTION
		Deletes specified registry key from all user hives in HKEY_Users
	.EXAMPLE
		Remove-HKUKey "SOFTWARE\Hummingbird"
	#>
	
	Param([String]$RegistryKey, [String]$Recurse)
	$Temp = New-PSDrive HKU Registry HKEY_USERS
	$HKUsers = Get-ChildItem HKU:\ -ErrorAction SilentlyContinue
	ForEach ($User in $HKUsers) {
		$TestKey = $User.Name
		$TestKey1 = $null
		$TestKey = $TestKey.Split("\")
		$TestKey[0] = "HKU:"
		For ($i=0; $i -lt $TestKey.Count; $i++) {
			$TestKey1 = $TestKey1+$TestKey[$i]
			If ($i -lt $TestKey.Count-1) {
				$TestKey1 = $TestKey1+"\"
			}
		}
		$TestKey1 = $TestKey1+"\"+$RegistryKey
		If (Test-Path $TestKey1) {
			$Output = "Delete"+$TestKey1+"....."
			Write-Host "Delete"$TestKey1"....." -NoNewline
			If (($Recurse -eq "0") -or ($Recurse -eq $null)) {
				Remove-Item -Path $TestKey1 -Force
			} elseIf ($Recurse -eq "1") {
				Remove-Item -Path $TestKey1 -Recurse -Force
			}
			If ((Test-Path $TestKey1) -eq $false)  {
				$Output = $Output + "Success"
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				$Output = $Output + "Failed"
				Write-Host "Failed" -ForegroundColor Yellow
				$Global:Errors++
			}
		}
		Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
	}
}

Function Remove-RegistryKey {
	<#
	.SYNOPSIS
		Remove-RegistryKey
	.DESCRIPTION
		Deletes a specific registry key
	.EXAMPLE
		Remove-RegistryKey "HKEY_LOCAL_MACHINE\SOFTWARE\Hummingbird"
	#>

	Param([String]$RegistryKey, [String]$Recurse)
	$tempdrive = New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT
	$RegistryKey1 = $RegistryKey.split("\")
	switch ($RegistryKey1[0]) {
		"HKEY_CLASSES_ROOT" {$RegistryKey1[0] = "HKCR"}
		"HKEY_CURRENT_USER" {$RegistryKey1[0] = "HKCU"}
		"HKEY_LOCAL_MACHINE" {$RegistryKey1[0] = "HKLM"}
		"HKEY_USERS" {$RegistryKey1[0] = "HKU"}
		"HKEY_CURRENT_CONFIG" {$RegistryKey1[0] = "HKCC"}
	}
	For ($i=0; $i -lt $RegistryKey1.Count; $i++) {
		$RegKey = $RegKey+$RegistryKey1[$i]
		If ($i -eq 0) {
			$RegKey = $RegKey+":\"
		} elseif ($i -ne $RegistryKey1.Count-1){
			$RegKey = $RegKey+"\"
		} else {
			$RegKey = $RegKey
		}
	}
	$Output = "Delete "+$RegKey+"....."
	Write-Host "Delete"$RegKey"....." -NoNewline
	If (Test-Path $RegKey) {
		If (($Recurse -eq "0") -or ($Recurse -eq $null)) {
			Remove-Item -Path $RegKey -Force
		} elseIf ($Recurse -eq "1") {
			Remove-Item -Path $RegKey -Recurse -Force
		}
	}
	If ((Test-Path $RegKey) -eq $false) {
		$Output = $Output + "Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output + "Failed"
		Write-Host "Failed" -ForegroundColor Yellow
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Remove-StartMenuShortcut {
	<#
	.SYNOPSIS
		Remove-StartMenuShortcut
	.DESCRIPTION
		Unpin application shortcut from the start menu bar
	.EXAMPLE
		Remove-StartMenuShortcut -ApplicationName "Outlook" -PinnedApplicationShortcut $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" -Executable "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"
	#>
	
	Param([String]$ApplicationName, [String]$PinnedApplicationShortcut, [String]$Executable)
	Write-Host "Unpin"$ApplicationName" from Start Menu....." -NoNewline
	If ((Test-Path $PinnedApplicationShortcut) -eq $true) {
		$sa = new-object -c shell.application
		$AppSplit = $Executable.split("\")
		$AppSplitCount = $AppSplit.Count
		$Filename = $AppSplit[$AppSplitCount-1]
		For ($i=0; $i -lt $AppSplitCount-1) {
			$DirectoryPath = $DirectoryPath+$AppSplit[$i]
			If ($i -ne $AppSplitCount-2) {
				$DirectoryPath = $DirectoryPath+"\"
			}
			$i++
		}
		$pn = $sa.namespace($DirectoryPath).parsename($Filename)
		$pn.invokeverb('startunpin')
		If ((Test-Path $PinnedApplicationShortcut) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed " -ForegroundColor Red
		}
	} else {
		Write-Host "Already Removed" -ForegroundColor Yellow
	}
}

Function Remove-TaskbarShortcut {
	<#
	.SYNOPSIS
		Remove-StartMenuShortcut
	.DESCRIPTION
		Unpin application shortcut from the start menu bar
	.EXAMPLE
		Remove-StartMenuShortcut -ApplicationName "Outlook" -PinnedApplicationShortcut $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" -Executable "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"
	#>
	
	Param([String]$ApplicationName, [String]$PinnedApplicationShortcut, [String]$Executable)
	Write-Host "Unpin"$ApplicationName" from Taskbar....." -NoNewline
	If ((Test-Path $PinnedApplicationShortcut) -eq $true) {
		$AppSplit = $Executable.split("\")
		$AppSplitCount = $AppSplit.Count
		$Filename = $AppSplit[$AppSplitCount-1]
		$DirectoryPath = $Executable.Trim($Filename)
		$DirectoryPath = $DirectoryPath.Trim("\")
		If ($Filename -eq "EXCEL.EXE") {
			$DirectoryPath = "c"+$DirectoryPath
		}
		$sa = new-object -c shell.application
		$pn = $sa.namespace($DirectoryPath).parsename($Filename)
		$pn.invokeverb('taskbarunpin')
		If ((Test-Path $PinnedApplicationShortcut) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed " -ForegroundColor Red
		}
	} else {
		Write-Host "Already Removed" -ForegroundColor Yellow
	}
}

Function Remove-Variables {
	<#
	.SYNOPSIS
		Remove-Variables
	.DESCRIPTION
		Removes all variables in the passed array from memory
	.EXAMPLE
		Remove-Variables $GlobalVariables "Global"
	#>
	
	Param([String]$Variables, [String]$Scope)
	$VariablesArray = $Variables -split " "
	Foreach ($Var in $VariablesArray) {
		$VarTest = Get-Variable $Var -Scope $Scope
		If ($VarTest -ne $null) {
			Remove-Variable -Name $Var -Scope $Scope -Force
		}
	}
}

Function Set-ConsoleTitle {
	<#
	.SYNOPSIS
		Set-ConsoleTitle
	.DESCRIPTION
		Renames the PowerShell console window
	.EXAMPLE
		Set-ConsoleTitle "Test"
	#>
	
	Param([String]$Title)
	$host.ui.RawUI.WindowTitle = $Title
}

Function Set-FolderPermissions {
	<#
	.SYNOPSIS
		Set-FolderPermissions
	.DESCRIPTION
		Set permission to a specific folder
	.EXAMPLE
		Set-FolderPermissions $Env:systemdrive"\temp\NetDocuments" "NT AUTHORITY\Authenticated Users" "Modify" "Allow"
	#>
	
	Param([String]$Folder, [String]$Account, [String]$FolderRights, [String]$AccessControl)
	$ACL = Get-Acl $Folder
	$Count = $ACL.Access.Count
	$IdentityReference = $ACL.Access | ForEach-Object { $_.identityReference.value }
	For ($i=0; $i -le $Count; $i++) {
		If ($ACL.Access[$i].IdentityReference -eq $Account) {
			$AR = New-Object system.security.accesscontrol.filesystemaccessrule($ACL.Access[$i].IdentityReference,$FolderRights,$AccessControl)
			$ACL.SetAccessRule($AR)
			Set-Acl $Folder $ACL
			$ACL = Get-Acl $Folder
			[string]$Rights = $ACL.Access[$i].FileSystemRights
			$a = @()
			$a = $Rights.split(",")
			If ($a[0] -ne "-536805376") {
				Write-Host $ACL.Access[$i].IdentityReference"....." -NoNewline
				Write-Host $a[0] -ForegroundColor Yellow
				[string]$Output = $ACL.Access[$i].IdentityReference
				$Output = $Output + "....." + $a[0]
				Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
			}
		}
	}
}

Function Set-Variables {
	<#
	.SYNOPSIS
		Set-Variables
	.DESCRIPTION
		Declares all items in the passed array as variables
	.EXAMPLE
		Set-Variables $GlobalVariables "Global"
	#>
	
	Param([String]$Variables, [String]$Scope)
	Foreach ($Var in $Variables) {
		$VarTest = Get-Variable $Var -Scope $Scope -ErrorAction SilentlyContinue
		If ($VarTest -ne $null) {
			Remove-Variable -Name $Var -Scope $Scope -Force
		}
		Set-Variable -Name $Var -Scope $Scope
	}
}

Function Start-Task {
	<#
	.SYNOPSIS
		Start-Task
	.DESCRIPTION
		Starts a designated Process
	.EXAMPLE
		Start-Task "outlook"
	#>

	Param([String]$Process)
	$Proc = Get-Process $Process -ErrorAction SilentlyContinue
	$Output = "Starting "+$Process+"....."
	Write-Host "Starting"$Process"....." -NoNewline
	If ($Proc -eq $null) {
		Start-Process $Process -ErrorAction SilentlyContinue
		Start-Sleep -Seconds 2
		$Proc = Get-Process $Process -ErrorAction SilentlyContinue
		If ($Proc -ne $null) {
			$Output = $Output+"Started"
			Write-Host "Started" -ForegroundColor Yellow
		} else {
			$Output = $Output+"Failed"
			Write-Host "Failed" -ForegroundColor Red
			$Global:Errors++
		}
	} else {
		$Output = $Output+"Already Started"
		Write-Host "Already Started" -ForegroundColor Yellow
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Stop-Task {
	<#
	.SYNOPSIS
		Stop-Task
	.DESCRIPTION
		Kills a designated Task
	.EXAMPLE
		Stop-Task "outlook"
	#>
	
	Param([String]$Process)
	$Proc = Get-Process $Process -ErrorAction SilentlyContinue
	$Output = "Killing "+$Process+"....."
	Write-Host "Killing"$Process"....." -NoNewline
	If ($Proc -ne $null) {
		Do {
			$ProcName = $Process+".exe"
			$Temp = taskkill /F /IM $ProcName
			Start-Sleep -Seconds 2
			$Proc = $null
			$Proc = Get-Process $Process -ErrorAction SilentlyContinue
		} While ($Proc -ne $null)
		$Output = $Output+"Closed"
		Write-Host "Closed" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Already Closed"
		Write-Host "Already Closed" -ForegroundColor Green
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Uninstall-EXE {
	<#
	.SYNOPSIS
		Uninstall-EXE
	.DESCRIPTION
		Uninstalls an EXE file
	.EXAMPLE
		Uninstall-EXE "Microsoft Office 2013" "c:\temp\setup.exe" "/uninstall /passive /norestart"
	#>
	
	Param([String]$DisplayName, [String]$Executable, [String]$Switches)
	$Output = "Uninstall "+$DisplayName+"....."
	Write-Host "Uninstall"$DisplayName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Uninstall-MSI {
	<#
	.SYNOPSIS
		Uninstall-MSI
	.DESCRIPTION
		Uninstalls an MSI application using the MSI file
	.EXAMPLE
		Uninstall-MSI "Workshare Professional" "c:\temp\ACME.msi"
	#>

	Param([String]$DisplayName, [String]$MSI, [String]$Switches)
	$Executable = $Env:windir+"\system32\msiexec.exe"
	$Parameters = "/x "+$MSI+[char]32+$Switches
	$Output = "Uninstall "+$DisplayName+"....."
	Write-Host "Uninstall"$DisplayName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} elseIf ($ErrCode -eq 1605) {
		$Output = $Output+"Not Present"
		Write-Host "Not Present" -ForegroundColor Green
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Uninstall-MSIByName {
	<#
	.SYNOPSIS
		Uninstall-MSIByName
	.DESCRIPTION
		Uninstalls an MSI application using the MSI file
	.EXAMPLE
		Uninstall-MSIByName "Adobe Reader" "/qb- /norestart"
	#>

	Param([String]$ApplicationName, [String]$Switches)
	$Uninstall = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ea SilentlyContinue
	$Uninstall += Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ea SilentlyContinue
	$SearchName = "*"+$ApplicationName+"*"
	$Executable = $Env:windir+"\system32\msiexec.exe"
	Foreach ($Key in $Uninstall) {
		$TempKey = $Key.Name -split "\\"
		If ($TempKey[002] -eq "Microsoft") {
			$Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"+$Key.PSChildName
		} else {
			$Key = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"+$Key.PSChildName
		}
		If ((Test-Path $Key) -eq $true) {
			$KeyName = Get-ItemProperty -Path $Key
			If ($KeyName.DisplayName -like $SearchName) {
				$TempKey = $KeyName.UninstallString -split " "
				If ($TempKey[0] -eq "MsiExec.exe") {
					$Output = "Uninstall "+$KeyName.DisplayName+"....."
					Write-Host "Uninstall"$KeyName.DisplayName"....." -NoNewline
					$Parameters = "/x "+$KeyName.PSChildName+[char]32+$Switches
					$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
					If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {
						$Output = $Output+"Success"
						Write-Host "Success" -ForegroundColor Yellow
					} else {
						$Output = $Output+"Failed with error code "+$ErrCode
						Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
						$Global:Errors++
					}
					Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
				}
			}
		}
	}
}

Function Uninstall-MSIByGUID {
	<#
	.SYNOPSIS
		Uninstall-MSIByGUID
	.DESCRIPTION
		Uninstalls an MSI application using the GUID
	.EXAMPLE
		Uninstall-MSIByGUID "Workshare Professional" "{8686EC18-6282-4AA9-92AC-2865B972E244}"
	#>

	Param([String]$DisplayName, [String]$GUID)
	$Executable = $Env:windir+"\system32\msiexec.exe"
	$Switches = [char]32+"/qb- /norestart"
	$Parameters = "/x "+$GUID+$Switches
	$Output = "Uninstall "+$DisplayName+"....."
	Write-Host "Uninstall"$DisplayName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} elseIf ($ErrCode -eq 1605) {
		$Output = $Output+"Not Present"
		Write-Host "Not Present" -ForegroundColor Green
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Wait-ProcessEnd {
	<#
	.SYNOPSIS
		Wait-Process
	.DESCRIPTION
		Waits for a Process to end before continuing.
	.EXAMPLE
		Wait-Process "explorer"
	#>

	Param([String]$Process)
	$Output = "Waiting for "+$Process+" to end....."
	Write-Host "Waiting for"$Process" to end....." -NoNewline
	$Proc = Get-Process $Process -ErrorAction SilentlyContinue
	If ($Proc -ne $null) {
		Do {
			Start-Sleep -Seconds 5
			$Proc = Get-Process $Process -ErrorAction SilentlyContinue
		} While ($Proc -ne $null)
		$Output = $Output+"Ended"
		Write-Host "Ended" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Process Already Ended"
		Write-Host "Process Already Ended" -ForegroundColor Yellow
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function Write-LogFile {
	<#
	.SYNOPSIS
		Write-LogFile
	.DESCRIPTION
		This will delete the logfile in the beginning of the script and then
		add _ERROR to the filename if an error is detected during the installation.
	.EXAMPLE
		Write-LogFile
	#>

	If ((Test-Path $Global:BuildLog) -eq $false) {
		New-Item $Global:BuildLog -ItemType File -Force
	}
	If ($Global:Errors -eq $null) {
		$date = get-date
		$LogTitle = $Global:Phase+[char]9+$Global:Sequence+[char]9+$Global:Title+[char]9+$date.month+"/"+$date.day+"/"+$date.year+" "+$date.hour+":"+$date.minute
		Out-File -FilePath $Global:BuildLog -InputObject $LogTitle -Append -Force
	} elseIf (Test-Path $Global:LogFile) {
		$Global:LogFile.ToString()
		$File1 = $Global:LogFile.Split(".")
		$Filename1 = $File1[0]+"_ERROR"+"."+$File1[1]
		Rename-Item $Global:LogFile -NewName $Filename1 -Force
	}
}
# SIG # Begin signature block
# MIID9QYJKoZIhvcNAQcCoIID5jCCA+ICAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFEdutHB6P4FP1QXu95JCgXjE
# GoygggITMIICDzCCAXygAwIBAgIQ7HIUNzqOT5xDLZzmAt84bjAJBgUrDgMCHQUA
# MBgxFjAUBgNVBAMTDU1pY2sgUGxldGNoZXIwHhcNMTQwNzE2MTM1NTA1WhcNMzkx
# MjMxMjM1OTU5WjAYMRYwFAYDVQQDEw1NaWNrIFBsZXRjaGVyMIGfMA0GCSqGSIb3
# DQEBAQUAA4GNADCBiQKBgQCScgjcWXrW4VkX2SFeT8Qse6Vxpr0KEiP1htaEeI4Y
# hnYkdu+BsI8EvDRcXtBl8jbb+2hrwhLPCIs73ha/mJ8Bi93aG1lZxBj0skknENwc
# WRnppmmfPR6ZB3YPJ/JI1LMKUenKE5LgriojqfKLR1bX27IO8NK6EAcicZqwidLr
# zwIDAQABo2IwYDATBgNVHSUEDDAKBggrBgEFBQcDAzBJBgNVHQEEQjBAgBAmjhAc
# F97GTTLK+hLMy2UQoRowGDEWMBQGA1UEAxMNTWljayBQbGV0Y2hlcoIQ7HIUNzqO
# T5xDLZzmAt84bjAJBgUrDgMCHQUAA4GBAG8Ll2EtPpoJxDEBWHbN2+Kaae0lB9il
# CNTJwUB09Xqul7CFMKOOUt2zU+VsPQAHaJb2VY5ajgJRU22KFwAUk0KFbMxGibDc
# giw5FkzyAHqGyDZjwdPPFs7PJ1Ulnq3qc/JF/fXH5De02Dt7NEZQsTO+SMJWYjHE
# vb6aRW4Q0oDwMYIBTDCCAUgCAQEwLDAYMRYwFAYDVQQDEw1NaWNrIFBsZXRjaGVy
# AhDschQ3Oo5PnEMtnOYC3zhuMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTmShmy6rdBiilpevWn
# 5b40JNVvgTANBgkqhkiG9w0BAQEFAASBgHSZ1MCgVoj3r9gOU1/zH9GVDcuCnffU
# GxetChZvy2/T6h4lrexStKVTFEiQfenlb1QZS2Fs4JKvuAcJd1pXR3h8EJ0XzT0D
# JViui/K8DKtK91m18VvQ5kV/7S/vz+A6ZiWx4yRlRtfAN2vCfiw4E0TS6U9t0Fim
# 1VA9PfbaPuoG
# SIG # End signature block
