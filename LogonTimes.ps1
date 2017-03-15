<#
	.SYNOPSIS
		User Logon Report
	
	.DESCRIPTION
		This script will query the event viewer logs of a specified system for a list of logon times for a specific user. There are four fields in the report: Keyboard logons, Screen Unlock, Remote Session logons, and Cached Logon. It has the option to either generate a report in a CSV file with all of the above field data, or it can generate a TXT file containing the raw message data with each data field split off by two dash rows.
		
		NOTE: This does not require WinRM to be enabled to run on external systems. Also, this can take quite a while to execute if the logs are really big.
	
	.PARAMETER ComputerName
		Name of system to retrieve the logs from. If this is left blank, the script will use "." representing the computer this script is executing on.
	
	.PARAMETER Rawdata
		Generate a report using the raw data from the event viewer logs of the specified user
	
	.PARAMETER Username
		Username to generate this report of.
	
	.EXAMPLE
		Generate a CSV file report containing the times and sorted by each logon type
		powershell.exe -file LogonTimes.ps1 -Username MickPletcher -ComputerName PC01
		
		Generate a TXT file that contains all of the raw message data fields for the specified system
		powershell.exe -file LogonTimes.ps1 -Username MickPletcher -ComputerName PC01 -Rawdata
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.136
		Created on:   	3/15/2017 12:00 PM
		Created by:   	Mick Pletcher
		Filename:		LogonTimes.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[String]$ComputerName,
	[switch]$Rawdata,
	[ValidateNotNullOrEmpty()][string]$Username
)

function Get-FilteredData {
<#
	.SYNOPSIS
		Filter By LogonType Type
	
	.DESCRIPTION
		This will filter the data for the specified LogonType type
	
	.PARAMETER LogonType
		Specified LogonType type
	
	.PARAMETER Message
		Message to display on the screen
	
	.PARAMETER Logons
		Array containing all logons
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$LogonType,
		[ValidateNotNullOrEmpty()][string]$Message,
		[ValidateNotNullOrEmpty()]$Logons
	)
	
	$Errors = $false
	Write-Host $Message"....." -NoNewline
	Try {
		$Data = $Logons | Where-Object { $_.Message -like "*Logon Type:" + [char]9 + [char]9 + $LogonType + "*" }
	} catch {
		$Errors = $true
	}
	If ($Errors -eq $false) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
	Return $Data
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

function New-Report {
<#
	.SYNOPSIS
		Generate CSV Report File
	
	.DESCRIPTION
		This function will generate a CSV report.
	
	.PARAMETER Keyboard
		A description of the Keyboard parameter.
	
	.PARAMETER Unlock
		A description of the Unlock parameter.
	
	.PARAMETER Remote
		A description of the Remote parameter.
	
	.PARAMETER Cached
		A description of the Cached parameter.
	
	.EXAMPLE
				PS C:\> New-Report
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		$Keyboard,
		$Unlock,
		$Remote,
		$Cached
	)
	
	$RelativePath = Get-RelativePath
	#Name of report file
	$FileName = $RelativePath + "$Username.csv"
	#Delete report file if it exists
	If ((Test-Path $FileName) -eq $true) {
		Write-Host "Deleting $Username.csv....." -NoNewline
		Remove-Item -Path $FileName -Force
		If ((Test-Path $FileName) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	Write-Host "Generating $Username.csv report file....." -NoNewline
	#Create new file
	"Logon Type,Date/Time" | Out-File -FilePath $FileName -Encoding UTF8 -Force
	$Errors = $false
	#Report all keyboard logons
	foreach ($Logon in $Keyboard) {
		$Item = "Keyboard," + [string]$Logon.TimeCreated
		try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	#Report all screen unlocks
	foreach ($Logon in $Unlock) {
		$Item = "Unlock," + [string]$Logon.TimeCreated
		Try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	#Report all remote logons
	foreach ($Logon in $Remote) {
		$Item = "Remote," + [string]$Logon.TimeCreated
		Try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	#Report all cached logons
	foreach ($Logon in $Cached) {
		$Item = "Cached," + [string]$Logon.TimeCreated
		Try {
			$Item | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		} catch {
			$Errors = $true
		}
	}
	If ($Errors -eq $false) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
}

Clear-Host
If (($ComputerName -eq "") -or ($ComputerName -eq $null)) {
	$ComputerName = "."
}
#Get associated GUID of User Profile
$GUID = (get-childitem -path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.Name -like "*S-1-5-21*" } | ForEach-Object { Get-ItemProperty REGISTRY::$_ } | Where-Object { $_.ProfileImagePath -like "*$Username*" }).PSChildName
#Retrieve all logon logs
If ($ComputerName -ne ".") {
	Write-Host "Retrieving all logon logs for $Username on $ComputerName....." -NoNewline
} else {
	Write-Host "Retrieving all logon logs for $Username on $env:COMPUTERNAME....." -NoNewline
}
$Errors = $false
Try {
	$AllLogons = Get-WinEvent -FilterHashtable @{ logname = 'security'; ID = 4624 } -ComputerName localhost | where-object { ($_.properties.value -like "*$GUID*") }
} catch {
	$Errors = $true
}
If ($Errors -eq $false) {
	Write-Host "Success" -ForegroundColor Yellow
} else {
	Write-Host "Failed" -ForegroundColor Red
}



#Logon at keyboard and screen of system
$KeyboardLogons = Get-FilteredData -Logons $AllLogons -LogonType "2" -Message "Filtering keyboard logons"
#Unlock workstation with password protected screen saver
$Unlock = Get-FilteredData -Logons $AllLogons -LogonType "7" -Message "Filtering system unlocks"
#Terminal Services, Remote Desktop or Remote Assistance
$Remote = Get-FilteredData -Logons $AllLogons -LogonType "10" -Message "Filtering remote accesses"
#logon with cached domain credentials such as when logging on to a laptop when away from the network
$CachedCredentials = Get-FilteredData -Logons $AllLogons -LogonType "11" -Message "Filtering cached logins"
#Generate a rawdata report
If ($Rawdata.IsPresent) {
	$RelativePath = Get-RelativePath
	#Name of report file
	$FileName = $RelativePath + "$Username.txt"
	#Delete report file if it exists
	If ((Test-Path $FileName) -eq $true) {
		Write-Host "Deleting $Username.txt....." -NoNewline
		Remove-Item -Path $FileName -Force
		If ((Test-Path $FileName) -eq $false) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	}
	Write-Host "Generating raw data file....." -NoNewline
	foreach ($Logon in $AllLogons) {
		[string]$Logon.TimeCreated | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		$Logon.Message | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		" " | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		"----------------------------------------------------------------------------------------------------------------------------------------------------------------" | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		"----------------------------------------------------------------------------------------------------------------------------------------------------------------" | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
		" " | Out-File -FilePath $FileName -Encoding UTF8 -Append -Force
	}
	If ((Test-Path $FileName) -eq $true) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed" -ForegroundColor Red
	}
} else {
	New-Report -Keyboard $KeyboardLogons -Unlock $Unlock -Remote $Remote -Cached $CachedCredentials
}#>