'*******************************************************************************
'     Program: FlashBIOS.vbs
'      Author: Mick Pletcher
'        Date: 04 March 2010
'    Modified:
' Description: Flashes the BIOS, unattended. This script will only push header
'			   (.HDR) files to the system's CMOS for BIOS upgrade. The .HDR 
'			   file will need to be extracted from BIOS upgrades. New Computer
'			   models will need to be added to the GetComputerModel()
'			   procedure, and old models removed. When adding new computers,
'			   the relative path must be placed in front of the .HDR filename.
'              1) Define relative installation path
'              2) Retrieve the computer model and assign .HDR file
'              3) Flash the BIOS if Computer Model was found
'              4) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Variables
DIM BIOSVer      : Set BIOSVer      = Nothing
DIM Flash        : Flash            = False
DIM RelativePath : Set RelativePath = Nothing

REM Define the relative installation path
DefineRelativePath()
REM Retrieve the computer model
GetComputerModel()
REM Flash the BIOS if Computer Model was found
If Flash then
	FlashBIOS()
End If
REM Cleanup Global Variables
GlobalVariableCleanup()

'*******************************************************************************
'*******************************************************************************

Sub DefineRelativePath()

	REM Define Local Objects
	DIM oShell : Set oShell = CreateObject("WScript.Shell")

	REM Get File Name with full relative path
	RelativePath = WScript.ScriptFullName
	REM Remove file name, leaving relative path only
	RelativePath = Left(RelativePath, InStrRev(RelativePath, "\"))

	REM Cleanup Local Variables
	Set oShell = Nothing

End Sub

'*******************************************************************************

Sub GetComputerModel()

	REM Define Local Varaibles
	DIM CompModel       : Set CompModel       = Nothing
	DIM objComputer     : Set objComputer     = Nothing
	DIM strComputer     : strComputer = "."

	REM Define Local Objects
	DIM objWMI          : Set objWMI = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" _
							& strComputer & "\root\cimv2")
	DIM colSettingsComp : Set colSettingsComp = objWMI.ExecQuery("Select * from Win32_ComputerSystem")

	For Each objComputer in colSettingsComp
		CompModel = Trim(objComputer.Model)
	Next

	Select Case CompModel
		Case "Latitude D410"
			BIOSVer = RelativePath & "D410.EXE"
			Flash = True
		Case "Latitude D600"
			BIOSVer = RelativePath & "D600.EXE"
			Flash = True
		Case "Latitude D610"
			BIOSVer = RelativePath & "D610.EXE"
			Flash = True
		Case "Latitude D620"
			BIOSVer = RelativePath & "D620.EXE"
			Flash = True
		Case "Latitude D630"
			BIOSVer = RelativePath & "D630.EXE"
			Flash = True
		Case "Latitude D810"
			BIOSVer = RelativePath & "D810.EXE"
			Flash = True
		Case "Latitude D820"
			BIOSVer = RelativePath & "D820.EXE"
			Flash = True
		Case "Latitude D830"
			BIOSVer = RelativePath & "D830.EXE"
			Flash = True
		Case "Latitude E6400"
			BIOSVer = RelativePath & "E6400.EXE"
			Flash = True
		Case "Latitude E6410"
			BIOSVer = RelativePath & "E6410.EXE"
			Flash = True
		Case "Latitude E6500"
			BIOSVer = RelativePath & "E6500.EXE"
			Flash = True
		Case "Latitude E6510"
			BIOSVer = RelativePath & "E6510.EXE"
			Flash = True
		Case "Optiplex GX270"
			BIOSVer = RelativePath & "GX270.EXE"
			Flash = True
		Case "Optiplex GX280"
			BIOSVer = RelativePath & "GX280.EXE"
			Flash = True
		Case "Optiplex 745"
			BIOSVer = RelativePath & "O745.EXE"
			Flash = True
		Case "Optiplex 755"
			BIOSVer = RelativePath & "O755.EXE"
			Flash = True
		Case "Precision M4500"
			BIOSVer = RelativePath & "M4500.EXE"
			Flash = True
		Case "Precision M6300"
			BIOSVer = RelativePath & "M6300.EXE"
			Flash = True
		Case "Precision M70"
			BIOSVer = RelativePath & "M70.EXE"
			Flash = True
		Case "Precision M90"
			BIOSVer = RelativePath & "M90.EXE"
			Flash = True
		Case "Precision WorkStation 360"
			BIOSVer = RelativePath & "WS360.EXE"
			Flash = True
		Case "Precision WorkStation 370"
			BIOSVer = RelativePath & "WS370.EXE"
			Flash = True
		Case "Precision WorkStation 380"
			BIOSVer = RelativePath & "WS380.EXE"
			Flash = True
		Case "Precision WorkStation 390"
			BIOSVer = RelativePath & "WS390.EXE"
			Flash = True
		Case "Precision WorkStation T3400"
			BIOSVer = RelativePath & "T3400.EXE"
			Flash = True
	End Select


	REM Cleanup Local Variables
	Set colSettingsComp = Nothing
	Set CompModel       = Nothing
	Set objComputer     = Nothing
	Set objWMI          = Nothing
	Set strComputer     = Nothing

End Sub

'*******************************************************************************

Sub FlashBIOS()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Parameters : Parameters = "-noreboot -nopause"
	DIM Execute    : Execute    = BIOSVer & Chr(32) & Parameters
	
	oShell.Run Execute, 7, True
	
	REM Local Variable Cleanup
	Set oShell     = Nothing
	Set Parameters = Nothing
	Set Execute    = Nothing
End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set BIOSVer      = Nothing
	Set Flash        = Nothing
	Set RelativePath = Nothing

End Sub
