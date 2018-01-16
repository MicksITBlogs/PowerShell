<# 
   Author: Mick Pletcher
   Date: 04 March 2014
   Synopsis: This script will robocopy specific user data from one profile to another on
   			 the same machine, or to a new machine. It will require user input in the following
			 format:
			 1) Have the user logout
			 2) Rename the user profile to <profile>.old
			 3) Have the user log back in
			 1) Define Global Memory
			 2) Get the relative path
			 3) User input
			 	a) User profile to copy
				b) Is the profile to be copied to a new machine
				c) If yes, what is the computer name of the new machine
			 4) Get the OS version of the source machine
			 5) If copying to a new machine, get the OS version of destination machine
			 6) 
#> 

#Define Global Variables
Set-Variable -Name AdminPassword -Scope Global -Force
Set-Variable -Name AdminUsername -Scope Global -Force
Set-Variable -Name DestinationComputer -Scope Global -Force
Set-Variable -Name DestinationProfile -Scope Global -Force
Set-Variable -Name RelativePath -Scope Global -Force
Set-Variable -Name SourceComputer -Scope Global -Force
Set-Variable -Name SourceProfile -Scope Global -Force

Function GetRelativePath { 
	$Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\" 
} 

Function GetUserInput {

	#Define Local Memory
	Set-Variable -Name Message -Scope Local -Force
	Set-Variable -Name No -Scope Local -Force
	Set-Variable -Name Options -Scope Local -Force
	Set-Variable -Name Result -Scope Local -Force
	Set-Variable -Name Title -Scope Local -Force
	Set-Variable -Name Username -Scope Local -Force
	Set-Variable -Name Yes -Scope Local -Force

	$Username = Read-Host "Enter the username"
	$Global:SourceComputer = Read-Host "Enter the computer name of the source system"
	$Title = ""
	$message = "Is the profile to be copied to a different machine?"
	$Yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Copy files to profile on different machine"
	$No = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Copy files to new profile on same machine"
	$Options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
	$Result = $host.ui.PromptForChoice($title, $message, $options, 0) 
	If ($Result -eq 1) {
		$Global:DestinationComputer = $Global:SourceComputer
		$Global:SourceProfile = Read-Host "Enter renamed profile name"
		$Global:SourceProfile = "\\"+$Global:SourceComputer+"\c$\users\"+$Global:SourceProfile
		$Global:DestinationProfile = "\\"+$Global:DestinationComputer+"\c$\users\"+$Username
	} else {
		$Global:DestinationComputer = Read-Host "Enter the computer name of the new machine"
		#$Global:SourceProfile = $Env:systemdrive+"\users\"+$Username
		$Global:SourceProfile = $Username
		$Global:DestinationProfile = "\\"+$Global:DestinationComputer+"\c$\users\"+$Username

	}
	$Global:AdminUsername = Read-Host "Enter administrator username"
	$Global:AdminPassword = Read-Host -AsSecureString "Enter administrator account password"
	$Global:AdminPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Global:AdminPassword))
	$Global:AdminUsername = "[Domain]\"+$Global:AdminUsername

	#Cleanup Local Memory
	Remove-Variable -Name Message -Scope Local -Force
	Remove-Variable -Name No -Scope Local -Force
	Remove-Variable -Name Options -Scope Local -Force
	Remove-Variable -Name Result -Scope Local -Force
	Remove-Variable -Name Title -Scope Local -Force
	Remove-Variable -Name Username -Scope Local -Force
	Remove-Variable -Name Yes -Scope Local -Force

}

Function RoboCopyFiles {

	#Define Local Memory
	Set-Variable -Name ErrCode -Scope Local -Force
	Set-Variable -Name ExcludeDir -Scope Local -Force
	Set-Variable -Name ExcludeFiles -Scope Local -Force
	Set-Variable -Name EXE -Scope Local -Force
	Set-Variable -Name Logs -Scope Local -Force
	Set-Variable -Name Parameters -Scope Local -Force
	Set-Variable -Name RemoteExec -Scope Local -Force
	Set-Variable -Name Robocopy -Scope Local -Force
	Set-Variable -Name Switches -Scope Local -Force

	$EXE = "\\BNASANIS01\SupportServices\Tools\PSTools\PsExec.exe"
	$RemoteExec = "\\"+$Global:SourceComputer+[char]32+"-accepteula -u $Global:AdminUsername -p $Global:AdminPassword"+[char]32
	$Switches = [char]32+"/e /eta /r:1 /w:0"
	$ExcludeDir = [char]32+"/xd AppData Application* Downloads LocalService *Games* NetworkService *Links* *temp *TEMPOR~1 *cache Local*"
	$ExcludeFiles = [char]32+"/xf ntuser.* *.exd *.nk2 *.srs extend.dat *cache* *.oab index.* {* *.ost UsrClass.* SharePoint*.pst history* *tmp*"
	$Logs = [char]32+"/log:"+$Env:windir+"\waller\Logs\ApplicationLogs\ProfileCopy.log"
	$Parameters = $Switches+$ExcludeDir+$ExcludeFiles+$Logs
	$Arguments = $RemoteExec+$Env:windir+"\system32\robocopy.exe"+[char]32+$Env:systemdrive+"\users\"+$Global:SourceProfile+[char]32+$Global:DestinationProfile+$Parameters
	$ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Arguments -Wait -Passthru).ExitCode

	#Cleanup Local Memory
	Remove-Variable -Name ErrCode -Scope Local -Force
	Remove-Variable -Name ExcludeDir -Scope Local -Force
	Remove-Variable -Name ExcludeFiles -Scope Local -Force
	Remove-Variable -Name EXE -Scope Local -Force
	Remove-Variable -Name Logs -Scope Local -Force
	Remove-Variable -Name Parameters -Scope Local -Force
	Remove-Variable -Name RemoteExec -Scope Local -Force
	Remove-Variable -Name Robocopy -Scope Local -Force
	Remove-Variable -Name Switches -Scope Local -Force

}

Function CopyFiles ($FileSource,$FileDest,$FileFilter) {
	$Dest = $FileDest
	$Files = Get-ChildItem $FileSource -Filter $FileFilter
	If ($Files.Count -eq $null) {
		Write-Host "Copy "$Files.Name"....." -NoNewline
		Copy-Item $Files.FullName -Destination $Dest -Force
		$Test = $Dest + "\"+$Files.Name
		If (Test-Path $Test) {
			Write-Host "Success" -ForegroundColor Yellow
		} else {
			Write-Host "Failed" -ForegroundColor Red
		}
	} else {
		For ($i = 0; $i -lt $Files.Count; $i++) {
			$File = $Files[$i].FullName
			Write-Host "Copy"$Files[$i].Name"....." -NoNewline
			Copy-Item $File -Destination $Dest -Force
			$Test = $Dest + "\"+$Files[$i].Name
			If (Test-Path $Test) {
				Write-Host "Success" -ForegroundColor Yellow
			} else {
				Write-Host "Failed" -ForegroundColor Red
			}
		}
	}
}

cls
GetRelativePath
GetUserInput
RoboCopyFiles
#Copy Outlook Signatures
$TempSource = "\\"+$SourceComputer+"\c$\users\"+$SourceProfile+"\AppData\Roaming\Microsoft\Signatures"
$TempDestination = "\\"+$DestinationComputer+"\c$\users\"+$DestinationProfile+"\AppData\Roaming\Microsoft\Signatures"
CopyFiles $TempSource $TempDestination "*.*"
