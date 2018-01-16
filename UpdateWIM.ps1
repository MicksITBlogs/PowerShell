Clear-Host
$Global:MountPath
$Global:RelativePath
$Global:WimFile
$Global:UpdatesPath

Function GetRelativePath{
	$Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
	Write-Host $Global:RelativePath
}

Function GetWimFile{

	$FileName = Get-ChildItem $Global:RelativePath | Where-Object {($_.Name -like "*.wim")}
	$Global:WimFile = $Global:RelativePath+$FileName
	Write-Host $Global:WimFile

}

Function MountWIM{

	$Global:MountPath = $Global:RelativePath+"Mount\"
	If ((Test-Path $Global:MountPath) -ne $true){
		New-Item -ItemType directory -Path $Global:RelativePath"Mount"
	}
	Write-Host $Global:MountPath
	$Arguments = "dism.exe /mount-wim /wimfile:"+$Global:WimFile+[char]32+"/index:1 /mountdir:"+$Global:MountPath
	Write-Host $Arguments
	Invoke-Expression -Command $Arguments

}

Function UnmountWIM{

	$Arguments = "dism.exe /unmount-wim /mountdir:"+$Global:MountPath+[char]32+"/commit"
	Write-Host $Arguments
	Invoke-Expression -Command $Arguments

}

Function CleanupWIM{

	$Arguments = "dism.exe /cleanup-wim"
	Write-Host $Arguments
	Invoke-Expression -Command $Arguments

}

Function GlobalMemoryCleanup{

	Clear-Variable -Name MountPath -Scope Global -Force
	Clear-Variable -Name WimFile -Scope Global -Force
	Clear-Variable -Name UpdatesPath -Scope Global -Force
	Clear-Variable -Name RelativePath -Scope Global -Force
	Remove-Variable -Name MountPath -Scope Global -Force
	Remove-Variable -Name WimFile -Scope Global -Force
	Remove-Variable -Name UpdatesPath -Scope Global -Force
	Remove-Variable -Name RelativePath -Scope Global -Force

}

GetRelativePath
GetWimFile
MountWIM
$Global:UpdatesPath = $Global:RelativePath+"*.msu"
$UpdatesArray = Get-Item $Global:UpdatesPath
ForEach ($Updates in $UpdatesArray) {
	$Arguments = "dism.exe /image:"+$Global:MountPath+[char]32+"/Add-Package /PackagePath:"+$Updates
	Write-Host $Arguments
	Invoke-Expression -Command $Arguments
	Start-Sleep -Seconds 10
}
UnmountWIM
CleanupWIM
Clear-Variable -Name Arguments -Scope Local -Force
Clear-Variable -Name Updates -Scope Local -Force
Clear-Variable -Name UpdatesArray -Scope Local -Force
Remove-Variable -Name Arguments -Scope Local -Force
Remove-Variable -Name Updates -Scope Local -Force
Remove-Variable -Name UpdatesArray -Scope Local -Force
GlobalMemoryCleanup
