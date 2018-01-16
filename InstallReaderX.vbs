'*******************************************************************************
'     Program: InstallReaderX.vbs
'      Author: Mick Pletcher
'        Date: 11 May 2012
'    Modified: 
'
'     Program: Adobe Reader
'     Version: X
' Description: This will install 
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   3) Uninstall Previous Versions
'			   4) Install Current Version
'			   5) Configure Automatic Update
'			   6) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "ReaderX"

REM Define Global Variables
DIM Architecture  : Set Architecture = Nothing
DIM LogFolder     : LogFolder        = TempFolder & LogFolderName & "\"
DIM RelativePath  : Set RelativePath = Nothing

REM Define the relative installation path
DefineRelativePath()
REM Determine Architecture
DetermineArchitecture()
REM Create the Log Folder
CreateLogFolder()
REM Uninstall Previous Version
Uninstall()
REM Install Current Version
Install()
REM Configure Automatic Update
AutoUpdate()
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

Sub DetermineArchitecture()

	REM Define Local Objects
	DIM WshShell : Set WshShell = CreateObject("WScript.Shell")

	REM Define Local Variables
	DIM OsType : OsType = WshShell.RegRead("HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment\PROCESSOR_ARCHITECTURE")

	If OsType = "x86" then
		Architecture = "x86"
	elseif OsType = "AMD64" then
		Architecture = "x64"
	end if
	
	REM Cleanup Local Variables
	Set WshShell = Nothing
	Set OsType   = Nothing

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

Sub Uninstall()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Parameters      : Parameters      = Chr(32) & "/qb- /norestart"
	DIM Uninstall4x     : Uninstall4x     = "C:\WINDOWS\IsUninst.exe -a -f" & Chr(34) &_
											"C:\Program Files\Common Files\Adobe\Acrobat 4.0\NT\Uninst.isu" &_
											Chr(34) & Chr(32) & "-c" & Chr(34) &_
											"C:\Program Files\Common Files\Adobe\Acrobat 4.0\NT\Uninst.dll" & Chr(34)
	DIM Uninstall5x     : Uninstall5x     = "C:\WINDOWS\IsUninst.exe -a -f" & Chr(34) &_
											"C:\Program Files\Common Files\Adobe\Acrobat 5.0\NT\Uninst.isu" &_
											Chr(34) & Chr(32) & "-c" & Chr(34) &_
											"C:\Program Files\Common Files\Adobe\Acrobat 5.0\NT\Uninst.dll" & Chr(34)
	DIM Uninstall60     : Uninstall60     = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-000000000001}" & Parameters
	DIM Uninstall601    : Uninstall601    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A00000000001}" & Parameters
	DIM Uninstall602    : Uninstall602    = "msiexec.exe /x {AC76BA86-0000-0000-0000-6028747ADE01}" & Parameters
	DIM Uninstall603    : Uninstall603    = "msiexec.exe /x {AC76BA86-0000-7EC8-7489-000000000603}" & Parameters
	DIM Uninstall604    : Uninstall604    = "msiexec.exe /x {AC76BA86-0000-7EC8-7489-000000000604}" & Parameters
	DIM Uninstall605    : Uninstall605    = "msiexec.exe /x {AC76BA86-0000-7EC8-7489-000000000605}" & Parameters
	DIM Uninstall606    : Uninstall606    = "msiexec.exe /x {AC76BA86-0000-7EC8-7489-000000000606}" & Parameters
	DIM Uninstall705    : Uninstall705    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A70500000002}" & Parameters
	DIM Uninstall707    : Uninstall707    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A70700000002}" & Parameters
	DIM Uninstall708    : Uninstall708    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A70800000002}" & Parameters
	DIM Uninstall709    : Uninstall709    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A70900000002}" & Parameters
	DIM Uninstall71x    : Uninstall71x    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A71000000002}" & Parameters
	DIM Uninstall8DICT1 : Uninstall8DICT1 = "msiexec.exe /x {AC76BA86-7AD7-5464-3428-800000000003}" & Parameters
	DIM Uninstall8DICT2 : Uninstall8DICT2 = "msiexec.exe /x {AC76BA86-7AD7-5464-3428-800000000004}" & Parameters
	DIM Uninstall80     : Uninstall80     = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A80000000002}" & Parameters
	DIM Uninstall81x    : Uninstall81x    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A81000000003}" & Parameters
	DIM Uninstall811    : Uninstall811    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A81100000003}" & Parameters
	DIM Uninstall812    : Uninstall812    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A81200000003}" & Parameters
	DIM Uninstall812U   : Uninstall812U   = "msiexec.exe /x {6846389C-BAC0-4374-808E-B120F86AF5D7}" & Parameters
	DIM Uninstall81xx   : Uninstall81xx   = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A81300000003}" & Parameters
	DIM Uninstall82x    : Uninstall82x    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A82000000003}" & Parameters
	DIM Uninstall830    : Uninstall830    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A83000000003}" & Parameters
	DIM Uninstall9DICT  : Uninstall9DICT  = "msiexec.exe /x {AC76BA86-7AD7-5464-3428-900000000004}" & Parameters
	DIM Uninstall91x    : Uninstall91x    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A81000000003}" & Parameters
	DIM Uninstall920    : Uninstall920    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A92000000001}" & Parameters
	DIM Uninstall93x    : Uninstall93x    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A93000000001}" & Parameters
	DIM Uninstall940    : Uninstall940    = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-A94000000001}" & Parameters
	DIM UninstallXDICT  : UninstallXDICT  = "msiexec.exe /x {AC76BA86-7AD7-5464-3428-A00000000004}" & Parameters
	DIM Uninstall1000   : Uninstall1000   = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-AA0000000001}" & Parameters
	DIM Uninstall101x   : Uninstall101x   = "msiexec.exe /x {AC76BA86-7AD7-1033-7B44-AA1000000001}" & Parameters

   'oShell.Run Uninstall4x,     1, True
	oShell.Run Uninstall60,     1, True
	oShell.Run Uninstall601,    1, True
	oShell.Run Uninstall602,    1, True
	oShell.Run Uninstall603,    1, True
	oShell.Run Uninstall604,    1, True
	oShell.Run Uninstall605,    1, True
	oShell.Run Uninstall606,    1, True
	oShell.Run Uninstall705,    1, True
	oShell.Run Uninstall707,    1, True
	oShell.Run Uninstall708,    1, True
	oShell.Run Uninstall709,    1, True
	oShell.Run Uninstall71x,    1, True
	oShell.Run Uninstall8DICT1, 1, True
	oShell.Run Uninstall8DICT2, 1, True
	oShell.Run Uninstall80,     1, True
	oShell.Run Uninstall81x,    1, True
	oShell.Run Uninstall811,    1, True
	oShell.Run Uninstall812,    1, True
	oShell.Run Uninstall812U,   1, True
	oShell.Run Uninstall81xx,   1, True
	oShell.Run Uninstall82x,    1, True
	oShell.Run Uninstall830,    1, True
	oShell.Run Uninstall9DICT,  1, True
	oShell.Run Uninstall91x,    1, True
	oShell.Run Uninstall920,    1, True
	oShell.Run Uninstall93x,    1, True
	oShell.Run Uninstall940,    1, True
	oShell.Run UninstallXDICT,  1, True
	oShell.Run Uninstall1000,   1, True
	oShell.Run Uninstall101x,   1, True

	REM Cleanup Local Variables
	Set oShell          = Nothing
	Set Parameters      = Nothing
	Set Uninstall4x     = Nothing
	Set Uninstall60     = Nothing
	Set Uninstall601    = Nothing
	Set Uninstall602    = Nothing
	Set Uninstall603    = Nothing
	Set Uninstall604    = Nothing
	Set Uninstall605    = Nothing
	Set Uninstall606    = Nothing
	Set Uninstall705    = Nothing
	Set Uninstall707    = Nothing
	Set Uninstall708    = Nothing
	Set Uninstall709    = Nothing
	Set Uninstall71x    = Nothing
	Set Uninstall8DICT1 = Nothing
	Set Uninstall8DICT2 = Nothing
	Set Uninstall80     = Nothing
	Set Uninstall81x    = Nothing
	Set Uninstall811    = Nothing
	Set Uninstall812    = Nothing
	Set Uninstall812U   = Nothing
	Set Uninstall81xx   = Nothing
	Set Uninstall82x    = Nothing
	Set Uninstall830    = Nothing
	Set Uninstall9DICT  = Nothing
	Set Uninstall91x    = Nothing
	Set Uninstall920    = Nothing
	Set Uninstall93x    = Nothing
	Set Uninstall940    = Nothing
	Set UninstallXDICT  = Nothing
	Set Uninstall1000   = Nothing
	Set Uninstall101x   = Nothing

End Sub

'*******************************************************************************

Sub Install()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM MSI        : MSI        = Chr(32) & RelativePath & "AcroRead.msi"
	DIM Logs       : Logs       = Chr(32) & "/lvx" & Chr(32) & LogFolder & LogFolderName & ".log"
	DIM Transforms : Transforms = Chr(32) & "TRANSFORMS=" & RelativePath & "Transform.mst"
	DIM Parameters : Parameters = Chr(32) & "/qb- /norestart"
	DIM InstallX   : InstallX    = "msiexec.exe /i" & MSI & Transforms & Logs & Parameters

	oShell.Run InstallX, 1, True

	REM Cleanup Local Variables
	Set InstallX   = Nothing
	Set Logs       = Nothing
	Set MSI        = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing
	Set Transforms = Nothing

End Sub

'*******************************************************************************

Sub AutoUpdate()

	REM Define Local Constants
	CONST HKEY_LOCAL_MACHINE = &H80000002
	
	REM Define Local Objects
	DIM oReg			  : Set oReg          = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" &_
											    strComputer & "\root\default:StdRegProv")
	DIM oShell		      : SET oShell        = CreateObject("Wscript.Shell")
	DIM strKeyPath_x86    : strKeyPath_x86    = "SOFTWARE\Adobe\Adobe ARM\1.0\ARM"
	DIM strKeyPath_x64    : strKeyPath_x64    = "SOFTWARE\Wow6432Node\Adobe\Adobe ARM\1.0\ARM"
	DIM strDWORDValueName : strDWORDValueName = "iCheckReader"
	DIM dwValue           : dwValue           = "3"

	If Architecture = "x86" then
		oReg.DeleteValue HKEY_LOCAL_MACHINE,strKeyPath_x86,strDWORDValueName
		oReg.SetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath_x86,strDWORDValueName,dwValue
		'oShell.regwrite "HKLM\SOFTWARE\Adobe\Adobe ARM\1.0\ARM\iCheckReader", 3, "REG_DWORD"
	Else
		oReg.DeleteValue HKEY_LOCAL_MACHINE,strKeyPath_x64,strDWORDValueName
		oReg.SetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath_x64,strDWORDValueName,dwValue
		'oShell.regwrite "HKLM\SOFTWARE\Wow6432Node\Adobe\Adobe ARM\1.0\ARM\iCheckReader", 3, "REG_DWORD"
	End If

	REM Cleanup Local Variables
	Set dwValue           = Nothing
	Set oReg              = Nothing
	Set oShell            = Nothing
	Set strDWORDValueName = Nothing
	Set strKeyPath_x86    = Nothing
	Set strKeyPath_x64    = Nothing
	
End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set LogFolder    = Nothing
	Set RelativePath = Nothing

End Sub