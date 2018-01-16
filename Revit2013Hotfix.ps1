#*******************************************************************************
#      Author: Mick Pletcher
#        Date: 12 June 2013
#
#     Program: Revit 2013 Hotfix
#*******************************************************************************

Clear-Host
$Global:OS
$Global:RelativePath
$FileLoc = "C:\Program Files\Autodesk\Revit 2013\Program\"
$DLL_01 = "RS.Common.ClientServer.Proxy"
$DLL_02 = "DataStorageClient"
$DLL_03 = "DesktopMFC"
$DLL_04 = "FamilyDB"
$DLL_05 = "GeomUtil"
$DLL_06 = "Graphics"
$DLL_07 = "GrphOGS3"
$DLL_08 = "CommandServiceClient"
$DLL_09 = "RS.Common.ClientServer.Proxy"

Function GetRelativePath{
	$Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
	Write-Host $Global:RelativePath
}

Function GetOSArchitecture{
	$Global:OS=Get-WMIObject win32_operatingsystem
	#$Global:OS.OSArchitecture
	#Answers: 32-bit, 64-bit
}

GetRelativePath
GetOSArchitecture
If ($Global:OS.OSArchitecture -eq "64-bit"){
	If ((Test-Path -Path $FileLoc$DLL_01".dll") -eq $true){
		Copy-Item -Path $FileLoc$DLL_01".dll" -Destination $FileLoc$DLL_01".orig" -Force
		Remove-Item -Path $FileLoc$DLL_01".dll" -Force
		Copy-Item -Path $Global:RelativePath$DLL_01".dll" -Destination $FileLoc -Force
	}
	If ((Test-Path -Path $FileLoc$DLL_02".dll") -eq $true){
		Copy-Item -Path $FileLoc$DLL_02".dll" -Destination $FileLoc$DLL_02".orig" -Force
		Remove-Item -Path $FileLoc$DLL_02".dll" -Force
		Copy-Item -Path $Global:RelativePath$DLL_02".dll" -Destination $FileLoc -Force
	}
	If ((Test-Path -Path $FileLoc$DLL_03".dll") -eq $true){
		Copy-Item -Path $FileLoc$DLL_03".dll" -Destination $FileLoc$DLL_03".orig" -Force
		Remove-Item -Path $FileLoc$DLL_03".dll" -Force
		Copy-Item -Path $Global:RelativePath$DLL_03".dll" -Destination $FileLoc -Force
	}
	If ((Test-Path -Path $FileLoc$DLL_04".dll") -eq $true){
		Copy-Item -Path $FileLoc$DLL_04".dll" -Destination $FileLoc$DLL_04".orig" -Force
		Remove-Item -Path $FileLoc$DLL_04".dll" -Force
		Copy-Item -Path $Global:RelativePath$DLL_04".dll" -Destination $FileLoc -Force
	}
	If ((Test-Path -Path $FileLoc$DLL_05".dll") -eq $true){
		Copy-Item -Path $FileLoc$DLL_05".dll" -Destination $FileLoc$DLL_05".orig" -Force
		Remove-Item -Path $FileLoc$DLL_05".dll" -Force
		Copy-Item -Path $Global:RelativePath$DLL_05".dll" -Destination $FileLoc -Force
	}
	If ((Test-Path -Path $FileLoc$DLL_06".dll") -eq $true){
		Copy-Item -Path $FileLoc$DLL_06".dll" -Destination $FileLoc$DLL_06".orig" -Force
		Remove-Item -Path $FileLoc$DLL_06".dll" -Force
		Copy-Item -Path $Global:RelativePath$DLL_06".dll" -Destination $FileLoc -Force
	}
	If ((Test-Path -Path $FileLoc$DLL_07".dll") -eq $true){
		Copy-Item -Path $FileLoc$DLL_07".dll" -Destination $FileLoc$DLL_07".orig" -Force
		Remove-Item -Path $FileLoc$DLL_07".dll" -Force
		Copy-Item -Path $Global:RelativePath$DLL_07".dll" -Destination $FileLoc -Force
	}
	If ((Test-Path -Path $FileLoc"RevitServerToolCommand\"$DLL_08".dll") -eq $true){
		Copy-Item -Path $FileLoc"RevitServerToolCommand\"$DLL_08".dll" -Destination $FileLoc"RevitServerToolCommand\"$DLL_08".orig" -Force
		Remove-Item -Path $FileLoc"RevitServerToolCommand\"$DLL_08".dll" -Force
		Copy-Item -Path $Global:RelativePath"RevitServerToolCommand\"$DLL_08".dll" -Destination $FileLoc"RevitServerToolCommand\" -Force
	}
	If ((Test-Path -Path $FileLoc"RevitServerToolCommand\"$DLL_09".dll") -eq $true){
		Copy-Item -Path $FileLoc"RevitServerToolCommand\"$DLL_09".dll" -Destination $FileLoc"RevitServerToolCommand\"$DLL_09".orig" -Force
		Remove-Item -Path $FileLoc"RevitServerToolCommand\"$DLL_09".dll" -Force
		Copy-Item -Path $Global:RelativePath"RevitServerToolCommand\"$DLL_09".dll" -Destination $FileLoc"RevitServerToolCommand\" -Force
	}
}
Remove-Variable -Name DLL_01
Remove-Variable -Name DLL_02
Remove-Variable -Name DLL_03
Remove-Variable -Name DLL_04
Remove-Variable -Name DLL_05
Remove-Variable -Name DLL_06
Remove-Variable -Name DLL_07
Remove-Variable -Name DLL_08
Remove-Variable -Name DLL_09
Remove-Variable -Name FileLoc
Remove-Variable -Name OS
Remove-Variable -Name RelativePath
