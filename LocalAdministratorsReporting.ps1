<#
	.SYNOPSIS
		Execute SCCM Stored Queries
	
	.DESCRIPTION
		This script will execute SCCM stored queries.
	
	.PARAMETER ListQueries
		Generate a list of queries
	
	.PARAMETER Query
		Name of the query to execute
	
	.PARAMETER SCCMServer
		Name of SCCM server
	
	.PARAMETER SCCMServerDrive
		A description of the SCCMServerDrive parameter.
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.139
		Created on:   	5/8/2017 1:32 PM
		Created by:   	Mick Pletcher
		Filename:		SCCMQuery.ps1
		===========================================================================
#>
param
(
	[switch]$ListQueries,
	[string]$Query,
	[string]$SCCMServer,
	[string]$SCCMServerDrive
)

function Get-ListOfQueries {
<#
	.SYNOPSIS
		Get List of Queries
	
	.DESCRIPTION
		This function will retrieve a list of all queries in SCCM
	
	.EXAMPLE
				PS C:\> Get-ListOfQueries
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	Set-Location $SCCMServerDrive
	$Queries = Get-CMQuery
	Set-Location $env:SystemDrive
	$QueryArray = @()
	foreach ($Query in $Queries) {
		$QueryArray += $Query.Name
	}
	$QueryArray = $QueryArray | Sort-Object
	$QueryArray
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

function Get-SCCMQueryData {
	[CmdletBinding()]
	param ()
	
	$Report = @()
	#Change directory to the SCCM server drive
	Set-Location $SCCMServerDrive
	#Retrieve report from SCCM
	$Output = Get-CMQuery -Name $Query | Invoke-CMQuery
	#Change directory back to the system this script is running on
	Set-Location $env:SystemDrive
	#Parse through data and create report object
	foreach ($Item in $Output) {
		$Item1 = [string]$Item
		$Domain = (($Item1.split(';'))[0]).Split('"')[1]
		$User = ((($Item1.split(";"))[1]).Split('"'))[1]
		$ComputerName = ((($Item1.split(";"))[3]).Split('"'))[1]
		$Object = New-Object -TypeName System.Management.Automation.PSObject
		$Object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $ComputerName.ToUpper()
		$Object | Add-Member -MemberType NoteProperty -Name Domain -Value $Domain.ToUpper()
		$Object | Add-Member -MemberType NoteProperty -Name UserName -Value $User.ToUpper()
		$Report += $Object
	}
	$Report = $Report | Sort-Object -Property UserName
	Return $Report
}

function Import-SCCMModule {
<#
	.SYNOPSIS
		Import SCCM Module
	
	.DESCRIPTION
		Locate the ConfigurationManager.psd1 file and import it.
	
	.PARAMETER SCCMServer
		Name of the SCCM server to connect to.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$SCCMServer
	)
	
	#Get the architecture of the specified SCCM server
	$Architecture = (get-wmiobject win32_operatingsystem -computername $SCCMServer).OSArchitecture
	#Get list of installed applications
	$Uninstall = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	If ($Architecture -eq "64-bit") {
		$Uninstall += Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path REGISTRY::"HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -Force -ErrorAction SilentlyContinue }
	}
	#Get the registry key that specifies the location of the SCCM installation drive and directory
	$RegKey = ($Uninstall | Where-Object { $_ -like "*SMS Primary Site*" }) -replace 'HKEY_LOCAL_MACHINE', 'HKLM:'
	$Reg = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ItemProperty -Path $args[0] } -ArgumentList $RegKey
	#Parse the directory listing
	$Directory = (($Reg.UninstallString).Split("\", 4) | Select-Object -Index 0, 1, 2) -join "\"
	#Locate the location of the SCCM module
	$Module = Invoke-Command -ComputerName $SCCMServer -ScriptBlock { Get-ChildItem -Path $args[0] -Filter "ConfigurationManager.psd1" -Recurse } -ArgumentList $Directory
	#If more than one module is present, use the latest one
	If ($Module.Length -gt 1) {
		foreach ($Item in $Module) {
			If (($NewModule -eq $null) -or ($Item.CreationTime -gt $NewModule.CreationTime)) {
				$NewModule = $Item
			}
		}
		$Module = $NewModule
	}
	#format the $Module unc path
	[string]$Module = "\\" + $SCCMServer + "\" + ($Module.Fullname -replace ":", "$")
	#Import the SCCM module
	Import-Module -Name $Module
}

function Send-Report {
<#
	.SYNOPSIS
		Email report
	
	.DESCRIPTION
		A detailed description of the Send-Report function.
	
	.EXAMPLE
				PS C:\> Send-Report
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	#TODO: Place script here
}

Clear-Host
#Add colon to end of SCCMServerDrive if not present
If ($SCCMServerDrive[$SCCMServerDrive.Length - 1] -ne ":") {
	$SCCMServerDrive += ":"
}
#Import SCCM module
Import-SCCMModule -SCCMServer $SCCMServer
#Generate a list of all available queries in SCCM
If ($ListQueries.IsPresent) {
	Get-ListOfQueries
}
#If query is not filled in, then end the script
If (($Query -ne $null) -and ($Query -ne "")) {
	#Perform query from SCCM
	$Report = Get-SCCMQueryData | Sort-Object -Property ComputerName
	#Display report to screen
	$Report
	#Get path where this script is executing from
	$RelativePath = Get-RelativePath
	#Location where to write the report to
	$File = $RelativePath + "LocalAdministrators.csv"
	#Delete old report if it exists
	If ((Test-Path $File) -eq $true) {
		Remove-Item -Path $File -Force
	}
	#Write new report to CSV file
	$Report | Export-Csv -Path $File -Encoding UTF8 -Force
}
