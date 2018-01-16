<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.92
	 Created on:   	8/21/2015 1:33 PM
	 Created by:   	Mick Pletcher
	 Filename:     	LicensedSoftwareVerification.ps1
	===========================================================================
	.DESCRIPTION
		This script will query SCCM for all systems with a specified 
		software installed. It will then grab all system within a specified
		collection to compare the query with. The collection is the 
		definitive place where all necessary systems are placed that 
		require the licensed software. Any systems the query sees that are
		not in the collection will be added to the excel report for further
		investigation. If the system is valid, it should then be added to
		the collection.
#>

param
(
	[string]
	$OutputFile = 'AdobeAcrobatReport.csv',
	[string]
	$Path
)

function ProcessTextFile {
	If ((Test-Path -Path $OutputFile) -eq $true) {
		Remove-Item -Path $OutputFile -Force
	}
}

function Get-CollectionSystems {
    Param([string]$CollectionID)

	#Declare Local Variables
	Set-Variable -Name System -Scope Local -Force
	Set-Variable -Name SystemArray -Scope Local -Force
	Set-Variable -Name Systems -Scope Local -Force
	
    $SystemArray = @()
	$Systems = get-cmdevice -collectionid $CollectionID | select name | Sort-Object Name
    Foreach ($System in $Systems) {
        $SystemArray = $SystemArray + $System.Name
    }
	Return $SystemArray
	
	#Cleanup Local Variables
	Remove-Variable -Name System -Scope Local -Force
	Remove-Variable -Name SystemArray -Scope Local -Force
	Remove-Variable -Name Systems -Scope Local -Force
}


cls
Import-Module "D:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1" -Force -Scope Global
Set-Location SCCMSiteCode:
$CollectionSystems = @()
$QuerySystems = @()
$UnlicensedSystems = @()
#Input the SCCM query code for the $WQL variable
$WQL = 'select *  from  SMS_R_System inner join SMS_G_System_ADD_REMOVE_PROGRAMS on SMS_G_System_ADD_REMOVE_PROGRAMS.ResourceID = SMS_R_System.ResourceId where SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat 8 Professional" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat X Pro - English, Français, Deutsch" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat X Standard - English, Français, Deutsch" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat XI Pro" or SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName = "Adobe Acrobat XI Standard"'
$WMI = Get-WmiObject -Namespace Root\SMS\Site_BNA -Query $WQL
#Use the collectionID of the collection you use as the definitive licensing site
$CollectionSystems = Get-CollectionSystems -CollectionID "SCCM00024"
Set-Location c:
$OutputFile = $Path + "\" + $OutputFile
ProcessTextFile
$Output = "Computer Name"
Out-File -FilePath $OutputFile -InputObject $Output -Force -Encoding UTF8
Foreach ($Item in $WMI) {
	$QuerySystems = $QuerySystems + $Item.SMS_R_System.Name
}
Foreach ($QuerySystem in $QuerySystems) {
    $SystemVerified = $false
    Foreach ($CollectionSystem in $CollectionSystems) {
        If ($QuerySystem -eq $CollectionSystem) {
            $SystemVerified = $true
        }
    }
    If ($SystemVerified -eq $false) {
        Out-File -FilePath $OutputFile -InputObject $QuerySystem -Force -Encoding UTF8
    }
}