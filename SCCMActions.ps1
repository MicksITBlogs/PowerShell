<#
	.SYNOPSIS
		Initiate SCCM actions
	
	.DESCRIPTION
		This script will initiate SCCM actions and wait until the action is complete before continuing. 
	
	.EXAMPLE
		powershell.exe -executionpolicy bypass -file SCCMActions.ps1
	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.122
	 Created on:   	5/20/2016 2:28 PM
	 Created by:   	Mick Pletcher
	 Filename:     	SCCMActions.ps1
	===========================================================================
#>
[CmdletBinding()]
param ()

function Get-CurrentDate {
<#
	.SYNOPSIS
		Get the current date and return formatted value
	
	.DESCRIPTION
		Return the current date in the following format: mm-dd-yyyy
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()][OutputType([string])]
	param ()
	
	$CurrentDate = Get-Date
	$CurrentDate = $CurrentDate.ToShortDateString()
	$CurrentDate = $CurrentDate -replace "/", "-"
	If ($CurrentDate[2] -ne "-") {
		$CurrentDate = $CurrentDate.Insert(0, "0")
	}
	If ($CurrentDate[5] -ne "-") {
		$CurrentDate = $CurrentDate.Insert(3, "0")
	}
	Return $CurrentDate
}

function Invoke-ApplicationDeploymentEvaluationCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Application Deployment Evaluation Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000121"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\DCMReporting.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*FinalRelease*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-DiscoveryDataCollectionCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Discovery Data Collection Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000003"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\InventoryAgent.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*End of message processing*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-FileCollectionCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running File Collection Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000010"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\InventoryAgent.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If ((($Log -like "*Action completed*") -or ($Log -like "*Exiting as no items to collect*")) -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-HardwareInventoryCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Hardware Inventory Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000001"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\InventoryAgent.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*End of message processing*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If (($Log -like "*already in queue. Message ignored.*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Ignored" -ForegroundColor Red
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-MachinePolicyEvaluationCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %r
	$StartTime = $StartTime.Split(' ')
	$StartTime = $StartTime[0]
	$StartTime = $StartTime.Substring(0, $StartTime.Length - 3)
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Machine Policy Evaluation Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000022"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\PolicyEvaluator.log"
		$Count = $Log.count
		$LogTime = $Log[$Count - 6]
		$LogTime = $LogTime.Split('"')
		$LogTime = $LogTime[1]
		$LogTime = [management.managementdatetimeconverter]::ToDateTime($LogTime)
		$LogDate = $LogTime
		$LogTime = $LogTime.ToShortTimeString()
		$LogTime = $Logtime.Split(' ')
		$LogTime = $LogTime[0]
		If ($LogTime[2] -ne ":") {
			$LogTime = $LogTime.Insert(0, "0")
		}
		$LogDate = $LogDate.ToShortDateString()
		$LogDate = Get-CurrentDate
		$LogStatus = $Log[$Count - 9]
		If (($LogStatus -like "*instance of CCM_PolicyAgent_PolicyEvaluationComplete*") -and ($CurrentDate -eq $LogDate) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-MachinePolicyRetrievalCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %r
	$StartTime = $StartTime.Split(' ')
	$StartTime = $StartTime[0]
	$StartTime = $StartTime.Substring(0, $StartTime.Length - 3)
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Machine Policy Retrieval Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000021"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\PolicyEvaluator.log"
		$Count = $Log.count
		$LogTime = $Log[$Count - 6]
		$LogTime = $LogTime.Split('"')
		$LogTime = $LogTime[1]
		$LogTime = [management.managementdatetimeconverter]::ToDateTime($LogTime)
		$LogDate = $LogTime
		$LogTime = $LogTime.ToShortTimeString()
		$LogTime = $Logtime.Split(' ')
		$LogTime = $LogTime[0]
		If ($LogTime[2] -ne ":") {
			$LogTime = $LogTime.Insert(0, "0")
		}
		$LogDate = $LogDate.ToShortDateString()
		$LogDate = Get-CurrentDate
		$LogStatus = $Log[$Count - 9]
		If (($LogStatus -like "*instance of CCM_PolicyAgent_PolicyEvaluationComplete*") -and ($CurrentDate -eq $LogDate) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-SoftwareInventoryCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Software Inventory Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000002"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\InventoryAgent.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*Initialization completed in*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-SoftwareMeteringUsageReportCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Software Metering Usage Report Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000031"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\SWMTRReportGen.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If ((($Log -like "*No usage data found to generate software metering report*") -or ($Log -like "*Successfully generated report header*") -or ($Log -like "*Message ID of sent message*")) -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-SoftwareUpdatesDeploymentEvaluationCycle {
<#
	.SYNOPSIS
		Scan for software updates that are out of compliance
	
	.DESCRIPTION
		Initiates a scan for software updates compliance. Before client computers can scan for software update compliance, the software updates environment must be configured.
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param ()
	
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Software Updates Deployment Evaluation Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000108"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\ScanAgent.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*Calling back to client on Scan request complete*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-SoftwareUpdatesScanCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Software Updates Scan Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000113"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\scanagent.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*scan completion received*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Invoke-WindowsInstallerSourceListUpdateCycle {
	$Completed = $false
	$StartTime = Get-Date -UFormat %R
	$CurrentDate = Get-CurrentDate
	Write-Host "Running Windows Installer Source List Update Cycle....." -NoNewline
	Start-ConfigurationManagerClientScan -ScheduleID "00000000-0000-0000-0000-000000000032"
	Do {
		Start-Sleep -Seconds 1
		$CurrentTime = Get-Date -UFormat %R
		$TimeDifference = New-TimeSpan -Start $StartTime -End $CurrentTime
		$Log = Get-Content $env:windir"\ccm\logs\SrcUpdateMgr.log"
		$Count = $Log.count
		$Count = $Count - 1
		$Log = $Log[$Count]
		$LogTable = $Log.split("<")[-1]
		$LogTable = $LogTable.Substring(0, $LogTable.length - 1) -replace ' ', ';'
		$LogTable = "@{$($LogTable)}" | Invoke-Expression
		$LogTime = $LogTable.time.Substring(0, 5)
		[datetime]$StringTime = $LogTable.time
		If (($Log -like "*MSI update source list task finished successfully*") -and ($CurrentDate -eq $LogTable.date) -and ($LogTime -ge $StartTime)) {
			Write-Host "Completed" -ForegroundColor Yellow
			$Completed = $true
		}
		If ($TimeDifference.Minutes -ge 5) {
			Write-Host "Failed" -ForegroundColor Yellow
			$Completed = $true
		}
	} while ($Completed -eq $false)
}

function Start-ConfigurationManagerClientScan {
<#
	.SYNOPSIS
		Initiate Configuration Manager Client Scan
	
	.DESCRIPTION
		This will initiate an SCCM action
	
	.PARAMETER ScheduleID
		GUID ID of the SCCM action
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
			[ValidateSet('00000000-0000-0000-0000-000000000121', '00000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000108', '00000000-0000-0000-0000-000000000113', '00000000-0000-0000-0000-000000000111', '00000000-0000-0000-0000-000000000026', '00000000-0000-0000-0000-000000000027', '00000000-0000-0000-0000-000000000032')]$ScheduleID
	)
	
	$WMIPath = "\\" + $env:COMPUTERNAME + "\root\ccm:SMS_Client"
	$SMSwmi = [wmiclass]$WMIPath
	$Action = [char]123 + $ScheduleID + [char]125
	[Void]$SMSwmi.TriggerSchedule($Action)
}

Clear-Host
Invoke-SoftwareUpdatesScanCycle
Invoke-SoftwareUpdatesDeploymentEvaluationCycle
Invoke-ApplicationDeploymentEvaluationCycle
Invoke-DiscoveryDataCollectionCycle
Invoke-FileCollectionCycle
Invoke-HardwareInventoryCycle
Invoke-MachinePolicyEvaluationCycle
Invoke-MachinePolicyRetrievalCycle
Invoke-SoftwareInventoryCycle
Invoke-SoftwareMeteringUsageReportCycle
Invoke-WindowsInstallerSourceListUpdateCycle
