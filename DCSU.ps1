 #*******************************************************************************  
 #   Author: Mick Pletcher  
 #   Date: 25 November 2013  
 #  
 #   Program: Dell Client System Update  
 #*******************************************************************************

 Clear-Host  
 #Declare Global Memory  
 Set-Variable -Name OS -Scope Global -Force  
 Set-Variable -Name RelativePath -Scope Global -Force  
 Function RenameWindow ($Title) {  
      #Declare Local Memory  
      Set-Variable -Name a -Scope Local -Force  
      $a = (Get-Host).UI.RawUI  
      $a.WindowTitle = $Title  
      #Cleanup Local Memory  
      Remove-Variable -Name a -Scope Local -Force  
 }  
 Function GetRelativePath {  
      $Global:RelativePath=(split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"  
 }  
 Function GetOSArchitecture {  
      $Global:Architecture = Get-WMIObject win32_operatingsystem  
      $Global:Architecture = $Global:Architecture.OSArchitecture  
      #Answers: 32-bit, 64-bit  
 }  
 Function ProcessRunning($Description,$Process) {  
      #Declare Local Memory  
      Set-Variable -Name ProcessActive -Scope Local -Force  
      Write-Host $Description"....." -NoNewline  
      $ProcessActive = Get-Process $Process -ErrorAction SilentlyContinue  
      if($ProcessActive -eq $null) {  
           Write-Host "Not Running" -ForegroundColor Yellow  
      } else {  
           Write-Host "Running" -ForegroundColor Red  
      }  
      #Cleanup Local Memory  
      Remove-Variable -Name ProcessActive -Scope Local -Force  
 }  
 Function KillProcess($Description,$Process) {  
      #Declare Local Memory  
      Set-Variable -Name ProcessActive -Scope Local -Force  
      Write-Host $Description"....." -NoNewline  
      $ProcessActive = Stop-Process -Name $Process -Force  
      If ($ProcessActive -eq $null) {  
           Write-Host "Killed" -ForegroundColor Yellow  
      } else {  
           Write-Host "Still Running" -ForegroundColor Red  
      }  
 }  
 Function CopyFile($FileName,$SourceDir,$DestinationDir,$NewFileName) {  
      If ($SourceDir.SubString($SourceDir.length-1) -ne "\") {  
           $SourceDir = $SourceDir+"\"  
      }  
      If ((Test-Path -Path $SourceDir$FileName) -eq $true) {  
           Write-Host "Copying"$FileName"....."  
           Copy-Item -Path $SourceDir$FileName -Destination $DestinationDir -Force  
           If ($NewFileName -ne "") {  
                If ($DestinationDir.SubString($DestinationDir.length-1) -ne "\") {  
                     $DestinationDir = $DestinationDir+"\"  
                }  
                Rename-Item -Path $DestinationDir$FileName -NewName $NewFileName -Force  
           }  
      }  
 }  
 Function BalloonTip($ApplicationName, $Status, $DisplayTime) {  
      #Declare Local Memory  
      Set-Variable -Name balloon -Scope Local -Force  
      Set-Variable -Name icon -Scope Local -Force  
      Set-Variable -Name path -Scope Local -Force  
      [system.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null  
      $balloon = New-Object System.Windows.Forms.NotifyIcon  
      $path = Get-Process -id $pid | Select-Object -ExpandProperty Path  
      $icon = [System.Drawing.Icon]::ExtractAssociatedIcon($path)  
      $balloon.Icon = $icon  
      $balloon.BalloonTipIcon = 'Info'  
      $balloon.BalloonTipTitle = "Gresham, Smith and Partners"  
      $balloon.BalloonTipText = $ApplicationName+[char]13+[char]13+$Status  
      $balloon.Visible = $true  
      $balloon.ShowBalloonTip($DisplayTime)  
      #Cleanup Local Memory  
      Remove-Variable -Name balloon -Scope Local -Force  
      Remove-Variable -Name icon -Scope Local -Force  
      Remove-Variable -Name path -Scope Local -Force  
 }  
 Function UninstallOldMSIApplication($Description) {  
      #Declare Local Memory  
      Set-Variable -Name AppName -Scope Local -Force  
      Set-Variable -Name Arguments -Scope Local -Force  
      Set-Variable -Name Desc -Scope Local -Force  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name GUID -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name Output1 -Scope Local -Force  
      #Change '%application%' to whatever app you are calling  
      $Desc = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34  
      $Output1 = wmic product where $Desc get Description  
      cls  
      $Output1 | ForEach-Object {  
           $_ = $_.Trim()  
        if(($_ -ne "Description")-and($_ -ne "")){  
          $AppName = $_  
        }  
      }  
      If ($AppName -eq $null) {  
           return  
      }  
      Write-Host "Uninstalling"$AppName"....." -NoNewline  
      $Output = wmic product where $Desc get IdentifyingNumber  
      $Output | ForEach-Object {  
           $_ = $_.Trim()  
             if(($_ -ne "IdentifyingNumber")-and($_ -ne "")){  
               $GUID = $_  
             }  
      }  
      $Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"  
      $ErrCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode  
      $Result = (AppInstalled $Description)  
      If ($Result) {  
           Write-Host "Failed with error code"$ErrCode -ForegroundColor Red  
      } else {  
           Write-Host "Uninstalled" -ForegroundColor Yellow  
      }  
      #Cleanup Local Memory  
      Remove-Variable -Name AppName -Scope Local -Force  
      Remove-Variable -Name Arguments -Scope Local -Force  
      Remove-Variable -Name Desc -Scope Local -Force  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name GUID -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name Output1 -Scope Local -Force  
 }  
 Function InstallMSIApplication($App,$Switches,$Transforms,$Desc) {  
      #Declare Local Memory  
      Set-Variable -Name App -Scope Local -Force  
      Set-Variable -Name Arguments -Scope Local -Force  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name Result -Scope Local -Force  
      Write-Host "Installing"$Desc"....." -NoNewline  
      $App = [char]32+[char]34+$RelativePath+$App+[char]34  
      $Switches = [char]32+$Switches  
      If ($Transforms -ne $null) {  
           $Transforms = [char]32+"TRANSFORMS="+$RelativePath+$Transforms  
           $Arguments = "/I"+$App+$Transforms+$Switches  
      } else {  
           $Arguments = "/I"+$App+$Switches  
      }  
      $ErrCode = (Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode  
      $Result = (AppInstalled $Desc)  
      If ($Result) {  
           Write-Host "Installed" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error"$ErrCode -ForegroundColor Red  
      }  
      #Cleanup Local Memory  
      Remove-Variable -Name App -Scope Local -Force  
      Remove-Variable -Name Arguments -Scope Local -Force  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name Result -Scope Local -Force  
 }  
 Function InstallEXEApplication($App,$Switches,$Desc) {  
      #Declare Local Memory  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name Result -Scope Local -Force  
      Write-Host "Installing <Application>....." -NoNewline  
      $App = [char]32+[char]34+$RelativePath+$App+[char]34  
      $ErrCode = (Start-Process -FilePath $App -ArgumentList $Switches -Wait -Passthru).ExitCode  
      $Result = (AppInstalled $Desc)  
      If ($Result) {  
           Write-Host "Installed" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error"$ErrCode -ForegroundColor Red  
      }  
      #Cleanup Local Memory  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name Result -Scope Local -Force  
 }  
 Function AppInstalled($Description) {  
      #Declare Local Memory  
      Set-Variable -Name AppName -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      #Change '%application%' to whatever app you are calling  
      $Description = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34  
      $Output = wmic product where $Description get Description  
      $Output | ForEach-Object {  
           $_ = $_.Trim()  
             if(($_ -ne "Description")-and($_ -ne "")){  
                $AppName = $_  
             }  
      }  
      If ($AppName -eq $null) {  
           return $false  
      } else {  
           return $true  
      }  
      #Cleanup Local Memory  
      Remove-Variable -Name AppName -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
 }  
 Function ExecuteDCSU($App,$Switches) {  
      #Declare Local Memory  
      Set-Variable -Name ErrCode -Scope Local -Force  
      $App = [char]34+"C:\Program Files (x86)\Dell\ClientSystemUpdate\"+$App+[char]34  
      $Switches = "/policy"+[char]32+$RelativePath+$Switches  
      $ErrCode = (Start-Process -FilePath $App -ArgumentList $Switches -Wait -Passthru).ExitCode  
      If ($ErrCode -eq 0) {  
           Write-Host "Drivers Updated" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error"$ErrCode -ForegroundColor Red  
      }  
      #Cleanup Local Memory  
      Remove-Variable -Name ErrCode -Scope Local -Force  
 }  
 RenameWindow "Install Dell Client System Update"  
 GetRelativePath  
 GetOSArchitecture  
 BalloonTip "Dell Client System Update" "Updating Drivers...." 10000  
 InstallMSIApplication "Dell Client System Update.msi" "/qb- /norestart" $null "Dell Client System Update"  
 ExecuteDCSU "dcsu-cli.exe" "BuildPolicy.xml"  
 UninstallOldMSIApplication "Dell Client System Update"  
 BalloonTip "Dell Client System Update" "Driver Update Complete" 30000  
 #Cleanup Global Memory  
 Remove-Variable -Name OS -Scope Global -Force  
 Remove-Variable -Name RelativePath -Scope Global -Force  
