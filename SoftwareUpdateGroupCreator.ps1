<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.98
	 Created on:   	12/28/2015 9:08 AM
	 Created by:   	Mick Pletcher
	 Filename:     	WindowsUpdatesList.ps1
	===========================================================================
	.DESCRIPTION
		This script will create a new software update group each month. It then
		generates an email to send to the admin(s) to review what updates
		were put into the new update group. It does not download the updates so
		that if an update needs to be removed, it can be done before it is 
		downloaded. 
		
#>

Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

function Get-Updates  {
	param ([String]$Architecture, [String]$OperatingSystem, [String]$Namespace, $Updates )
	
	$Updates = @()
	$Updates = Get-WmiObject -Class SMS_SoftwareUpdate -Namespace $Namespace
	$Updates = $Updates | where-object { ($_.LocalizedDisplayName -match $OperatingSystem) }
	If ($Architecture -eq "x86") {
		$Updates = $Updates | where-object { ($_.LocalizedDisplayName -notmatch "x64") }
	} elseif ($Architecture -eq "x64") {
		#$Updates = Get-WmiObject -Class SMS_SoftwareUpdate -Namespace $Namespace | where-object { ($_.LocalizedDisplayName -match $OperatingSystem) -and ($_.LocalizedDisplayName -match "x64-based Systems") }
		$Updates = Get-WmiObject -Class SMS_SoftwareUpdate -Namespace $Namespace | where-object { ($_.LocalizedDisplayName -match $OperatingSystem) -and ($_.LocalizedDisplayName -match "x64") }
	}
	Return $Updates
}

function Set-Filters {
	param($Filters, $Updates, $UpdateTypes)
	
	#Declare Variables
	Set-Variable -Name Filter -Scope Local -Force
	Set-Variable -Name UpdateType -Scope Local -Force
	
	foreach ($Filter in $Filters) {
		$Updates = $Updates | Where-Object { $_.LocalizedDisplayName -notmatch $Filter }
	}
	If ($UpdateTypes.Count -ge 1) {
		foreach ($UpdateType in $UpdateTypes) {
			$Updates = $Updates | Where-Object { $_.LocalizedCategoryInstanceNames -match $UpdateType }
		}
		If ($UpdateTypes -eq "Update") {
			$Updates = $Updates | Where-Object { $_.LocalizedDisplayName -notmatch "Security Update" }
		}
	}
	return $Updates
	
	#Cleanup Variables
	Remove-Variable -Name Filter -Scope Local -Force
	Remove-Variable -Name UpdateType -Scope Local -Force
}

function Set-TimeSpanByMonthsOld {
	param ($MonthsOld, $Updates)
	
	#Declare Local Variables
	Set-Variable -Name Day -Scope Local -Force
	Set-Variable -Name Month -Scope Local -Force
	Set-Variable -Name FirstDayOfMonth -Scope Local -Force
	Set-Variable -Name LastDayOfMonth -Scope Local -Force
	Set-Variable -Name Today -Scope Local -Force
	
	If ($MonthsOld -ge 1) {
		$MonthsOld = $MonthsOld * -1
	}
	$Today = Get-Date
	$Month = $Today.AddMonths($MonthsOld)
	$Day = $Month.Day
	$FirstDayOfMonth = $Month.AddDays(($Day - 1) * -1)
	$LastDayOfMonth = [System.DateTime]::DaysInMonth($Month.Year, $Month.Month)
	$LastDayOfMonth = $LastDayOfMonth - 1
	$LastDayOfMonth = $FirstDayOfMonth.AddDays($LastDayOfMonth)
	$FirstDayOfMonth = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($FirstDayOfMonth)
	$LastDayOfMonth = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($LastDayOfMonth)
	$Updates = $Updates | Where { ($_.DateCreated -ge $FirstDayOfMonth) -and ($_.DateCreated -le $LastDayOfMonth) }
	return $Updates
	
	#Cleanup Local Variables
	Remove-Variable -Name Day -Scope Local -Force
	Remove-Variable -Name Month -Scope Local -Force
	Remove-Variable -Name FirstDayOfMonth -Scope Local -Force
	Remove-Variable -Name LastDayOfMonth -Scope Local -Force
}

function Set-TimeSpanByDatePeriod {
	param ([String]$StartDate,
		[String]$EndDate,
		$Updates)
	
	$StartDate = [DateTime]$StartDate
	$StartDate = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($StartDate)
	$EndDate = [DateTime]$EndDate
	$EndDate = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($EndDate)
	$Updates = $Updates | Where { ($_.DateCreated -ge $StartDate) -and ($_.DateCreated -le $EndDate) }
	return $Updates
}

function Set-TimeSpanAllUpdatesBeforeDate {
	param ([String]$StartDate, $Updates)
	
	$StartDate = [DateTime]$StartDate
	$StartDate = [System.Management.ManagementDateTimeConverter]::ToDmtfDateTime($StartDate)
	$Updates = $Updates | Where { $_.DateCreated -lt $StartDate }
	return $Updates
}

function CreateSoftwareUpdateGroup {
	param ($OperatingSystem, $Architecture, $Updates)
	
	#Declare Variables
	Set-Variable -Name Description -Scope Local -Force
	Set-Variable -Name Month -Scope Local -Force
	Set-Variable -Name SoftwareUpdateGroupName -Scope Local -Force
	Set-Variable -Name SoftwareUpdates -Scope Local -Force
	Set-Variable -Name Temp -Scope Local -Force
	Set-Variable -Name Update -Scope Local -Force
	Set-Variable -Name Year -Scope Local -Force
	
	$SoftwareUpdates = @()
	$Year = (Get-Date).Year
	$Month = Get-Date -format "MMMM"
	$SoftwareUpdateGroupName = $OperatingSystem + $Architecture + [char]32 + $Month + [char]45 + $Year
	$Description = $SoftwareUpdateGroupName + [char]32 + "Updates"
	foreach ($Update in $Updates) {
		$SoftwareUpdates += ($Update.CI_ID)
	}
	cd BNA:
	$TEMP = New-CMSoftwareUpdateGroup -Name $SoftwareUpdateGroupName -UpdateID $SoftwareUpdates -Description $Description
	cd c:
	$SoftwareUpdates = $null
	
	#Cleanup Variables
	Remove-Variable -Name Description -Scope Local -Force
	Remove-Variable -Name Month -Scope Local -Force
	Remove-Variable -Name SoftwareUpdateGroupName -Scope Local -Force
	Remove-Variable -Name SoftwareUpdates -Scope Local -Force
	Remove-Variable -Name Temp -Scope Local -Force
	Remove-Variable -Name Update -Scope Local -Force
	Remove-Variable -Name Year -Scope Local -Force
}

function ProcessLogFile {
	param([String]$OperatingSystem, [String]$Architecture)
	
	#Declare Local Variables
	Set-Variable -Name LogFile -Scope Local -Force
	Set-Variable -Name Month -Scope Local -Force
	Set-Variable -Name Output -Scope Local -Force
	Set-Variable -Name temp -Scope Local -Force
	
	$Month = Get-Date -format "MMMM"
	$OperatingSystem = $OperatingSystem -replace '\s',''
	$LogFile = $env:TEMP + "\" + $OperatingSystem + $Architecture + $Month + "UpdatesReport.csv"
	if ((Test-Path $LogFile) -eq $true) {
		Remove-Item $LogFile -Force
	}
	if ((Test-Path $LogFile) -eq $false) {
		$temp = New-Item $LogFile -ItemType file -Force
		$Output = "Update Name, Article ID, Update Type, Release Date"
		Out-File -FilePath $LogFile -InputObject $Output -Force -Encoding UTF8
	}
	Return $LogFile
	
	#Cleanup Local Variables
	Remove-Variable -Name LogFile -Scope Local -Force
	Remove-Variable -Name Month -Scope Local -Force
	Remove-Variable -Name Output -Scope Local -Force
	Remove-Variable -Name temp -Scope Local -Force
}

function New-Report  {
	param($EmailAddressList, $Updates, $OperatingSystem, $Architecture)
	
	#Declare Variables
	Set-Variable -Name ArticleID -Scope Local -Force
	Set-Variable -Name Body -Scope Local -Force
	Set-Variable -Name DateCreated -Scope Local -Force
	Set-Variable -Name EmailAddress -Scope Local -Force
	Set-Variable -Name Month -Scope Local -Force
	Set-Variable -Name Output -Scope Local -Force
	Set-Variable -Name Subject -Scope Local -Force
	Set-Variable -Name Update -Scope Local -Force
	
	foreach ($Update in $Updates) {
		$Update.LocalizedDisplayName = $Update.LocalizedDisplayName -replace ",", ""
		$ArticleID = "KB" + $Update.ArticleID
		[String]$DateCreated = [System.Management.ManagementDateTimeConverter]::ToDateTime($Update.DateCreated)
		If ($Update.LocalizedCategoryInstanceNames -match "Security Updates") {
			$Output = $Update.LocalizedDisplayName + "," + $ArticleID + ",Security Update," + $DateCreated
		} elseif (($Update.LocalizedCategoryInstanceNames -notmatch "Security Updates") -and ($Update.LocalizedCategoryInstanceNames -match "Update")) {
			$Output = $Update.LocalizedDisplayName + "," + $ArticleID + ",Update," + $DateCreated
		} else {
			$Output = $Update.LocalizedDisplayName + "," + $ArticleID + ", ," + $DateCreated
		}
		Out-File -FilePath $LogFile -InputObject $Output -Append -Force -Encoding UTF8
	}
	$Month = Get-Date -format "MMMM"
	$Subject = $OperatingSystem + $Architecture + [char]32 + $Month + [char]32 + "SCCM Windows Update List"
	$Body = "List of Windows updates added to the" + $OperatingSystem + $Architecture + [char]32 + $Month + " software update group."
	foreach ($EmailAddress in $EmailAddressList) {
		Send-MailMessage -To $EmailAddress -From "engineers@wallerlaw.com" -Subject $Subject -Body $Body -Attachments $LogFile -SmtpServer "smtp.wallerlaw.com"
	}
	$EmailAddresses = $null
	
	#Cleanup Variables
	Remove-Variable -Name ArticleID -Scope Local -Force
	Remove-Variable -Name Body -Scope Local -Force
	Remove-Variable -Name DateCreated -Scope Local -Force
	Remove-Variable -Name EmailAddress -Scope Local -Force
	Remove-Variable -Name Month -Scope Local -Force
	Remove-Variable -Name Output -Scope Local -Force
	Remove-Variable -Name Subject -Scope Local -Force
	Remove-Variable -Name Update -Scope Local -Force
}

#Declare Variables
Set-Variable -Name Architecture -Scope Local -Force
Set-Variable -Name EmailAddresses -Scope Local -Force
Set-Variable -Name Filters -Scope Local -Force
Set-Variable -Name LogFile -Scope Local -Force
Set-Variable -Name Namespace -Value root\sms\site_bna -Scope Local -Force
Set-Variable -Name OperatingSystem -Scope Local -Force
Set-Variable -Name Updates -Scope Local -Force
Set-Variable -Name UpdateTypes -Scope Local -Force

cls
$EmailAddresses = @("mick.pletcher@test.com")
$OperatingSystem = "Windows 7" #Windows 7, Windows 8.1, Windows Server 2012 R2
$Architecture = "x86" #x86, x64, or null
$UpdateTypes = @() #Security Update, Update, Service Pack
$Filters = @("Internet Explorer 8", "Internet Explorer 9", "Internet Explorer 10")
$Updates = @()

$LogFile = ProcessLogFile -OperatingSystem $OperatingSystem -Architecture $Architecture
$Updates = Get-Updates -Architecture $Architecture -Namespace $Namespace -OperatingSystem $OperatingSystem -Updates $Updates
$Updates = Set-Filters -Filters $Filters -Updates $Updates -UpdateTypes $UpdateTypes
$Updates = Set-TimeSpanByMonthsOld -MonthsOld 1 -Updates $Updates
#$Updates = Set-TimeSpanByDatePeriod -StartDate "1/1/2015" -EndDate "12/28/2015" -Updates $Updates
#$Updates = Set-TimeSpanAllUpdatesBeforeDate -StartDate "9/30/2015" -Updates $Updates
CreateSoftwareUpdateGroup -OperatingSystem $OperatingSystem -Updates $Updates -Architecture $Architecture
New-Report -EmailAddressList $EmailAddresses -Updates $Updates -OperatingSystem $OperatingSystem -Architecture $Architecture
Write-Host
Write-Host "Total Number of Updates:"$Updates.Count
$Filters = $null
$Updates = $null
$UpdateTypes = $null

#Remove Variables
Remove-Variable -Name Architecture -Scope Local -Force
Remove-Variable -Name EmailAddresses -Scope Local -Force
Remove-Variable -Name Filters -Scope Local -Force
Remove-Variable -Name LogFile -Scope Local -Force
Remove-Variable -Name Namespace -Scope Local -Force
Remove-Variable -Name OperatingSystem -Scope Local -Force
Remove-Variable -Name Updates -Scope Local -Force
Remove-Variable -Name UpdateTypes -Scope Local -Force
