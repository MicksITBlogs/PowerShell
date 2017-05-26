<#	
	.NOTES
	===========================================================================
     Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.127
     Created on:   	8/5/2016 11:11 AM
	 Created by:   	Mick Pletcher
	 Organization: 	 
	 Filename:     	ApplicationVirusDetectionMethod.ps1
	===========================================================================
	.DESCRIPTION
#>


$LastInfection = get-winevent -filterhashtable @{ logname = 'system'; ID = 1116 } -maxevents 1 -ErrorAction SilentlyContinue
$LastScan = Get-WinEvent -FilterHashtable @{ logname = 'system'; ProviderName = 'Microsoft Antimalware'; ID = 1001 } -MaxEvents 1
If ($LastScan.TimeCreated -lt $LastInfection.TimeCreated) {
	#No scan since last infection
	Start-Sleep -Seconds 5
	exit 0
} else {
	#No infection since last scan
	Write-Host "No Infection"
	Start-Sleep -Seconds 5
	exit 0
}
