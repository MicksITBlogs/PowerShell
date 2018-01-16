'*******************************************************************************
'     Program: Install.vbs
'      Author: Mick Pletcher
'        Date: 09 March 2011
'    Modified:
'
'     Program: VerifyBaseBuild
'     Version: N/A
' Description: This will check for installed programs by verifying the existance
'			   of the uninstall registry key. The programs will submit the results
'			   to the log file.
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   3) Check if LocalAdming is in Administrators Group
'			   4) Check if RDP is enabled
'			   5) Check if VBScript RunAs Admin exists
'			   6) Microsoft .Net Framework 1.1
'			   7) Sun Java Runtime
'			   8) Apple Quicktime
'			   9) Bentley Prerequisite
'			  10) CAD Standards
'			  11) Make Directories
'			  12) GSP Vision
'			  13) GSP Way
'			  14) GSP Enterprise Search
'			  15) Advertisement Wizard
'			  16) Microsoft Office 2007
'			  17) Microsoft Office Communicator 2007
'			  18) Microsoft Live Meeting
'			  19) Seavus Project Viewer
'			  20) Autodesk TruView 2011
'			  21) Adobe Flash
'			  22) Bentley View
'			  23) Windows XP Mode
'			  24) GSP PDF2
'			  25) GS&P Directory File Service Shortcut
'			  26) Equitrac
'			  27) Check if Remote Registry is enabled
'			  28) PDFx
'			  29) Bentley XM Folder
'			  30) Microsoft DaRT
'			  31) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Constants
CONST LogFile       = "VerifyBaseBuild.log"
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "VerifyBaseBuild"


REM Define Global Variables
DIM LogFolder    : LogFolder        = TempFolder & LogFolderName & "\"
DIM MsgBoxVar    : MsgBoxVar        = ""
DIM RelativePath : Set RelativePath = Nothing

REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Create Log File
CreateLogFile()
REM Check if LocalAdming is in Administrators Group
CheckLocalAdming()
REM Check RDP is enabled
CheckRDP()
REM Check if VBScript RunAs Admin exists
CheckVBScriptRunAs()
REM Check for Microsoft .Net Framework 1.1
MicrosoftDotNetFramework1DOT1()
REM Check for Sun Java Runtime
SunJavaRuntime()
REM Check for Apple Quicktime
AppleQuicktime()
REM Check for Bentley Prerequisite
BentleyPrerequisites()
REM Check for CAD Standards
CADStandards()
REM Check for Make Directories
MakeDirectories()
REM Check for GSP Vision
GSPVision()
REM Check for GSP Way
GSPWay()
REM Check for GSP Enterprise Search
GSPEnterpriseSearch()
REM Check for Advertisement Wizard
AdvertisementWizard()
REM Check for Microsoft Office 2007
MicrosoftOffice2007()
REM Check for Microsoft Office Communicator 2007
MicrosoftOfficeCommunicator2007()
REM Check for Microsoft Live Meeting
MicrosoftLiveMeeting()
REM Check for Seavus Project Viewer
SeavusProjectViewer()
REM Check for Adobe Flash
AdobeFlash()
REM Check for Bentley View
BentleyView()
REM Check for Windows XP Mode
WindowsXPMode()
REM Check for GSP PDF2
GSPPDF2()
REM Check for GS&P Directory File Service Shortcut
GSPDirectoryFileServiceShortcut()
REM Check for Equitrac
Equitrac()
REM Check if Remote Registry is enabled
CheckRemoteRegistry()
REM Pop up window displaying errors
'DisplayErrors()
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

Sub CreateLogFolder()

	REM Define Local Objects
	DIM FSO : SET FSO = CreateObject("Scripting.FileSystemObject")

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

Sub CreateLogFile()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.CreateTextFile(LogFolder & LogFile, True)

	FileTxt.Close

	REM Cleanup Local Variables
	Set FSO     = Nothing
	Set FileTxt = Nothing

End Sub

'*******************************************************************************

Sub CheckLocalAdming()

	REM Define Local Constants
	CONST strComputer = "."
	CONST strUserName = "nash\localadming"
	
	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)
	DIM Group   : Set Group = GetObject("WinNT://" & strComputer & "/Administrators,group")

	REM Define Local Variables
	DIM aMember : Set aMember = Nothing
	
	For Each aMember In Group.Members
		If aMember.Name = strUserName Then
			FileTxt.WriteLine("LocalAdming is present")
		Else
			FileTxt.WriteLine("LocalAdming is missing")
		End If
	Next
	FileTxt.Close
	
	REM Cleanup Local Variables
	Set aMember = Nothing
	Set FileTxt = Nothing
	Set FSO     = Nothing
	Set Group   = Nothing

End Sub

'*******************************************************************************

Sub CheckRDP()

	REM Define Local Constants
	CONST HKEY_LOCAL_MACHINE = &H80000002
	CONST strComputer        = "."

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)
	DIM oReg    : Set oReg = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" &_ 
							 strComputer & "\root\default:StdRegProv")

	REM Define Local Variables
	DIM dwValue      : Set dwValue  = Nothing
	DIM StdOut       : Set StdOut   = WScript.StdOut
	DIM strKeyPath   : strKeyPath   = "SYSTEM\CurrentControlSet\Control\Terminal Server"
	DIM strValueName : strValueName = "fDenyTSConnections"

	On Error Resume Next

	oReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,strValueName,dwValue
	If dwValue = 1 Then
		FileTxt.WriteLine("Remote Desktop is Currently Disabled")
	ElseIf dwValue = 0 then
		FileTxt.WriteLine("Remote Desktop is Currently Enabled")
	End If
	FileTxt.Close
	
	REM Cleanup Local Variables
	Set dwValue      = Nothing
	Set FileTxt      = Nothing
	Set FSO          = Nothing
	Set oReg         = Nothing
	Set StdOut       = Nothing
	Set StrKeyPath   = Nothing
	Set StrValueName = Nothing

End Sub

'*******************************************************************************

Sub CheckVBScriptRunAs()

	REM Define Local Constants
	CONST HKLM        = &H80000002
	CONST strComputer = "."

	REM Define Local Objects
	DIM FSO         : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt     : Set FileTxt     = FSO.OpenTextFile(LogFolder & LogFile, 8, True)
	DIM objRegistry : Set objRegistry = GetObject("winmgmts:\\" & strComputer & "\root\default:StdRegProv")

	REM Define Local Variables
	DIM dwValue      : Set dwValue  = Nothing
	DIM strKeyPath   : strKeyPath   = "SOFTWARE\Classes\VBSFile\Shell\runas\Command"
	DIM strValueName : strValueName = ""

	objRegistry.GetStringValue HKLM,strKeyPath,strValueName,dwValue
	If IsNull(dwValue) Then
		FileTxt.WriteLine("VBScript RunAs key does NOT exist")
	Else
		FileTxt.WriteLine("VBScript RunAs key EXISTS")
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set dwValue      = Nothing
	Set FileTxt      = Nothing
	Set FSO          = Nothing
	Set objRegistry  = Nothing
	Set strKeyPath   = Nothing
	Set strValueName = Nothing


End Sub

'*******************************************************************************

Sub MicrosoftDotNetFramework1DOT1()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM Directory  : Directory      = "C:\Windows\Microsoft.NET\Framework\v1.1.4322"
	DIM FolderTest : Set FolderTest = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{CB2F7EDD-9D1F-43C1-90FC-4F52EAE172A1}\"
	DIM Program    : Program        = "Microsoft .Net Framework 1.1"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FolderTest = DirExists(Directory)
	If (KeyTest = True) AND (FolderTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set Directory  = Nothing
	Set FileTxt    = Nothing
	Set FolderTest = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub SunJavaRuntime()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\Java\jre6\bin\java.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{26A24AE4-039D-4CA4-87B4-2F83216024FF}\"
	DIM Program    : Program        = "Java(TM) 6 Update 24"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub AppleQuicktime()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\QuickTime\QuickTimePlayer.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{57752979-A1C9-4C02-856B-FBB27AC4E02C}\"
	DIM Program    : Program        = "Quicktime"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub BentleyPrerequisites()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM KeyTest1 : Set KeyTest1 = Nothing
	DIM KeyTest2 : Set KeyTest2 = Nothing
	DIM KeyTest3 : Set KeyTest3 = Nothing
	DIM RegKey1  : RegKey1      = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{FB97C283-1F3C-42D4-AE01-ADC1DC12F774}\"
	DIM Program1 : Program1     = "Microsoft Visual Basic for Applications core"
	DIM RegKey2  : RegKey2      = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{A13D16C5-38A9-4D96-9647-59FCCAB12A85}\"
	DIM Program2 : Program2     = "Microsoft Visual Basic for Applications localized"
	DIM RegKey3  : RegKey3      = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{2EA870FA-585F-4187-903D-CB9FFD21E2E0}"
	DIM Program3 : Program3     = "DHTML Editing Component for Applications"
	DIM Program  : Program      = "Bentley Prerequisites"
	DIM Output   : Output       = Program & Chr(32) & "=" & Chr(32)

	KeyTest1 = KeyExists(RegKey1)
	KeyTest2 = KeyExists(RegKey2)
	KeyTest3 = KeyExists(RegKey3)
	If KeyTest1 = True Then
		If KeyTest2 = True Then
			If KeyTest3 = True Then
				FileTxt.WriteLine(Output & KeyTest3)
			Else
				FileTxt.WriteLine(Output & "False")
				MsgBoxVar = OutPut & "False" & Chr(13)
			End If
		End If
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set FileTxt  = Nothing
	Set FSO      = Nothing
	Set KeyTest1 = Nothing
	Set KeyTest2 = Nothing
	Set KeyTest3 = Nothing
	Set oShell   = Nothing
	Set Output   = Nothing
	Set Program  = Nothing
	Set Program1 = Nothing
	Set Program2 = Nothing
	Set Program3 = Nothing
	Set RegKey1  = Nothing
	Set RegKey2  = Nothing
	Set RegKey3  = Nothing

End Sub

'*******************************************************************************

Sub CADStandards()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM Directory  : Directory      = "C:\cad_stds\"
	DIM FolderTest : Set FolderTest = Nothing
	DIM Program    : Program        = "CAD_STDS"
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	FolderTest = DirExists(Directory)
	FileTxt.WriteLine(Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & FolderTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set Directory  = Nothing
	Set FileTxt    = Nothing
	Set FolderTest = Nothing
	Set FSO        = Nothing
	Set Program    = Nothing
	Set Output     = Nothing

End Sub

'*******************************************************************************

Sub MakeDirectories()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM CADSTDSFolder : CADSTDSFolder  = "C:\cad_stds\"
	DIM fldrGSP       : fldrGSP        = "c:\Program Files\GSP\"
	DIM fldrDocProp   : fldrDocProp    = "c:\Program Files\GSP\DocProp\"
	DIM fldrDGN       : fldrDGN        = "c:\DGN\"
	DIM fldrTmp       : fldrTmp        = "c:\tmp\"
	DIM fldrTemp      : fldrTemp       = "c:\Temp\"
	DIM fldrBackup    : fldrBackup     = "c:\backup\"
	DIM fldrProgGSP   : fldrProgGSP    = "c:\ProgramGSP\"
	DIM FolderTest    : Set FolderTest = Nothing
	DIM Output        : Output         = Chr(32) & "=" & Chr(32)

	FolderTest = DirExists(CADSTDSFolder)
	FileTxt.WriteLine(CADSTDSFolder & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & CADSTDSFolder & OutPut & FolderTest & Chr(13)
	End If
	FolderTest = DirExists(fldrGSP)
	FileTxt.WriteLine(fldrGSP & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & fldrGSP & OutPut & FolderTest & Chr(13)
	End If
	FolderTest = DirExists(fldrDocProp)
	FileTxt.WriteLine(fldrDocProp & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & fldrDocProp & OutPut & FolderTest & Chr(13)
	End If
	FolderTest = DirExists(fldrDGN)
	FileTxt.WriteLine(fldrDGN & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & fldrDGN & OutPut & FolderTest & Chr(13)
	End If
	FolderTest = DirExists(fldrTmp)
	FileTxt.WriteLine(fldrTmp & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & fldrTmp & OutPut & FolderTest & Chr(13)
	End If
	FolderTest = DirExists(fldrTemp)
	FileTxt.WriteLine(fldrTemp & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & fldrTemp & OutPut & FolderTest & Chr(13)
	End If
	FolderTest = DirExists(fldrBackup)
	FileTxt.WriteLine(fldrBackup & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & fldrBackup & OutPut & FolderTest & Chr(13)
	End If
	FolderTest = DirExists(fldrProgGSP)
	FileTxt.WriteLine(fldrProgGSP & Output & FolderTest)
	If FolderTest = False Then
		MsgBoxVar = MsgBoxVar & fldrProgGSP & OutPut & FolderTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set CADSTDSFolder = Nothing
	Set FileTxt       = Nothing
	Set fldrBackup    = Nothing
	Set fldrDocProp   = Nothing
	Set fldrDGN       = Nothing
	Set fldrGSP       = Nothing
	Set fldrProgGSP   = Nothing
	Set fldrTemp      = Nothing
	Set fldrTmp       = Nothing
	Set FSO           = Nothing
	Set Output        = Nothing

End Sub

'*******************************************************************************

Sub GSPVision()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File     : File         = "C:\Users\Public\Desktop\Vision.lnk"
	DIM FileTest : Set FileTest = Nothing
	DIM Program  : Program      = "GS&P Vision"
	DIM Output   : Output       = Program & Chr(32) & "=" & Chr(32)

	FileTest = FileExists(File)
	FileTxt.WriteLine(Output & FileTest)
	If FileTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & FileTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File     = Nothing
	Set FileTest = Nothing
	Set FileTxt  = Nothing
	Set FSO      = Nothing
	Set Program  = Nothing
	Set Output   = Nothing

End Sub

'*******************************************************************************

Sub GSPWay()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File     : File         = "C:\Users\Public\Desktop\GSPway.lnk"
	DIM FileTest : Set FileTest = Nothing
	DIM Program  : Program      = "GS&P Way"
	DIM Output   : Output       = Program & Chr(32) & "=" & Chr(32)

	FileTest = FileExists(File)
	FileTxt.WriteLine(Output & FileTest)
	If FileTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & FileTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File     = Nothing
	Set FileTest = Nothing
	Set FileTxt  = Nothing
	Set FSO      = Nothing
	Set Program  = Nothing
	Set Output   = Nothing

End Sub

'*******************************************************************************

Sub GSPEnterpriseSearch()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File     : File         = "C:\Users\Public\Desktop\Enterprise Search.LNK"
	DIM FileTest : Set FileTest = Nothing
	DIM Program  : Program      = "GS&P Enterprise Search"
	DIM Output   : Output       = Program & Chr(32) & "=" & Chr(32)

	FileTest = FileExists(File)
	FileTxt.WriteLine(Output & FileTest)
	If FileTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & FileTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File     = Nothing
	Set FileTest = Nothing
	Set FileTxt  = Nothing
	Set FSO      = Nothing
	Set Program  = Nothing
	Set Output   = Nothing

End Sub

'*******************************************************************************

Sub AdvertisementWizard()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File     : File         = "C:\Users\Public\Desktop\GSP Advertised Programs.lnk"
	DIM FileTest : Set FileTest = Nothing
	DIM Program  : Program      = "GS&P Advertised Programs"
	DIM Output   : Output       = Program & Chr(32) & "=" & Chr(32)

	FileTest = FileExists(File)
	FileTxt.WriteLine(Output & FileTest)
	If FileTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & FileTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File     = Nothing
	Set FileTest = Nothing
	Set FileTxt  = Nothing
	Set FSO      = Nothing
	Set Program  = Nothing
	Set Output   = Nothing

End Sub

'*******************************************************************************

Sub MicrosoftOffice2007()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\Microsoft Office\Office12\OUTLOOK.EXE"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{90120000-0011-0000-0000-0000000FF1CE}\"
	DIM Program    : Program        = "Office 2007"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub MicrosoftOfficeCommunicator2007()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\Microsoft Office Communicator\communicator.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{0D1CBBB9-F4A8-45B6-95E7-202BA61D7AF4}\"
	DIM Program    : Program        = "Communicator 2007"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.WriteLine(Output & ProgTest)
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub MicrosoftLiveMeeting()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\Microsoft Office\Live Meeting 8\Console\PWConsole.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{AC388C78-2619-452C-BFBE-FABCC3194387}\"
	DIM Program    : Program        = "Live Meeting"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub SeavusProjectViewer()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\Seavus\Seavus Project Viewer\SeavusProjectViewer.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{EC852FE4-9F93-4152-ADB8-916623FB45AA}\"
	DIM Program    : Program        = "Seavus Project Viewer"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub AdobeFlash()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM KeyTest    : Set KeyTest = Nothing
	DIM RegKey     : RegKey      = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{148D9D03-5D23-4D4F-B5D0-BA6030C45DCF}\"
	DIM Program    : Program     = "Adobe Flash"
	DIM Output     : Output      = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTxt.WriteLine(Output & KeyTest)
	If KeyTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & KeyTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set FileTxt = Nothing
	Set FSO     = Nothing
	Set KeyTest = Nothing
	Set oShell  = Nothing
	Set Output  = Nothing
	Set Program = Nothing
	Set RegKey  = Nothing

End Sub

'*******************************************************************************

Sub BentleyView()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\Bentley\View V8i\View\BentleyView.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{87D6CF41-5817-4725-8AB2-90E6B20EDE02}\"
	DIM Program    : Program        = "Bentley View"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub WindowsXPMode()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files\Windows XP Mode\Windows XP Mode base.vhd"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{1374CC63-B520-4f3f-98E8-E9020BF01CFF}\"
	DIM Program    : Program        = "Windows XP Mode"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub GSPPDF2()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\GSPPDF2\pdfwriter.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\GSP PDF Creator 2\"
	DIM Program    : Program        = "GSPPDF2"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub GSPDirectoryFileServiceShortcut()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File     : File         = "C:\Users\Public\Desktop\GS&P Directory File Service.lnk"
	DIM FileTest : Set FileTest = Nothing
	DIM Program  : Program      = "GS&P Directory File Service"
	DIM Output   : Output       = Program & Chr(32) & "=" & Chr(32)

	FileTest = FileExists(File)
	FileTxt.WriteLine(Output & FileTest)
	If FileTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & FileTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File     = Nothing
	Set FileTest = Nothing
	Set FileTxt  = Nothing
	Set FSO      = Nothing
	Set Program  = Nothing
	Set Output   = Nothing

End Sub

'*******************************************************************************

Sub Equitrac()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files\Equitrac\Professional\Client\EQToolTray.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{C8DED4CE-A2CF-4370-8A7E-96D941126F97}\"
	DIM Program    : Program        = "Equitrac"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing

End Sub

'*******************************************************************************

Sub CheckRemoteRegistry()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM ArrComputer   : ArrComputer       = Array(".")
	DIM ArrServices   : ArrServices       = Array("Remote Registry")
	DIM colItems      : Set colItems      = Nothing
	DIM objItem       : Set objItem       = Nothing
	DIM objWMIService : Set objWMIService = Nothing
	DIM Service       : Set Service       = Nothing
	DIM strComputer   : strComputer       = "."

	For Each strComputer In ArrComputer
		For Each Service In ArrServices
			Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
			Set colItems = objWMIService.ExecQuery("Select * from Win32_Service where DisplayName = '" & Service & "'")
			For Each objItem in colItems
				If objItem.State = "Running" then
					FileTxt.WriteLine("Remote Registry service is running")
				Else
					FileTxt.WriteLine("Remote Registry service is NOT running")
				End If
			Next
		Next
	Next
	FileTxt.Close

	REM Cleanup Local Variables
	Set ArrComputer   = Nothing
	Set ArrServices   = Nothing
	Set colItems      = Nothing
	Set FileTxt       = Nothing
	Set FSO           = Nothing
	Set objItem       = Nothing
	Set objWMIService = Nothing
	Set Service       = Nothing
	Set strComputer   = Nothing

End Sub

'*******************************************************************************

Sub PDFx()

	REM Define Local Objects
	DIM FSO     : SET FSO     = CreateObject("Scripting.FileSystemObject")
	DIM oShell  : SET oShell  = CreateObject("Wscript.Shell")
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM File       : File           = "C:\Program Files (x86)\PDFx\PDFx.exe"
	DIM FileTest   : Set FileTest   = Nothing
	DIM KeyTest    : Set KeyTest    = Nothing
	DIM RegKey     : RegKey         = "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\{33B72057-339D-4D08-BC19-3452C7C807EB}\"
	DIM Program    : Program        = "PDFx2"
	DIM ProgTest   : Set ProgTest   = Nothing
	DIM Output     : Output         = Program & Chr(32) & "=" & Chr(32)

	KeyTest = KeyExists(RegKey)
	FileTest = FileExists(File)
	If (KeyTest = True) AND (FileTest = True) then
		ProgTest = True
	Else
		ProgTest = False
	End If
	FileTxt.WriteLine(Output & ProgTest)
	If ProgTest = False Then
		MsgBoxVar = MsgBoxVar & OutPut & ProgTest & Chr(13)
	End If
	FileTxt.Close

	REM Cleanup Local Variables
	Set File       = Nothing
	Set FileTxt    = Nothing
	Set FileTest   = Nothing
	Set FSO        = Nothing
	Set KeyTest    = Nothing
	Set oShell     = Nothing
	Set Output     = Nothing
	Set Program    = Nothing
	Set ProgTest   = Nothing
	Set RegKey     = Nothing


End Sub

'*******************************************************************************

Sub XMBentleyExists()

	REM Define Local Objects
	DIM FileTxt : Set FileTxt = FSO.OpenTextFile(LogFolder & LogFile, 8, True)

	REM Define Local Variables
	DIM FolderTest : Set FolderTest = Nothing
	DIM XMBentleyFolder : XMBentleyFolder = "C:\Users\Default\AppData\Roaming\XMBENTLEY\"

	FolderTest = DirExists(XMBentleyFolder)
	If FolderTest = False Then
		FileTxt.WriteLine(XMBentleyFolder & Chr(32) & "does not exist")
	Else
		FileTxt.WriteLine(XMBentleyFolder & Chr(32) & "exists")
	End If

	REM Cleanup Local Variables
	Set FileTxt         = Nothing
	Set FolderTest      = Nothing
	Set XMBentleyFolder = Nothing

End Sub

'*******************************************************************************

Function KeyExists(Key)

	REM Define Local Objects
	DIM oShell : Set oShell = CreateObject("WScript.Shell")

	On Error Resume Next
	oShell.RegRead (Key)
	If Err = 0 Then
		KeyExists = True
	Else
		KeyExists = False
	End If

	REM Cleanup Local Variables
	Set oShell = Nothing

End Function

'*******************************************************************************

Function FileExists(File)

	REM Define Local Objects
	DIM FSO : SET FSO = CreateObject("Scripting.FileSystemObject")

	If FSO.FileExists(File) then
		FileExists = True
	Else
		FileExists = False
	End If

	REM Cleanup Local Variables
	Set FSO = Nothing

End Function

'*******************************************************************************

Function DirExists(Folder)

	REM Define Local Objects
	DIM FSO : SET FSO = CreateObject("Scripting.FileSystemObject")

	If FSO.FolderExists(Folder) then
		DirExists = True
	Else
		DirExists = False
	End If

	REM Cleanup Local Variables
	Set FSO = Nothing

End Function

'*******************************************************************************

Sub DisplayErrors()

	If MsgBoxVar = "" Then
		MsgBoxVar = "No Errors"
	End If
	WScript.Echo MsgBoxVar

End Sub

'*******************************************************************************
Sub GlobalVariableCleanup()

	Set LogFolder    = Nothing
	Set MsgBoxVar    = Nothing
	Set RelativePath = Nothing

End Sub