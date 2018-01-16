<#       
     .NOTES  
     ===========================================================================  
      Created with:      SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.90  
      Created on:       7 August 2015 12:18 PM  
      Created by:       Mick Pletcher  
      Organization:        
      Filename:        installSCCMClient_Standalone.ps1  
     ===========================================================================  
     .DESCRIPTION  
          This script will uninstall all previous versions of SCCM Client,  
          including the execution of the ccmclean.exe to rid the system of  
          any remnants of the previous client. It will then install the new  
          client and wait until the client is installed and is communicating  
          with the SCCM server.  

#>

#Declare Global Variables  
Set-Variable -Name RelativePath -Scope Global -Force  
Set-Variable -Name Title -Scope Global -Force  

Function InitializeVariables {  
     $Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"  
     $Global:Title = "SCCM 2012 R2 Client"  
}  

Function Install-EXE {  
     <#  
     .SYNOPSIS  
          Install-EXE  
     .DESCRIPTION  
          Installs an EXE file  
     .EXAMPLE  
          Install-EXE -DisplayName "Microsoft Office 2013" -Executable "c:\temp\install.exe" -Switches "/passive /norestart"  
     #>  

     Param ([String]$DisplayName,  
          [String]$Executable,  
          [String]$Switches)  

     Write-Host "Install"$DisplayName"....." -NoNewline  
     If ((Test-Path $Executable) -eq $true) {  
          $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode  
     } else {  
          $ErrCode = 1  
     }  
     If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
          Write-Host "Success" -ForegroundColor Yellow  
     } else {  
          Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
     }  
}  

Function Install-MSP {  
     <#  
     .SYNOPSIS  
          Install-MSP  
     .DESCRIPTION  
          Installs an MSP patch  
     .EXAMPLE  
          Install-MSP -DisplayName "KB977203" -MSP $Global:RelativePath"i386\sccm2007ac-sp2-kb977203-x86.msp" -Switches "/qb- /norestart"  
     #>  

     Param ([String]$DisplayName,  
          [String]$MSP,  
          [String]$Switches)  

     $Executable = $Env:windir + "\system32\msiexec.exe"  
     $Parameters = "/p " + [char]34 + $MSP + [char]34 + [char]32 + $Switches  
     Write-Host "Install"$DisplayName"....." -NoNewline  
     $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode  
     If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
          Write-Host "Success" -ForegroundColor Yellow  
     } else {  
          Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
     }  
}  

Function Set-ConsoleTitle {  
     <#  
     .SYNOPSIS  
          Set-ConsoleTitle  
     .DESCRIPTION  
          Renames the PowerShell console window  
     .EXAMPLE  
          Set-ConsoleTitle -Title "Test"  
     #>  

     Param ([String]$Title)  
     $host.ui.RawUI.WindowTitle = $Title  
}  

Function Stop-Task {  
     <#  
     .SYNOPSIS  
         Stop-Task  
     .DESCRIPTION  
         Kills a designated Task  
     .EXAMPLE  
          Stop-Task -Process "outlook"  
     #>  

     Param ([String]$Process)  

     $Proc = Get-Process $Process -ErrorAction SilentlyContinue  
     Write-Host "Killing"$Process"....." -NoNewline  
     If ($Proc -ne $null) {  
          Do {  
               $ProcName = $Process + ".exe"  
               $Temp = taskkill /F /IM $ProcName  
               Start-Sleep -Seconds 2  
               $Proc = $null  
               $Proc = Get-Process $Process -ErrorAction SilentlyContinue  
          } While ($Proc -ne $null)  
          Write-Host "Closed" -ForegroundColor Yellow  
     } else {  
          Write-Host "Already Closed" -ForegroundColor Green  
     }  
}  

Function Uninstall-EXE {  
     <#  
     .SYNOPSIS  
          Uninstall-EXE  
     .DESCRIPTION  
          Uninstalls an EXE file  
     .EXAMPLE  
          Uninstall-EXE -DisplayName "Microsoft Office 2013" -Executable "c:\temp\setup.exe" -Switches "/uninstall /passive /norestart"  
     #>  

     Param ([String]$DisplayName,  
          [String]$Executable,  
          [String]$Switches)  

     Write-Host "Uninstall"$DisplayName"....." -NoNewline  
     $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Switches -Wait -Passthru).ExitCode  
     If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
          Write-Host "Success" -ForegroundColor Yellow  
     } else {  
          Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
     }  
}  

Function Uninstall-MSIByGUID {  
     <#  
     .SYNOPSIS  
          Uninstall-MSIByGUID  
     .DESCRIPTION  
          Uninstalls an MSI application using the GUID  
     .EXAMPLE  
          Uninstall-MSIByGUID -DisplayName "Workshare Professional" -GUID "{8686EC18-6282-4AA9-92AC-2865B972E244}" -Switches "/qb- /norestart"  
     #>  

     Param ([String]$DisplayName,  
          [String]$GUID,  
          [String]$Switches)  

     $Executable = $Env:windir + "\system32\msiexec.exe"  
     $Parameters = "/x " + $GUID + [char]32 + $Switches  
     Write-Host "Uninstall"$DisplayName"....." -NoNewline  
     $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode  
     If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
          Write-Host "Success" -ForegroundColor Yellow  
     } elseIf ($ErrCode -eq 1605) {  
          Write-Host "Not Present" -ForegroundColor Green  
     } else {  
          Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
     }  
}  

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
}  

Function Wait-ProcessEnd {  
     <#  
     .SYNOPSIS  
          Wait-Process  
     .DESCRIPTION  
          Waits for a Process to end before continuing.  
     .EXAMPLE  
          Wait-Process -Process "explorer"  
     #>  

     Param ([String]$Process)  

     Write-Host "Waiting for"$Process" to end....." -NoNewline  
     $Proc = Get-Process $Process -ErrorAction SilentlyContinue  
     If ($Proc -ne $null) {  
          Do {  
               Start-Sleep -Seconds 5  
               $Proc = Get-Process $Process -ErrorAction SilentlyContinue  
          } While ($Proc -ne $null)  
          Write-Host "Ended" -ForegroundColor Yellow  
     } else {  
          Write-Host "Process Already Ended" -ForegroundColor Yellow  
     }  
}  

cls  
InitializeVariables  
Set-ConsoleTitle -Title $Global:Title  
Stop-Task -Process "msiexec"  
Uninstall-MSIByName -ApplicationName "Configuration Manager Client" -Switches "/qb- /norestart"  
Stop-Task -Process "msiexec"  
Uninstall-MSIByGUID -DisplayName "SCCM 2007 Client" -GUID "{2609EDF1-34C4-4B03-B634-55F3B3BC4931}" -Switches "/qb- /norestart"  
Stop-Task -Process "msiexec"  
Uninstall-MSIByGUID -DisplayName "SCCM 2012 Client" -GUID "{BFDADC41-FDCD-4B9C-B446-8A818D01BEA3}" -Switches "/qb- /norestart"  
Stop-Task -Process "msiexec"  
Uninstall-EXE -DisplayName "CCMClean" -Executable $Global:RelativePath"ccmclean.exe" -Switches "/all /logdir:%windir%\waller\logs /removehistory /q"  
Stop-Task -Process "msiexec"  
Install-EXE -DisplayName "SCCM 2012 R2 Client" -Executable $Global:RelativePath"ccmsetup.exe" -Switches "/mp:bnasccm.wallerlaw.int SMSSITECODE=BNA"  
Wait-ProcessEnd -Process "CCMSETUP"  
Stop-Task -Process "msiexec"  

#Cleanup Global Variables  
Remove-Variable -Name RelativePath -Scope Global -Force  
Remove-Variable -Name Title -Scope Global -Force  
