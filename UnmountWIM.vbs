'*******************************************************************************
'     Program: UnmountWIM.vbs
'      Author: Mick Pletcher
'        Date: 22 February 2010
'    Modified:
'
' Description: This script will unmount the current mounted WIM file.
'			   1) Define Relative Path
'			   2) Select the WIM file
'			   3) Mount the WIM file
'			   4) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Global Variables
DIM RelativePath : Set RelativePath = Nothing

DefineRelativePath()
UnmountWIM()
ImageUnmounted()
GlobalVariableCleanup()

'*******************************************************************************

Sub DefineRelativePath()

	REM Get File Name with full relative path
	RelativePath = WScript.ScriptFullName
	REM Remove file name, leaving relative path only
	RelativePath = Left(RelativePath, InStrRev(RelativePath, "\"))

End Sub

'*******************************************************************************

Sub UnmountWIM()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
'	DIM Unmount : Unmount = Chr(34) & "C:\Program Files\Windows AIK\Tools\x86\imagex.exe" & Chr(34) & " /unmount mount /commit"
	DIM MountDIR   : MountDIR   = Chr(32) & "/MountDir:" & RelativePath & "Mount"
	DIM Parameters : Parameters = Chr(32) & "/commit"
	DIM Unmount    : Unmount    = "DISM /Unmount-WIM" & MountDIR & Parameters

	oShell.Run Unmount, 1, True

	REM Cleanup Local Variables
	Set MountDIR   = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing
	Set Unmount    = Nothing

End Sub

'*******************************************************************************

Sub ImageUnmounted()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	If NOT FSO.FolderExists(RelativePath & "Mount\Windows") Then
		MsgBox("Image is unmounted")
	Else
		MsgBox("Image failed to unmount")
	End If
	
	REM Cleanup Local Objects
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set RelativePath = Nothing

End Sub
