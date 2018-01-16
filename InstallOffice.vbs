 '*******************************************************************************  
 '      Author: Mick Pletcher  
 '        Date: 03 January 2012  
 '    Modified:   
 '  
 ' Description: This will install Office 2010 & extensions. It gives laptop users  
 '              the option to install Office at their leisure until the mandatory  
 '              installation date specified in global variable ManDate, at which  
 '              point office will automatically install.   
 '              1) Define the relative installation path  
 '              2) Create the Log Folder  
 '              3) Detect the chassis type  
 '              4) If Laptop  
 '                 a) Check if mandatory installation date  
 '                 b) If not mandatory installation, get user approval  
 '              5) If approved  
 '                 a) Close programs  
 '                 b) Uninstall 2007 components  
 '                 c) Install Office 2010  
 '                 d) Install Primary Interop Assemblies  
 '                 e) Install Visual Studio 2010 Tools for Office  
 '                 f) Install Visio Viewer 2010  
 '                 g) Install Live Meeting Addin  
 '                 h) If Laptop, display completion message, else end with error 1  
 '              6) Copy AIA files if present  
 '              7) Cleanup Global Variables  
 '*******************************************************************************  
 Option Explicit  

 REM Define Global Constants  
 CONST TempFolder    = "c:\temp\"  
 CONST LogFolderName = "MSOF2010"  

 REM Define Global Variables  
 DIM IsLaptop     : Set IsLaptop     = Nothing  
 DIM LogFolder    : LogFolder        = TempFolder & LogFolderName & "\"  
 DIM ManDate      : ManDate          = "31-Mar-12"  
 DIM Mandatory    : Set Mandatory    = Nothing  
 DIM RelativePath : Set RelativePath = Nothing  
 DIM UserApprove  : Set UserApprove  = Nothing  

 REM Define the relative installation path  
 DefineRelativePath()  
 REM Create the Log Folder  
 CreateLogFolder()  
 REM Detect Chassis Type  
 DetectChassis()  
 If IsLaptop Then  
   REM Check Mandatory Date  
   CheckMandatoryDate()  
   REM Prompt for User Approval of Installation  
   If NOT Mandatory Then  
      GetUserApproval()  
   End If  
 Else  
   UserApprove = True  
 End If  
 If UserApprove Then  
   REM Close Communicator  
   CloseProgs()  
   REM Uninstall 2007 Components  
   UninstallComponents()  
   REM Install Office 2010  
   InstallOffice()  
   REM Install Primary Interop Assemblies  
   InstallPIA()  
   REM Install Visual Studio 2010 Tools for Office  
   'InstallVSTOR()  
   REM Install Visio Viewer 2010  
   InstallVisioViewer()  
   REM Install LM Addin Pack  
   InstallLMAddin()  
   If IsLaptop Then  
      REM Installation Complete Message  
      InstallationComplete()  
   End If  
 Else  
   GlobalVariableCleanup()  
   WScript.Quit (1)  
 End If  
 CopyAIAFile()  
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

  REM Cleanup Local Memory
  Set FSO = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub DetectChassis()  

  REM Define Local Constants  
  CONST strComputer = "."  

  REM Define Local Objects  
  DIM objWMIService : Set objWMIService = GetObject("winmgmts:" _  
                      & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")  
  DIM colChassis    : Set colChassis = objWMIService.ExecQuery _  
                      ("Select * from Win32_SystemEnclosure")  

  REM Define Local Variables  
  DIM objChassis     : Set objChassis     = Nothing  
  DIM strChassisType : Set strChassisType = Nothing  

  For Each objChassis in colChassis  
      For Each strChassisType in objChassis.ChassisTypes  
         Select Case strChassisType  
         Case 1  
            REM "Other"  
            IsLaptop = False  
         Case 2  
            REM "Unknown"  
            IsLaptop = False  
         Case 3  
            REM "Desktop"  
            IsLaptop = False  
         Case 4  
            REM "Low Profile Desktop"  
            IsLaptop = False  
         Case 5  
            REM "Pizza Box"  
            IsLaptop = False  
         Case 6  
            REM "Mini Tower"  
            IsLaptop = False  
         Case 7  
            REM "Tower"  
            IsLaptop = False  
         Case 8  
            REM "Portable"  
            IsLaptop = True  
         Case 9  
            REM "Laptop"  
            IsLaptop = True  
         Case 10  
            REM "Notebook"  
            IsLaptop = True  
         Case 11  
            REM "Handheld"  
            IsLaptop = True  
         Case 12  
            REM "Docking Station"  
            IsLaptop = True  
         Case 13  
            REM "All-in-One"  
            IsLaptop = True  
         Case 14  
            REM "Sub-Notebook"  
            IsLaptop = True  
         Case 15  
            REM "Space Saving"  
            IsLaptop = False  
         Case 16  
            REM "Lunch Box"  
            IsLaptop = False  
         Case 17  
            REM "Main System Chassis"  
            IsLaptop = False  
         Case 18  
            REM "Expansion Chassis"  
            IsLaptop = False  
         Case 19  
            REM "Sub-Chassis"  
            IsLaptop = False  
         Case 20  
            REM "Bus Expansion Chassis"  
            IsLaptop = False  
         Case 21  
            REM "Peripheral Chassis"  
            IsLaptop = False  
         Case 22  
            REM "Storage Chassis"  
            IsLaptop = False  
         Case 23  
            REM "Rack Mount Chassis"  
            IsLaptop = False  
         Case 24  
            REM "Sealed-Case PC"  
            IsLaptop = False  
         Case 65  
            REM "Tablet"  
            IsLaptop = True  
         Case Else  
            REM "Unknown"  
            IsLaptop = False  
         End Select  
      Next  
  Next  

  REM Cleanup Local Variables  
  Set objChassis     = Nothing  
  Set objWMIService  = Nothing  
  Set colChassis     = Nothing  
  Set strChassisType = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub CheckMandatoryDate()  

  REM Define Local Variables  
  DIM Diff  : Set Diff = Nothing  
  DIM Today : Today    = Date  

  Diff = DateDiff("d", Today, ManDate)  
  If (Diff < 0) or (Diff = 0) then  
     Mandatory  = True  
     UserApprove = True  
  Else  
     Mandatory = False  
  End If  

  REM Cleanup Local Memory 
  Set Diff  = Nothing  
  Set Today = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub GetUserApproval()  

   MsgBox "The following box will ask if you want to upgrade to Microsoft Office 2010. It will close out " &_  
          "all of your office applications, including Microsoft Communicator. If you " &_  
          "choose to not install, you will be prompted daily until the mandatory installation date of " &_  
          ManDate & " at which time Office will be installed.",64,"Microsoft Office 2010 Upgrade"  
   UserApprove = MsgBox("Click OK to proceed with the Microsoft Office 2010 Installation Upgrade",1,"Microsoft Office 2010 Installation")  
   If UserApprove = "1" Then  
      UserApprove = True  
   Else  
      UserApprove = False  
   End If  

 End Sub  

 '*******************************************************************************  

 Sub CloseProgs()  

  REM Define Local Objects  
  DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

  REM Define Local Variables  
  DIM CloseCommunicator : CloseCommunicator = "taskkill.exe /IM communicator.* /F /T"  
  DIM CloseOutlook      : CloseOutlook      = "taskkill.exe /IM outlook.* /F /T"  

  oShell.Run CloseCommunicator, 1 ,True  
  oShell.Run CloseOutlook, 1, True  

  REM Cleanup Local Variables  
  Set CloseCommunicator = Nothing  
  Set CloseOutlook      = Nothing  
  Set oShell            = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub UninstallComponents()  

  REM Define Local Objects  
  DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

 REM Define Local Variables  
  DIM UninstallPath : UninstallPath = RelativePath & "Components\Uninstall\"  
  DIM Switches      : Switches      = Chr(32) & "/qn /norestart"  
  DIM WGST          : WGST          = "msiexec.exe /x" & Chr(32) & UninstallPath & "Word2007GetStartedTabSetup.msi" & Switches  
  DIM EGST          : EGST          = "msiexec.exe /x" & Chr(32) & UninstallPath & "Excel2007GetStartedTabSetup.msi" & Switches  
  DIM PPGST         : PPGST         = "msiexec.exe /x" & Chr(32) & UninstallPath & "PowerPoint2007GetStartedTabSetup.msi" & Switches  
  DIM SaveAsPDF     : SaveAsPDF     = "msiexec.exe /x" & Chr(32) & UninstallPath & "ExPdfXps.msi" & Switches  
  DIM PIA           : PIA           = "msiexec.exe /x" & Chr(32) & UninstallPath & "o2007pia.msi" & Switches  
  DIM OfficeMath    : OfficeMath    = "msiexec.exe /x" & Chr(32) & UninstallPath & "officemath.msi" & Switches  
  DIM VisioViewer   : VisioViewer   = "msiexec.exe /x" & Chr(32) & UninstallPath & "vviewer.msi" & Switches  

  oShell.Run WGST, 1, True  
  oShell.Run EGST, 1, True  
  oShell.Run PPGST, 1, True  
  oShell.Run SaveAsPDF, 1, True  
  oShell.Run PIA, 1, True  
  oShell.Run OfficeMath, 1, True  
  oShell.Run VisioViewer, 1, True  

  REM Cleanup Local Variables  
  Set UninstallPath = Nothing  
  Set Switches      = Nothing  
  Set WGST          = Nothing  
  Set EGST          = Nothing  
  Set PPGST         = Nothing  
  Set SaveAsPDF     = Nothing  
  Set PIA           = Nothing  
  Set OfficeMath    = Nothing  
  Set VisioViewer   = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub InstallOffice()  

  REM Define Local Objects  
  DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

 REM Define Local Variables  
  DIM Config  : Config  = Chr(32) & "/config" & Chr(32) & RelativePath & "config.xml"  
  DIM MSP     : MSP     = Chr(32) & "/adminfile" & Chr(32) & RelativePath & "setup.MSP"  
  DIM Install : Install = "setup.exe" & MSP & Chr(32) & Config  

  oShell.Run Install, 1, True  

  REM Cleanup Local Variables  
  Set Config  = Nothing  
  Set Install = Nothing  
  Set MSP     = Nothing  
  Set oShell  = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub InstallPIA()  

  REM Define Local Objects  
  DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

    REM Define Local Variables  
  DIM MSI        : MSI        = Chr(32) & RelativePath & "Components\o2010pia.msi"  
  DIM Log        : Log        = "PIA.log"  
  DIM Logs       : Logs       = Chr(32) & "/lvx" & Chr(32) & LogFolder & Log  
  DIM Parameters : Parameters = Chr(32) & "/qn /norestart"  
  DIM Install    : Install    = "msiexec.exe /i" & MSI & Logs & Parameters  

  oShell.Run Install, 1, True  

  REM Cleanup Local Variables  
  Set Install    = Nothing  
  Set Log        = Nothing  
  Set Logs       = Nothing  
  Set MSI        = Nothing  
  Set oShell     = Nothing  
  Set Parameters = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub InstallVSTOR()  

  REM Define Local Objects  
  DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

  REM Define Local Variables  
  DIM MSIx86     : MSIx86     = Chr(32) & RelativePath & "Components\vstor40_x86.msi"  
  DIM MSIx64     : MSIx64     = Chr(32) & RelativePath & "Components\vstor40_x64.msi"  
  DIM Logx86     : Logx86     = "VSTORx86.log"  
  DIM Logx64     : Logx64     = "VSTORx64.log"  
  DIM Logsx86    : Logsx86    = Chr(32) & "/lvx" & Chr(32) & LogFolder & Logx86  
  DIM Logsx64    : Logsx64    = Chr(32) & "/lvx" & Chr(32) & LogFolder & Logx64  
  DIM Parameters : Parameters = Chr(32) & "/qn /norestart"  
  DIM Installx86 : Installx86 = "msiexec.exe /i" & MSIx86 & Logsx86 & Parameters  
  DIM Installx64 : Installx64 = "msiexec.exe /i" & MSIx64 & Logsx64 & Parameters  

  oShell.Run Installx86, 1, True  
  oShell.Run Installx64, 1, True  

  REM Cleanup Local Variables  
  Set Installx86 = Nothing  
  Set Installx64 = Nothing  
  Set Logx86     = Nothing  
  Set Logx64     = Nothing  
  Set Logsx86    = Nothing  
  Set Logsx64    = Nothing  
  Set MSIx86     = Nothing  
  Set MSIx64     = Nothing  
  Set oShell     = Nothing  
  Set Parameters = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub InstallVisioViewer()  

  REM Define Local Objects  
  DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

  REM Define Local Variables  
  DIM MSI        : MSI        = Chr(32) & RelativePath & "Components\vviewer.msi"  
  DIM Log        : Log        = "VisioViewer.log"  
  DIM Logs       : Logs       = Chr(32) & "/lvx" & Chr(32) & LogFolder & Log  
  DIM Parameters : Parameters = Chr(32) & "/qn /norestart"  
  DIM Install    : Install    = "msiexec.exe /i" & MSI & Logs & Parameters  

  oShell.Run Install, 1, True  

  REM Cleanup Local Variables  
  Set Install    = Nothing  
  Set Log        = Nothing  
  Set Logs       = Nothing  
  Set MSI        = Nothing  
  Set oShell     = Nothing  
  Set Parameters = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub InstallLMAddin()  

  REM Define Local Objects  
  DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

  REM Define Local Variables  
  DIM MSI        : MSI        = Chr(32) & RelativePath & "Components\LMAddinPack.msi"  
  DIM Log        : Log        = "LMAddin.log"  
  DIM Logs       : Logs       = Chr(32) & "/lvx" & Chr(32) & LogFolder & Log  
  DIM Parameters : Parameters = Chr(32) & "/qn /norestart"  
  DIM Install    : Install    = "msiexec.exe /i" & MSI & Logs & Parameters  

  oShell.Run Install, 1, True  

  REM Cleanup Local Variables  
  Set Install    = Nothing  
  Set Log        = Nothing  
  Set Logs       = Nothing  
  Set MSI        = Nothing  
  Set oShell     = Nothing  
  Set Parameters = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub CopyAIAFile()  

  REM Define Local Objects  
  DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")  

  REM Define Local Variables  
  DIM File   : File   = "ACDWordToolbars.dot"  
  DIM x86    : x86    = "C:\Program Files (x86)\Microsoft Office\Office14\STARTUP"  
  DIM x64    : x64    = "C:\Program Files\Microsoft Office\Office14\STARTUP"  
  DIM Source : Source = "\\global.gsp\data\clients\na_clients\Microsoft\MSOF2010x86\ACDWordToolbars.dot"  

  If FSO.FileExists(x86 & File) Then  
     FSO.CopyFile Source, x86  
  End If  
  IF FSO.FileExists(x64 & File) Then  
     FSO.CopyFile Source, x64  
  End If  

  REM Cleanup Local Variables  
  Set File   = Nothing  
  Set FSO    = Nothing  
  Set Source = Nothing  
  Set x86    = Nothing  
  Set x64    = Nothing  

 End Sub  

 '*******************************************************************************  

 Sub InstallationComplete()  

  MsgBox "Microsoft Office 2010 installation has now completed. Press OK to reboot", 64, "Microsoft Office 2010 Installation Complete"  

 End Sub  

 '*******************************************************************************  

 Sub GlobalVariableCleanup()  

  Set IsLaptop     = Nothing  
  Set LogFolder    = Nothing  
  Set ManDate      = Nothing  
  Set Mandatory    = Nothing  
  Set RelativePath = Nothing  
  Set UserApprove  = Nothing  

 End Sub  