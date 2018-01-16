'*******************************************************************************
'      Author: Mick Pletcher
'        Date: 29 October 2012
'    Modified:
'
'     Program: SMSCache
'     Version:
' Description: This will retrieve the SMS/SCCM cache size and amount of memory
'			   in use to return to SMS via a MIF this script modifies.
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "SMSCache"

REM Define Global Variables
DIM CACHESIZE    : Set CACHESIZE    = Nothing
DIM INUSE        : Set INUSE        = Nothing
DIM LogFolder    : LogFolder        = TempFolder & LogFolderName & "\"
DIM RelativePath : Set RelativePath = Nothing


REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Get Cache Info
GetCacheInfo()
REM Create MIF File to be copied to NOIDMIF directory
CreateMIF()
REM Generate MIF File
GenerateMIF()
REM Copy MIF to NOIDMIF directory
CopyMIF()
REM Initiate Hardware Inventory
InitiateHardwareInventory()
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

Sub GetCacheInfo()

	DIM objWMIService : Set objWMIService = GetObject("winmgmts:\\.\root\ccm\softmgmtagent")
	DIM colCacheInfo  : Set colCacheInfo = objWMIService.ExecQuery("SELECT * FROM CacheConfig")
	DIM objCacheInfo  : Set objCacheInfo = Nothing

	For Each objCacheInfo In colCacheInfo
		INUSE = objCacheInfo.INUSE
		CACHESIZE = objCacheInfo.Size
	Next

	REM Cleanup Local Memory
	Set colCacheInfo  = Nothing
	Set objCacheInfo  = Nothing
	Set objWMIService = Nothing

End Sub

'*******************************************************************************

Sub CreateMIF()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	If FSO.FileExists(RelativePath & "CacheInfo.mif") Then
		If FSO.FileExists(RelativePath & "SMSCache.mif") Then
			FSO.DeleteFile(RelativePath & "SMSCache.mif")
		End If
		FSO.CopyFile RelativePath & "CacheInfo.mif", RelativePath & "SMSCache.mif", True
	End If

	REM Cleanup Local Memory
	Set FSO = Nothing

End Sub

'*******************************************************************************

Sub GenerateMIF()

	REM Define Local Constants
	CONST ForReading = 1
	CONST ForWriting = 2

	REM Define Local Objects
	DIM File          : File              = RelativePath & "SMSCache.mif"
	DIM strOld01      : strOld01          = "               Value = " & Chr(34) & "INUSE" & Chr(34)
	DIM strNew01      : strNew01          = "               Value = " & Chr(34) & INUSE & Chr(34)
	DIM strOld02      : strOld02          = "               Value = " & Chr(34) & "CACHESIZE" & Chr(34)
	DIM strNew02      : strNew02          = "               Value = " & Chr(34) & CACHESIZE & Chr(34)
	DIM objFSO        : Set objFSO        = CreateObject("Scripting.FileSystemObject")
	DIM objFile       : Set objFile       = objFSO.getFile(File)
	DIM objTextStream : Set objTextStream = objFile.OpenAsTextStream(ForReading)
	DIM strInclude    : strInclude        = objTextStream.ReadAll

	objTextStream.Close
	Set objTextStream = Nothing

	If InStr(strInclude,strOld01) > 0 Then
		strInclude = Replace(strInclude,strOld01,strNew01)
		Set objTextStream = objFile.OpenAsTextStream(ForWriting)
		objTextStream.Write strInclude
		objTextSTream.Close
		Set objTextStream = Nothing
	End If
	If InStr(strInclude,strOld02) > 0 Then
		strInclude = Replace(strInclude,strOld02,strNew02)
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
	Set strNew01      = Nothing
	Set strNew02      = Nothing
	Set strOld01      = Nothing
	Set strOld02      = Nothing

End Sub

'*******************************************************************************

Sub CopyMIF()

	REM Define Local Objects
	DIM FSO      : Set FSO = CreateObject("Scripting.FileSystemObject")
	DIM NOIDMIFS : Set NOIDMIFS = Nothing

	If FSO.FolderExists("C:\Program Files (x86)\") Then
		NOIDMIFS = "C:\Windows\SysWOW64\CCM\Inventory\noidmifs\"
	Else
		NOIDMIFS = "C:\Windows\System32\CCM\Inventory\noidmifs\"
	End If
	IF FSO.FileExists(NOIDMIFS & "SMSCache.mif") Then
		FSO.DeleteFile NOIDMIFS & "SMSCache.mif", True
	End IF
	FSO.CopyFile RelativePath & "SMSCache.mif", NOIDMIFS, True
	If FSO.FileExists(RelativePath & "SMSCache.mif") Then
		FSO.DeleteFile(RelativePath & "SMSCache.mif")
	End If

	REM Cleanup Local Memory
	Set FSO      = Nothing
	Set NOIDMIFS = Nothing

End Sub

'*******************************************************************************

Sub InitiateHardwareInventory()

	On Error Resume Next

	REM Declare Local Objects
	DIM oCPAppletMgr   : Set oCPAppletMgr   = CreateObject("CPApplet.CPAppletMgr")
	DIM oClientAction  : Set oClientAction  = Nothing
	DIM oClientActions : Set oClientActions = oCPAppletMgr.GetClientActions()

	For Each oClientAction In oClientActions
		If oClientAction.Name = "Hardware Inventory Collection Cycle" Then
			oClientAction.PerformAction
		End If
	Next
	
	REM Cleanup Local Memory
	Set oCPAppletMgr   = Nothing
	Set oClientAction  = Nothing
	Set oClientActions = Nothing

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set CACHESIZE    = Nothing
	Set INUSE        = Nothing
	Set LogFolder    = Nothing
	Set RelativePath = Nothing

End Sub