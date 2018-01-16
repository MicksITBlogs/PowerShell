'*******************************************************************************
'      Author: Mick Pletcher
'        Date: 20 November 2012
'    Modified:
'
' Description: This will install Revit 2013
'*******************************************************************************
Option Explicit

REM Define Global Variables
DIM Architecture  : Set Architecture = Nothing
DIM INIFile       : INIFile          = "bldg_premium_full_Relative.ini"
DIM InstallFile   : InstallFile      = "setup.exe"
DIM TempFolder    : TempFolder       = "c:\temp\"
DIM LogFolderName : LogFolderName    = "bldg_premium_full"
DIM LogFolder     : LogFolder        = TempFolder & LogFolderName & "\"
DIM NewformaExist : NewformaExist    = False
DIM RelativePath  : Set RelativePath = Nothing

REM Define the relative installation path
DefineRelativePath()
REM Disable File Security Warning
DisableWarning()
REM Map Drive Letter
MapDrive()
REM Create the Log Folder
CreateLogFolder()
REM Install RAC
InstallRevit()
REM Enable File Security Warning
EnableWarning()
REM Cleanup Global Memory
GlobalMemoryCleanup()

'*******************************************************************************
'*******************************************************************************

Sub DefineRelativePath()

	REM Get File Name with full relative path
	RelativePath = WScript.ScriptFullName
	REM Remove file name, leaving relative path only
	RelativePath = Left(RelativePath, InStrRev(RelativePath, "\"))

End Sub

'*******************************************************************************

Sub MapDrive()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM DeleteDrive    : DeleteDrive    = "net use z: /delete /Y"
	DIM MapDriveLetter : MapDriveLetter = "net use z:" & Chr(32) & Left(RelativePath, InStrRev(RelativePath, "\")-1)

	oShell.Run DeleteDrive, 1, True
	oShell.Run MapDriveLetter, 1, True
	RelativePath = "z:\"

	REM Cleanup Local Variables
	Set DeleteDrive    = Nothing
	Set MapDriveLetter = Nothing
	Set oShell         = Nothing

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

Sub DetermineArchitecture()

	REM Define Local Objects
	DIM WshShell : Set WshShell = CreateObject("WScript.Shell")

	REM Define Local Variables
	DIM OSType : OSType = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")

	If OSType = "x86" then
		Architecture = "x86"
	elseif OSType = "AMD64" then
		Architecture = "x64"
	end if

	REM Cleanup Local Memory
	Set WshShell = Nothing
	Set OSType   = Nothing

End Sub

'*******************************************************************************

Sub CheckFreeSpace()

	REM Define Local Objects
	DIM oShell : Set oShell = CreateObject( "WScript.Shell" )

	REM Define Local Variables
	DIM strComputer : strComputer = "."
	DIM SystemDrive : SystemDrive = oShell.ExpandEnvironmentStrings("%SystemDrive%")

	Set objWMIService = GetObject("winmgmts:" _
		& "{impersonationLevel=impersonate}!\\" _
		& strComputer & "\root\cimv2")
	Set colDisks = objWMIService.ExecQuery _
		("Select * from Win32_LogicalDisk")
	For Each objDisk in colDisks
		If objDisk.DeviceID = SystemDrive then
			Wscript.Echo "DeviceID: " & objDisk.DeviceID
			Wscript.Echo "Free Disk Space: " _
				& objDisk.FreeSpace
		End If
	Next

	REM Cleanup Local Memory
	Set oShell      = Nothing
	Set strComputer = Nothing
	Set SystemDrive = Nothing

End Sub

'*******************************************************************************

Sub DisableWarning()

	REM Define Local Objects
	DIM oShell : Set oShell= CreateObject("Wscript.Shell")
	DIM oEnv   : Set oEnv = oShell.Environment("PROCESS")
	
	oEnv("SEE_MASK_NOZONECHECKS") = 1
	
	REM Cleanup Memory
	Set oShell = Nothing
	Set oEnv   = Nothing

End Sub

'*******************************************************************************

Sub EnableWarning()

	REM Define Local Objects
	DIM oShell : Set oShell= CreateObject("Wscript.Shell")
	DIM oEnv   : Set oEnv = oShell.Environment("PROCESS")
	
	oEnv.Remove("SEE_MASK_NOZONECHECKS")
	
	REM Cleanup Memory
	Set oShell = Nothing
	Set oEnv   = Nothing

End Sub

'*******************************************************************************

Sub InstallCpp()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Switches : Switches = Chr(32) & "/passive /uninstall /norestart /log" & Chr(32) & LogFolder & "InstallC++.log"
	DIM Install  : Install  = RelativePath & "AdminImage\3rdParty\x86\VCRedist\2010\vcredist_x86_NEW.exe" & Switches
	DIM NoWait   : NoWait   = False
	DIM Wait     : Wait     = True

	oShell.Run Install, 1, True

	REM Cleanup Local Memory
	Set Switches = Nothing
	Set Install  = Nothing
	Set NoWait   = Nothing
	Set oShell   = Nothing
	Set Wait     = Nothing

End Sub

'*******************************************************************************

Sub UninstallCpp()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Switches    : Switches    = Chr(32) & "/passive /uninstall /norestart /log" & Chr(32) & LogFolder & "UninstallC++.log"
	DIM Uninstall01 : Uninstall01 = RelativePath & "AdminImage\3rdParty\x86\VCRedist\2010\vcredist_x86.exe" & Switches
	DIM Uninstall02 : Uninstall02 = RelativePath & "AdminImage\3rdParty\x86\VCRedist\2010\vcredist_x86_NEW.exe" & Switches
	DIM NoWait      : NoWait = False
	DIM Wait        : Wait   = True

	oShell.Run Uninstall01, 1, True
	oShell.Run Uninstall02, 1, True

	REM Cleanup Local Memory
	Set Switches    = Nothing
	Set Uninstall01 = Nothing
	Set Uninstall02 = Nothing
	Set NoWait      = Nothing
	Set oShell      = Nothing
	Set Wait        = Nothing

End Sub

'*******************************************************************************

Sub InstallRevit()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Switches : Switches = Chr(32) & "/qb /I" & Chr(32) & RelativePath & "AdminImage\" & INIFile & Chr(32) & "/language en-us"
	DIM Install  : Install  = RelativePath & "AdminImage\" & InstallFile & Switches
	DIM NoWait   : NoWait   = False
	DIM Wait     : Wait     = True

	oShell.Run Install, 1, True
	Call WaitForInstall()

	REM Cleanup Local Variables
	Set Install  = Nothing
	Set NoWait   = Nothing
	Set oShell   = Nothing
	Set Switches = Nothing
	Set Wait     = Nothing

End Sub

'*******************************************************************************

Sub WaitForInstall()

	REM Define Local Constants
	CONST Timeout  = 3000
	CONST Timepoll = 500

	REM Define Local Variables
	DIM sQuery : sQuery  = "select * from win32_process where name=" & Chr(39) & InstallFile & Chr(39)
	DIM SVC    : Set SVC = GetObject("winmgmts:root\cimv2")

	REM Define Local Variables
	DIM cproc   : Set cproc   = Nothing
	DIM iniproc : Set iniproc = Nothing

	REM Wait until Second Setup.exe closes
	Wscript.Sleep 30000
	Set cproc = svc.execquery(sQuery)
	iniproc = cproc.count
	Do While iniproc = 1
		wscript.sleep 5000
		set svc=getobject("winmgmts:root\cimv2")
		sQuery = "select * from win32_process where name=" & Chr(39) & InstallFile & Chr(39)
		set cproc=svc.execquery(sQuery)
		iniproc=cproc.count
	Loop

	REM Cleanup Local Variables
	Set cproc   = Nothing
	Set iniproc = Nothing
	Set sQuery  = Nothing
	set SVC     = Nothing

End Sub

'*******************************************************************************

Sub GlobalMemoryCleanup()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM DeleteDrive : DeleteDrive = "net use z: /delete /Y"

	oShell.Run DeleteDrive, 1, True

	Set Architecture  = Nothing
	Set INIFile       = Nothing
	Set InstallFile   = Nothing
	Set LogFolder     = Nothing
	Set LogFolderName = Nothing
	Set RelativePath  = Nothing
	Set TempFolder    = Nothing

	REM Cleanup Local Memory
	Set DeleteDrive = Nothing
	Set oShell      = Nothing

End Sub
