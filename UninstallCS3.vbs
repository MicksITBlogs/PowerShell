'*******************************************************************************
'      Author: Mick Pletcher
'        Date: 02 November 2012
'    Modified: 
'
'     Program: Adobe CS3 Uninstaller
'     Version: 
' Description: This will uninstall Design Standard CS3
'*******************************************************************************
Option Explicit

REM Define Global Variables
DIM RelativePath  : Set RelativePath = Nothing

REM Define the relative installation path
DefineRelativePath()
REM Install 
Uninstall()
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

Sub Uninstall()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Uninstall  : Uninstall  = RelativePath & "setup.exe" & Chr(32) & "--mode=silent --deploymentFile=" &_
								  RelativePath & "deployment\uninstall.xml --skipProcessCheck=1"

	oShell.Run Uninstall, 1, True

	REM Cleanup Local Variables
	Set Uninstall = Nothing
	Set oShell    = Nothing

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set RelativePath = Nothing

End Sub