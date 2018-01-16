'*******************************************************************************
'     Program: Install.vbs
'      Author: Mick Pletcher
'        Date: 01 March 2011
'    Modified:
'
'     Program: Apple QuickTime
'     Version: 7.6.9
' Description: This will install Apple QuickTime
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   6) Install Apple Application Support
'			   6) Install QuickTime
'			   6) Install Apple Software Update
'			   7) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder = "c:\temp\"
CONST LogFolderName = "QuickTime"

REM Define Global Variables
DIM LogFolder     : LogFolder = TempFolder & LogFolderName & "\"
DIM RelativePath  : Set RelativePath = Nothing

REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Install Apple Application Support
InstallAppleApplicationSupport()
REM Install QuickTime
InstallQuickTime()
REM Install Apple Software Update
InstallAppleSoftwareUpdate()
REM Disable QTTASK from Startup
DisableQTTASK()
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

Sub CreateLogFolder()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	If NOT FSO.FolderExists(TempFolder) then
		FSO.CreateFolder(TempFolder)
	End If
	If NOT FSO.FolderExists(LogFolder) then
		FSO.CreateFolder(LogFolder)
	End If

	REM Cleanup Local Variables
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub InstallAppleApplicationSupport()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM MSI        : MSI        = Chr(32) & RelativePath & "AppleApplicationSupport.msi"
	DIM Logs       : Logs       = Chr(32) & "/lvx" & Chr(32) & LogFolder & "AppleApplicationSupport.log"
	DIM Parameters : Parameters = Chr(32) & "/qb- /norestart"
	DIM Install    : Install    = "msiexec.exe /i" & MSI & Logs & Parameters

	oShell.Run Install, 1, True

	REM Cleanup Local Variables
	Set Install    = Nothing
	Set Logs       = Nothing
	Set MSI        = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing

End Sub

'*******************************************************************************

Sub InstallQuickTime()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM SearchDesktopShortcuts : SearchDesktopShortcuts = Chr(32) & "REGSRCH_DESKTOP_SHORTCUTS=0"
	DIM ScheduleUpdates        : ScheduleUpdates        = Chr(32) & "SCHEDULE_ASUW=1"
	DIM CheckForUpdates        : CheckForUpdates        = Chr(32) & "ChkOptInstASU=1"
	DIM DesktopShortcuts       : DesktopShortcuts       = Chr(32) & "ChkOptInstShortcuts=0"
	DIM MSI                    : MSI                    = Chr(32) & RelativePath & "QuickTime.msi"
	DIM Logs                   : Logs                   = Chr(32) & "/lvx" & Chr(32) & LogFolder & "QuickTime.log"
	DIM Transform              : Transform              = Chr(32) & "TRANSFORMS=" & Chr(34) & RelativePath & "QuickTime.mst" & Chr(34)
	DIM Parameters             : Parameters             = Chr(32) & "/qb- /norestart" & SearchDesktopShortcuts & ScheduleUpdates & CheckForUpdates & DesktopShortcuts
	DIM Install                : Install                = "msiexec.exe /i" & MSI & Logs & Parameters

	oShell.Run Install, 1, True

	REM Cleanup Local Variables
	Set Install    = Nothing
	Set Logs       = Nothing
	Set MSI        = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing
	Set Transform  = Nothing

End Sub

'*******************************************************************************

Sub InstallAppleSoftwareUpdate()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM MSI        : MSI        = Chr(32) & RelativePath & "AppleSoftwareUpdate.msi"
	DIM Logs       : Logs       = Chr(32) & "/lvx" & Chr(32) & LogFolder & "AppleSoftwareUpdate.log"
	DIM Parameters : Parameters = Chr(32) & "/qb- /norestart"
	DIM Install    : Install    = "msiexec.exe /i" & MSI & Logs & Parameters

	oShell.Run Install, 1, True

	REM Cleanup Local Variables
	Set Install    = Nothing
	Set Logs       = Nothing
	Set MSI        = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing

End Sub

'*******************************************************************************

Sub DisableQTTASK()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")
	
	REM Define Local Variables
	DIM Install : Install = "REG.EXE DELETE" & Chr(32) & Chr(34) & "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" & Chr(34) &_
							Chr(32) & "/v" & Chr(32) & Chr(34) & "QuickTime Task" & Chr(34) & Chr(32) & "/f"

	oShell.Run Install, 1, True

	REM Cleanup Local Variables
	Set Install = Nothing
	Set oShell  = Nothing

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set LogFolder     = Nothing
	Set RelativePath  = Nothing

End Sub