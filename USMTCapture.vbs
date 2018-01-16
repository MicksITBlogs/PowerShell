 REM ***************************************************************************   
 REM ***     Program: USMTCapture.vbs   
 REM ***      Author: Mick Pletcher   
 REM ***     Created: 23 July 2010   
 REM ***      Edited: 21 March 2011   
 REM ***   
 REM *** Description: This script will execute the USMT, creating a MIG file   
 REM ***              located on the selected location, either on the local   
 REM ***              machine, or on the network location. This is intended to   
 REM ***              be used for generating the MIG file for the MDT/SCCM   
 REM ***              imaging process to be included in the build. This was written   
 REM ***              so that this script can be executed from any machine   
 REM ***              which then executes the USMT process locally on the   
 REM ***              target machine. PSTools will need to be downloaded and   
 REM ***              extracted to the USMTLocation, specified below in the   
 REM ***              Global constants. The global constants should be the   
 REM ***              primary changes needed to be made to run this script   
 REM ***              on any machine. The other change that will be needed   
 REM ***              is in the USMTMigrate Subroutine. There are   
 REM ***              additional XML files I have written for the USMT   
 REM ***              process that would need to be removed.   
 REM ***   
 REM ***              NOTE: To expedite the USMT process, I would suggest   
 REM ***              going to HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\   
 REM ***              CurrentVersion\ProfileList and deleting all keys except for   
 REM ***              the following (You can find the key name under   
 REM ***              ProfileImagePath): SystemProfile, LocalService,   
 REM ***              NetworkService, Administrator, and the user profile   
 REM ***              being migrated. This will dramatically speed up the process   
 REM ***              otherwise it will scan each profile 20 times, with a 5   
 REM ***              second delay upon each failure. You need not delete   
 REM ***              the profile directory, as the USMT only scans the   
 REM ***              profiles listed under that registry key.   
 REM ***   
 REM ***              Script Process:   
 REM ***              1) Create HTML Display Status Window   
 REM ***              2) Enter Source, Destination, and Username   
 REM ***              3) Delete Old USMT folders and Create New USMT Folders   
 REM ***              4) Determine if the system is x86 or x64   
 REM ***              5) Perform USMT Migration on Old Machine   
 REM ***              6) Exit Script if USMT Migration Failed   
 REM ***              7) Verify USMT   
 REM ***              8) Cleanup Global Variables   
 REM ***    
 REM ***************************************************************************   
 Option Explicit   

 REM Define Global Constants   
 'Used in the query for retrieving the SID   
 CONST NetDomain = "nash"   
 ' Specifies where to find the USMT executables   
 CONST USMTLocation = "\\global.gsp\data\special\Deploy\USMT40\"   
 ' Specifies where to write the MIG file locally   
 CONST USMTLocalStore = "c:\temp\MigData\"   
 ' Specifies where to write the MIG file on the network share   
 CONST USMTNetworkStore = "\\MDT02\USMT\"   

 REM Define Global Objects   
 DIM objIE : Set objIE = CreateObject("InternetExplorer.Application")   

 REM Define Global Variables   
 DIM OldComputer   : Set OldComputer = Nothing   
 DIM ReturnCode    : ReturnCode      = "0"   
 DIM SID           : Set SID         = Nothing   
 DIM UserName      : Set UserName    = Nothing   
 DIM USMTOutput    : Set USMTOutput  = Nothing   
 DIM USMTSourceCMD : USMTSourceCMD   = "0"   
 DIM USMTDestCMD   : USMTDestCMD     = "0"   

 REM Create HTML Display Status Window   
 CreateDisplayWindow()   
 REM Enter Source, Destination, and Username   
 GetComputerInfo()   
 REM Delete Old USMT folders, if exists, and Create New USMT Folders   
 CreateUSMTFolders()   
 REM Determine if the system is x86 or x64   
 DetermineArchitecture()   
 REM Retrieve SID from Old Computer   
 GetSID()   
 REM Perform USMT Migration on Old Machine   
 USMTMigrate()   
 REM Verify the ScanState ran with no errors   
 VerifyScanState()   
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
   DIM intWidth        : intWidth            = 320   
   DIM intHeight       : intHeight           = 240   
   DIM intScreenWidth  : Set intScreenWidth  = Nothing   
   DIM intScreenHeight : Set intScreenHeight = Nothing   

   For Each objItem in colItems   
     intScreenWidth = objItem.PelsWidth   
     intScreenHeight = objItem.PelsHeight   
   Next   
   objIE.Navigate "about:blank"   
   objIE.Toolbar  = 0   
   objIE.StatusBar = 0   
   objIE.AddressBar = 0   
   objIE.MenuBar  = 0   
   objIE.Resizable = 0   
   While objIE.ReadyState <> 4   
     WScript.Sleep 100   
   Wend   
   objIE.Left = (intScreenWidth / 2) - (intWidth / 2)   
   objIE.Top = (intScreenHeight / 2) - (intHeight / 2)   
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
   UserName    = InputBox( "Enter the username:" )   
   USMTOutput  = MsgBox("Output USMT to Network Location?", 4)   
   If USMTOutput = 6 then   
     USMTOutput = USMTNetworkStore & UserName & "\" & OldComputer   
   Else   
     USMTOutput = USMTLocalStore & UserName & "\" & OldComputer   
   End If   
   objIE.Document.WriteLn "<FONT SIZE=8>USMT migration of " & UserName & " from " & OldComputer & " to " & USMTOutput &_   
               Chr(32) & "</FONT><BR><BR><BR>"   

 End Sub   

 '******************************************************************************   

 Sub CreateUSMTFolders()   

   On Error Resume Next   

   REM Define Local Objects   
   DIM FSO    : SET FSO    = CreateObject("Scripting.FileSystemObject")   
   DIM oShell : Set oShell = WScript.CreateObject("WScript.Shell")   

   REM Define Local Variables   
   DIM CreateFolder : CreateFolder = "cmd.exe /c md" & Chr(32) & USMTOutput

   objIE.Document.WriteLn "Creating USMT Folders....."   
   REM Create the USMT folders if they do not exist   
   If NOT FSO.FolderExists(USMTOutput) then   
     oShell.Run CreateFolder, 7, True   
   End If   

   REM Cleanup Local Variables   
   Set FSO          = Nothing   
   Set CreateFolder = Nothing   
   Set oShell       = Nothing   

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
   DIM x86RUNPATH  : x86RUNPATH  = USMTLocation & "x86"   
   DIM x64RUNPATH  : x64RUNPATH  = USMTLocation & "x64"   
   DIM OSSourceType : OSSourceType = "\\" & OldComputer & "\c$\Program Files (x86)"   
   DIM msgSource  : Set msgSource = Nothing   

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
   objIE.Document.WriteLn "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Source:&nbsp; " & msgSource &_   
               Chr(32) & Right(USMTSourceCMD,3) & "<BR><BR>"   

   REM Cleanup Variables   
   Set colOperatingSystems = Nothing   
   Set FSO                 = Nothing   
   Set msgSource           = Nothing   
   Set x86RUNPATH          = Nothing   
   Set x64RUNPATH          = Nothing   
   Set objWMIService       = Nothing   
   Set objWMIServiceSet    = Nothing   
   Set OSSourceType        = Nothing   
   Set objOperatingSystem  = Nothing   

 End Sub   

 '******************************************************************************   

 Sub GetSID()   

   REM Define Local Objects   
   DIM objWMIService : Set objWMIService = GetObject("winmgmts:\\" & OldComputer & "\root\cimv2")   
   DIM objAccount  : Set objAccount  = Nothing   

 '  Set objAccount = objWMIService.Get _   
 '    ("Win32_UserAccount.Name=" & Chr(39) & UserName & Chr(39) & ",Domain='nash'")   
   Set objAccount = objWMIService.Get _   
     ("Win32_UserAccount.Name=" & Chr(39) & UserName & Chr(39) & ",Domain=" & Chr(39) & NetDomain & Chr(39))   
   SID = objAccount.SID   

   REM Local Variable Cleanup   
   Set objAccount    = Nothing   
   Set objWMIService = Nothing   

 End Sub   

 '******************************************************************************   

 Sub USMTMigrate()   

   REM Define Local Objects   
   DIM oShell : SET oShell = CreateObject("Wscript.Shell")   

   REM Define Local Variables   
   DIM Debug       : Debug       = "13"   
   DIM IgnoreProfs : IgnoreProfs = "cmd.exe /c Set MIG_IGNORE_PROFILE_MISSING=1"   
   DIM TMP         : TMP         = "c:\Temp"   
   DIM MigData     : MigData     = TMP & "\MigData"   
   DIM LOGPATH     : LOGPATH     = MigData & "\" & UserName   
   DIM RemoteExec  : RemoteExec  = USMTLocation & "PSTools\PsExec.exe \\" & OldComputer &_   
                                   Chr(32) & "-s" & Chr(32)   
   DIM USMT        : USMT        = RemoteExec & USMTSourceCMD & "\scanstate.exe " & USMTOutput & Chr(32) & "/v:" & Debug & Chr(32) & "/i:" &_   
                                   USMTSourceCMD & "\Migapp.xml" & Chr(32) & "/i:" & USMTSourceCMD & "\MigDocs.xml" & Chr(32) & "/i:" &_   
                                   USMTSourceCMD & "\miguser.xml" & Chr(32) & "/i:" & USMTSourceCMD & "\MigExclude.xml" & Chr(32) &_   
                                   "/progress:" & LOGPATH & "\ScanStateProg.log" & Chr(32) & "/l:" & LOGPATH & "\ScanState.log" &_   
                                   Chr(32) & "/ui:" & SID & Chr(32) & "/ue:*\* /c /vsc"   

   objIE.Document.WriteLn "Executing Scanstate on " & OldComputer & "....."   
   ReturnCode = oShell.Run(IgnoreProfs, 7, True)   
   ReturnCode = oShell.Run(USMT, 7, True)   
   If ReturnCode = "0" Then   
     objIE.Document.WriteLn "Success" & "<BR><BR>"   
   else   
     objIE.Document.WriteLn "Failure(" & ReturnCode & ")" & "<BR><BR>"   
   End If   

   REM Cleanup Variables   
   Set Debug       = Nothing   
   SET IgnoreProfs = Nothing   
   SET oShell      = Nothing   
   SET TMP         = Nothing   
   SET MigData     = Nothing   
   SET LOGPATH     = Nothing   
   Set RemoteExec  = Nothing   
   Set USMT        = Nothing   

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
 
 Sub GlobalVariableCleanUp()   

   Set OldComputer   = Nothing   
   Set objIE         = Nothing   
   Set ReturnCode    = Nothing   
   Set UserName      = Nothing   
   Set USMTOutput    = Nothing   
   Set USMTSourceCMD = Nothing   
   Set USMTDestCMD   = Nothing   

 End Sub  
