<#
	.SYNOPSIS
		LastBootup
	
	.DESCRIPTION
		This script will query the SCCM SQL database for a list of machines that have not been rebooted for more than ten days
	
	.PARAMETER Collection
		Name of the collection to query. PowerShell will find the SQL table name from the collection name
	
	.PARAMETER SQLServer
		Name of the SQL server that contains the SCCM database
	
	.PARAMETER SQLDatabase
		Name of the SCCM SQL database 
	
	.PARAMETER DeploymentName
		Name of deployment of the SCCM reboot package
	
	.PARAMETER MaxDays
		If system has not rebooted for this number of days, then add to $Report
	
	.PARAMETER SQLInstance
		Name of the SQL Database
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	10/22/2019 10:21 AM
		Created by:   	Mick Pletcher
		Filename:		RebootManagement.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$Collection,
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase,
	[ValidateNotNullOrEmpty()]
	[string]$DeploymentName,
	[ValidateNotNullOrEmpty()]
	[int]$MaxDays
)

function Initialize-Reboot {
<#
	.SYNOPSIS
		Initialize Timed Reboot
	
	.DESCRIPTION
		This will change the reboot package from advertised to mandatory in order to initiate the reboot. It will then change package back to advertised once the package has been executed.
	
	.PARAMETER Object
		A description of the Object parameter.
	
	.EXAMPLE
		PS C:\> Initialize-Reboot
	
	.NOTES
		Additional information about the function.
#>
	
	[CmdletBinding()]
	param
	(
		$Object
	)
	
	If ((Test-Connection -ComputerName $Object.Name -Quiet) -eq $true) {
		#Query the remote system to make sure it has not been rebooted since the LastBootUpTime was updated to SCCM
		If ((New-TimeSpan -Start ([Management.ManagementDateTimeConverter]::ToDateTime((Get-WmiObject -Class win32_operatingsystem -ComputerName $Object.Name).LastBootUpTime))).Days -gt $MaxDays) {
			#Package and Advertisement IDs of the SCCM package
			$Advertisement = Get-WmiObject -Namespace "root\ccm\policy\machine\actualconfig" -Class "CCM_SoftwareDistribution" -ComputerName $Object.Name | Where-Object {$_.PKG_Name -eq $DeploymentName} | Select-Object -Property PKG_PackageID, ADV_AdvertisementID
			#Continue to next array item if the advertisement is null, meaning the reboot application was not advertised to the system
			If ($Advertisement -ne $null) {
				#Schedule IS of the SCCM package deployment
				$ScheduleID = Get-WmiObject -Namespace "root\ccm\scheduler" -Class "CCM_Scheduler_History" -ComputerName $Object.Name | Where-Object {
					$_.ScheduleID -like "*$($Advertisement.PKG_PackageID)*"
				} | Select-Object -ExpandProperty ScheduleID
				#Retrieve advertisement policy
				$Policy = Get-WmiObject -Namespace "root\ccm\policy\machine\actualconfig" -Class "CCM_SoftwareDistribution" -ComputerName $Object.Name | Where-Object {
					$_.PKG_Name -eq $DeploymentName
				}
				#Change advertisement policy to mandatory so the package can be executed
				If ($Policy.ADV_MandatoryAssignments -eq $false) {
					$Policy.ADV_MandatoryAssignments = $true
					$Policy.Put() | Out-Null
				}
				#Execute the advertisement
				Invoke-WmiMethod -Namespace "root\ccm" -Class "SMS_Client" -Name "TriggerSchedule" -ArgumentList $ScheduleID -ComputerName $Object.Name
				#Wait one second to give time for the package to initiate
				Start-Sleep -Seconds 1
				#Retrieve advertisement policy
				$Policy = Get-WmiObject -Namespace "root\ccm\policy\machine\actualconfig" -Class "CCM_SoftwareDistribution" -ComputerName $Object.Name | Where-Object {
					$_.PKG_Name -eq $DeploymentName
				}
				#Remove the mandatory assignment from the package so this is not rerun
				If ($Policy.ADV_MandatoryAssignments -eq $true) {
					$Policy.ADV_MandatoryAssignments = $false
					$Policy.Put() | Out-Null
				}
			}
		}
	} else {
		Return $null
	}
	Return $object
}

#Get the table name from the $Collection value
$TableName = 'dbo.' + ((Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('SELECT ResultTableName FROM dbo.v_Collections WHERE CollectionName = ' + [char]39 + $Collection + [char]39)).ResultTableName)
#Query active systems in the above table to list the computer name and the last boot up time
$Query = 'SELECT Name, LastBootUpTime0, ClientState FROM dbo.v_GS_OPERATING_SYSTEM INNER JOIN' + [char]32 + $TableName + [char]32 + 'ON dbo.v_GS_OPERATING_SYSTEM.ResourceID =' + [char]32 + $TableName + '.MachineID WHERE ((((DATEDIFF(DAY,LastBootUpTime0,GETDATE())) >' + [char]32 + $MaxDays + ') OR ClientState <> 0) AND LastBootUpTime0 IS NOT NULL)'
#Query SCCM SQL database
$List = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query $Query
#Create report array to contain list of all systems that have not rebooted for $Threshold days
$Report = @()
#Check if list is null. If so, exit with error code 1 so if script is used in Orchestrator or SMA, it can be set to not proceed with email.
If ($List -ne '') {
	#Get list of machines that are exceed number of days allowed without rebooting. This is also used as a report if desired to be emailed.
	$List | ForEach-Object {
		If ($_.ClientState -ne 0) {
			$PendingReboot = $true
		} else {
			$PendingReboot = $false
		}
		If ((Test-Connection -ComputerName $_.Name -Count 1 -Quiet) -eq $true) {
			$Online = $true
		} else {
			$Online = $false
		}
		#Create new object
		$object = New-Object -TypeName System.Management.Automation.PSObject
		$object | Add-Member -MemberType NoteProperty -Name Name -Value $_.Name
		$object | Add-Member -MemberType NoteProperty -Name LastBootUpTime -Value $_.LastBootUpTime0
		$object | Add-Member -MemberType NoteProperty -Name PendingReboot -Value $PendingReboot
		$object | Add-Member -MemberType NoteProperty -Name Online -Value $Online
		If ($object.Online -eq $true) {
			$obj = Initialize-Reboot -Object $object
		}
		#If the reboot was initiated, then add to $Report
		If ($obj -ne $null) {
			$Report += $obj
		}
	}
	If ($Report -eq $null) {
		#This exit code is used for signaling to a link in Orchestrator or Azure Automation to not proceed to the next activity
		Write-Host "Null"
		Exit 1
	} else {
		Write-Output $Report | Sort-Object LastBootUpTime, Name
	}
} else {
	#This exit code is used for signaling to a link in Orchestrator or Azure Automation to not proceed to the next activity
	Write-Host "Null"
	Exit 1
}
