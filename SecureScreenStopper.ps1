Clear-Host
Add-Type -AssemblyName System.Windows.Forms

# Rename Powershell Window
$PowershellConsole = (Get-Host).UI.RawUI
$PowershellConsole.WindowTitle = "Secure Screen Stopper"


#Declare Variable
$button = $null
$Global:MainProcess
$Global:RelativePath
$Global:MMProcess

Function GetRelativePath{
	$Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"
	Write-Host $Global:RelativePath
}

Function KillProcesses{
	$Running = Get-Process -Name conhost -ErrorAction SilentlyContinue
	If($Running -ne $null){
		Stop-Process -Name conhost -Force
	}
	$Running = Get-Process -Name powershell -ErrorAction SilentlyContinue
	If($Running -ne $null){
		Stop-Process -Name powershell -Force
	}
}

GetRelativePath
$a = "-WindowStyle Minimized -File"+[char]32+[char]34+$Global:RelativePath+"MouseMover.ps1"+[char]34
Write-Host $a
Start-Process powershell.exe $a
$button = [system.windows.forms.messagebox]::show("Click OK to reinstate secure screen saver!")
#Start-Sleep -Seconds 10
KillProcesses
