'*******************************************************************************
'     Program: MountWIM.vbs
'      Author: Mick Pletcher
'        Date: 19 February 2010
'    Modified:
'
' Description: This script will mount a WIM file. It will display a list of
'			   WIM files and allow the user to select which one to mount.
'			   1) Define Relative Path
'			   2) Select the WIM file
'			   3) Mount the WIM file
'			   4) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Global Variables
DIM strImageName : Set strImageName = Nothing
DIM RelativePath : Set RelativePath = Nothing

DefineRelativePath()
SelectImage()
MountWIM()
ImageMounted()
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

Sub SelectImage()

	REM Define Local Constants
	CONST ForAppending = 2

	REM Define Objects
	DIM strComputer   : strComputer       = "."
	DIM objWMIService : Set objWMIService = GetObject("winmgmts:" _
		& "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
	DIM colFileList   : Set colFileList   = objWMIService.ExecQuery _
		("ASSOCIATORS OF {Win32_Directory.Name=" & Chr(39) & Left(RelativePath, Len(RelativePath)-1) & Chr(39) & "} Where " _
		& "ResultClass = CIM_DataFile")
	DIM objFile       : Set ObjFile       = Nothing
	DIM FSO           : Set FSO           = CreateObject("Scripting.FileSystemObject")
	
	REM Define Local Variables
	DIM Count         : Count          = 1
	DIM FileName      : Set FileName   = Nothing
	DIM FileVerify    : Set FileVerify = Nothing
	DIM strList       : strList        = "Select an Image File:"

	REM Get List of WIM files
	For Each objFile In colFileList
		FileVerify = Right(objFile.Name, 3)
		If FileVerify = "wim" then
			FileName = Len(objFile.Name)
			FileName = FileName - 9
			FileName = Right(objFile.Name, FileName)
			strList = strList & vbCrLf & Count & " - " & FileName
			Count = Count + 1
		End If
		Set FileVerify = Nothing
	Next

	REM Select WIM File
	strImageName = InputBox(strList, "Image")
	strImageName = CInt(strImageName)

	REM ReInitialize Variables
	Count = 1
	Set FileName   = Nothing
	Set FileVerify = Nothing
	Set objFile    = Nothing

	REM Get File Name
	For Each objFile In colFileList
		FileVerify = Right(objFile.Name, 3)
		If FileVerify = "wim" then
			FileName = Len(objFile.Name)
			FileName = FileName - 9
			FileName = Right(objFile.Name, FileName)
			If Count = strImageName then
				strImageName = FileName
			End If
			Count = Count + 1
		End If
		Set FileVerify = Nothing
	Next


	REM Cleanup Local Variables
	Set colFileList   = Nothing
	Set Count         = Nothing
	Set FileName      = Nothing
	Set FileVerify    = Nothing
	Set strComputer   = Nothing
	Set objFile       = Nothing
	Set FSO           = Nothing
	Set objWMIService = Nothing
	Set strList       = Nothing

End Sub

'*******************************************************************************

Sub MountWIM()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM WIMFile   : WIMFile   = Chr(32) & "/wimfile:" & RelativePath & strImageName
	DIM Index     : Index     = Chr(32) & "/index:1"
	DIM MountDIR  : MountDIR  = Chr(32) & "/mountdir:" & RelativePath & "mount"
	DIM MountFile : MountFile = "DISM.exe /mount-wim" & WIMFile & Index & MountDIR

	oShell.Run MountFile, 1, True

	REM Cleanup Local Variables
	Set Index     = Nothing
	Set MountDIR  = Nothing
	Set MountFile = Nothing
	Set oShell    = Nothing
	Set WIMFile   = Nothing

End Sub

'*******************************************************************************

Sub ImageMounted()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	If FSO.FolderExists(RelativePath & "Mount\Windows") Then
		MsgBox(strImageName & Chr(32) & "is mounted")
	Else
		MsgBox(strImageName & Chr(32) & "failed to mount")
	End If
	
	REM Cleanup Local Objects
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set RelativePath = Nothing
	Set strImageName = Nothing

End Sub
