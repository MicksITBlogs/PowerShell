REM Define Local Variables
DIM strComputer : strComputer = "."
	
REM Define Local Objects
DIM FSO           : Set FSO = CreateObject("Scripting.FileSystemObject")
DIM objFile       : Set objFile = FSO.CreateTextFile("Updates.csv", True)
DIM objHotfixFile : Set objHotfixFile = FSO.OpenTextFile("Updates.csv", 1,True)
DIM objWMIService : Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" _
						& strComputer & "\root\cimv2")
DIM colQuickFixes : Set colQuickFixes = objWMIService.ExecQuery _
						("Select * from Win32_QuickFixEngineering")

	
For Each objQuickFix in colQuickFixes
'	Wscript.Echo "Description: " & objQuickFix.Description & Chr(13) & "Hotfix ID: " & objQuickFix.HotFixID
'	objHotfixFile.WriteLine(objQuickFix.Description & Chr(44) & objQuickFix.HotFixID)
	objFile.WriteLine(objQuickFix.Description & Chr(44) & objQuickFix.HotFixID)
Next
Wscript.Echo "Done"
objFile.Close

REM Cleanup Local Objects and Variables
Set colQuickFixes = Nothing
Set FSO           = Nothing
Set objFile       = Nothing
Set objHotfixFile = Nothing
Set objWMIService = Nothing
Set strComputer   = Nothing
