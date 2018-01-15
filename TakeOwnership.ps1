<#
	.SYNOPSIS
		A brief description of the TakeOwnership.ps1 file.
	
	.DESCRIPTION
		This script will grant ownership of files to the credentials this script is being executed under.
	
	.PARAMETER FilesFolders
		Files and folders to change permissions on.

	.EXAMPLE
		powershell.exe -executionpolicy bypass -file TakeOwnership.ps1 -FilesFolders "c:\Users\Mick\AppData\Roaming\Microsoft\Windows"
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
		Created on:   	9/2/2016 9:49 AM
		Created by:   	Mick Pletcher
		Organization:
		Filename:     	TakeOwnership.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]
	$FilesFolders
)

function Grant-FolderOwnership {
<#
	.SYNOPSIS
		Take  FileFolder Ownership
	
	.DESCRIPTION
		Take ownership of the FileFolder
	
	.PARAMETER FileFolder
		File or FileFolder to take ownership of
	
	.PARAMETER Recurse
		Take ownership of all subfolders
	
	.EXAMPLE
		PS C:\> Grant-FolderOwnership -FileFolder 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]
		$FileFolder,
		[switch]
		$Recurse
	)
	
	$Errors = $false
	If ((Test-Path $FileFolder) -eq $true) {
		$Output = "Taking ownership of " + $FileFolder + "....."
		If ($Recurse.IsPresent) {
			#Take ownership of the top folder
			$Items = takeown.exe /F $FileFolder
			#Take ownership of all child folders and files
			$Items = Get-ChildItem $FileFolder -Recurse | ForEach-Object { takeown.exe /F $_.FullName }
		} else {
			#Take ownership of the individual folder
			$Executable = takeown.exe /F $FileFolder
		}
	}
	#Get the current user this script is being executed under
	[string]$CurrentUser = [Environment]::UserDomainName + "\" + [Environment]::UserName
	If ($Recurse.IsPresent) {
		#Test if files are owned by the current user this script is being executed under
		$Item = Get-Item $FileFolder | where-object { (get-acl $_.FullName).owner -ne $CurrentUser }
		$Items = Get-ChildItem $FileFolder -Recurse | where-object { (get-acl $_.FullName).owner -ne $CurrentUser }
		#If no files/folders were added to $Items, then it is a success
		If ((($Item -ne "") -and ($Item -ne $null)) -and (($Items -ne "") -and ($Items -ne $null))) {
			$Output += "Failed"
		} else {
			$Output += "Success"
		}
	} else {
		[string]$FolderOwner = (get-acl $FileFolder).owner
		If ($CurrentUser -ne $FolderOwner) {
			$Output += "Failed"
			$Errors = $true
		} else {
			$Output += "Success"
		}
	}
	Write-ToDisplay -Output $Output
	If ($Errors -eq $true) {
		#Error 5 is an arbitrary number I chose to flag if this fails
		Exit 5
	}
}

function Write-ToDisplay {
<#
	.SYNOPSIS
		Output Success/Failure to Display
	
	.DESCRIPTION
		Write the output to the Display color coded yellow for success and red for failure
	
	.PARAMETER Output
		Data to display to the screen
	
	.EXAMPLE
				PS C:\> Write-ToDisplay -Output 'Value1'
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]$Output
	)
	
	$OutputSplit = (($Output.Replace(".", " ")).Replace("     ", ".")).Split(".")
	Write-Host $OutputSplit[0]"....." -NoNewline
	If ($OutputSplit[1] -like "*Success*") {
		Write-Host $OutputSplit[1] -ForegroundColor Yellow
	} elseif ($OutputSplit[1] -like "*Fail*") {
		Write-Host $OutputSplit[1] -ForegroundColor Red
	}
}

Grant-FolderOwnership -FileFolder $FilesFolders
