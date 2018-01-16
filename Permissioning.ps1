<#
.Author
   Mick Pletcher
.SYNOPSIS
   Copy Permissions
.DESCRIPTION
   This script will replication permissions for both files and folders using
   robocopy. Change the $SourceDrive and $DestinationDrive variables to match what
   you need to replicate.
#>

cls
$Errors = 0


$SourceDrive = Read-Host 'Enter source folder'
$DestinationDrive = Read-Host 'Enter destination folder'

#Match capitalization with directories
$TempDrive = Get-Item -Path $SourceDrive
$SourceDrive = $TempDrive.FullName
$TempDrive = Get-Item -Path $DestinationDrive
$DestinationDrive = $TempDrive.FullName

$SourceFolders = Get-ChildItem $SourceDrive -Recurse | ?{ $_.PSIsContainer }
$SourceFiles = Get-ChildItem $SourceDrive -Recurse -Force | where { ! $_.PSIsContainer }
$DestinationFolders = Get-ChildItem $DestinationDrive -Recurse | ?{ $_.PSIsContainer }
$DestinationFiles = Get-ChildItem $DestinationDrive -Recurse -Force | where { ! $_.PSIsContainer }

#Copy permissions for folders
$Output = robocopy $SourceDrive $DestinationDrive /ZB /E /LEV:0 /COPY:SOU /XF *.* /R:5 /W:5

#Verify Folder Permissions Match
Write-Host "Folders:"
Write-Host "========"
For ($Count=0; $Count -le $SourceFolders.Count; $Count++) {
	If ($SourceFolders[$Count].FullName -ne $null) {
		$SourceFolder = $SourceFolders[$Count].FullName
		$DestinationFolder = $DestinationFolders[$Count].FullName
		Write-Host $SourceFolder"....." -NoNewline
		$SourceFolderACL = Get-Acl -Path $SourceFolder
		$DestinationFolderACL = Get-Acl -Path $DestinationFolder
		For ($Count1=0; $Count1 -le $SourceFolderACL.Access.Count; $Count1++) {
			If ($SourceFolderACL.Access[$Count1].FileSystemRights -ne $DestinationFolderACL.Access[$Count1].FileSystemRights) {
				$Errors++
			}
		}
		If ($Errors -eq 0) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	$Errors = 0
}

$Output = robocopy $SourceDrive $DestinationDrive /ZB /E /LEV:0 /COPY:SOU /XD *.* /R:5 /W:5
#Copy permissions for files
Write-Host "Files:"
Write-Host "======"
For ($Count=0; $Count -le $SourceFiles.Count; $Count++) {
	If ($SourceFiles[$Count].FullName -ne $null) {
		$SourceFile = $SourceFiles[$Count].FullName
		$DestinationFile = $DestinationFiles[$Count].FullName
		Write-Host $SourceFile"....." -NoNewline
		$SourceFileACL = Get-Acl -Path $SourceFile
		$DestinationFileACL = Get-Acl -Path $DestinationFile
		For ($Count1=0; $Count1 -le $SourceFileACL.Access.Count; $Count1++) {
			If ($SourceFileACL.Access[$Count1].FileSystemRights -ne $DestinationFileACL.Access[$Count1].FileSystemRights) {
				$Errors++
			}
		}
		If ($Errors -eq 0) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	$Errors = 0
}
