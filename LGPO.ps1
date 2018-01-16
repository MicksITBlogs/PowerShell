<#
.SYNOPSIS
   Apply Local Group Policy
.Author
   Mick Pletcher
.Date
   23 February 2015
.EXAMPLE
   powershell.exe -executionpolicy bypass -file LGPO.ps1
#>


Function Import-LGPO {

	Param([String]$LGPOName, [String]$LGPOLocation, [String]$GPOType)
	
	$Executable = $Global:RelativePath+"ImportRegPol.exe"
	If ($GPOType -eq "Machine") {
		$GPOType = "\DomainSysvol\GPO\Machine\registry.pol"
	} else {
		$GPOType = "\DomainSysvol\GPO\User\registry.pol"
	}
	$Parameters = "-m "+[char]34+$LGPOLocation+$GPOType+[char]34
	Write-Host "Apply Local"$LGPOName" Policy....." -NoNewline
	$ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} else {
		Write-Host "Failed with error code "$ErrCode -ForegroundColor Red
	}

}

cls
$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
Import-LGPO -LGPOName "User Friendly Name" -LGPOLocation "<Path_To_GPO_GUID>" -GPOType "Machine"
Start-Sleep -Seconds 5

