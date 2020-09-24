<#
	.SYNOPSIS
		Bitlocker Encryption Reporting
	
	.DESCRIPTION
		This script queries the Configuration Manager SQL database for a list of machines that are not Bitlocker Encrypted. It is limited to non-desktop chassis, which can be changed by modifying the SQL query. The script is designed to output the data so that it can be used with Orchestrator, Azure Automation, or a scheduled task.
	
	.PARAMETER SQLServer
		Name of the SQL server
	
	.PARAMETER SQLDatabase
		Name of the SQL database
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	9/21/2020 3:35 PM
		Created by:   	Mick Pletcher
		Filename:     	BitlockerEncryptionReporting.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase
)

$Query = "SELECT ResultTableName FROM dbo.v_Collections"
$Collection = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query $Query
#SQL query to retrieve the list of machines
$Query = "SELECT DISTINCT Name as ComputerName, dbo.Computer_System_DATA.Model00 AS Model, dbo.System_Enclosure_DATA.ChassisTypes00 AS Chassis, dbo.ENCRYPTABLE_VOLUME_DATA.DriveLetter00 AS DriveLetter, ProtectionStatus00 AS BitlockerStatus, LastHardwareScan, ADLastLogonTime AS LastLogonTime FROM dbo.Computer_System_DATA INNER JOIN dbo.ENCRYPTABLE_VOLUME_DATA ON dbo.Computer_System_DATA.MachineID = dbo.ENCRYPTABLE_VOLUME_DATA.MachineID INNER JOIN dbo.v_GS_ENCRYPTABLE_VOLUME ON dbo.v_GS_ENCRYPTABLE_VOLUME.ResourceID = dbo.ENCRYPTABLE_VOLUME_DATA.MachineID INNER JOIN dbo._RES_COLL_SMS00001 ON dbo.ENCRYPTABLE_VOLUME_DATA.MachineID = dbo._RES_COLL_SMS00001.MachineID INNER JOIN dbo.System_Enclosure_DATA ON dbo._RES_COLL_SMS00001.MachineID = dbo.System_Enclosure_DATA.MachineID INNER JOIN dbo.v_GS_VOLUME ON dbo.System_Enclosure_DATA.MachineID = dbo.v_GS_VOLUME.ResourceID WHERE (((dbo.System_Enclosure_DATA.ChassisTypes00 = 8) OR (dbo.System_Enclosure_DATA.ChassisTypes00 = 9) OR (dbo.System_Enclosure_DATA.ChassisTypes00 = 10) OR (dbo.System_Enclosure_DATA.ChassisTypes00 = 12) OR (dbo.System_Enclosure_DATA.ChassisTypes00 = 14) OR (dbo.System_Enclosure_DATA.ChassisTypes00 = 31)) AND (dbo.ENCRYPTABLE_VOLUME_DATA.DriveLetter00 = 'C:') AND (dbo.ENCRYPTABLE_VOLUME_DATA.ProtectionStatus00 = 0)) ORDER BY Name"
$Report = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query $Query
#If the report has no machines, then exit this script with an error code 1 so that the automation tool the link will not continue to the email task
If ($Report -ne $null) {
	$Array = @()
	foreach ($Item in $Report) {
		$SysObj = New-Object -TypeName System.Management.Automation.PSObject
		$SysObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Item.ComputerName
		$SysObj | Add-Member -MemberType NoteProperty -Name Model -Value $Item.Model
		$SysObj | Add-Member -MemberType NoteProperty -Name Chassis -Value $Item.Chassis
		$SysObj | Add-Member -MemberType NoteProperty -Name DriveLetter -Value $Item.DriveLetter
		$SysObj | Add-Member -MemberType NoteProperty -Name BitlockerStatus -Value $Item.BitlockerStatus
		$SysObj | Add-Member -MemberType NoteProperty -Name LastHardwareScan -Value $Item.LastHardwareScan
		$SysObj | Add-Member -MemberType NoteProperty -Name LastLogonTime -Value $Item.LastLogonTime
		$Array += $SysObj
	}
	#Bitlocker reporting fields from the query
	$Fields = @("Computer Name", "Model", "Chassis", "Drive Letter", "Bitlocker Status", "Last Hardware Scan", "Last Logon Time")
	#Title row
	$Output =  ($Fields[0] + [char]9 + [char]9 + $Fields[1] + [char]9 + [char]9 + [char]9 + [char]9 + $Fields[2] + [char]9 + [char]9 + $Fields[3] + [char]9 + $Fields[4] + [char]9 + [char]9 + $Fields[5] + [char]9 + $Fields[6] + [char]13)
	#Add each entry while formatting the computername column as to the width of the computername
	foreach ($Item in $Array) {
		If ($Item.ComputerName.Length -le 3) {
			$ComputerName = $Item.ComputerName + [char]9 + [char]9 + [char]9 + [char]9 + [char]9
		} elseif ($Item.ComputerName.Length -le 7) {
			$ComputerName = $Item.ComputerName + [char]9 + [char]9 + [char]9 + [char]9
		} elseif ($Item.ComputerName.Length -le 11) {
			$ComputerName = $Item.ComputerName + [char]9 + [char]9 + [char]9
		} elseif ($Item.ComputerName.Length -le 15) {
			$ComputerName = $Item.ComputerName + [char]9 + [char]9
		} else {
			$ComputerName = $Item.ComputerName + [char]9
		}
		$Output += $ComputerName + $Item.Model + [char]9 + [char]9 + [char]9 + $Item.Chassis + [char]9 + [char]9 + $Item.DriveLetter + [char]9 + [char]9 + $Item.BitlockerStatus + [char]9 + [char]9 + [char]9 + $Item.LastHardwareScan + [char]9 + $Item.LastLogonTime + [char]13
	}
	#Write the output so it can be collected from the automation tool
	Write-Output -InputObject $Output
} else {
	Exit 1
}
