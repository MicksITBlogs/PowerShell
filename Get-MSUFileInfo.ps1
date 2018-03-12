<#
	.SYNOPSIS
		Get MSU Package Information
	
	.DESCRIPTION
		This script contains the function which can retrieve all available information on an MSU file. 
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.145
		Created on:   	3/12/2018 6:41 AM
		Created by:   	Mick Pletcher
		Filename:		Get-MSUFileInfo.ps1
		===========================================================================
#>

function Get-MSUFileInfo {
<#
	.SYNOPSIS
		Extract MSP information
	
	.DESCRIPTION
		This function will extract MSP file information from the metadata table. It has been written to be able to read data from a lot of different MSP files, including Microsoft Office updates and most application patches. There are some MSP files that were not populated with the metadata table, therefor no data is obtainable.
	
	.PARAMETER FileName
		A description of the FileName parameter.
	
#>
	
	[CmdletBinding()]
	param
	(
		[System.IO.FileInfo]$FileName
	)
	
	#Get the path of this script
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	#full path of expand.exe
	$Executable = Join-Path -Path $env:windir -ChildPath "System32\expand.exe"
	#Directory to place expanded file(s)
	$Directory = Join-Path -Path $RelativePath -ChildPath Expanded -ErrorAction SilentlyContinue
	#Delete the Expanded directory and all contents if it exists
	Remove-Item -Path $Directory -Recurse -Force -ErrorAction SilentlyContinue
	#Create the Expanded directory
	New-Item -Path $Directory -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
	#Parameters for the expand.exe
	$Parameters = '-F:*properties.txt' + [char]32 + [char]34 + $FileName.FullName + [char]34 + [char]32 + [char]34 + $Directory + [char]34
	#Expand the msu file
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -WindowStyle Hidden -Wait -Passthru).ExitCode
	#Define the file that contains information on the MSU
	$ExpandedFile = Get-ChildItem -Path $Directory -Filter *properties.txt
	#Create the object
	$MSUObject = New-Object System.Object
	$MSUObject | Add-Member -MemberType NoteProperty -Name AppliesTo -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Applies to*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name BuildDate -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Build Date*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name Company -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Company*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name FileVersion -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*File Version*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name InstallationType -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Installation Type*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name InstallerEngine -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Installer Engine*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name InstallerVersion -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Installer Version*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name KBArticle -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*KB Article Number*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name Language -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Language*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name PackageType -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Package Type*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name ProcessorArchitecture -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Processor Architecture*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name ProductName -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Product Name*' }).split("=")[1].replace('"', '')
	$MSUObject | Add-Member -MemberType NoteProperty -Name SupportLink -Value (Get-Content -Path $ExpandedFile.FullName | Where-Object { $_ -like '*Support Link*' }).split("=")[1].replace('"', '')
	#Delete the Expanded directory and all contents if it exists
	Remove-Item -Path $Directory -Recurse -Force -ErrorAction SilentlyContinue
	Return $MSUObject
}

$MSUInfo = Get-MSUFileInfo -FileName "\\RSAT\Windows7\Windows6.1-KB958830-x64-RefreshPkg.msu"
$MSUInfo