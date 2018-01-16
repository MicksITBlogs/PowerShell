'*******************************************************************************
'     Program: InstallFlash.vbs
'      Author: Mick Pletcher
'        Date: 11 April 2012
'    Modified:
'
'   Publisher: Adobe
'     Program: Flash
'     Version: 11.x
' Description: Adobe Flash Installation
'              1) Define Relative Installation Path
'			   2) Determine Architecture
'			   3) Create Logs Folder
'			   4) Uninstall all old versions of Flash
'			   5) Install Flash
'			   6) Copy MMS File
'			   6) Initiate SMS Hardware Inventory
'			   7) Cleanup Global Variables
'			   8) Exit Installation
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "AdobeFlash"

REM Define Global Variables
DIM Architecture  : Set Architecture = Nothing
DIM LogFolder     : LogFolder        = TempFolder & LogFolderName & "\"
DIM RelativePath  : Set RelativePath = Nothing

REM Define Relative Installation Path
DefineRelativePath()
REM Determine Architecture
DetermineArchitecture()
REM Create Logs Folder
CreateLogFolder()
REM Uninstall Old Version of Flash
UninstallOldFlash()
REM Install Flash
InstallFlash()
REM Copy MMS File
CopyMMS()
REM Initiate SMS Hardware Inventory
InitiateSMSHardwareInventory()
REM Cleanup Global Variables
GlobalVariableCleanup()

'*******************************************************************************
'*******************************************************************************

Sub DefineRelativePath()

	REM Get File Name with full relative path
	RelativePath = WScript.ScriptFullName
	REM Remove file name, leaving relative path only
	RelativePath = Left(RelativePath, InStrRev(RelativePath, "\"))

End Sub

'*******************************************************************************

Sub DetermineArchitecture()

	REM Define Local Objects
	DIM WshShell : Set WshShell = CreateObject("WScript.Shell")

	REM Define Local Variables
	DIM OsType : OsType = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")

	If OsType = "x86" then
		Architecture = "x86"
	elseif OsType = "AMD64" then
		Architecture = "x64"
	end if
	
	REM Cleanup Local Variables
	Set WshShell = Nothing
	Set OsType   = Nothing

End Sub

'*******************************************************************************

Sub CreateLogFolder()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	If NOT FSO.FolderExists(TempFolder) then
		FSO.CreateFolder(TempFolder)
	End If
	If NOT FSO.FolderExists(LogFolder) then
		FSO.CreateFolder(LogFolder)
	End If

	REM Cleanup Local Objects & Variables
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub UninstallOldFlash()

	REM Define Local Objects
	DIM FSO    : SET FSO    = CreateObject("Scripting.FileSystemObject")
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM oAPPDATA     : oAPPDATA     = oShell.ExpandEnvironmentStrings("%APPDATA%")
	DIM Parameters   : Parameters   = Chr(32) & "-uninstall activex"
	DIM Uninstallx86 : Uninstallx86 = RelativePath & "uninstall_flash_player_32bit.exe" & Parameters
	DIM Uninstallx64 : Uninstallx64 = RelativePath & "uninstall_flash_player_64bit.exe" & Parameters

	If Architecture = "x86" then
		oShell.Run Uninstallx86, 1, True
	Else
		oShell.Run Uninstallx64, 1, True
	End If
	If FSO.FolderExists("C:\Windows\system32\Macromed\Flash\") then
		FSO.DeleteFile "C:\Windows\system32\Macromed\Flash\*.*", True
		FSO.DeleteFolder "C:\Windows\system32\Macromed\Flash", True
	End If
	If FSO.FolderExists("C:\Windows\SysWOW64\Macromed\Flash\") then
		FSO.DeleteFile("C:\Windows\SysWOW64\Macromed\Flash\*.*")
		FSO.DeleteFolder "C:\Windows\system32\Macromed\Flash", True
	End If
	If FSO.FolderExists(oAPPDATA & "\Adobe\Flash Player\") then
		FSO.DeleteFile(oAPPDATA & "\Adobe\Flash Player\*.*")
		FSO.DeleteFolder oAPPDATA & "\Adobe\Flash Player", True
	End If
	If FSO.FolderExists(oAPPDATA & "\Macromedia\Flash Player\") then
		FSO.DeleteFile(oAPPDATA & "\Macromedia\Flash Player\*.*")
		FSO.DeleteFolder oAPPDATA & "\Macromedia\Flash Player", True
	End If

	REM Cleanup Local Objects & Variables
	Set FSO          = Nothing
	Set oShell       = Nothing
	Set Parameters   = Nothing
	Set Uninstallx86 = Nothing
	Set Uninstallx64 = Nothing

End Sub

'*******************************************************************************

Sub InstallFlash()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Filex86    : Filex86    = Chr(32) & RelativePath & "install_flash_player_11_active_x_32bit.msi"
	DIM Filex64    : Filex64    = Chr(32) & RelativePath & "install_flash_player_11_active_x_64bit.msi"
	DIM LogFilex86 : LogFilex86 = Chr(32) & "/lvx" & Chr(32) & LogFolder & "Flash11x86.log"
	DIM LogFilex64 : LogFilex64 = Chr(32) & "/lvx" & Chr(32) & LogFolder & "Flash11x64.log"
	DIM Parameters : Parameters = Chr(32) & "/qb- /norestart"
	DIM Install32  : Install32  = "msiexec.exe /i" & Filex86 & LogFilex86 & Parameters
	DIM Install64  : Install64  = "msiexec.exe /i" & Filex64 & LogFilex64 & Parameters

	oShell.Run Install32, 1, True
	If Architecture = "x64" Then
		oShell.Run Install64, 1, True
	End If

	REM Cleanup Local Variables
	Set Filex86    = Nothing
	Set Filex64    = Nothing
	Set LogFilex86 = Nothing
	Set LogFilex64 = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing
	Set Install32  = Nothing
	Set Install64  = Nothing

End Sub

'*******************************************************************************

Sub CopyMMS()

	REM Define Local Objects
	DIM FSO    : SET FSO    = CreateObject("Scripting.FileSystemObject")

	If Architecture = "x86" then
		If FSO.FileExists("C:\Windows\system32\Macromed\Flash") then
			FSO.DeleteFile "C:\Windows\system32\Macromed\Flash\mms.cfg", True
		End If
		FSO.CopyFile RelativePath & "mms.cfg", "C:\Windows\system32\Macromed\Flash\", True
	Else
		If FSO.FileExists("C:\Windows\SysWow64\Macromed\Flash") then
			FSO.DeleteFile "C:\Windows\SysWow64\Macromed\Flash\mms.cfg", True
		End If
		FSO.CopyFile RelativePath & "mms.cfg", "C:\Windows\SysWow64\Macromed\Flash\", True
	End If
	
	REM Cleanup Local Objects
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub InitiateSMSHardwareInventory()

	On Error Resume Next

	DIM oCPAppletMgr   : Set oCPAppletMgr   = CreateObject("CPApplet.CPAppletMgr")
	DIM oClientAction  : Set oClientAction  = Nothing
	DIM oClientActions : Set oClientActions = oCPAppletMgr.GetClientActions()

	For Each oClientAction In oClientActions
		If oClientAction.Name = "Hardware Inventory Collection Cycle" Then
			oClientAction.PerformAction
		End If
	Next

	REM Cleanup Local Objects
	Set oCPAppletMgr   = Nothing
	Set oClientAction  = Nothing  
	Set oClientActions = Nothing
	
End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set Architecture = Nothing
	Set LogFolder    = Nothing
	Set RelativePath = Nothing

End Sub