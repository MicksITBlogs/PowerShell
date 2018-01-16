'*******************************************************************************
'     Program: CreateUSB.vbs
'      Author: Mick Pletcher
'        Date: 08 February 2010
'    Modified:
'
' Description: This script creates a bootable USB thumb drive from a WIM file.
'			   WinPE must be installed on the machine and its directory
'			   specified in constant WinPELoc with no backslash after it. The
'			   WIM files reside in the WinPELoc directory for which this script
'			   reads from. A diskpart script must also be present in the WinPELOC
'			   directory specifing the parameters for the thumb drive.
'			   1) Partition and Format the USB Thumb Drive
'			   2) Select the WIM file
'			   3) Prompt to remove and reinsert the thumb drive
'			   4) Copy the OS down to the thumb Drive and prompt when complete
'			   5) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Global Constants
CONST WinPELoc = "c:\winpe"

REM Define Global Variables
DIM strImageName : Set strImageName = Nothing

PartitionDisk()
SelectImage()
CopyWIM()
PromptThumbRemoval()
CopyOS()
Complete()
GlobalVariableCleanup()

'*******************************************************************************
'*******************************************************************************

Sub PartitionDisk()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM PartDisk : PartDisk = "diskpart.exe /s" & Chr(32) & WinPELoc & "\usbpartscript.txt"

	oShell.Run PartDisk, 1, True

	REM Cleanup Local Variables
	Set oShell   = Nothing
	Set PartDisk = Nothing

End Sub

'*******************************************************************************

Sub SelectImage()

	REM Define Local Constants
	CONST ForAppending = 2
	CONST strComputer  = "."

	REM Define Local Variables
	DIM Count      : Count = 1
	DIM FileName   : Set FileName      = Nothing
	DIM FileVerify : Set FileVerify    = Nothing
	DIM objFile    : Set objFile       = Nothing
	DIM strList    : strList = "Select an Image File:"

	REM Define Objects
	DIM objFSO        : Set objFSO = CreateObject("Scripting.FileSystemObject")
	DIM objWMIService : Set objWMIService = GetObject("winmgmts:" _
						& "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
	DIM colFileList   : Set colFileList = objWMIService.ExecQuery _
		("ASSOCIATORS OF {Win32_Directory.Name=" & Chr(39) & WinPELoc & Chr(39) & "} Where " _
			& "ResultClass = CIM_DataFile")

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
	Set FileName = Nothing
	Set FileVerify = Nothing
	Set objFile = Nothing

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
	Set objFile       = Nothing
	Set objFSO        = Nothing
	Set objWMIService = Nothing
	Set strList       = Nothing

End Sub

'*******************************************************************************

Sub CopyWIM()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM CopyFile : CopyFile = "xcopy" & Chr(32) & WinPELoc & "\" & strImageName & Chr(32) & WinPELoc & "\iso\sources\boot.wim /y"

	oShell.Run CopyFile, 1, True

	REM Cleanup Local Variables
	Set CopyFile = Nothing
	Set oShell   = Nothing

	End Sub

'*******************************************************************************

Sub PromptThumbRemoval()

	MsgBox("Remove and Re-enter USB Thumb Drive. Press any key to continue")

End Sub

'*******************************************************************************

Sub CopyOS()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM CopyFiles

	CopyFiles = "xcopy" & Chr(32) & WinPELoc & "\iso\*.* /s /e /f e:\"
	oShell.Run CopyFiles, 1, True
	CopyFiles = "xcopy" & Chr(32) & WinPELoc & "\iso\*.* /s /e /f f:\"
	oShell.Run CopyFiles, 1, True

	REM Cleanup Local Variables
	Set oShell    = Nothing
	Set CopyFiles = Nothing

End Sub

'*******************************************************************************

Sub Complete()

	MsgBox("USB Image is Complete")

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set strImageName = Nothing

End Sub