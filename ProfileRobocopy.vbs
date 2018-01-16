'*******************************************************************************
'     Program: ProfileRobocopy.vbs
'      Author: Mick Pletcher
'        Date: 04 January 2010
'    Modified:
' Description: This script will robocopy a profile from one machine to another.
'			   It is intended to be used when the USMT fails. The user must
'			   logon to the new machine before running this script. If this is
'			   executed before a profile is created, a new profile will be
'			   created <profile>.xxx and the user will not see any of the 
'			   copied data.
'			   There needs to be a %NetworkPath%\PSTools directory containing
'			   PSTools. Robocopy needs to be present in the PSTools directory.
'			   PSTools allows for the robocopy to run locally on the old
'			   machine, thereby conserving bandwidth if it is at a remote
'			   location. 
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c$\temp\"
CONST LogFolderName = "ProfileCopy"
CONST NetworkPath   = "\\global.gsp\data\special\Deploy\USMT\"

REM Define Global Variables
DIM NewComputer   : Set NewComputer   = Nothing
DIM OldComputer   : Set OldComputer   = Nothing
DIM NewComputerOS : Set NewComputerOS = Nothing
DIM OldComputerOS : Set OldComputerOS = Nothing
DIM LogFolder     : Set LogFolder     = Nothing
DIM OS            : Set OS            = Nothing
DIM RelativePath  : Set RelativePath  = Nothing
DIM ReturnCode    : ReturnCode        = "0"
DIM UserName      : Set UserName      = Nothing

REM Define relative installation path
DefineRelativePath()
REM Prompt for Old Computer Name, New Computer Name, and Username
GetComputerInfo()
REM Create the log folder
CreateLogFolder()
REM Determine which OS this script is being run from
DetermineOS()
MSGBOX OldComputerOS & Chr(32) & NewComputerOS
If (OldComputerOS = "WindowsXP") and (NewComputerOS = "WindowsXP") then
	REM Robocopy the profile from the old XP machine to the new XP machine
	CopyFilesXP2XP()
End If
If (OldComputerOS = "WindowsXP") and (NewComputerOS = "Windows7") then
	REM Robocopy the profile from the old XP machine to the new Windows 7 machine
	CopyFilesXP2Win7()
End If
If (OldComputerOS = "Windows7") and (NewComputerOS = "Windows7") then
	REM Robocopy the profile from the old Windows 7 machine to the new Windows 7 machine
	CopyFilesWin72Win7()
End If
REM Verify there were no errors during the robocopy
VerifyCopy()
REM Cleanup Global Variables
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

Sub GetComputerInfo()

	OldComputer = InputBox( "Enter the old computer name:" )
	NewComputer = InputBox( "Enter the new computer name:" )
	UserName    = InputBox( "Enter the username:" )

End Sub

'*******************************************************************************

Sub CreateLogFolder()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM Logs : Set Logs = Nothing

	REM Initialize Local Variables
	LogFolder = "\\" & OldComputer & "\" & TempFolder & LogFolderName & "\"
	Logs = LogFolder & "robocopy.log"

	If NOT FSO.FolderExists("\\" & OldComputer & "\" & TempFolder) then
		FSO.CreateFolder("\\" & OldComputer & "\" & TempFolder)
	End If
	If NOT FSO.FolderExists(LogFolder) then
		FSO.CreateFolder(LogFolder)
	End If
	If FSO.FileExists(Logs) then
		FSO.DeleteFile(Logs)
	End If

	REM Cleanup Local Variables
	Set FSO  = Nothing
	Set Logs = Nothing

End Sub

'*******************************************************************************

Sub DetermineOS()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
	
	IF FSO.FolderExists("\\" & OldComputer & "\c$\users\") then
		OldComputerOS = "Windows7"
	Else
		OldComputerOS = "WindowsXP"
	End If
	IF FSO.FolderExists("\\" & NewComputer & "\c$\users\") then
		NewComputerOS = "Windows7"
	Else
		NewComputerOS = "WindowsXP"
	End If

	REM Cleanup Local Variables
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub CopyFilesXP2XP()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM ExcludeDir   : Set ExcludeDir   = Nothing
	DIM ExcludeFiles : Set ExcludeFiles = Nothing
	DIM Logs         : Set Logs         = Nothing
	DIM Parameters   : Set Parameters   = Nothing
	DIM RoboCopy     : Set RoboCopy     = Nothing
	DIM Switches     : Set Switches     = Nothing
	DIM RemoteExec   : RemoteExec       = RelativePath & "PSTools\PsExec.exe \\" & OldComputer &_
											Chr(32) & "-u nash\win2kload -p 2kosload" & Chr(32)

	REM Initialize Robocopy Variables
	Switches     = "/e /eta /r:1 /w:0"
	ExcludeDir   = "/xd LocalService NetworkService *Links* *temp *TEMPOR~1 *cache"
	ExcludeFiles = "/xf ntuser.* *.exd *.nk2 *.srs extend.dat *cache* *.oab index.* {* *.ost UsrClass.* SharePoint*.pst history* *tmp*"
	Logs         = "/log:" & LogFolder & "robocopy.log"
	Parameters   = Chr(32) & Switches & Chr(32) & ExcludeDir & Chr(32) & ExcludeFiles
	RoboCopy     = RemoteExec & NetworkPath & "PSTools\robocopy.exe " & Chr(34) & "c:\Documents and Settings\" & UserName & Chr(34) &_
					Chr(32) & Chr(34) & "\\" & NewComputer & "\c$\Documents and Settings\" & UserName & Chr(34) & Parameters

	ReturnCode = oShell.Run(RoboCopy, 1, True)

	REM Local Memory Cleanup
	Set oShell       = Nothing
	Set Switches     = Nothing
	Set ExcludeDir   = Nothing
	Set ExcludeFiles = Nothing
	Set Logs         = Nothing
	Set Parameters   = Nothing
	Set RemoteExec   = Nothing
	Set RoboCopy     = Nothing

End Sub

'*******************************************************************************

Sub CopyFilesXP2Win7()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM ExcludeDir   : Set ExcludeDir   = Nothing
	DIM ExcludeFiles : Set ExcludeFiles = Nothing
	DIM Logs         : Set Logs         = Nothing
	DIM Parameters   : Set Parameters   = Nothing
	DIM RoboCopy     : Set RoboCopy     = Nothing
	DIM Switches     : Set Switches     = Nothing
	DIM RemoteExec   : RemoteExec       = RelativePath & "PSTools\PsExec.exe \\" & OldComputer &_
											Chr(32) & "-u nash\win2kload -p 2kosload" & Chr(32)

	REM Initialize Robocopy Variables
	Switches     = "/e /eta /r:1 /w:0"
	ExcludeDir   = "/xd Application* Cookies IETldCache *Links* Local* NetHood NetworkService PrintHood PrivacIE Recent SendTo Start* *temp Templates *TEMPOR~1 Tracing *cache"
	ExcludeFiles = "/xf ntuser.* ilent* *.exd *.nk2 *.srs extend.dat *cache* *.oab index.* {* *.ost UsrClass.* SharePoint*.pst history* *tmp*"
	Logs         = "/log:" & LogFolder & "robocopy.log"
	Parameters   = Chr(32) & Switches & Chr(32) & ExcludeDir & Chr(32) & ExcludeFiles
	RoboCopy     = RemoteExec & NetworkPath & "PSTools\robocopy.exe " & Chr(34) & "c:\Documents and Settings\" & UserName & Chr(34) &_
					Chr(32) & Chr(34) & "\\" & NewComputer & "\c$\users\" & UserName & Chr(34) & Parameters

	ReturnCode = oShell.Run(RoboCopy, 1, True)

	REM Local Memory Cleanup
	Set oShell       = Nothing
	Set Switches     = Nothing
	Set ExcludeDir   = Nothing
	Set ExcludeFiles = Nothing
	Set Logs         = Nothing
	Set Parameters   = Nothing
	Set RemoteExec   = Nothing
	Set RoboCopy     = Nothing

End Sub

'*******************************************************************************

Sub CopyFilesWin72Win7()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM ExcludeDir   : Set ExcludeDir   = Nothing
	DIM ExcludeFiles : Set ExcludeFiles = Nothing
	DIM Logs         : Set Logs         = Nothing
	DIM Parameters   : Set Parameters   = Nothing
	DIM RoboCopy     : Set RoboCopy     = Nothing
	DIM Switches     : Set Switches     = Nothing
	DIM RemoteExec   : RemoteExec       = RelativePath & "PSTools\PsExec.exe \\" & OldComputer &_
											Chr(32) & "-u nash\win2kload -p 2kosload" & Chr(32)

	REM Initialize Robocopy Variables
	Switches     = "/e /eta /r:1 /w:0"
	ExcludeDir   = "/xd LocalService NetworkService *Links* *temp *TEMPOR~1 *cache"
	ExcludeFiles = "/xf ntuser.* *.exd *.nk2 *.srs extend.dat *cache* *.oab index.* {* *.ost UsrClass.* SharePoint*.pst history* *tmp*"
	Logs         = "/log:" & LogFolder & "robocopy.log"
	Parameters   = Chr(32) & Switches & Chr(32) & ExcludeDir & Chr(32) & ExcludeFiles
	RoboCopy     = RemoteExec & NetworkPath & "PSTools\robocopy.exe " & Chr(34) & "c:\users\" & UserName & Chr(34) &_
					Chr(32) & Chr(34) & "\\" & NewComputer & "\c$\users\" & UserName & Chr(34) & Parameters

	ReturnCode = oShell.Run(RoboCopy, 1, True)

	REM Local Memory Cleanup
	Set oShell       = Nothing
	Set Switches     = Nothing
	Set ExcludeDir   = Nothing
	Set ExcludeFiles = Nothing
	Set Logs         = Nothing
	Set Parameters   = Nothing
	Set RemoteExec   = Nothing
	Set RoboCopy     = Nothing

End Sub

'*******************************************************************************

Sub VerifyCopy()

	If ReturnCode = "0" then
		MsgBox("The profile, " & UserName & ", on " & OldComputer & " successfully copied to " & NewComputer & ".")
	Else
		MsgBox("The profile, " & UserName & ", on " & OldComputer & " failed to copy to " & NewComputer & " due to error " & ReturnCode & ".")
	End If

End Sub

'*******************************************************************************

Sub GlobalMemoryCleanup()

	Set NewComputer  = Nothing
	Set OldComputer  = Nothing
	Set RelativePath = Nothing
	Set UserName     = Nothing

End Sub