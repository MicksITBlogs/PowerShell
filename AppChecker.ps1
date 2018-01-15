<#
	.SYNOPSIS
		Check Application Install
	
	.DESCRIPTION
		This script will check if a specified application appears in the programs and features.
	
	.PARAMETER Application
		Name of application in the programs and features. It can be a partial name or the complete name.
	
	.PARAMETER LogFileName
		Name of the LogFileName containing the list of applications installed on the machine
	
	.PARAMETER LogFileLocation
		Location where to write the log file
	
	.PARAMETER ExactFileName
		Specifies to search for the exact filename, otherwise the script will search for filename that contain the designated search criteria.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.138
		Created on:   	4/4/2017 4:51 PM
		Created by:   	Mick Pletcher 
		Filename:     	AppChecker.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()][string]$Application,
	[ValidateNotNullOrEmpty()][string]$LogFileName,
	[string]$LogFileLocation,
	[switch]$ExactFileName
)

function New-LogFile {
<#
	.SYNOPSIS
		Create new build log
	
	.DESCRIPTION
		This function will compare the date/time of the first event viewer log with the date/time of the log file to determine if it needs to be deleted and a new one created.
	
	.PARAMETER LogFile
		Full name of log file including the unc address
	
	.EXAMPLE
		PS C:\> New-LogFile
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$Log
	)
	
	#Get the creation date/time of the first event viewer log
	$LogFile = Get-ChildItem -Path $LogFileLocation -Filter $LogFileName -ErrorAction SilentlyContinue
	Write-Output "Log File Name: $LogFile"
	$Output = "LogFile Creation Date: " + $LogFile.CreationTime
	Write-Output $Output
	If ($LogFile -ne $null) {
		$OSInstallDate = Get-WmiObject Win32_OperatingSystem | ForEach-Object{ $_.ConvertToDateTime($_.InstallDate) -f "MM/dd/yyyy" }
		Write-Output "        OS Build Date: $OSInstallDate"
		If ($LogFile.CreationTime -lt $OSInstallDate) {
			#Delete old log file
			Remove-Item -Path $LogFile.FullName -Force | Out-Null
			#Create new log file
			New-Item -Path $Log -ItemType File -Force | Out-Null
			#Add header row
			Add-Content -Path $Log -Value "Application,Version,TimeStamp,Installation"
		}
	} else {
		#Create new log file
		New-Item -Path $Log -ItemType File -Force | Out-Null
		#Add header row
		Add-Content -Path $Log -Value "Application,Version,TimeStamp,Installation"
	}
}

Clear-Host
#If the LogFileName is not predefined in the Parameter, then it is named after the computer name
If (($LogFileName -eq $null) -or ($LogFileName -eq "")) {
	If ($LogFileName -notlike "*.csv*") {
		$LogFileName += ".csv"
	} else {
		$LogFileName = "$env:COMPUTERNAME.csv"
	}
} elseIf ($LogFileName -notlike "*.csv*") {
		$LogFileName += ".csv"
}
#Add backslash to end of UNC path
If ($LogFileLocation[$LogFileLocation.Length - 1] -ne "\") {
	$File = $LogFileLocation + "\" + $LogFileName
} else {
	$File = $LogFileLocation + $LogFileName
}
#Create a new log file
New-LogFile -Log $File
#Get list of installed applications from programs and features
$Uninstall = Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue
$Uninstall += Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue
#Check if the list of Applications contains the search query
If ($ExactFileName.IsPresent) {
	$ApplicationInstall = $Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -eq $Application }
} else {
	$ApplicationInstall = $Uninstall | ForEach-Object { Get-ItemProperty $_.PsPath } | Where-Object { $_.DisplayName -like "*" + $Application + "*" }
}
#If more than one registry entry, select larger entry that contains more information
If ($ApplicationInstall.length -gt 1) {
	$Size = 0
	for ($i = 0; $i -lt $ApplicationInstall.length; $i++) {
		If (([string]$ApplicationInstall[$i]).length -gt $Size) {
			$Size = ([string]$ApplicationInstall[$i]).length
			$Temp = $ApplicationInstall[$i]
		}
	}
	$ApplicationInstall = $Temp
}
#Exit with error code 0 if the app is installed, otherwise exit with error code 1
If ($ApplicationInstall -ne $null) {
	$InstallDate = (($ApplicationInstall.InstallDate + "/" + $ApplicationInstall.InstallDate.substring(0, 4)).Substring(4)).Insert(2, "/")
	$Output = $ApplicationInstall.DisplayName + "," + $ApplicationInstall.Version + "," + $InstallDate + "," + "Success"
	Add-Content -Path $File -Value $Output
	Write-Host "Exit Code: 0"
	Exit 0
} else {
	$Output = $Application + "," + "," + "," + "Failed"
	Add-Content -Path $File -Value $Output
	Write-Host "Exit Code: 1"
	Exit 1
}
