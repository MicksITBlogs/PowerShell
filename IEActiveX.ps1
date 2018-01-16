<#
.SYNOPSIS
   Enable/Disable IE Active X Components
.DESCRIPTION
   
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   EnableIEActiveXControl "Application Name" "GUID" "Value"
   EnableIEActiveXControl "Flash for IE" "{D27CDB6E-AE6D-11CF-96B8-444553540000}" "0x00000000"
#>

#Declare Global Memory
Set-Variable -Name Errors -Value $null -Scope Global -Force
Set-Variable -Name LogFile -Value "c:\windows\waller\Logs\BuildLogs\AdobeFlashPlayer.log" -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force

Function ConsoleTitle ($Title){
	$host.ui.RawUI.WindowTitle = $Title
}

Function GetRelativePath { 
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
}

Function DisableIEActiveXControl ($AppName,$GUID,$Flag) {
	$Key = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\ActiveX Compatibility\"+$GUID
	If ((Test-Path $Key) -eq $true) {
		Write-Host $AppName"....." -NoNewline
		Set-ItemProperty -Path $Key -Name "Compatibility Flags" -Value $Flag -Force
		$Var = Get-ItemProperty -Path $Key -Name "Compatibility Flags"
		If ($Var."Compatibility Flags" -eq 1024) {
			Write-Host "Disabled" -ForegroundColor Yellow
		} else {
			Write-Host "Enabled" -ForegroundColor Red
		}
	}
}

Function EnableIEActiveXControl ($AppName,$GUID,$Flag) {
	$Key = "HKLM:\SOFTWARE\Microsoft\Internet Explorer\ActiveX Compatibility\"+$GUID
	If ((Test-Path $Key) -eq $true) {
		Write-Host $AppName"....." -NoNewline
		Set-ItemProperty -Path $Key -Name "Compatibility Flags" -Value $Flag -Force
		$Var = Get-ItemProperty -Path $Key -Name "Compatibility Flags"
		If ($Var."Compatibility Flags" -eq 0) {
			Write-Host "Enabled" -ForegroundColor Yellow
		} else {
			Write-Host "Disabled" -ForegroundColor Red
		}
	}
}

cls
#DisableIEActiveXControl "Flash for IE" "{D27CDB6E-AE6D-11CF-96B8-444553540000}" "0x00000400"
EnableIEActiveXControl "Flash for IE" "{D27CDB6E-AE6D-11CF-96B8-444553540000}" "0x00000000"
Start-Sleep -Seconds 5
