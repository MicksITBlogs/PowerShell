'*******************************************************************************
'     Program: sysprep.vbs
'      Author: Mick Pletcher
'        Date: 12 May 2011
'    Modified:
'
'     Program: Sysprep.vbs
'     Version:
' Description: This script will sysprep the HDD on one machine so that it can
'			   be swapped out in another PC. This can save considerable money
'			   in shipping when replacing a bad HDD or upgrading the OS in a
'			   remote office. You can use any model PC to build up the OS with
'			   all of the applications installed and configured. USMT can also
'			   be run to include the user's profile.
'
'			   To start, you will need to create a unattend.xml file using
'			   Windows System Image Manager. This will include the
'			   installation of the SID based apps that get uninstalled from
'			   this script. The next thing that will need to be done is to
'			   create a directory tree of the different computer models with
'			   the drivers under each Folder Model. This is imperative and
'			   this script reads the folder names (computer models) and displays
'			   the list to choose from to copy the drivers down to the machine
'			   for sysprepping. 
'
'			   Next, you will need to create a setupcomplete.cmd file and place
'			   it in the same directory as the sysprep.vbs file. This file will
'			   be copied down locally to the HDD and will execute a list of
'			   commands once the sysprep setup is complete. I have two lines in mine:
'
'			   del /Q /F c:\windows\system32\sysprep\unattend.xml
'			   RMDIR /s /q c:\drivers
'
'			   It deletes the unattend.xml file because of network credentials
'			   and then deletes the c:\drivers folder where the drivers were
'			   copied for the sysprep setup.
'
'			   To setup this script, you will need to configure the sourcedrivers
'			   and sourcefolders variables to point to the correct location on
'			   your network. These variables are located in the various subroutines.
'			   You may also need to remove or add additional applications to the
'			   Uninstall list. These applications are SID based apps and have to
'			   be installed on each specific machine. They cannot be included in
'			   an image. SID based apps are usually antivirus, SMS/SCCM type apps.
'
'			   To use this script, you will be prompted for the computer model.
'			   This is the computer model of the final machine that the HDD will
'			   be placed into. The second thing will be to enter the computer name
'			   of the final machine. You do not need to move the final machine in
'			   active directory, as this HDD will have the same computer name. The
'			   script will continue through and will shut down the machine when
'			   complete. At that point, you can remove the HDD and insert it into
'			   the user’s computer. This will be a seamless setup. There will be no
'			   prompts for the end-user. Once it is completed, the system will be
'			   sitting at ctrl+alt+del. 
'
'			   NOTE: It is very important that you make sure the BIOS is configured
'					 correctly to your company’s specs. If the BIOS on the user’s
'					 computer is not, the OS can become corrupt and a complete
'					 rebuild will be required. 
'
'			   1) Define the relative installation path
'			   2) Create the Log Folder
'			   3) Enable Administrator Account
'			   4) Stop Services
'			   5) Get Computer Model
'			   6) Robocopy drivers folders to Sysprep Folder
'			   7) Copy sysprep folder to c:\sysprep
'			   8) Insert Computer Name into unattend.xml
'			   9) Create SetupComplete
'			  10) Copy Copy Forefront to local directory
'			  11) Copy Forefront Threat Management Gateway to local directory
'			  12) Copy Junk Email Reporting Add-in to local directory
'			  13) Copy SMS to local directory
'			  10) Uninstall Forefront Client Security Antimalware Service
'			  11) Uninstall Microsoft Forefront Client Security State Assessment Service
'			  12) Uninstall Microsoft Operations Manager 2005 Agent
'			  13) Uninstall Microsoft Forefront TMG Client
'			  14) Uninstall Microsoft Junk E-mail Reporting Add-in
'			  15) Uninstall SMS Advanced Client
'			  16) Defrag Machine
'			  17) Sysprep machine
'			  18) Cleanup Global Variables
'*******************************************************************************
Option Explicit

REM Define Constants
CONST TempFolder    = "c:\temp\"
CONST LogFolderName = "sysprep"

REM Define Global Objects
DIM objIE : Set objIE = CreateObject("InternetExplorer.Application")

REM Define Global Variables
DIM ComputerModel : Set ComputerModel = Nothing
DIM ComputerName  : Set ComputerName  = Nothing
DIM LogFolder     : LogFolder         = TempFolder & LogFolderName & "\"
DIM RelativePath  : Set RelativePath  = Nothing
DIM UAC           : Set UAC           = Nothing

REM Create HTML Display Status Window
CreateDisplayWindow()
REM Minimize Folder
MinimizeFolder()
REM Define the relative installation path
DefineRelativePath()
REM Create the Log Folder
CreateLogFolder()
REM Get Computer Model
GetComputerModel()
REM Get Computer Name
GetComputerName()
REM Disable UAC?
DisableUAC()
REM Enable Administrator Account
EnableAdministratorAccount()
REM Stop Services
StopServices()
REM Robocopy drivers folders to Sysprep Folder
CopyDriverFolders()
REM Copy SCCM and Endpoint
CopySCCMEndPoint()
REM Copy sysprep folder to c:\sysprep
CopySysprepFiles()
REM Insert Computer Name into unattend.xml
InsertComputerName()
REM Create SetupComplete
CreateSetupComplete()
REM Copy UAC Script
CopyUAC()
REM Uninstall Endpoint Protection
UninstallEndpoint()
REM Uninstall SCCM Client
UninstallSCCM()
REM Defrag Machine
Defrag()
REM Sysprep machine
'Sysprep()
REM Cleanup Global Variables
GlobalVariableCleanup()

'*******************************************************************************
'*******************************************************************************

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

	objIE.Document.WriteLn "<FONT SIZE=8>Sysprep</FONT><BR><BR><BR>"

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

Sub MinimizeFolder()

	REM Define Local Variables
	DIM Active
	DIM FolderWindow : FolderWindow = "sysprepWin7"
	DIM oShell       : SET oShell = CreateObject("Wscript.Shell")

	Active = oshell.appactivate(FolderWindow)
	If Active Then
		oshell.sendkeys "% n"
	End If

	REM Cleanup Local Memory
	Set Active       = Nothing
	Set FolderWindow = Nothing
	Set oShell       = Nothing

End Sub

'******************************************************************************

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

Sub EnableAdministratorAccount()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	objIE.Document.WriteLn "Enabling Administrator Account....."
	oShell.Run "net.exe user administrator /active:yes", 7, True
	objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"

	REM Cleanup Local Variables
	Set oShell     = Nothing

End Sub

'*******************************************************************************

Sub StopServices()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Parameters1 : Parameters1 = Chr(32) & "stop"
	DIM Parameters2 : Parameters2 = Chr(32) & "start= disabled"
	DIM Service     : Service     = Chr(32) & "WMPNetworkSvc"
	DIM StopSvc     : StopSvc     = "sc.exe" & Parameters1 & Service
	DIM DisableSvc  : DisableSvc  = "sc.exe config" & Service & Parameters2

	objIE.Document.WriteLn "Disabling Windows Media Player Service....."
	oShell.Run StopSvc, 7, True
	oShell.Run DisableSvc, 7, True
	objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"

	REM Cleanup Local Variables
	Set DisableSvc  = Nothing
	Set oShell      = Nothing
	Set Parameters1 = Nothing
	Set Parameters2 = Nothing
	Set Service     = Nothing
	Set StopSvc     = Nothing


End Sub

'*******************************************************************************

Sub GetComputerModel()

	REM Define Local Constants
	CONST strFolder = "\\mdt01\c$\DeploymentShare\Drivers\Windows 7 Drivers\"

	REM Define Local Objects
	DIM FSO        : Set FSO        = CreateObject("Scripting.FileSystemObject")
	DIM oFolder    : Set oFolder    = FSO.GetFolder(strFolder)
	DIM colFolders : Set colFolders = oFolder.SubFolders

	REM Define Local Variables
	DIM Count      : Count          = 1
	DIM Folder     : Set Folder     = Nothing
	DIM oSubFolder : Set oSubFolder = Nothing
	DIM StrList    : StrList        = "Select the model for Sysprepping:"

	REM Get list of current model PCs
	strList = strList & vbCrLf
	For Each oSubFolder in colFolders
		Folder = Right(oSubFolder.Path, Len(oSubFolder.Path) - InStrRev(oSubFolder.Path, "\"))
		If Count < 10 then
			strList = strList & vbCrLf & Chr(32) & Chr(32) & Count & " - " & Folder
		Else
			strList = strList & vbCrLf & Count & " - " & Folder
		End If
		Count = Count + 1
	Next

	REM Select Computer Model
	ComputerModel = InputBox(strList, "ComputerModel")
	If ComputerModel = "" then
		GlobalVariableCleanup()
		WScript.quit
	End If
	ComputerModel = CInt(ComputerModel)

	REM Reinitialize Variables
	Count          = 1
	Set Folder     = Nothing
	Set oSubFolder = Nothing

	REM Get Computer Model
	For Each oSubFolder in colFolders
		If Count = ComputerModel then
			Folder = Right(oSubFolder.Path, Len(oSubFolder.Path) - InStrRev(oSubFolder.Path, "\"))
		End If
		Count = Count + 1
	Next
	ComputerModel = Folder

	REM Cleanup Local Variables
	Set colFolders = Nothing
	Set Count      = Nothing
	Set Folder     = Nothing
	Set FSO        = Nothing
	Set oFolder    = Nothing
	Set oSubFolder = Nothing
	Set StrList    = Nothing

End Sub

'*******************************************************************************

Sub GetComputerName()

	ComputerName = InputBox( "Enter the user's computer name:" )

End Sub

'*******************************************************************************

Sub DisableUAC()

	UAC = MsgBox( "Disable UAC?", 4, "UAC" )

End Sub

'*******************************************************************************

Sub CopyDriverFolders()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Robocopy      : Robocopy      = "robocopy.exe" & Chr(32)
	DIM SourceDrivers : SourceDrivers = "\\mdt01\Drivers\Windows 7 Drivers\"
	DIM DestDrivers   : DestDrivers   = "c:\Drivers"
	DIM Parameters    : Parameters    = "/e /eta /r:1 /w:0 /mir"
	DIM Install       : Install       = Robocopy & Chr(34) & SourceDrivers & ComputerModel &_
											Chr(34) & Chr(32) & DestDrivers & Chr(32) & Parameters

	objIE.Document.WriteLn "Copying " & ComputerModel & Chr(32) & "drivers to local directory....."
	oShell.Run Install, 7, True
	If FSO.FolderExists(DestDrivers) Then
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
	Else
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If

	REM Cleanup Local Variables
	Set DestDrivers   = Nothing
	Set FSO           = Nothing
	Set Install       = Nothing
	Set oShell        = Nothing
	Set Robocopy      = Nothing
	Set SourceDrivers = Nothing

End Sub

'*******************************************************************************

Sub CopySysprepFiles()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM MyFile  : MyFile  = RelativePath & "unattend.xml"
	DIM Dest    : Dest    = "C:\windows\system32\sysprep\"
	
	objIE.Document.WriteLn "Copying sysprep files....."
	FSO.CopyFile MyFile, Dest, True
	If FSO.FileExists(Dest & "unattend.xml") then
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
	Else
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If

	REM Cleanup Local Variables
	Set Dest    = Nothing
	Set MyFile  = Nothing
	Set FSO     = Nothing
	
End Sub

'*******************************************************************************

Sub InsertComputerName()

	REM Define Local Constants
	CONST ForReading = 1 
	CONST ForWriting = 2 
   
	REM Define Local Objects
	DIM File          : File              = "C:\windows\system32\sysprep\unattend.xml"
	DIM strOld        : strOld            = "<ComputerName></ComputerName>"
	DIM strNew        : strNew            = "<ComputerName>" & ComputerName & "</ComputerName>"
	DIM objFSO        : Set objFSO        = CreateObject("Scripting.FileSystemObject") 
	DIM objFile       : Set objFile       = objFSO.getFile(File) 
	DIM objTextStream : Set objTextStream = objFile.OpenAsTextStream(ForReading) 
	DIM strInclude    : strInclude        = objTextStream.ReadAll 
	DIM Written       : Written           = False

	objIE.Document.WriteLn "Injecting Computer Name into unattend.xml file....."
	objTextStream.Close
	Set objTextStream = Nothing

	If InStr(strInclude,strOld) > 0 Then 
		strInclude = Replace(strInclude,strOld,strNew) 
		Set objTextStream = objFile.OpenAsTextStream(ForWriting) 
		objTextStream.Write strInclude 
		objTextSTream.Close 
		Set objTextStream = Nothing 
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
		Written = True
	End If
	If NOT Written Then
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If

	REM Cleanup Local Variables
	Set File          = Nothing
	Set objFile       = Nothing 
	Set objFSO        = Nothing
	Set objTextStream = Nothing
	Set strInclude    = Nothing
	Set strNew        = Nothing
	Set strOld        = Nothing
	Set Written       = Nothing

End Sub

'*******************************************************************************

Sub CopySCCMEndPoint()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM SourceFolder  : SourceFolder  = "\\global.gsp\data\clients\na_clients\Microsoft\SCCM\Client"
	DIM DestFolder    : DestFolder    = "C:\sysprepfolders\"
	DIM SysprepFolder : SysprepFolder = "C:\sysprepfolders"
	
	objIE.Document.WriteLn "Copying SCCM and Endpoint installation files....."
	If NOT FSO.FolderExists(SysprepFolder) then
		FSO.CreateFolder(SysprepFolder)
	End If
	If NOT FSO.FolderExists(DestFolder) then
		FSO.CreateFolder(DestFolder)
	End If
	FSO.CopyFolder SourceFolder, DestFolder, True
	If FSO.FolderExists(DestFolder & "Client") then
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
	Else
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If

	REM Cleanup Local Variables
	Set DestFolder    = Nothing
	Set FSO           = Nothing
	Set SourceFolder  = Nothing
	Set SysprepFolder = Nothing

End Sub

'*******************************************************************************

Sub CopyUAC()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM SourceFolder  : SourceFolder  = "\\global.gsp\data\clients\na_clients\GSP\UserAccountControl"
	DIM DestFolder    : DestFolder    = "C:\sysprepfolders\"
	DIM SysprepFolder : SysprepFolder = "C:\sysprepfolders"

	objIE.Document.WriteLn "Copying UAC files....."
	If NOT FSO.FolderExists(SysprepFolder) then
		FSO.CreateFolder(SysprepFolder)
	End If
	If NOT FSO.FolderExists(DestFolder) then
		FSO.CreateFolder(DestFolder)
	End If
	FSO.CopyFolder SourceFolder, DestFolder, True
	'MsgBox( UAC )
	If UAC = 6 then
		FSO.CopyFile SourceFolder & "\DisableUAC.txt", DestFolder
	End If
	If FSO.FolderExists(DestFolder & "UserAccountControl") then
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
	Else
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If


End Sub

'*******************************************************************************

Sub CopyPageFileSize()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM SourceFolder  : SourceFolder  = "\\global.gsp\data\clients\na_clients\Build\PageFileSize"
	DIM DestFolder    : DestFolder    = "C:\sysprepfolders\"
	DIM SysprepFolder : SysprepFolder = "C:\sysprepfolders"
	
	objIE.Document.WriteLn "Copying Pagefile Size Script....."
	If NOT FSO.FolderExists(SysprepFolder) then
		FSO.CreateFolder(SysprepFolder)
	End If
	If NOT FSO.FolderExists(DestFolder) then
		FSO.CreateFolder(DestFolder)
	End If
	FSO.CopyFolder SourceFolder, DestFolder, True
	If FSO.FolderExists(DestFolder & "PageFileSize") then
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
	Else
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If

	REM Cleanup Local Variables
	Set DestFolder    = Nothing
	Set FSO           = Nothing
	Set SourceFolder  = Nothing
	Set SysprepFolder = Nothing

End Sub

'*******************************************************************************

Sub CreateSetupComplete()

	REM Define Local Objects
	DIM FSO : Set FSO = CreateObject("Scripting.FileSystemObject")

	REM Define Local Variables
	DIM Dest   : Dest       = "C:\windows\setup\scripts\"
	DIM MyFile : MyFile     = RelativePath & "SetupComplete.cmd"
	DIM NewDIR : Set NewDIR = Nothing
	
	objIE.Document.WriteLn "Copying setup completion script....."
	If NOT FSO.FolderExists(Dest) then
		Set NewDIR = FSO.CreateFolder(Dest)
	End If
	FSO.CopyFile MyFile, Dest, True
	If FSO.FileExists(Dest & "SetupComplete.cmd") then
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
	Else
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If

	REM Cleanup Local Variables
	Set Dest   = Nothing
	Set FSO    = Nothing
	Set MyFile = Nothing
	Set NewDIR = Nothing

End Sub

'*******************************************************************************

Sub UninstallEndpoint()

	REM Define Local Objects
	DIM FSO    : Set FSO    = CreateObject("Scripting.FileSystemObject")
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	objIE.Document.WriteLn "Uninstalling Endpoint Protection....."
	If FSO.FileExists("C:\Windows\ccmsetup\SCEPInstall.exe") Then
		oShell.Run "C:\Windows\ccmsetup\SCEPInstall.exe /u /s", 7, True
	End If
	If NOT FSO.FileExists("C:\Windows\ccmsetup\SCEPInstall.exe") Then
		objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
	Else
		objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
	End If

	REM Cleanup Local Variables
	Set FSO    = Nothing
	Set oShell = Nothing

End Sub

'*******************************************************************************

Sub UninstallSCCM()

	REM Define Local Objects
	DIM FSO    : Set FSO    = CreateObject("Scripting.FileSystemObject")
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")
	
	If FSO.FileExists("C:\Windows\ccmsetup\ccmsetup.exe") Then
		objIE.Document.WriteLn "Uninstalling SCCM Client....."
		oShell.Run "C:\Windows\ccmsetup\ccmsetup.exe /uninstall", 7, True
		If NOT FSO.FileExists("C:\Windows\CCM\CcmExec.exe") Then
			objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
		Else
			objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
		End If
	End If
	If FSO.FileExists("C:\Windows\ccmsetup\WindowsFirewallConfigurationProvider.msi") Then
		objIE.Document.WriteLn "Uninstalling Windows Firewall Configuration Provider....."
		oShell.Run "msiexec.exe /x C:\Windows\ccmsetup\WindowsFirewallConfigurationProvider.msi /qb- /norestart", 7, True
		If NOT FSO.FileExists("C:\Windows\ccmsetup\WindowsFirewallConfigurationProvider.msi") Then
			objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"
		Else
			objIE.Document.WriteLn "<FONT COLOR=RED>Failed</FONT>" & "<BR>"
		End If
	End If

	REM Cleanup Local Variables
	Set FSO    = Nothing
	Set oShell = Nothing

End Sub

'*******************************************************************************

Sub Defrag()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	objIE.Document.WriteLn "Defragmenting....."
	oShell.Run "defrag c: -v -w", 7, True
	objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"

	REM Cleanup Local Variables
	Set oShell  = Nothing

End Sub

'*******************************************************************************

Sub Sysprep()

	REM Define Local Objects
	DIM oShell : SET oShell = CreateObject("Wscript.Shell")

	REM Define Local Variables
	DIM Dir        : Dir        = "C:\Windows\System32\sysprep\"
	DIM Parameters : Parameters = Chr(32) & "/generalize /oobe /shutdown /unattend:C:\Windows\System32\sysprep\unattend.xml"
	DIM Execute    : Execute    = Dir & "sysprep.exe" & Parameters

	objIE.Document.WriteLn "Sysprepping....."
	oShell.Run Execute, 7, True
	objIE.Document.WriteLn "<FONT COLOR=BLUE>Complete</FONT>" & "<BR>"

	REM Cleanup Local Variables
	Set Dir        = Nothing
	Set Execute    = Nothing
	Set oShell     = Nothing
	Set Parameters = Nothing

End Sub

'*******************************************************************************

Sub GlobalVariableCleanup()

	Set ComputerModel = Nothing
	Set ComputerName  = Nothing
	Set LogFolder     = Nothing
	Set objIE         = Nothing
	Set RelativePath  = Nothing

End Sub