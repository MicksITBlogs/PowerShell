<#
.SYNOPSIS
   Verify Reboot Occurred
.DESCRIPTION
   This script verifies the reboot occurred by searching for the file NotRebooted.log
   and renaming it to Rebooted--dd-MMM-YYYY.log. 
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>

#Declare Variables
Set-Variable -Name Now -Force
Set-Variable -Name Log -Force

$Log = $Env:windir + "\Logs"
$File = $Log + "\" + "NotRebooted.log"
If (Test-Path $File) {
	$Now = Get-Date -Format "dd-MMM-yyyy"
	$Now = $Now + ".log"
	If (Test-Path -Path $File) {
		Remove-Item $File -Force
		$File = $Log + "\Rebooted---" + $Now
		New-Item $File -ItemType File -Force
	}
}
