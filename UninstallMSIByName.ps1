<#       
      .NOTES  
      ===========================================================================  
       Created with:     SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.99  
       Created on:       2/18/2016 12:32 PM  
       Created by:       Mick Pletcher  
       Filename:         UninstallMSIByName.ps1
       ===========================================================================  
      .DESCRIPTION  
           Here is a function that will uninstall an MSI installed application by  
           the name of the app. You do not need to input the entire name either.   
           For instance, say you are uninstalling all previous versions of Adobe   
           Reader. Adobe Reader is always labeled Adobe Reader X, Adobe Reader XI,  
           and so forth. You just need to enter Adobe Reader as the application   
           name and the desired switches. It will then search the name fields in   
           the 32 and 64 bit uninstall registry keys to find the associated GUID.   
           Finally, it will execute an msiexec.exe /x {GUID} to uninstall that   
           version.   
 #>  
   
 Function Uninstall-MSIByName {  
    <#   
    .SYNOPSIS   
       Uninstall-MSIByName   
    .DESCRIPTION   
       Uninstalls an MSI application using the MSI file   
    .EXAMPLE   
       Uninstall-MSIByName -ApplicationName "Adobe Reader" -Switches "/qb- /norestart"   
    #>       
        
      Param ([String]$ApplicationName,  
           [String]$Switches)  
        
      #Declare Local Variables   
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name Executable -Scope Local -Force  
      Set-Variable -Name Key -Scope Local -Force  
      Set-Variable -Name KeyName -Scope Local -Force  
      Set-Variable -Name Parameters -Scope Local -Force  
      Set-Variable -Name SearchName -Scope Local -Force  
      Set-Variable -Name TempKey -Scope Local -Force  
      Set-Variable -Name Uninstall -Scope Local -Force  
        
      $Uninstall = Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ea SilentlyContinue  
      $Uninstall += Get-ChildItem HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall -Recurse -ea SilentlyContinue  
      $SearchName = "*" + $ApplicationName + "*"  
      $Executable = $Env:windir + "\system32\msiexec.exe"  
      Foreach ($Key in $Uninstall) {  
           $TempKey = $Key.Name -split "\\"  
           If ($TempKey[002] -eq "Microsoft") {  
                $Key = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\" + $Key.PSChildName  
           } else {  
                $Key = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\" + $Key.PSChildName  
           }  
           If ((Test-Path $Key) -eq $true) {  
                $KeyName = Get-ItemProperty -Path $Key  
                If ($KeyName.DisplayName -like $SearchName) {  
                     $TempKey = $KeyName.UninstallString -split " "  
                     If ($TempKey[0] -eq "MsiExec.exe") {  
                          Write-Host "Uninstall"$KeyName.DisplayName"....." -NoNewline  
                          $Parameters = "/x " + $KeyName.PSChildName + [char]32 + $Switches  
                          $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode  
                          If (($ErrCode -eq 0) -or ($ErrCode -eq 3010) -or ($ErrCode -eq 1605)) {  
                               Write-Host "Success" -ForegroundColor Yellow  
                          } else {  
                               Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
                          }  
                     }  
                }  
           }  
      }  
        
      #Cleanup Local Variables   
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name Executable -Scope Local -Force  
      Remove-Variable -Name Key -Scope Local -Force  
      Remove-Variable -Name KeyName -Scope Local -Force  
      Remove-Variable -Name Parameters -Scope Local -Force  
      Remove-Variable -Name SearchName -Scope Local -Force  
      Remove-Variable -Name TempKey -Scope Local -Force  
      Remove-Variable -Name Uninstall -Scope Local -Force  
        
 }  
   
 Uninstall-MSIByName -ApplicationName "Adobe Reader" -Switches "/qb- /norestart"  
