<#
	.SYNOPSIS
		This script sends out emails to the IT staff with the status of
		MDT builds.
	
	.DESCRIPTION
		You can find detailed information on my blog:
		http://mickitblog.blogspot.com/2016/02/mdt-build-reporting-tool.html
	
	.PARAMETER LogFile
		Name of the log file must be <Filename>.log
	
	.PARAMETER MonitoringHost
		The FQDN of the MDT server
	
	.PARAMETER EmailAddress
		Enter the email address of the user(s) to email status messages
	
	.PARAMETER SMTPServer
		FQDN of the SMTP server
	
	.PARAMETER Sender
		Email address of the sender
	
	.PARAMETER MaxImageTime
		Designates the maximum allowable imaging time before an email is sent to IT staff that the image is taking longer than expected.
	
	.PARAMETER DaysSince
		Number of days since the system was imaged before removing from log file
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.99
		Created on:   	2/9/2016 12:22 PM
		Created by:   	Mick Pletcher
		Filename:     	MDTReportingTool.ps1
		===========================================================================
#>
param
(
	[Parameter(Mandatory = $false)][string]$LogFile = 'ImagedSystems.log',
	[Parameter(Mandatory = $true)][string]$MonitoringHost,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$EmailAddress,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$SMTPServer,
	[Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Sender,
	[Parameter(Mandatory = $false)]$MaxImageTime = '02:00:00',
	[Parameter(Mandatory = $false)][int]$DaysSince = 3
)

Function Get-LocalTime {
	param ($UTCTime)
	
	#Declare Local Variables
	Set-Variable -Name LocalTime -Scope Local -Force
	Set-Variable -Name strCurrentTimeZone -Scope Local -Force
	Set-Variable -Name TimeZone -Scope Local -Force
	
	$strCurrentTimeZone = (Get-WmiObject win32_timezone).StandardName
	$TimeZone = [System.TimeZoneInfo]::FindSystemTimeZoneById($strCurrentTimeZone)
	$LocalTime = [System.TimeZoneInfo]::ConvertTimeFromUtc($UTCTime, $TimeZone)
	Return $LocalTime
	
	#Cleanup Local Variables
	Remove-Variable -Name LocalTime -Scope Local -Force
	Remove-Variable -Name strCurrentTimeZone -Scope Local -Force
	Remove-Variable -Name TimeZone -Scope Local -Force
	
}

function Get-MDTData {
	param ($MonitoringHost)
	
	#Declare Local Variables
	Set-Variable -Name Data -Scope Local -Force
	Set-Variable -Name Property -Scope Local -Force
	
	$Data = Invoke-RestMethod $MonitoringHost
	
	foreach ($property in ($Data.content.properties)) {
		New-Object PSObject -Property @{
			Name = $($property.Name);
			PercentComplete = $($property.PercentComplete.’#text’);
			Warnings = $($property.Warnings.’#text’);
			Errors = $($property.Errors.’#text’);
			DeploymentStatus = $(
			Switch ($property.DeploymentStatus.’#text’) {
				1 { "Active/Running" }
				2 { "Failed" }
				3 { "Successfully completed" }
				Default { "Unknown" }
			}
			);
			StartTime = $($property.StartTime.’#text’) -replace "T", " ";
			EndTime = $($property.EndTime.’#text’) -replace "T", " ";
		}
	}
	
	#Cleanup Local Variables
	Remove-Variable -Name Data -Scope Local -Force
	Remove-Variable -Name Property -Scope Local -Force
}

function Get-RelativePath {
	#Declare Local Variables
	Set-Variable -Name RelativePath -Scope Local -Force
	
	$RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"
	Return $RelativePath
	
	#Cleanup Local Variables
	Remove-Variable -Name RelativePath -Scope Local -Force
}

function New-Logs {
	param ($LogFile)
	
	#Declare Local Variables
	Set-Variable -Name Temp -Scope Local -Force
	
	if ((Test-Path $LogFile) -eq $false) {
		$Temp = New-Item -Path $LogFile -ItemType file -Force
	}
	
	#Cleanup Local Variables
	Remove-Variable -Name Temp -Scope Local -Force
}

function New-Report {
	param ($System)
	
	#Declare Variables
	Set-Variable -Name Body -Scope Local -Force
	Set-Variable -Name EndTime -Scope Local -Force
	Set-Variable -Name Imaging -Scope Local -Force
	Set-Variable -Name StartTime -Scope Local -Force
	Set-Variable -Name Subject -Scope Local -Force
	
	$StartTime = $System.StartTime
	$StartTime = $StartTime -split " "
	[DateTime]$StartTime = $StartTime[1]
	$StartTime = Get-LocalTime -UTCTime $StartTime
	If ($System.EndTime -eq "") {
		$CurrentTime = Get-Date
		$Imaging = "{2:D2}:{4:D2}:{5:D2}" -f (New-TimeSpan -Start $StartTime -End $CurrentTime).psobject.Properties.Value
		$EndTime = "N/A"
	} else {
		$Imaging = "{2:D2}:{4:D2}:{5:D2}" -f (New-TimeSpan -Start $System.StartTime -End $System.EndTime).psobject.Properties.Value
		$EndTime = $System.EndTime
		$EndTime = $EndTime -split " "
		[DateTime]$EndTime = $EndTime[1]
		$EndTime = Get-LocalTime -UTCTime $EndTime
	}
	Write-Host
	Write-Host "System:"$System.Name
	Write-Host "Deployment Status:"$System.DeploymentStatus
	Write-Host "Completed:"$System.PercentComplete
	Write-Host "Imaging Time:"$Imaging
	Write-Host "Start:" $StartTime
	Write-Host "End:" $EndTime
	Write-Host "Errors:"$System.Errors
	Write-Host "Warnings:"$System.Warnings
	$Subject = "Image Status:" + [char]32 + $System.Name
	$Body = "System:" + [char]32 + $System.Name + [char]13 +`
		"Deployment Status:" + [char]32 + $System.DeploymentStatus + [char]13 +`
		"Completed:" + [char]32 + $System.PercentComplete + "%" + [char]13 +`
		"Start Time:" + [char]32 + $StartTime + [char]13 +`
		"End Time:" + [char]32 + $EndTime + [char]13 +`
		"Imaging Time:" + [char]32 + $Imaging + [char]13 +`
		"Errors:" + [char]32 + $System.Errors + [char]13 +`
		"Warnings:" + [char]32 + $System.Warnings + [char]13
	Send-MailMessage -To $EmailAddress -From $Sender -Subject $Subject -Body $Body -SmtpServer $SMTPServer
	
	#Cleanup Variables
	Remove-Variable -Name Body -Scope Local -Force
	Remove-Variable -Name EndTime -Scope Local -Force
	Remove-Variable -Name Imaging -Scope Local -Force
	Remove-Variable -Name StartTime -Scope Local -Force
	Remove-Variable -Name Subject -Scope Local -Force
}

function Remove-OldSystems {
	param
	(
		[parameter(Mandatory = $true)]$Systems
	)
	
	#Declare Local Variables
	Set-Variable -Name Log -Scope Local -Force
	Set-Variable -Name Logs -Scope Local -Force
	Set-Variable -Name NewLogs -Scope Local -Force
	Set-Variable -Name RelativePath -Scope Local -Force
	Set-Variable -Name System -Scope Local -Force
	
	$NewLogs = @()
	$RelativePath = Get-RelativePath
	$Logs = (Get-Content $LogFile)
	#Remove systems from logfile that do not exist in MDT Monitoring
	foreach ($Log in $Logs) {
		If (($Log -in $Systems.Name)) {
			$System = $Systems | where { $_.Name -eq $Log }
			If (($System.DeploymentStatus -eq "Successfully completed") -or ($System.DeploymentStatus -eq "Failed") -or ($System.DeploymentStatus -eq "Unknown")) {
				$NewLogs = $NewLogs + $Log
			}
		}
	}
	Out-File -FilePath $LogFile -InputObject $NewLogs -Force
	
	
	#Cleanup Local Variables
	Remove-Variable -Name Log -Scope Local -Force
	Remove-Variable -Name Logs -Scope Local -Force
	Remove-Variable -Name NewLogs -Scope Local -Force
	Remove-Variable -Name RelativePath -Scope Local -Force
	Remove-Variable -Name System -Scope Local -Force
	
}

function Add-NewSystems {
	param
	(
		[parameter(Mandatory = $true)]$Systems
	)
	
	#Declare Local Variables
	Set-Variable -Name CurrentTime -Scope Local -Force
	Set-Variable -Name Imaging -Scope Local -Force
	Set-Variable -Name Log -Scope Local -Force
	Set-Variable -Name Logs -Scope Local -Force
	Set-Variable -Name RelativePath -Scope Local -Force
	Set-Variable -Name StartTime -Scope Local -Force
	Set-Variable -Name System -Scope Local -Force
	Set-Variable -Name SystemName -Scope Local -Force
	
	$RelativePath = Get-RelativePath
	#Read Log File
	$Logs = (Get-Content $LogFile)
	#Add new systems to logfile
	foreach ($SystemName in $Systems.Name) {
		If (-not($SystemName -in $Logs)) {
			$System = $Systems | where { $_.Name -eq $SystemName }
			If (($System.DeploymentStatus -eq "Successfully completed") -or ($System.DeploymentStatus -eq "Failed") -or ($System.DeploymentStatus -eq "Unknown")) {
				New-Report -System $System
				Out-File -FilePath $LogFile -InputObject $SystemName -Append -Force
			} else {
				$StartTime = Get-LocalTime -UTCTime $System.StartTime
				$CurrentTime = Get-Date
				$Imaging = "{2:D2}:{4:D2}:{5:D2}" -f (New-TimeSpan -Start $StartTime -End $CurrentTime).psobject.Properties.Value
				If ($Imaging -ge $MaxImageTime) {
					New-Report -System $System
				}
			}
		}
	}

	#Cleanup Local Variables
	Remove-Variable -Name CurrentTime -Scope Local -Force
	Remove-Variable -Name Imaging -Scope Local -Force
	Remove-Variable -Name Log -Scope Local -Force
	Remove-Variable -Name Logs -Scope Local -Force
	Remove-Variable -Name RelativePath -Scope Local -Force
	Remove-Variable -Name StartTime -Scope Local -Force
	Remove-Variable -Name System -Scope Local -Force
	Remove-Variable -Name SystemName -Scope Local -Force
}

#Declare Local Variables
Set-Variable -Name ImagedSystems -Scope Local -Force
Set-Variable -Name RelativePath -Scope Local -Force

cls
$RelativePath = Get-RelativePath
$LogFile = $RelativePath + $LogFile
$MonitoringHost = "http://" + $MonitoringHost + ":9801/MDTMonitorData/Computers"
New-Logs -LogFile $LogFile
$ImagedSystems = Get-MDTData -MonitoringHost $MonitoringHost | Select Name, DeploymentStatus, PercentComplete, Warnings, Errors, StartTime, EndTime | Sort -Property Name
#Remove systems from logfile that do not exist in MDT Monitoring
Remove-OldSystems -Systems $ImagedSystems
#Add new systems to the logfile and report their status
Add-NewSystems -Systems $ImagedSystems

#Cleanup Local Variables
Remove-Variable -Name ImagedSystems -Scope Local -Force
Remove-Variable -Name RelativePath -Scope Local -Force
