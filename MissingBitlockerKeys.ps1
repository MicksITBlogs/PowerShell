<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.92
	 Created on:   	8/25/2015 1:25 PM
	 Created by:   	Mick Pletcher
	 Filename:     	MissingBitlockerKeys.ps1
	===========================================================================
	.DESCRIPTION
		This script will query SCCM for a list of laptop systems. It will then
        query active directory for a list of bitlockered systems. The script 
        then compares the laptop list with the bitlockered systems list and
        generates an excel report of systems which do not have a bitlocker
        key stored in active directory. This can happen when a system is 
        manually encrypted. This script must be executed on the SCCM server
        in order for this to execute. It has to load the SCCM module, which
        can only be done from the server. The $OutputFile and $Path are used
        to specify where to save the excel report and what to name the file.

        In order for this script to function, you will need to have the 
        powershell command line active directory enabled. 
        
        This can be either run manually, or you can implement this to run
        from Orchestrator on a scheduled basis. I wrote the script so that
        if all bitlockered systems have the recovery key present in AD, then
        an excel report is not generated. Orchestrator looks for the excel
        spreadsheet. If it is not present, then it does nothing. If it is
        present, then it emails that spreadsheet to the appropriate 
        management.
#>

param
(
	[string]
	$OutputFile = 'MissingBitlockerKeys.csv',
	[string]
	$Path
)

function ProcessTextFile {
	If ((Test-Path -Path $OutputFile) -eq $true) {
		Remove-Item -Path $OutputFile -Force
	}
}


function Get-Laptops {
	#Declare Local Variables
	Set-Variable -Name Item -Scope Local -Force
	Set-Variable -Name QuerySystems -Scope Local -Force
	Set-Variable -Name Systems -Scope Local -Force
	Set-Variable -Name WQL -Scope Local -Force
	
	$QuerySystems = @()
	Set-Location BNA:
	$WQL = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System inner join SMS_G_System_SYSTEM_ENCLOSURE on SMS_G_System_SYSTEM_ENCLOSURE.ResourceId = SMS_R_System.ResourceId where SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "8" or SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "9" or SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "10" or SMS_G_System_SYSTEM_ENCLOSURE.ChassisTypes = "14"'
	$Systems = Get-WmiObject -Namespace Root\SMS\Site_BNA -Query $WQL
	Foreach ($Item in $Systems) {
		$QuerySystems = $QuerySystems + $Item.Name
	}
	Set-Location c:
	$QuerySystems = $QuerySystems | Sort-Object
    Return $QuerySystems
	
	#Cleanup Local Variables
	Remove-Variable -Name Item -Scope Local -Force
	Remove-Variable -Name QuerySystems -Scope Local -Force
	Remove-Variable -Name Systems -Scope Local -Force
	Remove-Variable -Name WQL -Scope Local -Force
}

Function Get-BitlockeredSystems {
    #Declare Local Variables
    Set-Variable -Name BitLockerObjects -Scope Local -Force
    Set-Variable -Name System -Scope Local -Force
    Set-Variable -Name Systems -Scope Local -Force

    $Usernames = @()
    $Systems = @()
    $BitLockerObjects = Get-ADObject -Filter { objectclass -eq 'msFVE-RecoveryInformation' }
    foreach ($System in $BitLockerObjects) {
        $System = $System.DistinguishedName
        $System = $System.Split(',')
        $System = $System[1]
        $System = $System.Split('=')
        $Systems = $Systems + $System[1]
    }
    Return $Systems

    #Cleanup Local Variables
    Remove-Variable -Name BitLockerObjects -Scope Local -Force
    Remove-Variable -Name System -Scope Local -Force
    Remove-Variable -Name Systems -Scope Local -Force
}

Function Confirm-Bitlockered {
	param ([String[]]$Laptops, [String[]]$BitlockeredSystems)

    #Declare Local Variables
    Set-Variable -Name Bitlockered -Scope Local -Force
    Set-Variable -Name HeaderRow -Scope Local -Force
    Set-Variable -Name Laptop -Scope Local -Force
    Set-Variable -Name System -Scope Local -Force
	
	foreach ($Laptop in $Laptops) {
        $Bitlockered = $false
        foreach ($System in $BitlockeredSystems) {
            If ($Laptop -eq $System) {
                $Bitlockered = $true
            }
        }
        If ($Bitlockered -eq $false) {
            If ((Test-Path $OutputFile) -eq $false) {
                $HeaderRow = "Computers"+[char]44+"Encrypted"+[char]44+"Recovery Key"
                Out-File -FilePath $OutputFile -InputObject $HeaderRow -Force -Encoding UTF8
            }
            Out-File -FilePath $OutputFile -InputObject $Laptop -Append -Force -Encoding UTF8
            Write-Host $Laptop
        }
	}

    #Cleanup Local Variables
    Remove-Variable -Name Bitlockered -Scope Local -Force
    Remove-Variable -Name HeaderRow -Scope Local -Force
    Remove-Variable -Name Laptop -Scope Local -Force
    Remove-Variable -Name System -Scope Local -Force
}

#Declare Local Variables
Set-Variable -Name BitlockeredSystems -Scope Local -Force
Set-Variable -Name Laptops -Scope Local -Force

cls
Import-Module ActiveDirectory -Scope Global -Force
Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" -Force -Scope Global
$OutputFile = $Path + "\" + $OutputFile
ProcessTextFile
$Laptops = Get-Laptops
$BitlockeredSystems = Get-BitlockeredSystems
Confirm-Bitlockered -Laptops $Laptops -BitlockeredSystems $BitlockeredSystems

#Cleanup Local Variables
Remove-Variable -Name BitlockeredSystems -Scope Local -Force
Remove-Variable -Name Laptops -Scope Local -Force
