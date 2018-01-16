'*******************************************************************************
'     Program: Install.vbs
'      Author: Mick Pletcher
'        Date: 
'    Modified: 
'
'     Program: 
'     Version: 
' Description: This will install 
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   *) Install 
'			   *) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "UAC"

REM Define Global Variables
DIM Architecture  : Set Architecture = Nothing
DIM CADInstall    : Set CADInstall   = Nothing
DIM LogFolder     : LogFolder        = TempFolder & LogFolderName & "\"
DIM RelativePath  : Set RelativePath = Nothing
DIM UACStatus     : Set UACStatus    = Nothing


REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Determine if x86 or x64
DetermineArchitecture()
REM Check if CAD software is installed
CADInstalled()
REM Disable UAC if CAD software is installed
If CADInstall then
	DisableUAC()
End If
REM Check UAC Status
CheckUACStatus()
GenerateMIF()
REM Copy MIF to noidmifs
CopyMIF()
REM Initiate SMS Hardware Inventory
InitiateSMSHardwareInventory()
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

Sub CADInstalled()

	REM Define Local Objects
	DIM FSO    : Set FSO    = CreateObject("Scripting.FileSystemObject")
	DIM oShell : Set oShell = CreateObject("WScript.Shell")

	REM Define Local Variables
	DIM DataFolder   : Set DataFolder   = Nothing
	DIM DataFile     : Set DataFile     = Nothing
	DIM FileName     : Set FileName     = Nothing
	DIM NumberOfFile : NumberOfFile     = 0
	DIM ProgFilesx86 : ProgFilesx86     = "C:\Program Files (x86)"
	DIM ProgFilesx64 : ProgFilesx64     = "C:\Program Files"

	If FSO.FolderExists(ProgFilesx86) then
		If FSO.FolderExists(ProgFilesx86 & "\Autodesk\") then
			Set DataFolder = FSO.GetFolder(ProgFilesx86 & "\Autodesk\")
			Set DataFile   = DataFolder.Files
			NumberOfFile   = DataFile.Count
		End If
	End If
	If FSO.FolderExists(ProgFilesx64) then
		If FSO.FolderExists(ProgFilesx64 & "\Autodesk\") then
			Set DataFolder = FSO.GetFolder(ProgFilesx64 & "\Autodesk\")
			Set DataFile   = DataFolder.Files
			NumberOfFile   = DataFile.Count
		End If
	End If
	If NumberOfFile > 1 Then
		CADInstall = True
	Else
		CADInstall = False
	End If

	REM Cleanup Local Variables
	Set DataFile     = Nothing
	Set DataFolder   = Nothing
	Set Filename     = Nothing
	Set FSO          = Nothing
	Set NumberOfFile = Nothing
	Set oShell       = Nothing
	Set ProgFilesx86 = Nothing
	Set ProgFilesx64 = Nothing

End Sub

'*******************************************************************************

Sub DisableUAC()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM CMD        : CMD        = "C:\Windows\System32\cmd.exe /c"
	DIM REG        : REG        = Chr(32) & "%windir%\System32\reg.exe"
	DIM Parameters : Parameters = Chr(32) & "ADD HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v EnableLUA /t REG_DWORD /d 0 /f"
	DIM Install    : Install    = CMD & REG & Parameters

	oShell.Run Install, 1, True

	REM Cleanup Variables
	Set CMD        = Nothing
	Set Install    = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing
	Set REG        = Nothing

End Sub

'*******************************************************************************

Sub CheckUACStatus()

	REM Define Local Constants
	CONST HKEY_CURRENT_USER  = &H80000001
	CONST HKEY_LOCAL_MACHINE = &H80000002
	
	REM Define Local Variables
	DIM strComputer  : strComputer  = "."
	DIM StdOut       : Set StdOut   = WScript.StdOut
 	DIM oReg         : Set oReg     = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" &_
										strComputer & "\root\default:StdRegProv")
 	DIM strKeyPath   : strKeyPath   = "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
	DIM strValueName : strValueName = "EnableLUA"
	DIM dwValue      : Set dwValue  = Nothing

	REM Get UAC value
	oReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,dwValue
	If dwValue = 1 then
		UACStatus = "Enabled"
	Else
		UACStatus = "Disabled"
	End If
	
	REM Local Variable Cleanup
	Set dwValue      = Nothing
	Set oReg         = Nothing
	Set StdOut       = Nothing
	Set strComputer  = Nothing
	Set strKeyPath   = Nothing
	Set strValueName = Nothing

End Sub

'*******************************************************************************

Sub GenerateMIF()

	REM Define Local Constants
	CONST ForReading = 1 
	CONST ForWriting = 2 
   
	REM Define Local Objects
	DIM File          : File              = RelativePath & "UAC.mif"
	DIM strOld        : strOld            = Chr(9) & Chr(9) & Chr(9) & "Value =" & Chr(32) & Chr(34) & Chr(34)
	DIM strNew        : strNew            = Chr(9) & Chr(9) & Chr(9) & "Value =" & Chr(32) & UACStatus
	DIM objFSO        : Set objFSO        = CreateObject("Scripting.FileSystemObject") 
	DIM objFile       : Set objFile       = objFSO.getFile(File) 
	DIM objTextStream : Set objTextStream = objFile.OpenAsTextStream(ForReading) 
	DIM strInclude    : strInclude        = objTextStream.ReadAll 

	objTextStream.Close
	Set objTextStream = Nothing

	If InStr(strInclude,strOld) > 0 Then 
		strInclude = Replace(strInclude,strOld,strNew) 
		Set objTextStream = objFile.OpenAsTextStream(ForWriting) 
		objTextStream.Write strInclude 
		objTextSTream.Close 
		Set objTextStream = Nothing 
	End If 

	REM Cleanup Local Variables
	Set File          = Nothing
	Set objFile       = Nothing 
	Set objFSO        = Nothing
	Set objTextStream = Nothing
	Set strInclude    = Nothing
	Set strNew        = Nothing
	Set strOld        = Nothing

End Sub

'*******************************************************************************

Sub InitiateSMSHardwareInventory()

	On Error Resume Next

	DIM oCPAppletMgr   : Set oCPAppletMgr   = CreateObject("CPApplet.CPAppletMgr")
	DIM oClientAction  : Set oClientAction  = Nothing
	DIM oClientActions : Set oClientActions = oCPAppletMgr.GetClientActions()

	For Each oClientAction In oClientActions
		If oClientAction.Name = "Hardware Inventory Collection Cycle" Then
			oClientAction.PerformAction
		End If
	Next

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set Architecture = Nothing
	Set CADInstall   = Nothing
	Set LogFolder    = Nothing
	Set RelativePath = Nothing
	Set UACStatus    = Nothing

End Sub