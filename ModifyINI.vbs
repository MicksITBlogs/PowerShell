'*******************************************************************************
'      Author: Mick Pletcher
'        Date: 09 November 2012
'    Modified:
'
' Description: This script will modify the contents of the revit.ini files
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "RevitINI"

REM Define Global Variables
DIM FSO          : Set FSO          = CreateObject("Scripting.FileSystemObject")
DIM LogFolder    : LogFolder        = TempFolder & LogFolderName & "\"
DIM LogFile      : LogFile          = LogFolder & LogFolderName & ".txt"
DIM RelativePath : Set RelativePath = Nothing

REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Backup the old ini file and make desired changes to ini files across profiles
EditINIFiles()
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
	DIM objFile : Set objFile = Nothing

	If NOT FSO.FolderExists(TempFolder) then
		FSO.CreateFolder(TempFolder)
	End If
	If NOT FSO.FolderExists(LogFolder) then
		FSO.CreateFolder(LogFolder)
	End If
	If FSO.FileExists(LogFile) then
		FSO.DeleteFile Logfile, True
	End If
	If NOT FSO.FileExists(LogFile) then
		Set objFile = FSO.CreateTextFile(LogFile)
	End If

	REM Cleanup Local Memory
	Set objFile = Nothing

End Sub

'*******************************************************************************

Sub EditINIFiles()

	On Error Resume Next

	REM Define Local Objects
	DIM Folder                    : Set Folder                = FSO.GetFolder("C:\Users")
	DIM SubFolder                 : Set SubFolder             = Nothing
	DIM SubFolders                : Set SubFolders            = Folder.Subfolders

	REM Define Local Variables
	DIM DataLibraryLocations      : DataLibraryLocations      = "DataLibraryLocations=Imperial Library=\\global.gsp\data\gspm\CAD_ADSK_STDS\Revit\GSP\Libraries\US Imperial\, Imperial Detail Library=\\global.gsp\data\gspm\CAD_ADSK_STDS\Revit\GSP\Libraries\US Imperial\Detail Items\, GSP CADD=\\global.gsp\data\cadd\"
	DIM DefaultTemplate           : DefaultTemplate           = "DefaultTemplate=\\global.gsp\data\gspm\CAD_ADSK_STDS\Revit\GSP\Templates\US Imperial\Architectural_default.rte"
	DIM Username                  : Username                  = "Username="
	DIM DisplayRecentFilesPage    : DisplayRecentFilesPage    = "DisplayRecentFilesPage=0"
	DIM FamilyTemplatePath        : FamilyTemplatePath        = "FamilyTemplatePath=\\global.gsp\data\gspm\CAD_ADSK_STDS\Revit\GSP\Family Templates\English_I"
	DIM UserDataCacheRevitIniPath : UserDataCacheRevitInipath = "C:\Program Files\Autodesk\Revit Architecture 2012\Program\UserDataCache\revit.ini"
	DIM INIFile                   : INIFile                   = 0

	REM Backup and edit the master INI file
	If FSO.FileExists(UserDataCacheRevitInipath) Then
		REM Backup revit.ini file
		FSO.CopyFile UserDataCacheRevitInipath, Left(UserDataCacheRevitInipath, InStr(1,UserDataCacheRevitInipath,".")-1) & "_old.ini", True
		REM Make changes to ini file
		Call ParseFile(UserDataCacheRevitIniPath, DataLibraryLocations, Len(Left(DataLibraryLocations, InStr(1,DataLibraryLocations,"=")-1)))
		Call ParseFile(UserDataCacheRevitIniPath, DefaultTemplate, Len(Left(DefaultTemplate, InStr(1,DefaultTemplate,"=")-1)))
		Call ParseFile(UserDataCacheRevitIniPath, DisplayRecentFilesPage, Len(Left(DisplayRecentFilesPage, InStr(1,DisplayRecentFilesPage,"=")-1)))
		Call ParseFile(UserDataCacheRevitIniPath, FamilyTemplatePath, Len(Left(FamilyTemplatePath, InStr(1,FamilyTemplatePath,"=")-1)))
		Call AddSpace()
	End If
	REM Make changes to the revit.ini file under each profile
	For Each Subfolder in Subfolders
		IF (Subfolder.Name <> "Administrator") AND (Subfolder.Name <> "win2kload") AND _
		   (Subfolder.Name <> "All Users") AND (Subfolder.Name <> "Default") AND _
		   (Subfolder.Name <> "Default User") AND (Subfolder.Name <> "Public") THEN
			INIFile = Folder & Chr(92) & Subfolder.Name & "\AppData\Roaming\Autodesk\Revit\Autodesk Revit Architecture 2012\revit.ini"
			If FSO.FileExists(INIFile) then
				REM Backup the INI file
				FSO.CopyFile INIFile, Left(INIFile, InStr(1,INIFile,".")-1) & "_old.ini", True
				REM Parse through the INI file to make changes to each of the desired fields
				Call ParseFile(INIFile, DataLibraryLocations, Len(Left(DataLibraryLocations, InStr(1,DataLibraryLocations,"=")-1)))
				Call ParseFile(INIFile, DefaultTemplate, Len(Left(DefaultTemplate, InStr(1,DefaultTemplate,"=")-1)))
				Call ParseFile(INIFile, DisplayRecentFilesPage, Len(Left(DisplayRecentFilesPage, InStr(1,DisplayRecentFilesPage,"=")-1)))
				Call ParseFile(INIFile, FamilyTemplatePath, Len(Left(FamilyTemplatePath, InStr(1,FamilyTemplatePath,"=")-1)))
				Call AddSpace()
			End If
		End If
	Next

	REM Cleanup Local Memory
	Set DataLibraryLocations      = Nothing
	Set DefaultTemplate           = Nothing
	Set DisplayRecentFilesPage    = Nothing
	Set FamilyTemplatePath        = Nothing
	Set Folder                    = Nothing
	Set INIFile                   = Nothing
	Set SubFolder                 = Nothing
	Set SubFolders                = Nothing
	Set UserDataCacheRevitInipath = Nothing
	Set Username                  = Nothing

End Sub

'*******************************************************************************

Sub ParseFile(FileName, TxtString, StringLength)

	REM Define Local Variables
	DIM Count        : Count        = 0
	DIM ForAppending : ForAppending = 8
	DIM ForReading   : ForReading   = 1
	DIM ForWriting   : ForWriting   = 2
	DIM LineCount    : LineCount    = 0
	DIM StrContents  : StrContents  = 0
	DIM Written      : Written      = False

	REM Define Local Objects
	DIM File    : Set File = FSO.OpenTextFile(FileName, ForReading)
	DIM strText : strText  = File.ReadAll

	File.Close
	REM Divide contents into lines
	StrContents = Split(strText, vbNewLine)
	REM Count the number of lines
	LineCount = UBound(StrContents)
	REM Open File to write to it
	Set File = FSO.OpenTextFile(FileName, ForWriting)
	do while Count < LineCount
		IF NOT Left(StrContents(Count), StringLength) = "Username=" Then
			If (Left(StrContents(Count), StringLength) = Left(TxtString, StringLength)) Then
				File.WriteLine(TxtString)
				Written = True
			Else
				File.WriteLine(StrContents(Count))
			End If
		End If
		Count = Count + 1
	Loop
	If NOT Written Then
		File.WriteLine(TxtString)
	End If
	File.Close
	If FSO.FileExists(FileName) Then
		If FSO.FileExists(LogFile) Then
			Set File = FSO.OpenTextFile(LogFile, ForAppending)
			If Count = LineCount Then
				File.Write(Left(TxtString, InStr(1,TxtString,"=")-1) & Chr(32) & "was written to" & Chr(32) & FileName & Chr(13))
				File.Close
			Else
				File.Write(TxtString & Chr(32) & "was not written to FileName!")
			End If
		End If
	End If

	REM Cleanup Local Memory
	Set Count        = Nothing
	Set File         = Nothing
	Set ForAppending = Nothing
	Set ForReading   = Nothing
	Set ForWriting   = Nothing
	Set LineCount    = Nothing
	Set StrContents  = Nothing
	Set strText      = Nothing
	Set Written      = Nothing

End Sub

'*******************************************************************************

Sub AddSpace()

	REM Define Local Variables
	DIM ForAppending : ForAppending = 8
	DIM ForReading   : ForReading   = 1
	DIM ForWriting   : ForWriting   = 2

	REM Define Local Objects
	DIM File : Set File = FSO.OpenTextFile(LogFile, ForAppending)

	File.Write(Chr(13))
	File.Close

	REM Cleanup Local Memory
	Set File         = Nothing
	Set ForAppending = Nothing
	Set ForReading   = Nothing
	Set ForWriting   = Nothing

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set FSO          = Nothing
	Set LogFolder    = Nothing
	Set RelativePath = Nothing

End Sub