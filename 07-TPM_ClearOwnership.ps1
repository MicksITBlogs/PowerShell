<#
.SYNOPSIS
   Dell Client Configuration Toolkit
.DESCRIPTION
   Turn TPM On
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>


#Declare Global Memory
Set-Variable -Name BuildLog -Scope Global -Force
Set-Variable -Name Errors -Value $null -Scope Global -Force
Set-Variable -Name LogFile -Scope Global -Force
Set-Variable -Name Phase -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force
Set-Variable -Name Sequence -Scope Global -Force
Set-Variable -Name Title -Scope Global -Force

Function ConsoleTitle ($Title){
	$host.ui.RawUI.WindowTitle = $Title
}

Function DeclareGlobalVariables {
	$Global:BuildLog = $Env:windir+"\Logs\BuildLogs\Build.csv"
	$Global:LogFile = $Env:windir+"\Logs\BuildLogs\TPM_On.log"
	$Global:Phase = "Final Build"
	$Global:Sequence = ""
	$Global:Title = "TPM Clear Ownership"
}

Function GetRelativePath { 
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
}

Function ClearTPM {
	#Declare Local Memory
	Set-Variable -Name ClassName -Value "Win32_Tpm" -Scope Local -Force
	Set-Variable -Name Computer -Value $env:COMPUTERNAME -Scope Local -Force
	Set-Variable -Name NameSpace -Value "ROOT\CIMV2\Security\MicrosoftTpm" -Scope Local -Force
	Set-Variable -Name oTPM -Scope Local -Force
	
	$oTPM = Get-WmiObject -Class $ClassName -ComputerName $Computer -Namespace $NameSpace
	$Output = "Clearing TPM Ownership....."
	Write-Host "Clearing TPM Ownership....." -NoNewline
	$Temp = $oTPM.SetPhysicalPresenceRequest(5)
	If ($Temp.ReturnValue -eq 0) {
		$Output = "Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = "Failure"
		Write-Host "Failure" -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force

	#Cleanup Local Memory
	Remove-Variable -Name oTPM -Scope Local -Force
}

Function ProcessLogFile {
	If ((Test-Path $Env:windir"\Logs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\Logs"
	}
	If ((Test-Path $Env:windir"\Logs\ApplicationLogs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\Logs\ApplicationLogs"
	}
	If ((Test-Path $Env:windir"\Logs\BuildLogs") -eq $false) {
		New-Item -ItemType Directory -Path $Env:windir"\Logs\BuildLogs"
	}
	If ($Global:Errors -eq $null) {
		If (Test-Path $Global:LogFile) {
			Remove-Item $Global:LogFile -Force
		}
		$File1 = $Global:LogFile.Split(".")
		$Filename1 = $File1[0]+"_ERROR"+"."+$File1[1]
		If (Test-Path $Filename1) {
			Remove-Item $Filename1 -Force
		}
		$Global:Errors = 0
	} elseIf ($Global:Errors -ne 0) {
		If (Test-Path $Global:LogFile) {
			$Global:LogFile.ToString()
			$File1 = $Global:LogFile.Split(".")
			$Filename1 = $File1[0]+"_ERROR"+"."+$File1[1]
			Rename-Item $Global:LogFile -NewName $Filename1 -Force
		}
	} else {
		$date = get-date
		$LogTitle = $Global:Phase+[char]9+$Global:Sequence+[char]9+$Global:Title+[char]9+$date.month+"/"+$date.day+"/"+$date.year+" "+$date.hour+":"+$date.minute
		Out-File -FilePath $Global:BuildLog -InputObject $LogTitle -Append -Force
	}
}

Function ExitPowerShell {
	If (($Global:Errors -ne $null) -and ($Global:Errors -ne 0)) {
		Exit 1
	}
}

cls
GetRelativePath
DeclareGlobalVariables
ConsoleTitle $Global:Title
ProcessLogFile
ClearTPM
ProcessLogFile
Start-Sleep -Seconds 5
ExitPowerShell


