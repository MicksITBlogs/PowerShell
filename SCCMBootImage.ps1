<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
	 Created on:   	8/21/2019 12:59 PM
	 Created by:   	Mick Pletcher
	 Filename:     	SCCMBootImage.ps1
	===========================================================================
	.DESCRIPTION
		A description of the file.
#>

param
(
	[ValidateNotNullOrEmpty()]
	[string]$File = 'C:\WinPE\SCCM.iso'
)

Import-Module Dism
$Directory = $File.substring(0, $File.LastIndexOf('\'))
#Mount and assign drive letter
$Drive = ((Mount-DiskImage -ImagePath $File) | Get-Volume).DriveLetter
#Create Mount folder to copy WIM contents to
Remove-Item -Path ($Directory + '\Mount') -Recurse -Force
New-Item -Path ($Directory + '\Mount') -ItemType Directory -Force
#Copy boot.WIM file to $Directory
Remove-Item -Path ($Directory + '\boot.wim') -ErrorAction SilentlyContinue -Force
Copy-Item -Path ($Drive + ':\sources\boot.wim') -Destination $Directory -Force
#Turn off read only
Set-ItemProperty -Path ($Directory + '\boot.wim') -Name IsReadOnly -Value $false
#Mount the WIM file
Mount-WindowsImage -ImagePath ($Directory + '\boot.wim') -Index 1 -Path ($Directory + '\Mount')
#Copy data folder to mounted image
Copy-Item -Path ($Drive + ':\SMS\data') -Destination ($Directory + '\Mount\sms') -Recurse -Force
#Unmount Windows Image
Dismount-WindowsImage -Path ($Directory + '\Mount') -Save
#Dismount disk image
Dismount-DiskImage -ImagePath $File
