<#
	.SYNOPSIS
		Microsoft Office Updater
	
	.DESCRIPTION
		This script will keep the Updates folder populated with the latest Office
		updates that SCCM has downloaded. It should be setup to execute as a
		scheduled task on the SCCM server. I suggest executing it once a week.
	
	.PARAMETER Country
		The language-country of the updates
	
	.PARAMETER EmailLogs
		True or false on whether to email logs of the latest updates applied to the Office Updates folder.
	
	.PARAMETER EmailRecipients
		Email address to send report to
	
	.PARAMETER EmailSender
		Sender email address
	
	.PARAMETER ExclusionFileName
		Text file containing a list of updates to exclude
	
	.PARAMETER LogFileName
		Name of the log file to be written to
	
	.PARAMETER ProcessedUpdatesFile
		Name of the file containing a list of Microsoft Office updates that have already been copied over
	
	.PARAMETER SMTPServer
		fully qualified SMTP server name
	
	.PARAMETER SourceFolder
		The folder where SCCM stores the updates
	
	.PARAMETER UpdatesFolder
		The folder where Microsoft Office looks for the updates. This is typically <Office installer folder>\Updates.
	
	.EXAMPLE
		All parameters pre-populated
		powershell.exe -executionpolicy bypass -file OfficeUpdater.ps1
		
		All parameters pre-populated without email send (-command must be used when populating boolean values at the command line)
		powershell.exe -executionpolicy bypass -command OfficeUpdater.ps1 -EmailLogs $false
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
		Created on:   	6/15/2016 10:29 AM
		Created by:   	Mick Pletcher
		Filename:     	OfficeUpdater.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
		[ValidateNotNullOrEmpty()][string]$Country = 'en-us',
		[ValidateNotNullOrEmpty()][boolean]$EmailLogs = $true,
		[string]$EmailRecipients,
		[string]$EmailSender,
		[ValidateNotNullOrEmpty()][string]$ExclusionFileName = 'ExclusionList.txt',
		[ValidateNotNullOrEmpty()][string]$LogFileName = 'MicrosoftOfficeUpdates.log',
		[ValidateNotNullOrEmpty()][string]$ProcessedUpdatesFile = 'ProcessedUpdatesList.txt',
		[string]$SMTPServer,
		[ValidateNotNullOrEmpty()][string]$SourceFolder,
		[ValidateNotNullOrEmpty()][string]$UpdatesFolder
)

function Copy-Updates {
<#
	.SYNOPSIS
		Copy the Office updates to the updates folder
	
	.DESCRIPTION
		This will extract the .msp file from the .cab and then copy it to the Microsoft Office installation updates folder.
	
	.PARAMETER UnprocessedUpdates
		Updates that SCCM has downloaded but have not been copied to the updates folder.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[ValidateNotNullOrEmpty()][object]$UnprocessedUpdates
	)
	
	$RelativePath = Get-RelativePath
	$LogFile = $RelativePath + $LogFileName
	$ExclusionList = Get-ExclusionList
	foreach ($Update in $UnprocessedUpdates) {
		$ExtractedFolder = $SourceFolder + '\' + $Update.Name + '\extracted'
		If ((Test-Path $ExtractedFolder) -eq $true) {
			$Files = Get-ChildItem -Path $ExtractedFolder
			foreach ($File in $Files) {
				if ($File.Extension -eq '.msp') {
					[string]$KBUpdate = Get-MSPFileInfo -Path $File.Fullname -Property 'KBArticle Number'
					$KBUpdate = 'KB' + $KBUpdate.Trim()
					$KBUpdateShortName = $KBUpdate + '.msp'
					$KBUpdateFullName = $File.DirectoryName + '\' + $KBUpdateShortName
					$DestinationFile = $UpdatesFolder + '\' + $KBUpdateShortName
					If ($KBUpdate -notin $ExclusionList) {
						Write-Host "Renaming"$File.Name"to"$KBUpdateShortName"....." -NoNewline
						$NoOutput = Copy-Item -Path $File.Fullname -Destination $KBUpdateFullName -Force
						If ((Test-Path $KBUpdateFullName) -eq $true) {
							Write-Host "Success" -ForegroundColor Yellow
						} else {
							Write-Host "Failed" -ForegroundColor Red
						}
						Write-Host "Copying"$KBUpdateShortName" to Office updates folder....." -NoNewline
						$NoOutput = Copy-Item -Path $KBUpdateFullName -Destination $UpdatesFolder -Force
						If ((Test-Path $DestinationFile) -eq $true) {
							Write-Host "Success" -ForegroundColor Yellow
							Add-Content -Path $LogFile -Value $KBUpdate -Force
						} else {
							Write-Host "Failed" -ForegroundColor Red
						}
					} else {
						Write-Host $KBUpdate"....." -NoNewline
						Write-Host "Excluded" -ForegroundColor Green
					}
				}
			}
		}
		Start-Sleep -Seconds 1
	}
}

function Expand-CABFiles {
<#
	.SYNOPSIS
		Extract the contents of the .CAB file
	
	.DESCRIPTION
		This will extract the contents of the CAB file to a temporary subfolder for all unprocessed updates. It filters the updates to expand by the country code specified in the Country parameter. It also expands all cab with none in the name.
	
	.PARAMETER UnprocessedUpdates
		Updates that SCCM has downloaded but have not been copied to the updates folder.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[ValidateNotNullOrEmpty()][object]$UnprocessedUpdates
	)
	
	$Executable = $env:windir + "\System32\expand.exe"
	$Country = '*' + $Country + '*'
	foreach ($Update in $UnprocessedUpdates) {
		$Folder = $SourceFolder + '\' + $Update.Name
		$Files = Get-ChildItem -Path $Folder
		foreach ($File in $Files) {
			If (($File.Name -like $Country) -or ($File.Name -like "*none*")) {
				$ExtractedDirectory = $File.DirectoryName + '\extracted'
				If ((Test-Path $ExtractedDirectory) -eq $true) {
					$NoOutput = Remove-Item $ExtractedDirectory -Recurse -Force
				}
				$NoOutput = New-Item $ExtractedDirectory -ItemType Directory
				Write-Host "Extracting"$File.Name"....." -NoNewline
				$Parameters = [char]34 + $File.FullName + [char]34 + [char]32 + [char]34 + $ExtractedDirectory + [char]34 + [char]32 + "-f:*"
				$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -WindowStyle Minimized -Passthru).ExitCode
				If ($ErrCode -eq 0) {
					Write-Host "Success" -ForegroundColor Yellow
				} else {
					Write-Host "Failed" -ForegroundColor Red
				}
			}
		}
	}
}

function Get-ExclusionList {
<#
	.SYNOPSIS
		Office Updates Exclusion List
	
	.DESCRIPTION
		Contains a list of Microsoft Office updates to exclude from installation
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	$RelativePath = Get-RelativePath
	$ExclusionFile = $RelativePath + $ExclusionFileName
	If ((Test-Path $ExclusionFile) -eq $true) {
		$ExclusionList = Get-Content $ExclusionFile -Force
	} else {
		$NoOutput = New-Item -Path $ExclusionFile -Force
		$ExclusionList = Get-Content $ExclusionFile -Force
	}
	Return $ExclusionList
}

function Get-ExtractedUpdatesList {
<#
	.SYNOPSIS
		List of updates already extracted
	
	.DESCRIPTION
		This function retrieves the list of updates that have already been extracted to the updates folder.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$RelativePath = Get-RelativePath
	$ExtractedUpdatesFile = $RelativePath + $ProcessedUpdatesFile
	If ((Test-Path $ExtractedUpdatesFile) -eq $true) {
		$File = Get-Content -Path $ExtractedUpdatesFile -Force
		Return $File
	} else {
		$NoOutput = New-Item -Path $ExtractedUpdatesFile -ItemType File -Force
		Return $null
	}
}

function Get-MSPFileInfo {
<#
	.SYNOPSIS
		Extract MSP information
	
	.DESCRIPTION
		This function will extract MSP file information from the metadata table. It has been written to be able to read data from a lot of different MSP files, including Microsoft Office updates and most application patches. There are some MSP files that were not populated with the metadata table, therefor no data is obtainable.
	
	.PARAMETER Path
		Location of the MSP file
	
	.PARAMETER Property
		A pre-defined set of properties in the msi metadata table
	
	.NOTES
		Additional information about the function.
#>
	
	param
	(
			[Parameter(Mandatory = $true)][IO.FileInfo]$Path,
			[Parameter(Mandatory = $true)][ValidateSet('Classification', 'Description', 'DisplayName', 'KBArticle Number', 'ManufacturerName', 'ReleaseVersion', 'TargetProductName')][string]$Property
	)
	
	try {
		$WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer
		$MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($Path.FullName, 32))
		$Query = "SELECT Value FROM MsiPatchMetadata WHERE Property = '$($Property)'"
		$View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))
		$View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)
		$Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)
		$Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)
		return $Value
	} catch {
		Write-Output $_.Exception.Message
	}
}

function Get-NewUpdatesList {
<#
	.SYNOPSIS
		List new updates to install
	
	.DESCRIPTION
		Get the list of updates to process
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([object])]
	param ()
	
	$UnprocessedFolders = @()
	$ExtractedUpdatesList = Get-ExtractedUpdatesList
	$List = Get-ChildItem $SourceFolder
	foreach ($Update in $List) {
		If ($Update.Name -notin $ExtractedUpdatesList ) {
			$UnprocessedFolders = $UnprocessedFolders + $Update
		}
	}
	Return $UnprocessedFolders
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

function New-LogFile {
<#
	.SYNOPSIS
		Generate a log file
	
	.DESCRIPTION
		Generate a log file containing a list of the KB updates copied into the updates folder
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([boolean])]
	param ()
	
	$RelativePath = Get-RelativePath
	$LogFile = $RelativePath + $LogFileName
	If ((Test-path $LogFile) -eq $true) {
		Write-Host 'Deleting old log file.....' -NoNewline
		$NoOutput = Remove-Item $LogFile -Force
		If ((Test-path $LogFile) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Success = $false
		}
	}
	If ((Test-path $LogFile) -eq $false) {
		Write-Host "Creating new log file....." -NoNewline
		$NoOutput = New-Item $LogFile -Force
		If ((Test-path $LogFile) -eq $true) {
			Write-Host "Success" -ForegroundColor Yellow
			$Success = $true
		} else {
			Write-Host "Failed" -ForegroundColor Red
			$Success = $false
		}
	}
	Return $Success
}

function Remove-ExtractionFolders {
<#
	.SYNOPSIS
		Delete the extraction folders
	
	.DESCRIPTION
		Delete the extracted folders and contents of the unprocessed updates.
	
	.PARAMETER UnprocessedUpdates
		Updates that SCCM has downloaded but have not been copied to the updates folder.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[ValidateNotNullOrEmpty()][object]$UnprocessedUpdates
	)
	
	foreach ($Update in $UnprocessedUpdates) {
		$ExtractedFolder = $SourceFolder + '\' + $Update.Name + '\extracted'
		$Deleted = $false
		$Counter = 1
		If ((Test-Path $ExtractedFolder) -eq $true) {
			Do {
				Try {
					Write-Host "Removing"$ExtractedFolder"....." -NoNewline
					$NoOutput = Remove-Item $ExtractedFolder -Recurse -Force -ErrorAction Stop
					If ((Test-Path $ExtractedFolder) -eq $false) {
						Write-Host "Success" -ForegroundColor Yellow
						$Deleted = $true
					} else {
						Write-Host "Failed" -ForegroundColor Red
						$Deleted = $false
					}
				} Catch {
					$Counter++
					Write-Host 'Failed. Retrying in 5 seconds' -ForegroundColor Red
					Start-Sleep -Seconds 5
					If ((Test-Path $ExtractedFolder) -eq $true) {
						$Deleted = $false
						Write-Host "Removing"$ExtractedFolder"....." -NoNewline
						$NoOutput = Remove-Item $ExtractedFolder -Recurse -Force -ErrorAction SilentlyContinue
						If ((Test-Path $ExtractedFolder) -eq $false) {
							Write-Host "Success" -ForegroundColor Yellow
							$Deleted = $true
						} else {
							Write-Host "Failed" -ForegroundColor Red
							$Deleted = $false
						}
					}
					If ($Counter = 5) {
						$Deleted = $true
					}
				}
			} while ($Deleted = $false)
			Start-Sleep -Seconds 1
		}
	}
}

function Send-UpdateReport {
<#
	.SYNOPSIS
		Send a report of new updates applied
	
	.DESCRIPTION
		Send the log file with a list of Office updates that were copied over to the Office updates folder.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$RelativePath = Get-RelativePath
	$LogFile = $RelativePath + $LogFileName
	$Date = Get-Date -Format "dd-MMMM-yyyy"
	$Subject = 'Microsoft Office Updates Report as of ' + $Date
	$Body = 'List of Microsoft Office Updates added to the Office installation updates folder.'
	$Count = 1
	Do {
		Try {
			Write-Host "Emailing report....." -NoNewline
			Send-MailMessage -To $EmailRecipients -From $EmailSender -Subject $Subject -Body $Body -Attachments $LogFile -SmtpServer $SMTPServer
			Write-Host "Success" -ForegroundColor Yellow
			$Exit = $true
		} Catch {
			$Count++
			If ($Count -lt 4) {
				Write-Host 'Failed to send message. Retrying.....' -ForegroundColor Red
			} else {
				Write-Host 'Failed to send message' -ForegroundColor Red
				$Exit = $true
			}
		}
	} Until ($Exit = $true)
	
}

function Update-ProcessedUpdatesFile {
<#
	.SYNOPSIS
		Update the Processed Updates File with new updates
	
	.DESCRIPTION
		Add updates that were copied over to the processed updates file so they do not get processed again.
	
	.PARAMETER UnprocessedUpdates
		Updates that SCCM has downloaded but have not been copied to the updates folder.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[ValidateNotNullOrEmpty()]$UnprocessedUpdates
	)
	
	$RelativePath = Get-RelativePath
	$LogFile = $RelativePath + $ProcessedUpdatesFile
	foreach ($Update in $UnprocessedUpdates) {
		$Success = $false
		Do {
			Try {
				Write-Host 'Adding'$Update.Name'to Processed updates.....' -NoNewline
				Add-Content -Path $LogFile -Value $Update.Name -Force -ErrorAction Stop
				$Success = $true
				Write-Host "Success" -ForegroundColor Yellow
			} Catch {
				Write-Host "Failed" -ForegroundColor Red
				$Success = $false
			}
		} while ($Success -eq $false)
	}
}

Clear-Host
$UnprocessedFolders = Get-NewUpdatesList
If ($UnprocessedFolders -ne $null) {
	$NewLog = New-LogFile
	If ($NewLog -eq $true) {
		Expand-CABFiles -UnprocessedUpdates $UnprocessedFolders
		Copy-Updates -UnprocessedUpdates $UnprocessedFolders
		Remove-ExtractionFolders -UnprocessedUpdates $UnprocessedFolders
		Update-ProcessedUpdatesFile -UnprocessedUpdates $UnprocessedFolders
		If ($EmailLogs -eq $true) {
			Send-UpdateReport
		}
	} else {
		Write-Host "Failed to create log file."
	}
} else {
	Write-Host "No updates to process"
}
