Function GetRelativePath {
	$Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
}

Function GetPrinterList {

	#Declare Local Memory
	Set-Variable -Name Count -Scope Local -Force
	Set-Variable -Name DefaultPrinter -Scope Local -Force
	Set-Variable -Name Printers -Scope Local -Force
	Set-Variable -Name Temp -Scope Local -Force
	
	If (Test-Path -Path $Global:RelativePath"Printers.txt") {
		Remove-Item -Path $Global:RelativePath"Printers.txt" -Force
	}
	$DefaultPrinter = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true"
	$DefaultPrinter = $DefaultPrinter.ToString()
	$DefaultPrinter = $DefaultPrinter -replace [char]34,""
	$DefaultPrinter = $DefaultPrinter -replace "\\\\","\"
	$DefaultPrinter = $DefaultPrinter.split("=")
	$Temp = "Default Printer: "+$DefaultPrinter[$DefaultPrinter.Length-1]
	$Temp | Add-Content -Path $Global:RelativePath"Printers.txt"
	$Printers = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$false"
	For ($Count=0; $Count -lt $Printers.Length; $Count++) {
		$Temp = $Printers[$Count]
		$Temp = $Temp.ToString()
		$Temp = $Temp -replace [char]34,""
		$Temp = $Temp -replace "\\\\","\"
		$Temp = $Temp.split("=")
		$Temp = "Printer: "+$Temp[1]
		$Temp | Add-Content -Path $Global:RelativePath"Printers.txt"
		Write-Host $Temp
	}
	
	#Cleanup Local Memory
	Remove-Variable -Name Count -Scope Local -Force
	Remove-Variable -Name DefaultPrinter -Scope Local -Force
	Remove-Variable -Name Printers -Scope Local -Force
	Remove-Variable -Name Temp -Scope Local -Force
	
}
GetRelativePath
GetPrinterList
