#*******************************************************************************
#      Author: Mick Pletcher
#        Date: 12 June 2013
#
#     Program: Add/Remove Programs
# Description: This script will either list all applications in the Add/Remove
#              programs, which is pulled from both the registry. On a 64-bit
#              machine, it pulls from both the x86 and x64 add/remove programs
#              registry entries. You will also have the option to search for
#              a specific application. 
#*******************************************************************************

cls
$Global:OS

Function GetOSArchitecture{
	$Global:OS=Get-WMIObject win32_operatingsystem
	#$Global:OS.OSArchitecture
	#Answers: 32-bit, 64-bit
}

$DisplayOutput = $false
GetOSArchitecture
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$Output = [System.Windows.Forms.MessageBox]::Show("Search for a specific program?" , "Status" , 4)
If ($Output -eq "Yes"){
	$ProgramName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter specific software name:")
	$ProgramName = "*"+$ProgramName+"*"
}
If ($Global:OS.OSArchitecture -eq "32-bit"){
	$RegPath = "HKLM:\software\microsoft\windows\currentversion\uninstall\"
	$Results = Get-ChildItem $RegPath -Recurse -ErrorAction SilentlyContinue
	foreach ($item in $Resultsx86){
		If (($item.GetValue("DisplayName") -ne $null) -and ($item.GetValue("UninstallString") -ne $null)) {
			Write-Host
			Write-Host
    		Write-Host "   Software: "$item.GetValue("DisplayName")
			Write-Host "    Version: "$item.GetValue("DisplayVersion")
    		Write-Host "Uninstaller: "$item.GetValue("UninstallString")
		}
	}
}
If ($Global:OS.OSArchitecture -eq "64-bit"){
	$RegPathx86 = "HKLM:\software\wow6432node\microsoft\windows\currentversion\uninstall\"
	$RegPathx64 = "HKLM:\software\microsoft\windows\currentversion\uninstall\"
	$Resultsx86 = Get-ChildItem $RegPathx86 -Recurse -ErrorAction SilentlyContinue
	$Resultsx64 = Get-ChildItem $RegPathx64 -Recurse -ErrorAction SilentlyContinue
	foreach ($item in $Resultsx86){
		If (($item.GetValue("DisplayName") -ne $null) -and ($item.GetValue("UninstallString") -ne $null)) {
			If ($Output -eq "Yes"){
				If ($item.GetValue("DisplayName") -like $ProgramName){
					$DisplayOutput = $true
				}
			}else{
				$DisplayOutput = $true
			}
			If ($DisplayOutput -eq $true){
				Write-Host
				Write-Host
    			Write-Host "   Software: "$item.GetValue("DisplayName")
				Write-Host "    Version: "$item.GetValue("DisplayVersion")
    			Write-Host "Uninstaller: "$item.GetValue("UninstallString")
			}
		}
		$DisplayOutput = $false
	}
	$DisplayOutput = $false
	foreach ($item in $Resultsx64){
		If (($item.GetValue("DisplayName") -ne $null) -and ($item.GetValue("UninstallString") -ne $null)) {
			If ($Output -eq "Yes"){
				If ($item.GetValue("DisplayName") -like $ProgramName){
					$DisplayOutput = $true
				}
			}else{
				$DisplayOutput = $true
			}
			If ($DisplayOutput -eq $true){
				Write-Host
				Write-Host
    			Write-Host "   Software: "$item.GetValue("DisplayName")
				Write-Host "    Version: "$item.GetValue("DisplayVersion")
    			Write-Host "Uninstaller: "$item.GetValue("UninstallString")
			}
		}
		$DisplayOutput = $false
	}
}