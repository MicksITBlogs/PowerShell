'*******************************************************************************
'     Program: Install.vbs
'      Author: Mick Pletcher
'        Date: 23 August 2011
'    Modified:
'
'     Program: SetPageFileSize
'     Version:
' Description: This will set the page file size to double the size of installed
'			   memory.
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   3) Set Page File Size
'			   4) Write Log File
'			   7) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "PageFileSize"

REM Define Global Variables
DIM LogFolder    : LogFolder        = TempFolder & LogFolderName & "\"
DIM Pagefile     : Set Pagefile     = Nothing
DIM RelativePath : Set RelativePath = Nothing
DIM Installed    : Installed        = False

REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Set PageFile Size
SetPagefileSize()
REM Write Log File
WriteLog()
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

Sub SetPagefileSize()

	REM Define Local Constants
	CONST strComputer = "."

	REM Define Local Objects
	DIM oShell        : Set oShell        = CreateObject("Wscript.Shell")
	DIM objWMIService : Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" &_
						strComputer & "\root\cimv2")
	DIM colSettings   : Set colSettings   = objWMIService.ExecQuery("Select * from Win32_ComputerSystem")

	REM Define Local Variables
	DIM Command01   : Command01       = "wmic computersystem where name=" & Chr(34) & "%computername%" & Chr(34) &_
										Chr(32) & "set AutomaticManagedPagefile=False"
	DIM Command02   : Set Command02   = Nothing
	DIM objComputer : Set objComputer = Nothing

	For Each objComputer in colSettings
		Pagefile = objComputer.TotalPhysicalMemory
	Next
	If Pagefile > 1000000000 AND Pagefile < 2000000000 THEN
		Pagefile = "1024" * 2
	ElseIf Pagefile > 2000000000 AND Pagefile < 3000000000 THEN
		Pagefile = "2048" * 2
	ElseIf Pagefile > 3000000000 AND Pagefile < 4000000000 THEN
		Pagefile = "3072" * 2
	ElseIf Pagefile > 4000000000 AND Pagefile < 5000000000 THEN
		Pagefile = "4096" * 2
	ElseIf Pagefile > 5000000000 AND Pagefile < 6000000000 THEN
		Pagefile = "5120" * 2
	ElseIf Pagefile > 6000000000 AND Pagefile < 7000000000 THEN
		Pagefile = "6144" * 2
	ElseIf Pagefile > 7000000000 AND Pagefile < 8000000000 THEN
		Pagefile = "7168" * 2
	ElseIf Pagefile > 8000000000 AND Pagefile < 9000000000 THEN
		Pagefile = "8192" * 2
	ElseIf Pagefile > 9000000000 AND Pagefile < 10000000000 THEN
		Pagefile = "9216" * 2
	ElseIf Pagefile > 10000000000 AND Pagefile < 11000000000 THEN
		Pagefile = "10240" * 2
	ElseIf Pagefile > 11000000000 AND Pagefile < 12000000000 THEN
		Pagefile = "11264" * 2
	ElseIf Pagefile > 12000000000 AND Pagefile < 13000000000 THEN
		Pagefile = "12288" * 2
	ElseIf Pagefile > 13000000000 AND Pagefile < 14000000000 THEN
		Pagefile = "13312" * 2
	ElseIf Pagefile > 14000000000 AND Pagefile < 15000000000 THEN
		Pagefile = "14336" * 2
	ElseIf Pagefile > 15000000000 AND Pagefile < 16000000000 THEN
		Pagefile = "15360" * 2
	ElseIf Pagefile > 16000000000 AND Pagefile < 17000000000 THEN
		Pagefile = "16384" * 2
	ElseIf Pagefile > 17000000000 AND Pagefile < 18000000000 THEN
		Pagefile = "17408" * 2
	ElseIf Pagefile > 18000000000 AND Pagefile < 19000000000 THEN
		Pagefile = "18432" * 2
	ElseIf Pagefile > 19000000000 AND Pagefile < 20000000000 THEN
		Pagefile = "19456" * 2
	ElseIf Pagefile > 20000000000 AND Pagefile < 21000000000 THEN
		Pagefile = "20480" * 2
	ElseIf Pagefile > 21000000000 AND Pagefile < 22000000000 THEN
		Pagefile = "21504" * 2
	ElseIf Pagefile > 22000000000 AND Pagefile < 23000000000 THEN
		Pagefile = "22528" * 2
	ElseIf Pagefile > 23000000000 AND Pagefile < 24000000000 THEN
		Pagefile = "23552" * 2
	ElseIf Pagefile > 24000000000 AND Pagefile < 25000000000 THEN
		Pagefile = "24576" * 2
	ElseIf Pagefile > 25000000000 AND Pagefile < 26000000000 THEN
		Pagefile = "25600" * 2
	ElseIf Pagefile > 26000000000 AND Pagefile < 27000000000 THEN
		Pagefile = "26624" * 2
	ElseIf Pagefile > 27000000000 AND Pagefile < 28000000000 THEN
		Pagefile = "27648" * 2
	ElseIf Pagefile > 28000000000 AND Pagefile < 29000000000 THEN
		Pagefile = "28672" * 2
	ElseIf Pagefile > 29000000000 AND Pagefile < 30000000000 THEN
		Pagefile = "29696" * 2
	ElseIf Pagefile > 30000000000 AND Pagefile < 31000000000 THEN
		Pagefile = "30720" * 2
	ElseIf Pagefile > 31000000000 AND Pagefile < 32000000000 THEN
		Pagefile = "31744" * 2
	ElseIf Pagefile > 31000000000 AND Pagefile < 32000000000 THEN
		Pagefile = "32768" * 2
	End If

	Command02 = "wmic pagefileset where name=" & Chr(34) & "C:\\pagefile.sys" & Chr(34) &_
				Chr(32) & "set InitialSize=" & Pagefile & ",MaximumSize=" & Pagefile

	REM Disable Automatic Pagefile Management
	oShell.Run Command01, 1, True

	REM Set Pagefile size to twice the size of the physical memory
	oShell.Run Command02, 1, True

	REM Cleanup Local Variables
	Set colSettings   = Nothing
	Set Command01     = Nothing
	Set Command02     = Nothing
	Set objComputer   = Nothing
	Set objWMIService = Nothing
	Set oShell        = Nothing

End Sub

'*******************************************************************************

Sub WriteLog()

	REM Define Local Objects
	DIM FSO  : Set FSO = CreateObject("Scripting.FileSystemObject")
	DIM File : Set File = FSO.CreateTextFile(LogFolder & LogFolderName & ".log",True)

	File.WriteLine("PageFile Size has been set to" & Chr(32) & PageFile & Chr(32) & "megabytes.")
	File.Close

	REM Cleanup Local Variables
	Set FSO  = Nothing
	Set File = Nothing

End Sub

'*******************************************************************************
Sub GlobalVariableCleanup()

	Set Installed    = Nothing
	Set LogFolder    = Nothing
	Set Pagefile     = Nothing
	Set RelativePath = Nothing

End Sub