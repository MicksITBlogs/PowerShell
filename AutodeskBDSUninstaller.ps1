 #*******************************************************************************  
 #   Author: Mick Pletcher  
 #   Date: 30 November 2013  
 #  
 #   Program: Autodesk BDS Ultimate Uninstaller  
 #*******************************************************************************  

 Function UninstallApplication($Application,$GUID) {  

      #Declare Local Variables  
      Set-Variable -Name Code -Scope Local -Force  
      Set-Variable -Name Arguments -Scope Local -Force  

      Write-Host $Application"...." -NoNewline  
      $Arguments = "/x "+$GUID+" /qb- /norestart"  
      $Code = (Start-Process -FilePath msiexec.exe -ArgumentList $Arguments -Wait -Passthru).ExitCode  
      If ($Code -eq 0) {  
           Write-Host "Uninstalled" -ForegroundColor Yellow  
      } elseIf ($Code -eq 1605) {  
           Write-Host "Not Installed" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error code"$Code -ForegroundColor Red  
      }  

      #Cleanup Local Variables  
      Remove-Variable -Name Code -Scope Local -Force  
      Remove-Variable -Name Arguments -Scope Local -Force  

 }
  
 UninstallApplication "Microsoft Visual C++ 2008 SP1 Redistributable (x64)" "{5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4}"  
 UninstallApplication "Microsoft Visual C++ 2008 SP1 Redistributable (x64)" "{5FCE6D76-F5DC-37AB-B2B8-22AB8CEDB1D4}"  
 UninstallApplication "Microsoft Visual C++ 2008 SP1 Redistributable (x86)" "{9BE518E6-ECC6-35A9-88E4-87755C07200F}"  
 UninstallApplication "Microsoft Visual C++ 2008 SP1 Redistributable (x86)" "{9BE518E6-ECC6-35A9-88E4-87755C07200F}"  
 UninstallApplication "Microsoft Visual C++ 2010 SP1 Redistributable (x86)" "{F0C3E5D1-1ADE-321E-8167-68EF0DE699A5}"  
 UninstallApplication "Microsoft Visual C++ 2010 SP1 Redistributable (x64)" "{1D8E6291-B0D5-35EC-8441-6616F567A0F7}"  
 UninstallApplication "Microsoft Visual C++ 2008 x86 ATL Runtime" "{04B34E21-5BEE-3D2B-8D3D-E3E80D253F64}"  
 UninstallApplication "Microsoft Visual C++ 2008 x86 MFC Runtime" "{B42E259C-E4D4-37F1-A1B2-EB9C4FC5A04D}"  
 UninstallApplication "Microsoft Visual C++ 2008 x86 CRT Runtime" "{14866AAD-1F23-39AC-A62B-7091ED1ADE64}"  
 UninstallApplication "Microsoft Visual C++ 2008 x86 OpenMP Runtime" "{4B90093A-5D9C-3956-8ABB-95848BE6EFAD}"  
 UninstallApplication "Microsoft Visual C++ 2008 x64 ATL Runtime" "{C3A57BB3-9AA6-3F6F-9395-6C062BDD5FC4}"  
 UninstallApplication "Microsoft Visual C++ 2008 x64 MFC Runtime" "{6DA2B636-698A-3294-BF4A-B5E11B238CDD}"  
 UninstallApplication "Microsoft Visual C++ 2008 x64 CRT Runtime" "{F6F09DD8-F39B-3A16-ADB9-C9E6B56903F9}"  
 UninstallApplication "Microsoft Visual C++ 2008 x64 OpenMP Runtime" "{8CCEA24C-51AE-3B71-9092-7D0C44DDA2DF}"  
 UninstallApplication "FARO LS" "{8A470330-70B2-49AD-86AF-79885EF9898A}"  
 UninstallApplication "Revit 2014" "{7346B4A0-1400-0510-0000-705C0D862004}"  
 UninstallApplication "Autodesk Workflows 2014" "{11672AB2-3D48-4D38-9123-719E5FF93333}"  
 UninstallApplication "MSXML 6.0 Parser" "{FF59CB23-1800-4047-B40C-E20AE7051491}"  
 UninstallApplication "Revit 2014 Language Pack - English" "{7346B4A0-1400-0511-0409-705C0D862004}"  
 UninstallApplication "Autodesk Material Library 2014" "{644F9B19-A462-499C-BF4D-300ABC2A28B1}"  
 UninstallApplication "Autodesk Material Library Base Resolution Image Library 2014" "{51BF3210-B825-4092-8E0D-66D689916E02}"  
 UninstallApplication "Autodesk Material Library Low Resolution Image Library 2014" "{5C29CC1F-218F-4C30-948A-11066CAC59FB}"  
 UninstallApplication "Autodesk Content Service" "{62F029AB-85F2-0000-866A-9FC0DD99DDBC}"  
 UninstallApplication "Autodesk Content Service Language Pack" "{62F029AB-85F2-0001-866A-9FC0DD99DDBC}"  
 UninstallApplication "AutoCAD 2014 - English" "{5783F2D7-D001-0000-0102-0060B0CE6BBA}"  
 UninstallApplication "AutoCAD 2014 Language Pack - English" "{5783F2D7-D001-0409-1102-0060B0CE6BBA}"  
 UninstallApplication "AutoCAD 2014 - English" "{5783F2D7-D001-0409-2102-0060B0CE6BBA}"  
 UninstallApplication "Autodesk 360" "{52B28CAD-F49D-47BA-9FFE-29C2E85F0D0B}"  
 UninstallApplication "SketchUp Import for AutoCAD 2014" "{644E9589-F73A-49A4-AC61-A953B9DE5669}"  
 UninstallApplication "Autodesk Navisworks 2014 64 bit Exporter Plug-ins" "{914E5049-303D-5993-9734-CF12636383B4}"  
 UninstallApplication "Autodesk Navisworks 2014 64 bit Exporter Plug-ins English Language Pack" "{914E5049-303D-0409-9734-CF12636383B4}"  
 UninstallApplication "Autodesk Material Library Medium Resolution Image Library 2014" "{A0633D4E-5AF2-4E3E-A70A-FE9C2BD8A958}"  
 UninstallApplication "Autodesk Revit Interoperability for 3ds Max 2014" "{0BB716E0-1400-0410-0000-097DC2F354DF}"  
 UninstallApplication "Autodesk 3ds Max Design 2014" "{52B37EC7-D836-0409-0164-3C24BCED2010}"  
 UninstallApplication "Autodesk 3ds Max Design 2014 64-bit Populate Data" "{2BCAFE22-BE25-4437-815C-54596D630397}"  
 UninstallApplication "Autodesk DirectConnect 2014 64-bit" "{8FC7C2B2-0F64-4B35-AA3D-2B051D009243}"  
 UninstallApplication "Autodesk Inventor Server Engine for 3ds Max Design 2014 64-bit" "{CBC74B06-FE35-482C-89D6-CE95A0289C06}"  
 UninstallApplication "Autodesk Composite 2014" "{5AAB972C-FF31-4B01-8445-50C42860EC02}"  
 UninstallApplication "Autodesk® Backburner 2014" "{3D347E6D-5A03-4342-B5BA-6A771885F379}"  
 UninstallApplication "Autodesk Essential Skills Movies for 3ds Max Design 2014 64-bit" "{280881E4-0E3C-40E6-9B76-E05A865551BB}"  
 UninstallApplication "Autodesk Sketchbook Designer 2014" "{4057E6CF-C9AC-45D7-87D4-A8FAE305AAC1}"  
 UninstallApplication "Autodesk SketchBook Designer for AutoCAD 2014" "{8BFDC12D-7F32-4F77-95DE-D1A42BAC91DD}"  
 UninstallApplication "Autodesk Showcase 2014 64-bit" "{42FCE681-2220-4EAA-8E39-20B527585547}"  
 UninstallApplication "Autodesk Revit Interoperability for 3ds Max 2014" "{0BB716E0-1400-0610-0000-097DC2F354DF}"  
 UninstallApplication "AutoCAD Architecture 2014 - English" "{5783F2D7-D004-0000-0102-0060B0CE6BBA}"  