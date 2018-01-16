 '*******************************************************************************  
 '     Program: EnableDisableOfflineFiles.vbs  
 '      Author: Mick Pletcher  
 '        Date: 25 June 2012  
 '    Modified:   
 '  
 ' Description: This will enable or disable the Offline File Cache  
 '                 1) Set Offline File Cache  
 '*******************************************************************************  
 Option Explicit  

 REM Set Offline File Cache   
 SetOfflineFileCache()  

 '*******************************************************************************  
 '*******************************************************************************  
 Sub SetOfflineFileCache()  

      REM Define Local Constants  
      CONST Disable = "False"  
      CONST Enable  = "True"  

      REM Define Local Objects  
      DIM oShell : SET oShell = CreateObject("Wscript.Shell")  

      REM Define Local Variables  
      ' Change the variable at the end of the Install Variable to either Enable or Disable  
      DIM Install : Install = "wmic path win32_offlinefilescache call enable" & Chr(32) & Disable  

      oShell.Run Install, 1, True  

      REM Cleanup Local Variables  
      Set Install = Nothing  
      Set oShell  = Nothing  

 End Sub  
