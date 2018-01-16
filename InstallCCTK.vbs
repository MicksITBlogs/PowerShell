'*******************************************************************************
'      Program: Install.vbs
'       Author: Mick Pletcher
'         Date:
'     Modified:
'
'      Program:
'      Version:
'  Description: This will do the following to the MDT/SCCM generated WIM files:
'				inject the Dell CCTK, inject the HAPI drivers, and modify the
'				unattend.xml file.
' Requirements: Microsoft WAIK, location for the locally stored WinPE files
'				(WinPEDIR Global Variable), MDT Server (I have 2 servers
'				MDT01 and MDT02), designation of architecture, and Dell CCTK.
'				NOTE: This script has been created to automate the update process
'				on a Windows 7 64-bit PC, therefor the directory locations of
'				the CCTK files will differ for an x86 machine. 
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "CCTK"
CONST MDT01         = "MDT01"
CONST MDT02         = "MDT02"
CONST WinPEDIR      = "c:\winpe\"
CONST x64           = "x64"
CONST x86           = "x86"

REM Define Global Variables
DIM LogFolder     : LogFolder        = TempFolder & LogFolderName & "\"
DIM RelativePath  : Set RelativePath = Nothing

DefineRelativePath()
REM Refresh Local WIM Files from MDT Servers
	DeleteLocalWIMFiles()
	CopyWIMFiles( MDT01 )
	RenameWIMFiles( MDT01 )
	CopyWIMFiles( MDT02 )
	RenameWIMFiles( MDT02 )
REM Process Local x86 file for MDT01
	MountWIM MDT01,x86
	AddWMI(x86)
	CopyHAPIFiles( x86 )
	CopyCCTKFiles( x86 )
	EditUnattend( x86 )
	DismountWIM()
REM Process Local x64 File for MDT01
	MountWIM MDT01,x64
	AddWMI(x64)
	CopyHAPIFiles( x64 )
	CopyCCTKFiles( x64 )
	EditUnattend( x64 )
	DismountWIM()
REM Process Local x86 File for MDT02
	MountWIM MDT02,x86
	AddWMI(x86)
	CopyHAPIFiles( x86 )
	CopyCCTKFiles( x86 )
	EditUnattend( x86 )
	DismountWIM()
REM Process Local x64 File for MDT02
	MountWIM MDT02,x64
	AddWMI(x64)
	CopyHAPIFiles( x64 )
	CopyCCTKFiles( x64 )
	EditUnattend( x64 )
	DismountWIM()
Complete()
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

Sub DeleteLocalWIMFiles()

	REM Define Local Objects
	DIM FSO    : Set FSO = CreateObject("Scripting.FileSystemObject")
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Parameters : Parameters = "/F /Q"
	DIM sCMD_1     : sCMD_1     = "%COMSPEC% /c del " & RelativePath & "*MDT01.wim"
	DIM sCMD_2     : sCMD_2     = "%COMSPEC% /c del " & RelativePath & "*MDT02.wim" 
	DIM sCMD_3     : sCMD_3     = "%COMSPEC% /c del " & RelativePath & "generic*.wim" 

	oShell.Run sCMD_1 & Parameters, 1, True
	oShell.Run sCMD_2 & Parameters, 1, True
	oShell.Run sCMD_3 & Parameters, 1, True

	REM Cleanup Local Variables
	Set sCMD_1  = Nothing
	Set sCMD_2  = Nothing
	Set sCMD_3  = Nothing
	Set FSO        = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing

End Sub

'*******************************************************************************

Function CopyWIMFiles(Server)

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Source      : Source      = "\\" & Server & "\DeploymentShare\Boot"
	DIM Destination : Destination = "c:\winpe"
	DIM Parameters  : Parameters  = "*.wim /eta /r:1 /w:0"
	DIM Command01   : Command01   = "robocopy" & Chr(32) & Source & Chr(32) & Destination & Chr(32) & Parameters

	oShell.Run Command01, 1, True

	REM Cleanup Local Variables
	Set Command01   = Nothing
	Set Destination = Nothing
	Set oShell      = Nothing
	Set Parameters  = Nothing
	Set Source      = Nothing

End Function

'*******************************************************************************

Function RenameWIMFiles(Server)

	REM Define Local Objects
	DIM FSO    : Set FSO    = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM Source_x86  : Source_x86  = RelativePath & "LiteTouchPE_x86.wim"
	DIM Source_x64  : Source_x64  = RelativePath & "LiteTouchPE_x64.wim"
	DIM Dest_x86    : Dest_x86    = RelativePath & "LiteTouchPE_x86_" & Server & ".wim"
	DIM Dest_x64    : Dest_x64    = RelativePath & "LiteTouchPE_x64_" & Server & ".wim"

	If FSO.FileExists(Source_x86) then
		If NOT FSO.FileExists(Dest_x86) then
			FSO.MoveFile Source_x86, Dest_x86
		End If
	End If
	If FSO.FileExists(Source_x64) then
		If NOT FSO.FileExists(Dest_x64) then
			FSO.MoveFile Source_x64, Dest_x64
		End If
	End If

	REM Cleanup Local Variables
	Set Dest_x86    = Nothing
	Set Dest_x64    = Nothing
	Set FSO         = Nothing
	Set Source_x86  = Nothing
	Set Source_x64  = Nothing

End Function

'*******************************************************************************

Function MountWIM(Server,Architecture)

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM MountDIR   : MountDIR   = RelativePath & "Mount"
	DIM WIMFile    : WIMFile    = RelativePath & "LiteTouchPE_" & Architecture & "_" & Server & ".wim"
	DIM Command01  : Command01  = "DISM /Mount-Wim /WIMFile:" & WIMFile & Chr(32) & "/Index:1 /MountDIR:" & MountDIR

	oShell.Run Command01, 1, True

	REM Cleanup Local Variables
	Set Command01  = Nothing
	Set MountDIR   = Nothing
	Set oShell     = Nothing
	Set WIMFile    = Nothing

End Function

'*******************************************************************************

Sub AddWMI(Architecture)

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Image           : Image			  = "/Image:" & RelativePath & "Mount"
	DIM AddPackage      : AddPackage	  = "/Add-Package"
	DIM PackagePath     : Set PackagePath = Nothing
	DIM PackagePath_x86 : PackagePath_x86 = "/PackagePath:" & Chr(34) &_
											"C:\Program Files\Windows AIK\Tools\PETools\x86\WinPE_FPs\winpe-wmi.cab" & Chr(34)
	DIM PackagePath_x64 : PackagePath_x64 = "/PackagePath:" & Chr(34) &_
											"C:\Program Files\Windows AIK\Tools\PETools\amd64\WinPE_FPs\winpe-wmi.cab" & Chr(34)
	DIM Command01       : Set Command01   = Nothing

	If Architecture = "x86" Then
		PackagePath = PackagePath_x86
	Else
		PackagePath = PackagePath_x64
	End If
	Command01 = "DISM" & Chr(32) & Image & Chr(32) & AddPackage & Chr(32) & PackagePath
	oShell.Run Command01, 1, True

	REM Cleanup Local Variables
	Set AddPackage      = Nothing
	Set Command01       = Nothing
	Set Image           = Nothing
	Set oShell          = Nothing
	Set PackagePath     = Nothing
	Set PackagePath_x86 = Nothing
	Set PackagePath_x64 = Nothing

End Sub

'*******************************************************************************

Sub CreateFolderStructure(Architecture)

	REM Define Local Objects
	DIM FSO    : Set FSO = CreateObject("Scripting.FileSystemObject")
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Command01     : Set Command01 = Nothing
	DIM Directory     : Set Directory = Nothing
	DIM Directory_x86 : Directory_x86 = RelativePath & "Mount\CCTK\x86\HAPI"
	DIM Directory_x64 : Directory_x64 = RelativePath & "Mount\CCTK\x86_64\HAPI"

	If Architecture = "x86" Then
		Directory = Directory_x86
	Else
		Directory = Directory_x64
	End If
	If NOT FSO.FolderExists(Directory) then
		FSO.CreateFolder(Directory)
	End If

	REM Cleanup Local Variables
	Set Command01     = Nothing
	Set Directory     = Nothing
	Set Directory_x86 = Nothing
	Set Directory_x64 = Nothing
	Set FSO           = Nothing
	Set oShell        = Nothing

End Sub

'*******************************************************************************

Sub CopyHAPIFiles(Architecture)

	REM Define Local Objects
	DIM FSO    : Set FSO    = CreateObject("Scripting.FileSystemObject")
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM sCMD_1     : Set sCMD_1 = Nothing
	DIM sCMD_2     : Set sCMD_2 = Nothing
	DIM Source     : Set Source = Nothing
	DIM Source_x86 : Source_x86 = "C:\Program Files (x86)\Dell\CCTK\X86\HAPI\*.*"
	DIM Source_x64 : Source_x64 = "C:\Program Files (x86)\Dell\CCTK\X86_64\HAPI\*.*"
	DIM Dest       : Set Dest   = Nothing
	DIM Dest_x86   : Dest_x86   = RelativePath & "mount\CCTK\x86\HAPI"
	DIM Dest_x64   : Dest_x64   = RelativePath & "mount\CCTK\x86_64\HAPI"

	If Architecture = "x86" Then
		Source = Source_x86
		Dest   = Dest_x86
	Else
		Source = Source_x64
		Dest   = Dest_x64
	End If
	sCMD_1 = "%COMSPEC% /c mkdir " & Dest
	If NOT FSO.FolderExists(Dest) then
		oShell.Run sCMD_1, 1, True
	End If
	sCMD_2 = "%COMSPEC% /c copy " & Chr(34) & Source & Chr(34) & Chr(32) & Dest & Chr(32) & "/V /Y"
'	If FSO.FolderExists(Source) then
		oShell.Run sCMD_2, 1, True
'	End If

	REM Cleanup Local Variables
	Set Dest       = Nothing
	Set Dest_x86   = Nothing
	Set Dest_x64   = Nothing
	Set FSO        = Nothing
	Set oShell     = Nothing
	Set sCMD_1     = Nothing
	Set sCMD_2     = Nothing
	Set Source     = Nothing
	Set Source_x86 = Nothing
	Set Source_x64 = Nothing

End Sub

'*******************************************************************************

Sub CopyCCTKFiles(Architecture)

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM CCTKFile   : CCTKFile   = "cctk.exe"
	DIM MXMLFile   : MXMLFile   = "mxml1.dll"
	DIM INIFile    : INIFile    = "multiplatform.ini"
	DIM PCIFile    : PCIFile    = "pci.ids"
	DIM NetSource  : NetSource  = "\\global.gsp\data\clients\na_clients\Dell\BIOS\"
	DIM Source     : Set Source = Nothing
	DIM Source_x86 : Source_x86 = "C:\Program Files (x86)\Dell\CCTK\X86\"
	DIM Source_x64 : Source_x64 = "C:\Program Files (x86)\Dell\CCTK\X86_64\"
	DIM Dest       : Set Dest   = Nothing
	DIM Dest_x86   : Dest_x86   = RelativePath & "mount\CCTK\x86\"
	DIM Dest_x64   : Dest_x64   = RelativePath & "mount\CCTK\x86_64\"

	If Architecture = "x86" Then
		Source = Source_x86
		Dest   = Dest_x86
	Else
		Source = Source_x64
		Dest   = Dest_x64
	End If
	If NOT FSO.FolderExists(Dest) then
		FSO.CreateFolder(Dest)
	End If
	If FSO.FolderExists(Source) then
		FSO.CopyFile Source & CCTKFile, Dest, 1
	End If
	If FSO.FolderExists(Source) then
		FSO.CopyFile NetSource & INIFile, Dest, 1
	End If
	If FSO.FolderExists(Source) then
		FSO.CopyFile Source & PCIFile, Dest, 1
	End If
	If FSO.FolderExists(Source) then
		FSO.CopyFile Source & MXMLFile, Dest, 1
	End If

	REM Cleanup Local Variables
	Set CCTKFile   = Nothing
	Set INIFile    = Nothing
	Set MXMLFile   = Nothing
	Set PCIFile    = Nothing
	Set Dest       = Nothing
	Set Dest_x86   = Nothing
	Set Dest_x64   = Nothing
	Set FSO        = Nothing
	Set Source     = Nothing
	Set Source_x86 = Nothing
	Set Source_x64 = Nothing

End Sub

'*******************************************************************************

Sub EditUnattend(Architecture)

REM Define Local Constants
CONST ForReading = 1 
CONST ForWriting = 2 

REM Define Local Objects
DIM File          : File              = "C:\winpe\mount\unattend.xml"
DIM strOld1       : strOld1           = "<Order>1</Order>"
DIM strNew1       : strNew1           = "<Order>4</Order>"
DIM strOld2       : strOld2           = "<RunSynchronous>"
DIM strNew2       : strNew2           = "<RunSynchronous>" & Chr(10) &_
										"<RunSynchronousCommand wcm:action=" & Chr(34) & "add" & Chr(34) & ">" & Chr(10) &_
										"<Description>Map BIOS Drive</Description>" & Chr(10) &_
										"<Order>1</Order>" & Chr(10) &_
										"<Path>net use \\global.gsp\data\clients\na_clients\dell\bios /user:win2kload 2kosload</Path>" & Chr(10) &_
										"</RunSynchronousCommand>" & Chr(10) &_
										"<RunSynchronousCommand wcm:action=" & Chr(34) & "add" & Chr(34) & ">" & Chr(10) &_
										"<Description>Initiate HAPI</Description>" & Chr(10) &_
										"<Order>2</Order>" & Chr(10) &_
										"<Path>X:\CCTK\x86_64\HAPI\hapint -i -k C-C-T-K -p X:\CCTK\x86_64\HAPI\</Path>" & Chr(10) &_
										"</RunSynchronousCommand>" & Chr(10) &_
										"<RunSynchronousCommand wcm:action=" & Chr(34) & "add" & Chr(34) & ">" & Chr(10) &_
										"<Description>Set BIOS Settings</Description>" & Chr(10) &_
										"<Order>3</Order>" & Chr(10) &_
										"<Path>x:\CCTK\x86_64\cctk.exe -i \\global.gsp\data\clients\na_clients\Dell\BIOS\multiplatform.ini</Path>" & Chr(10) &_
										"</RunSynchronousCommand>"
DIM objFSO        : Set objFSO        = CreateObject("Scripting.FileSystemObject") 
DIM objFile       : Set objFile       = objFSO.getFile(File) 
DIM objTextStream : Set objTextStream = objFile.OpenAsTextStream(ForReading) 
DIM strInclude    : strInclude        = objTextStream.ReadAll 

objTextStream.Close
Set objTextStream = Nothing

If InStr(strInclude,strOld1) > 0 Then 
	strInclude = Replace(strInclude,strOld1,strNew1) 
	Set objTextStream = objFile.OpenAsTextStream(ForWriting) 
	objTextStream.Write strInclude 
	objTextSTream.Close 
	Set objTextStream = Nothing 
End If 
If InStr(strInclude,strOld2) > 0 Then 
	strInclude = Replace(strInclude,strOld2,strNew2) 
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
Set strNew1       = Nothing
Set strNew2       = Nothing
Set strOld1       = Nothing
Set strOld2       = Nothing

End Sub

'*******************************************************************************

Sub DismountWIM()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM MountDIR   : MountDIR   = RelativePath & "Mount"
	DIM Command01  : Command01  = "DISM /Unmount-WIM /MountDir:" & MountDIR & Chr(32) & "/commit"

	oShell.Run Command01, 1, True

	REM Cleanup Local Variables
	Set Command01  = Nothing
	Set MountDIR   = Nothing
	Set oShell     = Nothing

End Sub

'*******************************************************************************

Sub Complete()

	MsgBox "Process Complete"

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set LogFolder    = Nothing
	Set RelativePath = Nothing

End Sub