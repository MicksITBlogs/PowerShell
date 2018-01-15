<#
	.SYNOPSIS
		Disable Cisco Jabber Chat History
	
	.DESCRIPTION
		This script will disable the Jabber chat history by setting the .DB file to read-only. It begins by killing the Jabber task, deleting the .DB file, reopening Jabber, and then setting the .DB file to read-only. The script uses this process because if the old .DB file has not been deleted before setting it to read-only, the stored conversations will be there permanently. Since the .DB file is stored in the user profile, this cannot be done in the build.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.3.131
		Created on:   	03/21/2017 4:21 PM
		Created by:   	Mick Pletcher 
		Filename:	CiscoJabberChatCleanup.ps1
		===========================================================================
#>

[CmdletBinding()]
param ()

function Close-Process {
<#
	.SYNOPSIS
		Stop ProcessName
	
	.DESCRIPTION
		Kills a ProcessName and verifies it was stopped while reporting it back to the screen.
	
	.PARAMETER ProcessName
		Name of ProcessName to kill
	
	.EXAMPLE
		PS C:\> Close-ProcessName -ProcessName 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param
	(
		[ValidateNotNullOrEmpty()][string]$ProcessName
	)
	
	$Process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
	If ($Process -ne $null) {
		$Output = "Stopping " + $Process.Name + " process....."
		Stop-Process -Name $Process.Name -Force -ErrorAction SilentlyContinue
		Start-Sleep -Seconds 1
		$TestProcess = Get-Process $ProcessName -ErrorAction SilentlyContinue
		If ($TestProcess -eq $null) {
			$Output += "Success"
			Write-Host $Output
			Return $true
		} else {
			$Output += "Failed"
			Write-Host $Output
			Return $false
		}
	} else {
		Return $true
	}
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

function Open-Application {
<#
	.SYNOPSIS
		Open Application
	
	.DESCRIPTION
		Opens an applications
	
	.PARAMETER Executable
		A description of the Executable parameter.
	
	.PARAMETER ApplicationName
		Display Name of the application
	
	.PARAMETER Process
		Application Process Name
	
	.EXAMPLE
		PS C:\> Open-Application -Executable 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[string]$Executable,
		[ValidateNotNullOrEmpty()][string]$ApplicationName
	)
	
	$Architecture = Get-Architecture
	$Uninstall = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
	If ($Architecture -eq "64-bit") {
		$Uninstall += Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
	}
	$InstallLocation = ($Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq $ApplicationName }).InstallLocation
	If ($InstallLocation[$InstallLocation.Length - 1] -ne "\") {
		$InstallLocation += "\"
	}
	$Process = ($Executable.Split("."))[0]
	$Output = "Opening $ApplicationName....."
	Start-Process -FilePath $InstallLocation$Executable -ErrorAction SilentlyContinue
	Start-Sleep -Seconds 5
	$NewProcess = Get-Process $Process -ErrorAction SilentlyContinue
	If ($NewProcess -ne $null) {
		$Output += "Success"
	} else {
		$Output += "Failed"
	}
	Write-Output $Output
}

function Remove-ChatFiles {
<#
	.SYNOPSIS
		Delete Jabber Chat Files
	
	.DESCRIPTION
		Deletes Jabber chat files located at %USERNAME%\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History and verifies they were deleted
	
	.EXAMPLE
		PS C:\> Remove-ChatFiles
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#Get Jabber Chat history files
	$ChatHistoryFiles = Get-ChildItem -Path $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History' -Filter *.db
	If ($ChatHistoryFiles -ne $null) {
		foreach ($File in $ChatHistoryFiles) {
			$Output = "Deleting " + $File.Name + "....."
			Remove-Item -Path $File.FullName -Force | Out-Null
			If ((Test-Path $File.FullName) -eq $false) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
		}
		Write-Output $Output
	} else {
		$Output = "No Chat History Present"
		Write-Output $Output
	}
}

function Remove-MyJabberFilesFolder {
<#
	.SYNOPSIS
		Delete MyJabberFiles Folder
	
	.DESCRIPTION
		Delete the MyJabberFiles folder stores under %USERNAME%\documents and verifies it was deleted.
	
	.EXAMPLE
		PS C:\> Remove-MyJabberFilesFolder
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$MyJabberFilesFolder = Get-Item $env:USERPROFILE'\Documents\MyJabberFiles' -ErrorAction SilentlyContinue
	If ($MyJabberFilesFolder -ne $null) {
		$Output = "Deleting " + $MyJabberFilesFolder.Name + "....."
		Remove-Item -Path $MyJabberFilesFolder -Recurse -Force | Out-Null
		If ((Test-Path $MyJabberFilesFolder.FullName) -eq $false) {
			$Output += "Success"
		} else {
			$Output += "Failed"
		}
		Write-Output $Output
	} else {
		$Output = "No MyJabberFiles folder present"
		Write-Output $Output
	}
}

function Set-DBFilePermissions {
<#
	.SYNOPSIS
		Set .DB File Permission
	
	.DESCRIPTION
		Make the .DB file read-only
	
	.EXAMPLE
				PS C:\> Set-DBFilePermissions
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#Get list of chat history files
	$ChatHistoryFiles = Get-ChildItem -Path $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History' -Filter *.db
	foreach ($File in $ChatHistoryFiles) {
		#Set .DB file to read-only
		$Output = "Setting " + $File.Name + " to Read-Only....."
		$ReadOnly = Get-ItemPropertyValue -Path $File.FullName -Name IsReadOnly
		If (($ReadOnly) -eq $false) {
			Set-ItemProperty -Path $File.FullName -Name IsReadOnly -Value $true
			$ReadOnly = Get-ItemPropertyValue -Path $File.FullName -Name IsReadOnly
			If (($ReadOnly) -eq $true) {
				$Output += "Success"
			} else {
				$Output += "Failed"
			}
		} else {
			$Output += "Success"
		}
		Write-Output $Output
	}
}

Clear-Host
#Kill Cisco Jabber Process
$JabberClosed = Close-Process -ProcessName CiscoJabber
#Delete .DB files from %USERNAME%\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History
Remove-ChatFiles
#Delete %USERNAME%\documents\MyJabberFiles directory
Remove-MyJabberFilesFolder
#Reopen Jabber if it was open
If ($JabberClosed -eq $true) {
	Open-Application -ApplicationName "Cisco Jabber" -Executable CiscoJabber.exe
}
$JabberClosed = Close-Process -ProcessName CiscoJabber
#Set the .DB file to read-only
Set-DBFilePermissions
#Reopen Jabber
If ($JabberClosed -eq $true) {
	Open-Application -ApplicationName "Cisco Jabber" -Executable CiscoJabber.exe
}
