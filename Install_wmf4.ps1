<#
.Author
	Mick Pletcher
.Date
	29 July 2014
.SYNOPSIS
   Windows Management Framework 4.0
.EXAMPLE
	powershell.exe -executionpolicy bypass -file install_WMF4.ps1
#>

#Declare Global Memory
Set-Variable -Name Errors -Value $null -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force
Set-Variable -Name Title -Scope Global -Force

Function ConsoleTitle ($Title){
	$host.ui.RawUI.WindowTitle = $Title
}

Function DeclareGlobalVariables {
	$Global:Title = "Windows Management Framework 4.0"
}

Function GetRelativePath { 
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
}

Function InstallMSU ($ProgName,$MSU,$Switches) {
	$EXE = $Env:windir+"\system32\wusa.exe"
	$Parameters = [char]34+$MSU+[char]34+[char]32+$Switches
	Write-Host "Install "$ProgName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} elseif ($ErrCode -eq 2359302) {
		Write-Host "Already Installed" -ForegroundColor Green
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
		$Global:Errors++
	}
}

Function ExitPowerShell {
	If (($Global:Errors -ne $null) -and ($Global:Errors -ne 0)) {
		Exit 1
	}
}

cls
DeclareGlobalVariables
GetRelativePath
ConsoleTitle $Global:Title
InstallMSU "Windows Management Framework 4.0" $Global:RelativePath"Windows6.1-KB2819745-x86-MultiPkg.msu" "/quiet /norestart"
Start-Sleep -Seconds 5
ExitPowerShell
