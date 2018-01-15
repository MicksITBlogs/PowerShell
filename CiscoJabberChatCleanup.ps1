<#
	.SYNOPSIS
		Delete Cisco Jabber Chat History
	
	.DESCRIPTION
		Deletes the files and folder that contain the Cisco Jabber chat history
	
	.PARAMETER SecureDelete
		Implement Secure Deletion of files and folders
	
	.PARAMETER SecureDeletePasses
		Number of secure delete passes
	
	.EXAMPLE
		Delete Cisco Jabber chat without secure delete
			powershell.exe -file CiscoJabberChatCleanup.ps1

		Delete Cisco Jabber chate with secure delete
			powershell.exe -file CiscoJabberChatCleanup.ps1 -SecureDelete -SecureDeletePasses 3

	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.3.131
		Created on:   	12/13/2016 12:20 PM 
		Created by:   	Mick Pletcher
		Filename:	CiscoJabberChatCleanup.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[switch]$SecureDelete,
	[string]$SecureDeletePasses = '3'
)

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
	$InstallLocation = ($Uninstall | ForEach-Object {	Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq $ApplicationName }).InstallLocation
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
	
	#$JabberChatHistory = $env:USERPROFILE + '\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History'
	#Get Jabber Chat history files
	$ChatHistoryFiles = Get-ChildItem -Path $env:USERPROFILE'\AppData\Local\Cisco\Unified Communications\Jabber\CSF\History' -Filter *.db
	If ($ChatHistoryFiles -ne $null) {
		foreach ($File in $ChatHistoryFiles) {
			$Output = "Deleting " + $File.Name + "....."
			If ($SecureDelete.IsPresent) {
				$RelativePath = Get-RelativePath
				$Architecture = Get-Architecture
				If ($Architecture -eq "32-bit") {
					$sDelete = [char]34 + $RelativePath + "sdelete.exe" + [char]34
				} else {
					$sDelete = [char]34 + $RelativePath + "sdelete64.exe" + [char]34
				}
				$Switches = "-accepteula -p" + [char]32 + $SecureDeletePasses + [char]32 + "-q" + [char]32 + [char]34 + $File.FullName + [char]34
				$ErrCode = (Start-Process -FilePath $sDelete -ArgumentList $Switches -Wait -PassThru).ExitCode
				If (($ErrCode -eq 0) -and ((Test-Path $File.FullName) -eq $false)) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
			} else {
				Remove-Item -Path $File.FullName -Force | Out-Null
				If ((Test-Path $File.FullName) -eq $false) {
					$Output += "Success"
				} else {
					$Output += "Failed"
				}
			}
			Write-Output $Output
		}
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
