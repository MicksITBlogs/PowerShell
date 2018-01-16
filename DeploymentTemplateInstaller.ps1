<#
.SYNOPSIS
   <Application Name>
.DESCRIPTION
   <What does the script do?>
.EXAMPLE
   powershell.exe -executionpolicy bypass -file install.ps1
#>


#Declare Global Memory
$GlobalVariables = @("Architecture","BuildLog","Errors","LogFile","OSVersion","Phase","RelativePath","Sequence","Title")

Function InitializeVariables {
	$Global:BuildLog = $Env:windir+"\Logs\BuildLogs\Build.csv"
	$Global:Errors = $null
	$Global:LogFile = $Env:windir+"\Logs\BuildLogs\<ApplicationName>.log"
	$Global:Phase = "<Base Build, Final Build, Software Deployment>"
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
	$Global:Sequence = "<Build Sequence Number>"
	$Global:Title = "<PowerShell Window Title>"
}

cls
Import-Module -Name Deployment
Set-Variables -variable $GlobalVariables -Scope Global
InitializeVariables
Set-ConsoleTitle -Title $Global:Title
New-LogFile
Get-Architecture
Get-OSVersion
#<Insert Functions to install/uninstall applications>
Write-LogFile
Exit-PowerShell
Remove-Variables -Variables $GlobalVariables -Scope Global
Remove-Module -Name Deployment -Force

