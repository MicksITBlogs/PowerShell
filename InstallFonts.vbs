'*******************************************************************************
'      Author: Mick Pletcher
'        Date: 17 October 2012
'    Modified:
'
' Description: This will install all fonts residing in the same folder as this
'			   script.
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   3) Read list of Fonts into Array
'			   4) Install Fonts
'			   5) Cleanup Global Memory
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "Fonts"

REM Define Global Variables
DIM Count        : Count            = 1
DIM LogFolder    : LogFolder        = TempFolder & LogFolderName & "\"
DIM RelativePath : Set RelativePath = Nothing
ReDIM arrFiles(1)

REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Read list of Fonts into Array
ReadFonts()
REM Install Fonts
InstallFonts()
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

Sub ReadFonts()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM Folder : Set Folder = FSO.GetFolder(RelativePath)
	DIM Files  : Set files  = Folder.Files
	DIM File   : Set File   = Nothing

	For each File in Files
		If NOT Left(File.Name,Len(File.Name)-4) = "Install" then
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

Sub InstallFonts()

	REM Define Local Constants
	Const FONTS = &H14&

	REM Define Local Objects
	DIM FSO      : Set FSO      = CreateObject("Scripting.FileSystemObject")
	DIM i        : Set i        = Nothing
	DIM oShell   : SET oShell   = CreateObject("Shell.Application")
	DIM oFolder  : Set oFolder  = oShell.Namespace(FONTS)
	DIM WshShell : Set WshShell = WScript.CreateObject("Wscript.Shell")

	For i = 1 to Count
		If NOT FSO.FileExists("c:\windows\Fonts\" & arrFiles(i)) then
			oFolder.CopyHere RelativePath & arrFiles(i), 16
		End If
	Next

	REM Cleanup Local Variables
	Set FSO      = Nothing
	Set i        = Nothing
	Set oFolder  = Nothing
	Set oShell   = Nothing
	Set WshShell = Nothing

End Sub

'*******************************************************************************

Sub GlobalMemoryCleanup()

	Set Count        = Nothing
	Set LogFolder    = Nothing
	Set RelativePath = Nothing
	Erase arrFiles

End Sub