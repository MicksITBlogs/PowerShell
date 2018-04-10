function Uninstall-InnoSetup {
<#
	.SYNOPSIS
		Uninstall Inno Installed Application
	
	.DESCRIPTION
		This function uninstalls an application that was installed using the Inno installer.
	
	.PARAMETER AppName
		Exact name as shown in Add/Remove Programs	
#>
	
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()][string]$AppName
	)
	
	$QuietUninstallString = ((Get-ChildItem -Path "REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\","REGISTRY::HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" | ForEach-Object { Get-ItemProperty REGISTRY::$_ } | Where-Object { $_.DisplayName -eq $AppName }).QuietUninstallString).split("/")
	$Switches = "/" + $QuietUninstallString[1].Trim()
	Write-Host "Uninstall"$AppName"....." -NoNewline
	$ErrCode = (Start-Process -FilePath $QuietUninstallString[0].Trim() -ArgumentList $Switches -Wait -Passthru).ExitCode
	If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {
		Write-Host "Success" -ForegroundColor Yellow
	} elseif ($ErrCode -eq 1605) {
		Write-Host "Not Present" -ForegroundColor Green
	} else {
		Write-Host "Failed with Error Code:"$ErrCode
		Exit $ErrCode
	}
}
