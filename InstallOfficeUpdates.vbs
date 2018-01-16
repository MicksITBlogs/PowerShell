'*******************************************************************************
'      Author: Mick Pletcher
'        Date: 28 June 2013
'    Modified:
'
' Description: This will install all office updates residing in the same folder as this
'			   script.
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   3) Read list of Updates into Array
'			   4) Install updates
'			   5) Cleanup Global Memory
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "OfficeUpdates"

REM Define Global Variables
DIM Count        : Count            = 1
DIM LogFolder    : LogFolder        = TempFolder & LogFolderName & "\"
DIM RelativePath : Set RelativePath = Nothing
ReDIM arrFiles(1)

REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Read list of Updates into Array
ReadUpdates()
REM Install Updates
InstallUpdates()
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

Sub ReadUpdates()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM Folder : Set Folder = FSO.GetFolder(RelativePath)
	DIM Files  : Set files  = Folder.Files
	DIM File   : Set File   = Nothing

	For each File in Files
		If NOT File.Name = Wscript.ScriptName then
			arrFiles(Count) = File.Name
			Count = Count + 1
			ReDim Preserve arrFiles(Count)
		End If
	Next
	Count = Count - 1

	REM Cleanup Local Memory
	Set File    = Nothing
	Set Files   = Nothing
	Set Folder  = Nothing
	Set FSO     = Nothing

End Sub

'*******************************************************************************

Sub InstallUpdates()

	REM Define Local Objects
	DIM File     : Set File     = Nothing
	DIM FSO      : Set FSO      = CreateObject("Scripting.FileSystemObject")
	DIM i        : Set i        = Nothing
	DIM oShell   : Set oShell   = CreateObject("Wscript.Shell")
	DIM Switches : Set Switches = Nothing

	For i = 1 to Count
		File = Left(arrFiles(i),Len(arrFiles(i))-4)
		Switches = Chr(32) & "/passive /norestart /log:" & LogFolder & File & ".log"
		oShell.run arrFiles(i) & Switches, 1, True
	Next

	REM Cleanup Local Memory
	Set File     = Nothing
	Set FSO      = Nothing
	Set i        = Nothing
	Set oShell   = Nothing
	Set Switches = Nothing

End Sub

'*******************************************************************************

Sub GlobalMemoryCleanup()

	Set Count        = Nothing
	Set LogFolder    = Nothing
	Set RelativePath = Nothing
	Erase arrFiles

End Sub