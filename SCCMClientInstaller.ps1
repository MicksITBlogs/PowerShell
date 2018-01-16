<#  
 .NAME  
   Mick Pletcher  
 .DATE  
   13 June 2014  
 .SYNOPSIS  
   SCCM 2007  
 .DESCRIPTION  
   <A detailed description of the script>  
 .PARAMETER <paramName>  
   <Description of script parameter>  
 .EXAMPLE  
   <An example of using the script>  
 #>  
   
 #Declare Global Memory  
 Set-Variable -Name BuildLog -Scope Global -Force  
 Set-Variable -Name Errors -Value $null -Scope Global -Force  
 Set-Variable -Name LogFile -Scope Global -Force  
 Set-Variable -Name RelativePath -Scope Global -Force  
 Set-Variable -Name Sequence -Scope Global -Force  
 Set-Variable -Name Title -Scope Global -Force  
   
 Function DeclareGlobalVariables {  
      $Global:BuildLog = $Env:windir+"\Logs\BuildLogs\Build.log"  
      $Global:LogFile = $Env:windir+"\Logs\BuildLogs\SCCM2007Client.log"  
      $Global:Sequence = "01"  
      $Global:Title = "SCCM 2007 Client"  
 }  
   
 Function ConsoleTitle ($Title){  
      $host.ui.RawUI.WindowTitle = $Title  
 }  
   
 Function GetRelativePath {   
      $Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"   
 }  
   
 Function UninstallMSI ($ProgName,$GUID) {  
      $EXE = $Env:windir+"\system32\msiexec.exe"  
      $Switches = [char]32+"/qb- /norestart"  
      $Parameters = "/x "+$GUID+$Switches  
      $Output = "Uninstall"+$ProgName+"....."  
      Write-Host "Uninstall"$ProgName"....." -NoNewline  
      $ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -Passthru).ExitCode  
      If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
           $Output = $Output+"Success"  
           Write-Host "Success" -ForegroundColor Yellow  
      } elseIf ($ErrCode -eq 1605) {  
           $Output = $Output+"Not Present"  
           Write-Host "Not Present" -ForegroundColor Green  
      } else {  
           $Output = $Output+"Failed with error code "+$ErrCode  
           Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
           $Global:Errors++  
      }  
      Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force  
 }  
   
 Function InstallMSI ($ProgName,$MSI,$Switches) {  
      $EXE = $Env:windir+"\system32\msiexec.exe"  
      $Parameters = "/i "+[char]34+$MSI+[char]34+[char]32+$Switches  
      $Output = "Install"+$ProgName+"....."  
      Write-Host "Install"$ProgName"....." -NoNewline  
      $ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -Passthru).ExitCode  
      If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
           $Output = $Output+"Success"  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           $Output = $Output+"Failed with error code "+$ErrCode  
           Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
           $Global:Errors++  
      }  
      Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force  
 }  
   
 Function InstallEXE ($ProgName,$EXE,$Switches){  
      $Output = "Install "+$ProgName+"....."  
      Write-Host "Install "$ProgName"....." -NoNewline  
      $ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Switches -Wait -Passthru).ExitCode  
      If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
           $Output = $Output+"Success"  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           $Output = $Output+"Failed with error code "+$ErrCode  
           Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
           $Global:Errors++  
      }  
      Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force  
 }  
   
 Function InstallMSP ($ProgName,$MSP,$Switches) {  
      $EXE = $Env:windir+"\system32\msiexec.exe"  
      $Parameters = "/p "+[char]34+$MSP+[char]34+[char]32+$Switches  
      $Output = "Install"+$ProgName+"....."  
      Write-Host "Install"$ProgName"....." -NoNewline  
      $ErrCode = (Start-Process -FilePath $EXE -ArgumentList $Parameters -Wait -Passthru).ExitCode  
      If (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
           $Output = $Output+"Success"  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           $Output = $Output+"Failed with error code "+$ErrCode  
           Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
           $Global:Errors++  
      }  
      Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force  
 }  
   
 Function WaitForProcessEnd ($Process) {  
      $Proc = Get-Process $Process -ErrorAction SilentlyContinue  
      $Output = "Waiting for"+$Process+"to complete....."  
      Write-Host "Waiting for"$Process" to complete....." -NoNewline  
      If ($Proc -ne $null) {  
           Do {  
                Start-Sleep -Seconds 5  
                $Proc = Get-Process $Process -ErrorAction SilentlyContinue  
           } While ($Proc -ne $null)  
           $Output = $Output+"Completed"  
           Write-Host "Completed" -ForegroundColor Yellow  
      } else {  
           $Output = $Output+"Already Completed"  
           Write-Host "Already Completed" -ForegroundColor Yellow  
      }  
      Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force  
 }  
   
 Function ProcessLogFile {  
      If ((Test-Path $Env:windir"\Logs") -eq $false) {  
           New-Item -ItemType Directory -Path $Env:windir"\Logs"  
      }  
      If ((Test-Path $Env:windir"\Logs\ApplicationLogs") -eq $false) {  
           New-Item -ItemType Directory -Path $Env:windir"\Logs\ApplicationLogs"  
      }  
      If ((Test-Path $Env:windir"Logs\BuildLogs") -eq $false) {  
           New-Item -ItemType Directory -Path $Env:windir"\Logs\BuildLogs"  
      }  
      If ($Global:Errors -eq $null) {  
           If (Test-Path $Global:LogFile) {  
                Remove-Item $Global:LogFile -Force  
           }  
           $File1 = $Global:LogFile.Split(".")  
           $Filename1 = $File1[0]+"_ERROR"+"."+$File1[1]  
           If (Test-Path $Filename1) {  
                Remove-Item $Filename1 -Force  
           }  
           $Global:Errors = 0  
      } elseIf ($Global:Errors -ne 0) {  
           If (Test-Path $Global:LogFile) {  
                $Global:LogFile.ToString()  
                $File1 = $Global:LogFile.Split(".")  
                $Filename1 = $File1[0]+"_ERROR"+"."+$File1[1]  
                Rename-Item $Global:LogFile -NewName $Filename1 -Force  
           }  
      } else {  
           $LogTitle = $Global:Sequence+" - "+$Global:Title  
           Out-File -FilePath $Global:BuildLog -InputObject $LogTitle -Append -Force  
      }  
 }  
   
 cls  
 DeclareGlobalVariables  
 GetRelativePath  
 ConsoleTitle $Global:Title  
 ProcessLogFile  
 UninstallMSI "Microsoft SCCM 2007 Client" $Global:RelativePath"i386\client.msi"  
 InstallMSI "Microsoft XML 6" $Global:RelativePath"i386\msxml6.msi" "/qb- /norestart"  
 InstallEXE "Microsoft SCCM 2007" $Global:RelativePath"ccmsetup.exe" "SMSSITECODE=ENT SMSCACHESIZE=5120"  
 WaitForProcessEnd "CCMSETUP"  
 InstallMSP "KB977203" $Global:RelativePath"i386\sccm2007ac-sp2-kb977203-x86.msp" "/qb- /norestart"  
 InstallMSP "KB2659258" $Global:RelativePath"i386\sccm2007ac-sp2-kb2659258-x86-enu.msp" "/qb- /norestart"  
 ProcessLogFile  
 Start-Sleep -Seconds 5  
   