<#
	.SYNOPSIS
		SQL Backup Verification
	
	.DESCRIPTION
		This script retrieves the latest SQL database backup file and verifies its date matches the current date while also verifying the backup is good.
	
	.PARAMETER SQLBackupDir
		Location where the SQL backups exist
	
	.PARAMETER TimeSpan
		Number of days allowed since last SQL backup
	
	.PARAMETER SQLServer
		Name of the SQL server database to verify the backup
	
	.PARAMETER SQLDatabase
		Name of the SCCM SQL database the backup file is for
	
	.PARAMETER ModuleName
		Name of module to import
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2017 v5.4.142
		Created on:   	11/11/2019 4:49 PM
		Created by:   	Mick Pletcher
		Filename:     	SQLBackupVerification.ps1
		===========================================================================
#>
[CmdletBinding()]
param
(
	[ValidateNotNullOrEmpty()]
	[string]$SQLBackupDir,
	[ValidateNotNullOrEmpty()]
	$TimeSpan,
	[ValidateNotNullOrEmpty()]
	[string]$SQLServer,
	[ValidateNotNullOrEmpty()]
	[string]$SQLDatabase,
	[ValidateNotNullOrEmpty()]
	[string]$ModuleName
)

#Import SQL Server PowerShell Module
If ((Get-Module -Name ((Import-Module -Name $ModuleName -ErrorAction SilentlyContinue -Force -PassThru).Name)) -eq $null) {
	#Install module if it does not exist
	Install-Module -Name $ModuleName -Confirm:$false -Force
	#Verify module got installed. Exit the script if it failed
	If ((Get-Module -Name ((Import-Module -Name $ModuleName -ErrorAction SilentlyContinue -Force -PassThru).Name)) -eq $null) {
		Write-Host 'Failed'
		Exit 2
	}
}
#Retrieve file attributes from the latest SQL backup
$LatestBackup = Get-ChildItem -Path $SQLBackupDir -Filter *.bak -ErrorAction SilentlyContinue | Select-Object -Last 1
#Verify there is a backup file that exists
If ($LatestBackup -ne $null) {
	#Check if the latest SQL backup is within the designated allowable timespan
	If ((New-TimeSpan -Start $LatestBackup.LastWriteTime -End (Get-Date)).Days -le $TimeSpan) {
		#Execute SQL query to verify the backup is valid
		$Verbose = $($Verbose = Invoke-Sqlcmd -ServerInstance $SQLServer -Database $SQLDatabase -Query ('RESTORE VERIFYONLY FROM DISK = N' + [char]39 + $LatestBackup.FullName + [char]39) -QueryTimeout 0 -Verbose) 4>&1
		If ($Verbose -like '*The backup set on file 1 is valid*') {
			Write-Output 'Success'
			Exit 0
		} else {
			Write-Output 'Invalid Backup'
			Exit 1
		}
	} else {
		#SQL Server did not perform a backup within the designated timespan
		Write-Output ('Latest Backup for' + [char]32 + $SQLDatabase + [char]32 + 'database' + [char]32 + 'on' + [char]32 + $SQLServer + [char]32 + 'has failed')
		Exit 1
	}
} else {
	#Backups are not being performed
	Write-Output ('No backups available for' + [char]32 + $SQLDatabase + [char]32 + 'database' + [char]32 + 'on' + [char]32 + $SQLServer)
	Exit 1
}
