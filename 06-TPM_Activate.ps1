<#
.SYNOPSIS
   Dell Client Configuration Toolkit
.DESCRIPTION
   Installs CCTK
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>


#Declare Global Memory
Set-Variable -Name BuildLog -Scope Global -Force
Set-Variable -Name Errors -Value $null -Scope Global -Force
Set-Variable -Name IsDesktop -Value $false -Scope Global -Force
Set-Variable -Name IsLaptop -Value $false -Scope Global -Force
Set-Variable -Name LogFile -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force
Set-Variable -Name Sequence -Scope Global -Force
Set-Variable -Name Title -Scope Global -Force

Function ConsoleTitle ($Title){
	$host.ui.RawUI.WindowTitle = $Title
}

Function DeclareGlobalVariables {
	$Global:BuildLog = $Env:windir+"\Logs\BuildLogs\Build.log"
	$Global:LogFile = $Env:windir+"\Logs\BuildLogs\TPM_Activate.log"
	$Global:Sequence = ""
	$Global:Title = "TPM Activate"
}

Function GetRelativePath { 
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
}

Function GetPlatform {
	if(Get-WmiObject -Class win32_battery -ComputerName "localhost") {
		$Global:IsLaptop = $true
	} else {
		$Global:IsDesktop = $true
	}
}

Function InstallCCTK {
	$MSI = "/i "+[char]34+$Global:RelativePath+"cctk.msi"+[char]34
	$Switches = [char]32+"/qb- /norestart /lvx C:\Windows\logs\ApplicationLogs\CCTK.log"
	$Argument = $MSI+$Switches
	$Output = "Install CCTK....."
	Write-Host "Install CCTK....." -NoNewline
	$ErrCode = (Start-Process -FilePath msiexec.exe -ArgumentList $Argument -Wait -Passthru).ExitCode
	If ($ErrCode -eq 0) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function UninstallMSI ($ProgName,$GUID) {
	$EXE = $Env:windir+"\system32\msiexec.exe"
	$Switches = [char]32+"/qb- /norestart"
	$Parameters = "/x "+$GUID+$Switches
	$Output = "Uninstall"+$ProgName+"....."
	Write-Host "Uninstall"$ProgName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} elseIf ($ErrCode -eq 1605) {
		$Output = $Output+"Not Present"
		Write-Host "Not Present" -ForegroundColor Green
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
}

Function InstallMSI ($ProgName,$MSI,$Switches) {
	$EXE = $Env:windir+"\system32\msiexec.exe"
	$Parameters = "/i "+[char]34+$MSI+[char]34+[char]32+$Switches
	$Output = "Install"+$ProgName+"....."
	Write-Host "Install"$ProgName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		$Output = $Output+"Success"
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		$Output = $Output+"Failed with error code "+$ErrCode
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
	Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force
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
		$LogTitle = $Global:Sequence+" - "+$Global:Title
		Out-File -FilePath $Global:BuildLog -InputObject $LogTitle -Append -Force
	}
}

cls
GetRelativePath
DeclareGlobalVariables
GetPlatform
ConsoleTitle $Global:Title
ProcessLogFile
#Activate TPM
CCTKSetting "TPM Activation" "tpmactivation" "activate --valsetuppwd=<Password>" ""
ProcessLogFile
Start-Sleep -Seconds 5
