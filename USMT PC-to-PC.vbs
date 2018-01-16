REM *************************************************************************** 
REM ***     Program: USMT_New_Computer.vbs 
REM ***      Author: Guy Pletcher 
REM ***     Created: 21 February 2010 
REM ***      Edited: 22 July 2010 
REM *** 
REM ***    Description: This script will execute the USMT, migrating data from 
REM ***                 the old machine to the new machine. Both PCs must be on 
REM ***                 the network. You will be prompted to enter the old 
REM ***                 computer name, new computer name, and the username. 
REM ***                 This is the only interaction required. A status window 
REM ***                 will appear giving the status of each state of the 
REM ***                 migration. Error checking has been included in the 
REM ***                 coding and returns an error if one if generated. The USMT 
REM ***                 has been customized for the command prompt window to be 
REM ***                 minimized so that it can be restored if need be for 
REM ***                 troubleshooting/status purposes.  
REM *** 
REM ***                 The global variable, USMTLocation , contains the network 
REM ***                 location of where the USMT 4.0 is located, specifically 
REM ***                 this VBScript. Both USMT 4.0 x86 and x64 must be located 
REM ***                 at % USMTLocation%\x86 and % USMTLocation%\x64, as this 
REM ***                 script is set to automatically determine the architecture 
REM ***                 of the old machine and runs the appropriate USMT version. 
REM ***                 PSTools also needs to be installed at 
REM ***                 %USMTLocation%\PSTools so that PsExec is available to run. 
REM ***                 This is used to run the scanstate, robocopy, and loadstate 
REM ***                 locally on the machines so that bandwidth and speed are 
REM ***                 not compromised.  
REM ***                 1) Create HTML Display Status Window 
REM ***                 2) Enter Source PC, Destination PC, and Username 
REM ***                 3) Delete Old USMT folders and Create New USMT Folders 
REM ***                 4) Determine if the system is x86 or x64 
REM ***                 5) Perform USMT Migration on Old Machine 
REM ***                 6) Exit Script if USMT Migration Failed 
REM ***                 7) Copy Migrated USMT data to New Machine 
REM ***                 8) Load Migrated USMT data on New Machine 
REM ***                 9) Verify USMT 
REM ***                10) Cleanup Global Variables 
REM *** 
REM *************************************************************************** 
 
Option Explicit 
 
REM Define Global Constants 
CONST USMTLocation = "\\global.gsp\data\special\Deploy\USMT40\" 
 
REM Define Global Objects 
DIM objIE : Set objIE = CreateObject("InternetExplorer.Application") 
 
REM Define Global Variables 
DIM OldComputer   : Set OldComputer   = Nothing 
DIM NewComputer   : Set NewComputer   = Nothing 
DIM ReturnCode    : Set ReturnCode    = Nothing 
DIM UserName      : Set UserName      = Nothing 
DIM USMTSourceCMD : USMTSourceCMD     = "0" 
DIM USMTDestCMD   : USMTDestCMD       = "0" 
 
REM Create HTML Display Status Window 
CreateDisplayWindow() 
REM Enter Source PC, Destination PC, and Username 
GetComputerInfo() 
REM Delete Old USMT folders and Create New USMT Folders 
CreateUSMTFolders() 
REM Determine if the system is x86 or x64 
DetermineArchitecture() 
REM Perform USMT Migration on Old Machine 
USMTMigrate() 
REM Exit Script if USMT Migration Failed 
VerifyScanState() 
REM Copy Migrated USMT data to New Machine 
CopyUSMTData() 
REM Load Migrated USMT data on New Machine 
LoadUSMTData() 
REM Verify USMT 
VerifyLoadState() 
REM Cleanup Global Variables 
GlobalVariableCleanUp() 
 
'****************************************************************************** 
'****************************************************************************** 
 
Sub CreateDisplayWindow() 
 
    REM Define Local Constants 
    CONST strComputer = "." 
 
    REM Define Local Objects 
    DIM objWMIService : Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2") 
    DIM colItems      : Set colItems      = objWMIService.ExecQuery ("Select PelsWidth,PelsHeight From Win32_DisplayConfiguration") 
    DIM objItem       : Set objItem       = Nothing 
 
    REM Define Local Variables 
    DIM intWidth  : intWidth  = 320 
    DIM intHeight : intHeight = 240 
    DIM intScreenWidth  : Set intScreenWidth  = Nothing 
    DIM intScreenHeight : Set intScreenHeight = Nothing 
 
    For Each objItem in colItems 
        intScreenWidth  = objItem.PelsWidth 
        intScreenHeight = objItem.PelsHeight 
    Next 
    objIE.Navigate "about:blank" 
    objIE.Toolbar    = 0 
    objIE.StatusBar  = 0 
    objIE.AddressBar = 0 
    objIE.MenuBar    = 0 
    objIE.Resizable  = 0 
    While objIE.ReadyState <> 4 
        WScript.Sleep 100 
    Wend 
    objIE.Left = (intScreenWidth / 2) - (intWidth / 2) 
    objIE.Top =  (intScreenHeight / 2) - (intHeight / 2) 
    objIE.Visible = True 
 
    REM Cleanup Local Variables 
    Set colItems        = Nothing 
    Set intScreenWidth  = Nothing 
    Set intScreenHeight = Nothing 
    Set intWidth        = Nothing 
    Set intHeight       = Nothing 
    Set objItem         = Nothing 
    Set objWMIService   = Nothing 
 
End Sub 
 
'****************************************************************************** 
 
Sub GetComputerInfo() 
 
    OldComputer = InputBox( "Enter the old computer name:" ) 
    NewComputer = InputBox( "Enter the new computer name:" ) 
    UserName    = InputBox( "Enter the username:" ) 
    objIE.Document.WriteLn "<FONT SIZE=8>USMT migration of " & UserName & " from " & OldComputer & " to " & NewComputer & "</FONT><BR><BR><BR>" 
 
End Sub 
 
'****************************************************************************** 
 
Sub CreateUSMTFolders() 
 
    On Error Resume Next 
 
    REM Define Local Objects 
    DIM FSO : SET FSO = CreateObject("Scripting.FileSystemObject") 
 
    REM Define Local Variables 
    DIM comp         : Set comp         = Nothing 
    DIM DeleteFolder : Set DeleteFolder = Nothing 
    DIM TMP          : TMP              = "\\" & OldComputer & "\c$\Temp" 
    DIM MigData      : MigData          = TMP & "\MigData" 
    DIM USMTPath     : USMTPath         = MigData & "\" & UserName & "\" & OldComputer 
 
    objIE.Document.WriteLn "Creating USMT Folders....." 
    REM Delete old USMTPATH, if exists 
    If FSO.FolderExists(USMTPath) then 
        Set DeleteFolder = FSO.GetFolder(USMTPath) 
        DeleteFolder.Delete 
    End If 
    If FSO.FolderExists(MigData & "\" & UserName) then 
        Set DeleteFolder = FSO.GetFolder(MigData & "\" & UserName ) 
        DeleteFolder.Delete 
    End If 
    If FSO.FolderExists(MigData) then 
        Set DeleteFolder = FSO.GetFolder(MigData) 
        DeleteFolder.Delete 
    End If 
 
    REM Create USMTPATH 
    If NOT FSO.FolderExists(TMP) then 
        FSO.CreateFolder(TMP) 
    End If 
    FSO.CreateFolder(MigData) 
    FSO.CreateFolder(MigData & "\" & UserName) 
    FSO.CreateFolder(MigData & "\" & UserName & "\" & OldComputer) 
    If FSO.FolderExists(USMTPath) then 
        objIE.Document.WriteLn "Success" & "<BR><BR>" 
    else 
        objIE.Document.WriteLn "Failure" & "<BR><BR>" 
    End If 
 
    REM Cleanup Local Variables 
    Set FSO          = Nothing 
    Set comp         = Nothing 
    Set TMP          = Nothing 
    Set TMP          = Nothing 
    Set MigData      = Nothing 
    Set USMTPath     = Nothing 
    Set DeleteFolder = Nothing 
 
End Sub 
 
'****************************************************************************** 
 
Sub DetermineArchitecture() 
 
    REM Define Local Objects 
    DIM FSO                 : SET FSO                 = CreateObject("Scripting.FileSystemObject") 
    DIM objWMIService       : Set objWMIService       = Nothing 
    DIM objWMIServiceSet    : Set objWMIServiceSet    = Nothing 
    DIM colOperatingSystems : Set colOperatingSystems = Nothing 
    DIM objOperatingSystem  : Set objOperatingSystem  = Nothing 
 
    REM Define Local Variables 
    DIM x86RUNPATH   : x86RUNPATH    = USMTLocation & "x86" 
    DIM x64RUNPATH   : x64RUNPATH    = USMTLocation & "x64" 
    DIM OSSourceType : OSSourceType  = "\\" & OldComputer & "\c$\Program Files (x86)" 
    DIM OSDestType   : OSDestType    = "\\" & NewComputer & "\c$\Program Files (x86)" 
    DIM msgSource    : Set msgSource = Nothing 
    DIM msgDest      : Set msgDest   = Nothing 
 
    Set objWMIService = GetObject("winmgmts:\\" & OldComputer & "\root\cimv2")         
    Set colOperatingSystems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem") 
    For Each objOperatingSystem in colOperatingSystems 
        msgSource = objOperatingSystem.Caption 
    Next 
    objIE.Document.WriteLn "Determining Source Architecture....." 
    If FSO.FolderExists(OSSourceType) Then 
        USMTSourceCMD = x64RUNPATH 
    else 
        USMTSourceCMD = x86RUNPATH 
    End IF 
    If NOT USMTSourceCMD = "0" then 
        objIE.Document.WriteLn "Success" & "<BR>" 
    else 
        objIE.Document.WriteLn "Failure(" & ReturnCode & ")" & "<BR>" 
    End If 
    objIE.Document.WriteLn "Determining Destination Architecture....." 
    Set objWMIService = GetObject("winmgmts:\\" & NewComputer & "\root\cimv2")         
    Set colOperatingSystems = objWMIService.ExecQuery("Select * from Win32_OperatingSystem") 
    For Each objOperatingSystem in colOperatingSystems 
        msgDest = objOperatingSystem.Caption 
    Next 
    If FSO.FolderExists(OSDestType) Then 
        USMTDestCMD = x64RUNPATH 
    else 
        USMTDestCMD = x86RUNPATH 
    End IF 
    If NOT USMTDestCMD = "0" then 
        objIE.Document.WriteLn "Success" & "<BR>" 
    else 
        objIE.Document.WriteLn "Failure(" & ReturnCode & ")" & "<BR>" 
    End If 
    objIE.Document.WriteLn "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Source:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; " & msgSource &_ 
                            Chr(32) & Right(USMTSourceCMD,3) & "<BR>" 
    objIE.Document.WriteLn "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Destination: " & msgDest & Chr(32) & Right(USMTDestCMD,3) & "<BR><BR>" 
     
    REM Cleanup Variables 
    Set colOperatingSystems = Nothing 
    Set FSO                 = Nothing 
    Set msgDest             = Nothing 
    Set msgSource           = Nothing 
    Set x86RUNPATH          = Nothing 
    Set x64RUNPATH          = Nothing 
    Set objWMIService       = Nothing 
    Set objWMIServiceSet    = Nothing 
    Set OSSourceType        = Nothing 
    Set OSDestType          = Nothing 
    Set objOperatingSystem  = Nothing 
 
End Sub 
 
'****************************************************************************** 
 
Sub USMTMigrate() 
 
    REM Define Local Objects 
    DIM oShell : SET oShell = CreateObject("Wscript.Shell") 
 
    REM Define Local Variables 
    DIM Debug      : Debug      = "13" 
    DIM TMP        : TMP        = "c:\Temp" 
    DIM MigData    : MigData    = TMP & "\MigData" 
    DIM LOGPATH    : LOGPATH    = MigData & "\" & UserName 
    DIM StorePATH  : StorePATH  = MigData & "\" & UserName & "\" & OldComputer 
    DIM RemoteExec : RemoteExec = USMTLocation & "PSTools\PsExec.exe \\" & OldComputer &_ 
                                Chr(32) & "-s" & Chr(32) 
    DIM USMT       : USMT       = RemoteExec & USMTSourceCMD & "\scanstate.exe " & StorePATH & " /v:" & Debug & " /i:" & USMTSourceCMD &_ 
                                "\Migapp.xml /i:" & USMTSourceCMD & "\MigDocs.xml /i:" & USMTSourceCMD & "\miguser.xml /progress:" & LOGPATH &_ 
                                "\ScanStateProg.log /l:" & LOGPATH & "\ScanState.log /ui:Nash\" & UserName & " /c /vsc" 
 
    objIE.Document.WriteLn "Executing Scanstate on " & OldComputer & "....." 
    ReturnCode = oShell.Run(USMT, 7, True) 
    If ReturnCode = "0" then 
        objIE.Document.WriteLn "Success" & "<BR><BR>" 
    else 
        objIE.Document.WriteLn "Failure(" & ReturnCode & ")" & "<BR><BR>" 
    End If 
 
    REM Cleanup Variables 
    Set Debug      = Nothing 
    SET oShell     = Nothing 
    SET TMP        = Nothing 
    SET MigData    = Nothing 
    SET LOGPATH    = Nothing 
    Set RemoteExec = Nothing 
    SET StorePATH  = Nothing 
    Set USMT       = Nothing 
 
End Sub 
 
'****************************************************************************** 
 
Sub VerifyScanState() 
 
    If NOT ReturnCode = "0" then 
        MsgBox("The data migration on " & OldComputer & " failed due to error" & ReturnCode &_ 
                ". Please check the log file located at & \\" & OldComputer & "\c$\Temp\MigData\ScanLog.log.") 
        GlobalVariableCleanUp() 
        WScript.Quit 
    Else 
        Set ReturnCode = Nothing 
    End If 
 
End Sub 
 
'****************************************************************************** 
 
Sub CopyUSMTData() 
 
    REM Define Local Objects 
    DIM FSO    : SET FSO    = CreateObject("Scripting.FileSystemObject") 
    DIM oShell : SET oShell = CreateObject("Wscript.Shell") 
 
    REM Define Local Variables 
    DIM SourceUSMTPath : SourceUSMTPath = "\\" & OldComputer & "\c$\Temp\MigData" 
    DIM DestUSMTPath   : DestUSMTPath   = "\\" & NewComputer & "\c$\Temp\MigData" 
    DIM Parameters     : Parameters     = "/e /eta /mir" 
    DIM RemoteExec     : RemoteExec     = USMTLocation & "PSTools\PsExec.exe \\" & OldComputer &_ 
                                        Chr(32) & "-s" & Chr(32) 
    DIM RoboCopyCMD    : RoboCopyCMD    = RemoteExec & "RoboCopy.exe" & Chr(32) & SourceUSMTPath & Chr(32) & DestUSMTPath &_ 
                                        Chr(32) & Parameters 
 
    objIE.Document.WriteLn "Copying USMT folder from " & OldComputer & " to " & NewComputer & "....." 
    oShell.Run RoboCopyCMD, 7, True 
    If FSO.FolderExists(DestUSMTPath) then 
        objIE.Document.WriteLn "Success" & "<BR><BR>" 
    else 
        objIE.Document.WriteLn "Failure" & "<BR><BR>" 
    End If 
     
    REM Cleanup Variables 
    Set FSO            = Nothing 
    Set oShell         = Nothing 
    SET SourceUSMTPath = Nothing 
    SET DestUSMTPath   = Nothing 
    Set Parameters     = Nothing 
    Set RemoteExec     = Nothing 
    Set RoboCopyCMD    = Nothing 
 
End Sub 
 
'****************************************************************************** 
 
Sub LoadUSMTData() 
 
    REM Define Local Objects 
    DIM oShell : SET oShell = CreateObject("Wscript.Shell") 
 
    REM Define Local Variables 
    DIM Debug      : Debug      = "13" 
    DIM TMP        : TMP        = "c:\Temp" 
    DIM MigData    : MigData    = TMP & "\MigData" 
    DIM LOGPATH    : LOGPATH    = MigData & "\" & UserName 
    DIM StorePATH  : StorePATH  = MigData & "\" & UserName & "\" & OldComputer 
    DIM RemoteExec : RemoteExec = USMTLocation & "PSTools\PsExec.exe \\" & NewComputer &_ 
                                 Chr(32) & "-s" & Chr(32) 
    DIM USMT       : USMT       = RemoteExec & USMTDestCMD & "\loadstate.exe " & StorePATH & " /v:" & Debug & " /i:" & USMTDestCMD &_ 
                                "\Migapp.xml /i:" & USMTDestCMD & "\MigDocs.xml /i:" & USMTDestCMD & "\miguser.xml /progress:" &_ 
                                LOGPATH & "\LoadStateProg.log /l:" & LOGPATH & "\LoadState.log /ui:Nash\" & UserName & " /c" 
 
    objIE.Document.WriteLn "Executing Loadstate on " & NewComputer & "....." 
    ReturnCode = oShell.Run(USMT, 7, True) 
    If ReturnCode = "0" then 
        objIE.Document.WriteLn "Success" & "<BR><BR>" 
    else 
        objIE.Document.WriteLn "Failure(" & ReturnCode & ")" & "<BR><BR>" 
    End If 
 
    REM Cleanup Variables 
    Set Debug      = Nothing 
    SET oShell     = Nothing 
    SET TMP        = Nothing 
    SET MigData    = Nothing 
    SET LOGPATH    = Nothing 
    Set RemoteExec = Nothing 
 
End Sub 
 
'****************************************************************************** 
 
Sub VerifyLoadState() 
 
    If NOT ReturnCode = "0" then 
        MsgBox("The data migration on " & NewComputer & " failed due to error " & ReturnCode & ". Please check the log file located at & \\" &_ 
            NewComputer & "\c$\Temp\MigData\LoadState.log.") 
        GlobalVariableCleanUp() 
        objIE.Quit 
        WScript.Quit 
    Else 
        MsgBox("The data successfully migrated from " & OldComputer & " to " & NewComputer & ".") 
    End If 
 
End Sub 
 
'****************************************************************************** 
 
Sub GlobalVariableCleanUp() 
 
    objIE.Quit 
    Set OldComputer   = Nothing 
    Set objIE         = Nothing 
    Set NewComputer   = Nothing 
    Set ReturnCode    = Nothing 
    Set UserName      = Nothing 
    Set USMTSourceCMD = Nothing 
    Set USMTDestCMD   = Nothing 
 
End Sub
