<#
.SYNOPSIS
   ValidateSystems
.DESCRIPTION
   Validate if a system still exists
.Author
   Mick Pletcher
.Date
   26 February 2015
.EXAMPLE
   powershell.exe -executionpolicy bypass -file ValidateSystems.ps1
#>

Function InitializeGlobalMemory {
	Set-Variable -Name Computers -Scope Global -Force
	Set-Variable -Name Logfile -Scope Global -Force
	Set-Variable -Name RelativePath -Scope Global -Force
	Set-Variable -Name Webroot -Scope Global -Force
	$Global:Failures = @()
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
	$Global:LogFile = $Global:RelativePath + "Output.csv"
	$Global:Computers = Get-Content -Path $Global:RelativePath"SCCMSystems.txt" -Force
	$Global:Webroot = Get-Content -Path $Global:RelativePath"AntivirusSystems.txt" -Force

}

Function ProcessLogFile {
	If ((Test-Path $Global:LogFile) -eq $true) {
		Remove-Item $Global:LogFile -Force
	}
	If ((Test-Path $Global:LogFile) -eq $false) {
		$temp = New-Item $Global:LogFile -ItemType File -Force
		$Output = ","+"Deletions"+","+","+","+"Additions"
		Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force -Encoding UTF8
		$Output = "Computer Name"+","+"Active Directory"+","+"SCCM"+","+"Antivirus"+","+"Antivirus"
		Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force -Encoding UTF8
	}
}

Function ProcessComputers {
	$obj = New-Object PSObject
	$Count = 0
	Foreach ($Computer in $Global:Computers) {
		cls
		$Antivirus = $false
		$Count += 1
		Write-Host "Processing "$Count" of " -NoNewline
		Write-Host $Global:Computers.Count
		Write-Host
		Write-Host "Computer Name: "$Computer
		$ADAccount = $null
		#Active Directory
		Write-Host "Testing AD Presence....." -NoNewline
		$ErrorActionPreference = 'SilentlyContinue'
		$ADAccount = Get-ADComputer $Computer
		If ($ADAccount -eq $null) {
			$ADAccount = $false
			Write-Host "Does not Exist" -ForegroundColor Red
		} else {
			$ADAccount = $true
			Write-Host "Exists" -ForegroundColor Yellow
		}
		#Antivirus
		Write-Host "Testing Antivirus....." -NoNewline
		Foreach ($system in $Global:Webroot) {
			If ($system -eq $Computer) {
				$Antivirus = $true
			}
		}
		If ($Antivirus -eq $true) {
			Write-Host "Exists" -ForegroundColor Yellow
		} else {
			Write-Host "Does not exist" -ForegroundColor Red
		}
		#Network Connectivity
		Write-Host "Testing Network Connectivity....." -NoNewline
		If ((Test-Connection -ComputerName $Computer -Quiet) -eq $false) {
			$NetworkTest = ping $Computer
			If ($NetworkTest -like '*Ping request could not find host*') {
				$NetworkTest = $false
				Write-Host "Does not exist" -ForegroundColor Red
			} else {
				$NetworkTest = $true
				Write-Host "Exists" -ForegroundColor Yellow
			}
		} else {
			$NetworkTest = $true
			Write-Host "Exists" -ForegroundColor Yellow
		}
		If (($ADAccount -eq $true) -and ($NetworkTest -eq $false)) {
			#Write-Host $Computer -NoNewline
			#Write-Host " - Delete from AD and SCCM" -BackgroundColor Yellow -ForegroundColor Black
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer
			If ($Antivirus -eq $true) {
				$obj | Add-Member -MemberType NoteProperty -Name Action -Value "AD_SCCM_Antivirus"
			} else {
				$obj | Add-Member -MemberType NoteProperty -Name Action -Value "AD_SCCM"
			}
		}
		If (($ADAccount -eq $false) -and ($NetworkTest -eq $false)) {
			#Write-Host $Computer -NoNewline
			#Write-Host " - Delete from SCCM" -BackgroundColor Green -ForegroundColor Black
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer
			If ($Antivirus -eq $true) {
				$obj | Add-Member -MemberType NoteProperty -Name Action -Value "SCCM_Antivirus"
			} else {
				$obj | Add-Member -MemberType NoteProperty -Name Action -Value "SCCM"
			}
		}
		If (($ADAccount -eq $true) -and ($NetworkTest -eq $true) -and ($Antivirus -eq $false)) {
			$obj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer
			$obj | Add-Member -MemberType NoteProperty -Name Action -Value "AddAntivirus"
		}
		If ($obj -ne $null) {
			$Global:Failures += $obj
			$Output = $obj.ComputerName
			If ($obj.Action -eq "AD_SCCM") {
				$Output = $Output + ","+"X"+","+"X" 
			}
			If ($obj.Action -eq "AD_SCCM_Antivirus") {
				$Output = $Output + ","+"X"+","+"X"+","+"X"
			}
			If ($obj.Action -eq "SCCM") {
				$Output = $Output + ","+","+"X"
			}
			If ($obj.Action -eq "SCCM_Antivirus") {
				$Output = $Output + ","+","+"X"+","+"X"
			}
			If ($obj.Action -eq "AddAntivirus") {
				$Output = $Output + ","+","+","+","+"X"
			}
			Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force -Encoding UTF8
			Remove-Variable -Name obj
			$obj = New-Object PSObject
		}
		Start-Sleep -Seconds 1
	}
}

Function WriteToScreen {
	cls
	Foreach ($Failure in $Global:Failures) {
		If ($Failure -ne $null) {
			Write-Output $Failure
		}
	}
	$ErrorActionPreference = 'Continue'
}

cls
Import-Module -Name ActiveDirectory
InitializeGlobalMemory
ProcessLogFile
ProcessComputers
WriteToScreen
