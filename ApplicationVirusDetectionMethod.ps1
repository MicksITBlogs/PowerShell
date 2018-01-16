$LastInfection = get-winevent -filterhashtable @{ logname = 'system'; ID = 1116 } -maxevents 1 -ErrorAction SilentlyContinue
$LastFullScan = get-winevent -filterhashtable @{ logname = 'system'; ID = 1118 } -maxevents 1 -ErrorAction SilentlyContinue
If (($LastFullScan.TimeCreated -lt $LastInfection.TimeCreated) -or ($LastInfection -eq $null)) {
	Start-Sleep -Seconds 5
	exit 0
} else {
	Write-Host "No Infection"
	Start-Sleep -Seconds 5
	exit 0
}
