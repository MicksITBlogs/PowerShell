<#
	.SYNOPSIS
		PrinterInstaller
	
	.DESCRIPTION
		This script is intended to be used in ConfigMgr as an applicatio advertisement in Software Center. This allows non-admin users to install printers allowing companies to keep the Microsoft print server patch in place. It nwill retrieve all printers from all print servers. It then prompts the user for the office. At that point, it will display a list of printers in that office for the user to select from. Finally, it will check if the printer is already installed. If it is, it will uninstall the printer and proceed to install it, otherwise it will install the printer.
	
	.PARAMETER PrintServersFile
		Name of the file which contains a list of print servers
	
	.NOTES
		===========================================================================
		Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2021 v5.8.194
		Created on:   	10/12/2021 7:40 PM
		Created by:   	Mick Pletcher
		Filename:		PrinterInstaller.ps1
		===========================================================================
#>

[CmdletBinding()]
Param
(
	[ValidateNotNullOrEmpty()]$PrintServersFile = 'PrintServers.txt'
)

Clear-Host
Write-Host "Retrieving List of Offices..."
#Create Printers array
$Printers = @()
#Get list of print servers that includes the print server and printer location
$PrintServers = Get-Content -Path ($PSScriptRoot + '\' + $PrintServersFile)
#Get list of all printers from within each print server
$PrintServers | ForEach-Object {
    #Test if the print server is online before querying it
    If ((Test-Connection -ComputerName $_.Split(",")[0] -Count 1 -Quiet) -eq $true) {
        #Add all printer from the specified print server
        $Query += Get-Printer -ComputerName $_.Split(",")[0]
    }
}
#Create the object for each printer and add it to the $Printers array
$Query | ForEach-Object {
	$object = New-Object PSObject
	$object | Add-Member Noteproperty -Name PrinterName -Value $_.Name
   	$object | Add-Member Noteproperty -Name PrinterPort -Value $_.PortName
	$object | Add-Member Noteproperty -Name PrintServer -Value $_.ComputerName
	$object | Add-Member Noteproperty -Name DriverName -Value $_.DriverName
	Switch ($_.ComputerName) {
        "Printer1"  { $object | Add-Member Noteproperty -Name Office -Value "Austin" }
        "Printer2"  { $object | Add-Member Noteproperty -Name Office -Value "Birmingham" }
        "Printer3" { $object | Add-Member Noteproperty -Name Office -Value "Chattanooga" }
        "Printer4" { $object | Add-Member Noteproperty -Name Office -Value "Nashville" }
    }
    #Add a floor value to the Floor object if the print server is in Nashville
    If ($_.ComputerName -eq 'Printer4') {
        $object | Add-Member Noteproperty -Name Floor -Value ($_.Name.Split("-")[1])
    } else {
        #Leave the floor object blank if it is any office other than Nashville
        $object | Add-Member Noteproperty -Name Floor -Value ""
    }
    #Add the object to the $Printers array
    $Printers += $object
    
}
#Sort the array by Office and then Floor
$Printers = $Printers | Sort-Object -Property Office, Floor
#Counter for selecting the office
$Count = 1
#Display each office with a number selection
$PrintServers | ForEach-Object {Write-Host ([string]$Count + ' - ' + $_.Split(",")[1]);$Count++}
#Prompt for a user selection of the office
$Selection = Read-Host -Prompt "Select the office"
#Get list of printers for selected office
$PrintersSelection = $Printers | Where-Object {$_.PrintServer -eq ($PrintServers[$Selection - 1].Split(",")[0])}
#printer counter
$Count = 1
Clear-Host
Write-Host
Write-Host "Retrieving list of Printers..."
#Display list of printers in the selected office
$PrintersSelection | ForEach-Object {Write-Host ([string]$Count + ' - ' + $_.PrinterName);$Count++}
#Prompt the user to select the printer
$Selection = Read-Host -Prompt "Select the Printer"
#Display the selected printer
$PrintersSelection[$Selection - 1]
#Check if the printer is installed and uninstall it if true
If ((Get-Printer -Name $PrintersSelection[$Selection - 1].PrinterName -ErrorAction SilentlyContinue) -ne $null) {
	Remove-Printer -Name $PrintersSelection[$Selection - 1].PrinterName
	Remove-PrinterPort -Name $PrintersSelection[$Selection - 1].PrinterPort
}
Write-Host
Write-Host ('Installing Printer' + [char]32 + $PrintersSelection[$Selection - 1].PrinterName + '.....') -NoNewline
#Install the selected printer
Add-PrinterPort -Name $PrintersSelection[$Selection - 1].PrinterPort -PrinterHostAddress $PrintersSelection[$Selection - 1].PrinterPort
Add-Printer -Name $PrintersSelection[$Selection - 1].PrinterName -DriverName $PrintersSelection[$Selection - 1].DriverName -PortName $PrintersSelection[$Selection - 1].PrinterPort
#Verify the printer was installed
If ((Get-Printer -Name $PrintersSelection[$Selection - 1].PrinterName -ErrorAction SilentlyContinue) -ne $null) {
	Write-Host 'success' -ForegroundColor Yellow
} Else {
	Write-Host 'failed' -ForegroundColor Red
}
