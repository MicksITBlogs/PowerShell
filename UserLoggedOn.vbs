REM ***************************************************************************
REM ***     Program: User Logged On.vbs
REM ***      Author: Mick Pletcher
REM ***     Created: 10 January 2010
REM ***      Edited: 02 October 2012
REM ***
REM *** Description: This script will read from a list of computer names and
REM ***              check to see if a user is logged on. It will write the 
REM ***              status to the output text file for each system read from
REM ***              the input file. This was written like this so that admins
REM ***              can export lists of workstations from SMS/SCCM to find
REM ***              machines with no user logged on for troubleshooting
REM ***              deployments and/or find free machines to test other
REM ***              issues. It will display an error if there is no input
REM ***              file.
REM ***
REM ***************************************************************************

Option Explicit

REM Define Global Constants
CONST InputFileName  = "Workstations.txt"
CONST OutputFileName = "LoggedOn.txt"

REM Define Global Variables
DIM arrComputers    : Set arrComputers    = Nothing
DIM InputFile       : Set InputFile       = Nothing
DIM InputFileExists : Set InputFileExists = Nothing
DIM objIE           : Set objIE           = CreateObject("InternetExplorer.Application")
DIM OutputFile      : Set OutputFile      = Nothing
DIM RelativePath    : Set RelativePath    = Nothing

REM Define Relative Path
DefineRelativePath()
REM Define Input and Output Files
DefineIOFiles()
REM Create Display Window
CreateDisplayWindow()
If InputFileExists then
	REM Read Input File
	ReadInputFile()
	REM Parse Computer Status
	ParseComputerStatus()
Else
	Wscript.Echo " File containing workstation list does not exist."
End If
REM Cleanup Global Memory
CleanupGlobalMemory()

'*******************************************************************************
'*******************************************************************************

Sub DefineRelativePath()

	REM Get File Name with full relative path
	RelativePath = WScript.ScriptFullName
	REM Remove file name, leaving relative path only
	RelativePath = Left(RelativePath, InStrRev(RelativePath, "\"))

End Sub

'*******************************************************************************

Sub DefineIOFiles()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	InputFile  = RelativePath & InputFileName
	OutputFile = RelativePath & OutputFileName
	If FSO.FileExists(InputFile) then
		InputFileExists = True
	Else
		InputFileExists = False
	End If
	If FSO.FileExists(OutputFile) then
		FSO.DeleteFile OutputFile, True
	End If

	REM Cleanup Memory
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub CreateDisplayWindow()

	REM Define Local Constants
	CONST strComputer = "."

	REM Define Local Objects
	DIM objWMIService : Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	DIM colItems      : Set colItems      = objWMIService.ExecQuery ("Select PelsWidth,PelsHeight From Win32_DisplayConfiguration")
	DIM objItem       : Set objItem       = Nothing

	REM Define Local Variables
	DIM intWidth  : intWidth  = 500
	DIM intHeight : intHeight = 300
	DIM intScreenWidth  : Set intScreenWidth  = Nothing
	DIM intScreenHeight : Set intScreenHeight = Nothing

	For Each objItem in colItems
		intScreenWidth  = objItem.PelsWidth
		intScreenHeight = objItem.PelsHeight
	Next
	objIE.Navigate "about:blank"
	objIE.Document.Title = "Users Logged On"
	objIE.Toolbar    = 0
	objIE.StatusBar  = 0
	objIE.AddressBar = 0
	objIE.MenuBar    = 0
	objIE.Resizable  = 0
	objIE.Width      = 500
	objIE.Height     = 300
	While objIE.ReadyState <> 4
		WScript.Sleep 100
	Wend
	objIE.Left = (intScreenWidth / 2) - (intWidth / 2)
	objIE.Top =  (intScreenHeight / 2) - (intHeight / 2)
	objIE.Visible = True

	REM Cleanup Local Variables
	Set colItems        = Nothing
	Set intScreenWidth  = Nothing
	Set intScreenHeight = Nothing
	Set intWidth        = Nothing
	Set intHeight       = Nothing
	Set objItem         = Nothing
	Set objWMIService   = Nothing

End Sub

'******************************************************************************

Sub ReadInputFile()

	REM Define Local Constant
	CONST ForReading = 1

	REM Define Local Variables
	DIM FSO         : Set FSO         = CreateObject("Scripting.FileSystemObject")
	DIM objTextFile : Set objTextFile = FSO.OpenTextFile(InputFile, ForReading)
	DIM strText     : strText         = objTextFile.ReadAll

	objTextFile.Close
	arrComputers = Split(strText, VbCrLf)

	REM Cleanup Local Variables
	Set FSO         = Nothing
	Set objTextFile = Nothing
	Set strText     = Nothing

End Sub

'*******************************************************************************

Sub ParseComputerStatus()

	On Error Resume Next

	REM Define Local Objects
	DIM FSO           : Set FSO           = CreateObject("Scripting.FileSystemObject")
	DIM objFile       : Set objFile       = FSO.CreateTextFile(OutputFile, True)
	DIM objWMIService : Set objWMIService = Nothing

	REM Define Local Variables
	DIM colItems    : Set colItems    = Nothing
	DIM Count       : Count           = 0
	DIM objItem     : Set objItem     = Nothing
	DIM strComputer : Set strComputer = Nothing
	DIM Total       : Set Total       = Nothing

	objIE.Document.Body.InnerHTML = "<font color=black>"
	objIE.Document.Body.InnerHTML = ""
	objIE.Document.Body.InnerHTML = "Scanning Systems..." & "<BR>"
	Count = Count + 1
	Total = UBound(arrComputers)
	For Each strComputer In arrComputers
		Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
		Set colItems = objWMIService.ExecQuery("Select * from Win32_ComputerSystem",,48)
		For Each objItem in colItems
			If IsNull(objItem.UserName) then
				objFile.WriteLine( strComputer & ": ")
			else
				objFile.WriteLine( strComputer & ": " & objItem.UserName )
			End IF
			If Round((Count/Total)*100, 0) <= 100 Then
				objIE.Document.Body.InnerHTML = "<font color=black>"
				objIE.Document.Body.InnerHTML = "Scanning Systems..." & "<BR>" & "<BR>" & Round((Count/Total)*100, 0) & "% complete" 
				Count = Count + 1
			End If
		Next
	Next
	objIE.Document.Body.InnerHTML = "100% complete" & "<BR>" & "<BR>"&_
									Total & Chr(32) & "systems scanned."
	'Wscript.Echo " Query is complete."

	REM Cleanup Local Memory
	Set colItems      = Nothing
	Set Count         = Nothing
	Set FSO           = Nothing
	Set Total         = Nothing
	Set objItem       = Nothing
	Set objFile       = Nothing
	Set objWMIService = Nothing
	Set strComputer   = Nothing

End Sub

'*******************************************************************************

Sub CleanupGlobalMemory()

	Set arrComputers    = Nothing
	Set InputFile       = Nothing
	Set InputFileExists = Nothing
	Set OutputFile      = Nothing
	Set RelativePath    = Nothing

End Sub