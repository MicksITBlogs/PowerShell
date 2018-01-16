<#
.SYNOPSIS
   Produce list of newly installed windows updates
.DESCRIPTION
   Reads BDD.log file from a build and extracts the list of new updates
   that were applied.
.Author
   Mick Pletcher
.Date
   12 February 2015
.EXAMPLE
   powershell.exe -executionpolicy bypass -file UpdateList.ps1
#>

cls
$File = Get-Content -Path "C:\Users\Mick\Desktop\BDD.log" -Force
Foreach ($Entry in $File) {
	If (($Entry -like '*INSTALL - *') -and ($Entry -like '*ZTIWindowsUpdate*')) {
		#Write-Host $Entry
		$SplitLine = $Entry.Split('KB')
		$Update = $SplitLine[2]
		$Update = $Update.Split(')')
		$Update = $Update.Split('(')
		Write-Host "KB"$Update[0]
	}
}

Remove-Variable -Name Entry -Force
Remove-Variable -Name File -Force
Remove-Variable -Name Update -Force