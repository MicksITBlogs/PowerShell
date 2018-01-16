<#
.SYNOPSIS
   Restart the Computer
.DESCRIPTION
   This script creates a temporary log file to be updated by the VerifyReboot.ps1 script. It then
   reboots the machine.
.Author
   Mick Pletcher
.Date
   03 October 2014
#>

#Declare Global Memory
Set-Variable -Name FileName -Scope Global -Force
Set-Variable -Name Log -Scope Global -Force

Function DeleteLogFiles {

	#Declare Local Memory
	Set-Variable Count -Scope Local -Force
	Set-Variable Files -Scope Local -Force
	Set-Variable i -Scope Local -Force
	$Months = @("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec")
	
	$Files = Get-ChildItem $Global:Log -Filter "*.log"
	$Count = $Files.Count
	If ($Count -ne 0) {
		For ($i=0; $i -le $Count; $i++) {
			For ($j=0; $j -le $Months.Count; $j++) {
				$Month = "-"+$Months[$j]+"-"
				$a = $Files[$i] -match $Month
				If ($a -eq $true) {
					$File = $Global:Log + "\" + $Files[$i]
					If (Test-Path $File) {
						Remove-Item -Path $File -Force
					}
				}
			}
		}
	}
	$File = $Global:Log + "\NotRebooted.log"
	If (Test-Path $File) {
		Remove-Item -Path $File -Force
	}
	
	#Cleanup Local Memory
	Remove-Variable Count -Scope Local -Force
	Remove-Variable Files -Scope Local -Force
	Remove-Variable i -Scope Local -Force
}

Function NewLogFile {

	$FileName = "NotRebooted.log"
	$Log = $Env:windir + "\Logs"
	New-Item -Path $Log -Name $FileName -ItemType File -Force

}

cls
DeleteLogFiles
NewLogFile
Restart-Computer -ComputerName localhost -Force
