<#  
 .NAME  
   Mick Pletcher  
 .DATE  
   11 May 2014  
 .SYNOPSIS  
   Taskbar Shortcuts  
 .DESCRIPTION  
   Create taskbar shortcuts  
 .PARAMETER <paramName>  
   <Description of script parameter>  
 .EXAMPLE  
   <An example of using the script>  
 #>  
   
 #Declare Global Memory  
 Set-Variable -Name Architecture -Scope Global -Force  
 Set-Variable -Name RelativePath -Scope Global -Force  
 Set-Variable -Name Title -Value "Application Shortcuts" -Scope Global -Force  
   
 Function ConsoleTitle ($Title){  
      $host.ui.RawUI.WindowTitle = $Title  
 }  
   
 Function GetRelativePath {   
      $Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"   
 }  
   
 Function GetArchitecture {  
      $Global:Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture  
      $Global:Architecture = $Global:Architecture.OSArchitecture  
      #Returns 32-bit or 64-bit  
 }  
   
 Function PinToStartMenu ($AppName,$PinnedApp,$App) {  
      Write-Host "Pin"$AppName" on Start Menu....." -NoNewline  
      If ((Test-Path $App) -eq $true) {  
           If ((Test-Path $PinnedApp) -eq $false) {  
                $sa = new-object -c shell.application  
                $AppSplit = $App.split("\")  
                $AppSplitCount = $AppSplit.Count  
                $Filename = $AppSplit[$AppSplitCount-1]  
                For ($i=0; $i -lt $AppSplitCount-1) {  
                     $DirectoryPath = $DirectoryPath+$AppSplit[$i]  
                     If ($i -ne $AppSplitCount-2) {  
                          $DirectoryPath = $DirectoryPath+"\"  
                     }  
                     $i++  
                }  
                $pn = $sa.namespace($DirectoryPath).parsename($Filename)  
                $pn.invokeverb('startpin')  
                If ((Test-Path $PinnedApp) -eq $true) {  
                     Write-Host "Success" -ForegroundColor Yellow  
                } else {  
                     Write-Host "Failed " -ForegroundColor Red  
                }  
           } else {  
                Write-Host "Already Present" -ForegroundColor Yellow  
           }  
      } else {  
           Write-Host "Application not installed" -ForegroundColor Green  
      }  
 }  
   
 Function PinToTaskbar ($AppName,$PinnedApp,$App) {  
      Write-Host "Pin"$AppName" to Taskbar....." -NoNewline  
      If ((Test-Path $App) -eq $true) {  
           If ((Test-Path $PinnedApp) -eq $false) {  
                $sa = new-object -c shell.application  
                $AppSplit = $App.split("\")  
                $AppSplitCount = $AppSplit.Count  
                $Filename = $AppSplit[$AppSplitCount-1]  
                For ($i=0; $i -lt $AppSplitCount-1) {  
                     $DirectoryPath = $DirectoryPath+$AppSplit[$i]  
                     If ($i -ne $AppSplitCount-2) {  
                          $DirectoryPath = $DirectoryPath+"\"  
                     }  
                     $i++  
                }  
                $pn = $sa.namespace($DirectoryPath).parsename($Filename)  
                $pn.invokeverb('taskbarpin')  
                If ((Test-Path $PinnedApp) -eq $true) {  
                     Write-Host "Success" -ForegroundColor Yellow  
                } else {  
                     Write-Host "Failed " -ForegroundColor Red  
                }  
           } else {  
                Write-Host "Already Present" -ForegroundColor Yellow  
           }  
      } else {  
           Write-Host "Application not installed" -ForegroundColor Green  
      }  
 }  
   
 Function UnpinFromStartMenu ($AppName,$PinnedApp,$App) {  
      Write-Host "Unpin"$AppName" from Start Menu....." -NoNewline  
      If ((Test-Path $PinnedApp) -eq $true) {  
           $sa = new-object -c shell.application  
           $AppSplit = $App.split("\")  
           $AppSplitCount = $AppSplit.Count  
           $Filename = $AppSplit[$AppSplitCount-1]  
           For ($i=0; $i -lt $AppSplitCount-1) {  
                $DirectoryPath = $DirectoryPath+$AppSplit[$i]  
                If ($i -ne $AppSplitCount-2) {  
                     $DirectoryPath = $DirectoryPath+"\"  
                }  
                $i++  
           }  
           $pn = $sa.namespace($DirectoryPath).parsename($Filename)  
           $pn.invokeverb('startunpin')  
           If ((Test-Path $PinnedApp) -eq $false) {  
                Write-Host "Success" -ForegroundColor Yellow  
           } else {  
                Write-Host "Failed " -ForegroundColor Red  
           }  
      } else {  
           Write-Host "Already Removed" -ForegroundColor Yellow  
      }  
 }  
   
 Function UnpinFromTaskbar ($AppName,$PinnedApp,$App) {  
      Write-Host "Unpin"$AppName" from Taskbar....." -NoNewline  
      If ((Test-Path $PinnedApp) -eq $true) {  
           $AppSplit = $App.split("\")  
           $AppSplitCount = $AppSplit.Count  
           $Filename = $AppSplit[$AppSplitCount-1]  
           $DirectoryPath = $App.Trim($Filename)  
           $DirectoryPath = $DirectoryPath.Trim("\")  
           If ($Filename -eq "EXCEL.EXE") {  
                $DirectoryPath = "c"+$DirectoryPath  
           }  
           $sa = new-object -c shell.application  
           $pn = $sa.namespace($DirectoryPath).parsename($Filename)  
           $pn.invokeverb('taskbarunpin')  
           If ((Test-Path $PinnedApp) -eq $false) {  
                Write-Host "Success" -ForegroundColor Yellow  
           } else {  
                Write-Host "Failed " -ForegroundColor Red  
           }  
      } else {  
           Write-Host "Already Removed" -ForegroundColor Yellow  
      }  
 }  
   
 cls  
 GetRelativePath  
 ConsoleTitle $Global:Title  
 GetArchitecture  
 If ($Global:Architecture -eq "32-bit") {  
      UnpinFromStartMenu "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" "C:\Program Files\Microsoft Office\Office14\OUTLOOK.EXE"  
      UnpinFromStartMenu "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Word.lnk" "C:\Program Files\Microsoft Office\Office14\WINWORD.EXE"  
      UnpinFromStartMenu "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Excel.lnk" "C:\Program Files\Microsoft Office\Office14\EXCEL.EXE"  
      UnpinFromStartMenu "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft PowerPoint.lnk" "C:\Program Files\Microsoft Office\Office14\POWERPNT.EXE"  
      UnpinFromStartMenu "eDocs DM" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Open Text eDocs Email Marker.lnk" "C:\Program Files\Open Text\Email Filing\DMMarkEmail.exe"  
      PinToStartMenu "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" "C:\Program Files\Microsoft Office\Office14\OUTLOOK.EXE"  
      PinToStartMenu "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Word.lnk" "C:\Program Files\Microsoft Office\Office14\WINWORD.EXE"  
      PinToStartMenu "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Excel.lnk" "C:\Program Files\Microsoft Office\Office14\EXCEL.EXE"  
      PinToStartMenu "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft PowerPoint.lnk" "C:\Program Files\Microsoft Office\Office14\POWERPNT.EXE"  
      UnpinFromTaskbar "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Outlook 2010.lnk" "C:\Program Files\Microsoft Office\Office14\OUTLOOK.EXE"  
      UnpinFromTaskbar "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Word 2010.lnk" "C:\Program Files\Microsoft Office\Office14\WINWORD.EXE"  
      UnpinFromTaskbar "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Excel 2010.lnk" "C:\Program Files\Microsoft Office\Office14\EXCEL.EXE"  
      UnpinFromTaskbar "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft PowerPoint 2010.lnk" "C:\Program Files\Microsoft Office\Office14\POWERPNT.EXE"  
      PinToTaskbar "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Outlook 2010.lnk" "C:\Program Files\Microsoft Office\Office14\OUTLOOK.EXE"  
      PinToTaskbar "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Word 2010.lnk" "C:\Program Files\Microsoft Office\Office14\WINWORD.EXE"  
      PinToTaskbar "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Excel 2010.lnk" "C:\Program Files\Microsoft Office\Office14\EXCEL.EXE"  
      PinToTaskbar "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft PowerPoint 2010.lnk" "C:\Program Files\Microsoft Office\Office14\POWERPNT.EXE"  
 } else {  
      UnpinFromStartMenu "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"  
      UnpinFromStartMenu "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Word.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\WINWORD.EXE"  
      UnpinFromStartMenu "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Excel.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\EXCEL.EXE"  
      UnpinFromStartMenu "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft PowerPoint.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\POWERPNT.EXE"  
      PinToStartMenu "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Outlook.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"  
      PinToStartMenu "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Word.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\WINWORD.EXE"  
      PinToStartMenu "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft Excel.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\EXCEL.EXE"  
      PinToStartMenu "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\StartMenu\Microsoft PowerPoint.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\POWERPNT.EXE"  
      UnpinFromTaskbar "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Outlook 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"  
      UnpinFromTaskbar "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Word 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\WINWORD.EXE"  
      UnpinFromTaskbar "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Excel 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\EXCEL.EXE"  
      UnpinFromTaskbar "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft PowerPoint 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\POWERPNT.EXE"  
      PinToTaskbar "Outlook" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Outlook 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\OUTLOOK.EXE"  
      PinToTaskbar "Word" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Word 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\WINWORD.EXE"  
      PinToTaskbar "Excel" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Excel 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\EXCEL.EXE"  
      PinToTaskbar "PowerPoint" $Env:APPDATA"\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft PowerPoint 2010.lnk" "C:\Program Files (x86)\Microsoft Office\Office14\POWERPNT.EXE"  
 }  
 