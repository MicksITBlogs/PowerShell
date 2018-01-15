<#
.SYNOPSIS
   Dell Client Configuration Toolkit
.DESCRIPTION
   PPI Deprovision
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
	$Global:Title = "PPI Provision"
}

Function GetRelativePath { 
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
}

Function CCTKSetting ($Name,$Option,$Setting,$Drives) {
	$EXE = $Env:PROGRAMFILES+"\Dell\CCTK\X86\cctk.exe"
	If ($Option -ne "bootorder") {
		$Argument = "--"+$Option+"="+$Setting
	} else {
		$Argument = "bootorder"+[char]32+"--"+$Setting+"="+$Drives
	}
	$Output = $Name+"....."
	Write-Host $Name"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Argument -Wait -Passthru).ExitCode
	If ($ErrCode -eq 0) {
		If ($Drives -eq "") {
			$Output = $Output+"Success"
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			$Output = $Output+$Drives
			Write-Host $Drives -ForegroundColor Yellow
		}
	} elseIf ($ErrCode -eq 119) {
		$Output = $Output+"Unavailable"
		Write-Host "Unavailable" -ForegroundColor Green
	} elseIf ($ErrCode -eq 241) {
		$Output = $Output+"No Password"
		Write-Host "No Password" -ForegroundColor Green
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
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
#Turn On TPM
CCTKSetting "TPM PPI Deprovision" "tpmppidpo" "enable --valsetuppwd=<Password>" ""
ProcessLogFile
Start-Sleep -Seconds 5
ExitPowerShell
