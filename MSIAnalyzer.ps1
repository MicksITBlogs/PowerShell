<#       
    .NOTES  
    ===========================================================================  
     Created with:     SAPIEN Technologies, Inc., PowerShell Studio 2015 v4.2.90  
     Created on:       27 July 2015 9:24 AM  
     Created by:       Mick Pletcher  
     Filename:         MSIAnalyzer.ps1  
    ===========================================================================  
     .DESCRIPTION  
          This script will uninstall all previous versions of SCCM Client,  
          including the execution of the ccmclean.exe to rid the system of  
          any remnants of the previous client. It will then install the new  
          client and wait until the client is installed and is communicating  
          with the SCCM server.  
  
#>  
  
#Declare Global Variables  
Set-Variable -Name ApplicationName -Scope Global -Force  
Set-Variable -Name MSI -Scope Global -Force  
Set-Variable -Name ProductCode -Scope Global -Force  
  
function Get-RelativePath {  
     #Declare Local Variables  
     Set-Variable -Name RelativePath -Scope Local -Force  
       
     $RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent) + "\"  
     Return $RelativePath  
       
     #Cleanup Local Variables  
     Remove-Variable -Name RelativePath -Scope Local -Force  
}  
  
function Get-Architecture {  
     #Declare Local Variables  
     Set-Variable -Name Architecture -Scope Local -Force  
       
     $Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture  
     $Architecture = $Global:Architecture.OSArchitecture  
     Return $Architecture  
       
     #Cleanup Local Variables  
     Remove-Variable -Name Architecture -Scope Local -Force  
}  
  
function ProcessTextFiles {  
     #Declare Local Variables  
     Set-Variable -Name RelativePath -Scope Local -Force  
       
     If ((Test-Path -Path $RelativePath"Installer.log") -eq $true) {  
          Remove-Item -Path $RelativePath"Installer.log" -Force  
     }  
     If ((Test-Path -Path $RelativePath"UserInput.txt") -eq $true) {  
          Remove-Item -Path $RelativePath"UserInput.txt" -Force  
     }  
     If ((Test-Path -Path $RelativePath"Report.txt") -eq $true) {  
          Remove-Item -Path $RelativePath"Report.txt" -Force  
     }  
       
     #Cleanup Local Variables  
     Remove-Variable -Name RelativePath -Scope Local -Force  
}  
  
function Get-MSIFile {  
     #Declare Local Variables  
     Set-Variable -Name FileCount -Value 1 -Scope Local -Force  
     Set-Variable -Name MSIFile -Scope Local -Force  
     Set-Variable -Name RelativePath -Scope Local -Force  
       
     $RelativePath = Get-RelativePath  
     $MSIFile = Get-ChildItem $RelativePath -Filter *.msi  
     Write-Host $MSIFile.Count  
     If ($MSIFile.Count -eq 1) {  
          Return $MSIFile  
     } else {  
          Do {  
               Clear-Host  
               $FileCount = 1  
               Write-Host "Select MSI to process:"  
               foreach ($MSI in $MSIFile) {  
                    Write-Host $FileCount" - "$MSI  
                    $FileCount++  
               }  
               Write-Host  
               Write-Host "Selection:"  
               [int]$input = Read-Host  
          } while (($input -eq $null) -or ($input -eq "") -or ($input -gt $MSIFile.Count) -or (!($input -as [int] -is [int])))  
          $input = $input - 1  
          $MSIFile = $MSIFile[$input]  
          $global:MSI = $RelativePath + $MSIFile  
     }  
                 
     #Cleanup Local Variables  
     Remove-Variable -Name FileCount -Scope Local -Force  
     Remove-Variable -Name MSIFile -Scope Local -Force  
     Remove-Variable -Name RelativePath -Scope Local -Force  
}  
  
 function Get-MSIFileInfo {  
      param (  
           [parameter(Mandatory = $true)][IO.FileInfo]  
           $Path,  
           [parameter(Mandatory = $true)][ValidateSet("ProductCode", "ProductVersion", "ProductName")][string]  
           $Property  
      )  
        
      #Declare Local Variables  
      Set-Variable -Name MSIDatabase -Scope Local -Force  
      Set-Variable -Name Query -Scope Local -Force  
      Set-Variable -Name Record -Scope Local -Force  
      Set-Variable -Name Value -Scope Local -Force  
      Set-Variable -Name View -Scope Local -Force  
      Set-Variable -Name WindowsInstaller -Scope Local -Force  
        
      try {  
           $WindowsInstaller = New-Object -ComObject WindowsInstaller.Installer  
           $MSIDatabase = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($Path.FullName, 0))  
           $Query = "SELECT Value FROM Property WHERE Property = '$($Property)'"  
           $View = $MSIDatabase.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $MSIDatabase, ($Query))  
           $View.GetType().InvokeMember("Execute", "InvokeMethod", $null, $View, $null)  
           $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $View, $null)  
           $Value = $Record.GetType().InvokeMember("StringData", "GetProperty", $null, $Record, 1)  
           return $Value  
      } catch {  
           Write-Output $_.Exception.Message  
      }  
        
      #Declare Local Variables  
      Remove-Variable -Name MSIDatabase -Scope Local -Force  
      Remove-Variable -Name Query -Scope Local -Force  
      Remove-Variable -Name Record -Scope Local -Force  
      Remove-Variable -Name Value -Scope Local -Force  
      Remove-Variable -Name View -Scope Local -Force  
      Remove-Variable -Name WindowsInstaller -Scope Local -Force  
 }  
   
 function New-UserInputFile {  
      #Declare Local Variables  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
        
      $RelativePath = Get-RelativePath  
      If ((Test-Path -Path $RelativePath"UserInput.txt") -eq $true) {  
           Remove-Item -Path $RelativePath"UserInput.txt" -Force  
      }  
      Write-Host "Creating UserInput.txt File....." -NoNewline  
      $ErrCode = New-Item -Path $RelativePath"UserInput.txt" -Type File -Force  
      If ((Test-Path -Path $RelativePath"UserInput.txt") -eq $true) {  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed" -ForegroundColor Red  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
        
 }  
   
 function Install-MSI {  
      #Declare Local Variables  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name Executable -Scope Local -Force  
      Set-Variable -Name MSI -Scope Local -Force  
      Set-Variable -Name Parameters -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
      Set-Variable -Name Switches -Scope Local -Force  
        
      $RelativePath = Get-RelativePath  
      $Global:ApplicationName = Get-MSIFileInfo -Path $global:MSI -Property 'ProductName'  
      $Global:ProductCode = Get-MSIFileInfo -Path $global:MSI -Property 'ProductCode'  
      If ((Test-Path -Path $RelativePath"Installer.log") -eq $true) {  
           Remove-Item -Path $RelativePath"Installer.log" -Force  
      }  
      $Executable = $Env:windir + "\system32\msiexec.exe"  
      $Switches = "/qb- /norestart"  
      $Parameters = "/x" + [char]32 + $Global:ProductCode + [char]32 + $Switches  
      $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode  
      Write-Host "Uninstalling"$Global:ApplicationName"....." -NoNewline  
      if (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
      }  
      $Notepad = $env:windir + "\notepad.exe"  
      $Parameters = $RelativePath + "UserInput.txt"  
      $ErrCode = (Start-Process -FilePath $Notepad -ArgumentList $Parameters -PassThru).ExitCode  
      $Switches = "/norestart"  
      $Parameters = "/i " + [char]34 + $Global:MSI + [char]34 + [char]32 + $Switches + [char]32 + "/lvx " + [char]34 + $RelativePath + "Installer.log" + [char]34  
      Write-Host $Parameters  
      Write-Host "Installing"$Global:ApplicationName"....." -NoNewline  
      $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode  
      if (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
      }  
      Write-Host "Creating Log File....." -NoNewline  
      If ((Test-Path $RelativePath"Installer.log") -eq $true) {  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed" -ForegroundColor Red  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name Executable -Scope Local -Force  
      Remove-Variable -Name MSI -Scope Local -Force  
      Remove-Variable -Name Parameters -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
      Remove-Variable -Name Switches -Scope Local -Force  
 }  
   
 function Uninstall-MSI {  
      #Declare Local Variables  
      Set-Variable -Name ErrCode -Scope Local -Force  
      Set-Variable -Name Executable -Scope Local -Force  
      Set-Variable -Name Line -Scope Local -Force  
      Set-Variable -Name LogFile -Scope Local -Force  
      Set-Variable -Name MSI -Scope Local -Force  
      Set-Variable -Name Parameters -Scope Local -Force  
      Set-Variable -Name Process -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
      Set-Variable -Name Switches -Scope Local -Force  
        
      $RelativePath = Get-RelativePath  
      $Process = Get-Process -Name notepad -ErrorAction SilentlyContinue  
      If ($Process -ne $null) {  
           Stop-Process -Name notepad -ErrorAction SilentlyContinue -Force  
      }  
      $Executable = $Env:windir + "\system32\msiexec.exe"  
      $Switches = "/qb- /norestart"  
      $Parameters = "/x" + [char]32 + $Global:ProductCode + [char]32 + $Switches  
      Write-Host "Uninstalling"$Global:ApplicationName"....." -NoNewline  
      $ErrCode = (Start-Process -FilePath $Executable -ArgumentList $Parameters -Wait -Passthru).ExitCode  
      if (($ErrCode -eq 0) -or ($ErrCode -eq 3010)) {  
           Write-Host "Success" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed with error code "$ErrCode -ForegroundColor Red  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name ErrCode -Scope Local -Force  
      Remove-Variable -Name Executable -Scope Local -Force  
      Remove-Variable -Name Line -Scope Local -Force  
      Remove-Variable -Name LogFile -Scope Local -Force  
      Remove-Variable -Name MSI -Scope Local -Force  
      Remove-Variable -Name Parameters -Scope Local -Force  
      Remove-Variable -Name Process -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
      Remove-Variable -Name Switches -Scope Local -Force  
 }  
   
 function Get-ProductName {  
      #Declare Local Variables  
      Set-Variable -Name Database -Scope Local -Force  
      Set-Variable -Name MSIFileName -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name OutputFile -Scope Local -Force  
      Set-Variable -Name PropertyName -Scope Local -Force  
      Set-Variable -Name PropertyValue -Scope Local -Force  
      Set-Variable -Name Record -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
      Set-Variable -Name View -Scope Local -Force  
      Set-Variable -Name WindowsInstaller -Scope Local -Force  
        
      $RelativePath = Get-RelativePath  
      $MSIFileName = $global:MSI  
      $OutputFile = $RelativePath + "Report.txt"  
      $Output = [char]13  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "Product Name"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "------------"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $WindowsInstaller = New-Object -com WindowsInstaller.Installer  
      $Database = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIFileName, 0))  
      $View = $Database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Database, ("SELECT * FROM Property"))  
      $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)  
      $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)  
      while ($Record -ne $Null) {  
           $PropertyName = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 1)  
           [string]$PropertyValue = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 2)  
           IF ($PropertyName -like "*ProductName*") {  
                $Output = $PropertyValue  
                Write-Host $Output  
                Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
           }  
           $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name Database -Scope Local -Force  
      Remove-Variable -Name MSIFileName -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name OutputFile -Scope Local -Force  
      Remove-Variable -Name PropertyName -Scope Local -Force  
      Remove-Variable -Name PropertyValue -Scope Local -Force  
      Remove-Variable -Name Record -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
      Remove-Variable -Name View -Scope Local -Force  
      Remove-Variable -Name WindowsInstaller -Scope Local -Force  
 }  
   
 function Get-ProductCode {  
      #Declare Local Variables  
      Set-Variable -Name Database -Scope Local -Force  
      Set-Variable -Name MSIFileName -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name OutputFile -Scope Local -Force  
      Set-Variable -Name PropertyName -Scope Local -Force  
      Set-Variable -Name PropertyValue -Scope Local -Force  
      Set-Variable -Name Record -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
      Set-Variable -Name View -Scope Local -Force  
      Set-Variable -Name WindowsInstaller -Scope Local -Force  
        
      $RelativePath = Get-RelativePath  
      $MSIFileName = $global:MSI  
      $OutputFile = $RelativePath + "Report.txt"  
      $Output = [char]13  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "Product Code"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "------------"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $WindowsInstaller = New-Object -com WindowsInstaller.Installer  
      $Database = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIFileName, 0))  
      $View = $Database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Database, ("SELECT * FROM Property"))  
      $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)  
      $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)  
      while ($Record -ne $Null) {  
           $PropertyName = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 1)  
           [string]$PropertyValue = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 2)  
           IF ($PropertyName -like "*ProductCode*") {  
                $Output = $PropertyValue  
                Write-Host $Output  
                Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
           }  
           $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name Database -Scope Local -Force  
      Remove-Variable -Name MSIFileName -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name OutputFile -Scope Local -Force  
      Remove-Variable -Name PropertyName -Scope Local -Force  
      Remove-Variable -Name PropertyValue -Scope Local -Force  
      Remove-Variable -Name Record -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
      Remove-Variable -Name View -Scope Local -Force  
      Remove-Variable -Name WindowsInstaller -Scope Local -Force  
 }  
   
 function Get-MSIFileName {  
      #Declare Local Variables  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name OutputFile -Scope Local -Force  
        
      $OutputFile = $RelativePath + "Report.txt"  
      $Output = [char]13  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "MSI Filename"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "------------"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = $global:MSI  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
        
      #Cleanup Local Variables  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name OutputFile -Scope Local -Force  
        
 }  
   
 function Get-Properties {  
      #Declare Local Variables  
      Set-Variable -Name Entries -Scope Local -Force  
      Set-Variable -Name Entry -Scope Local -Force  
      Set-Variable -Name File -Scope Local -Force  
      Set-Variable -Name FormattedEntry -Scope Local -Force  
      Set-Variable -Name Line -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name OutputFile -Scope Local -Force  
      Set-Variable -Name Position -Scope Local -Force  
      Set-Variable -Name Property -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
      Set-Variable -Name Value -Scope Local -Force  
        
      $OutputArray = @()  
      $RelativePath = Get-RelativePath  
      $File = Get-Content -Path $RelativePath"Installer.log"  
      $OutputFile = $RelativePath+"Report.txt"  
      $Entries = Get-Content -Path $RelativePath"UserInput.txt"  
      $Output = [char]13  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "Properties"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "----------"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      If ($Entries -ne $null) {  
           foreach ($Line in $File) {  
                If ($Line -like "*PROPERTY CHANGE: Adding*") {  
                     foreach ($Entry in $Entries) {  
                          $FormattedEntry = [char]42 + [char]39 + $Entry + [char]39 + [char]42  
                          If ($Line -like $FormattedEntry) {  
                               $Property = $Line  
                               $Value = $Line  
                               $Property = $Property.split(':')[-1]  
                               If ($Property[0] -eq "\") {  
                                    $Property = $Line  
                                    $Property = $Property.split(':')[-2]  
                               }  
                               $Property = $Property.Trim()  
                               $Property = $Property.Trim("Adding")  
                               $Property = $Property.Trim()  
                               $Property = $Property.Trim(" ")  
                               $Position = $Property.IndexOf(" ")  
                               If ($Property -notlike "*:\*") {  
                                    $Property = $Property.Substring(0, $Position)  
                               }  
                               $Output = $Property + ": " + $Entry  
                               $OutputArray += $Output  
                          }  
                     }  
                }  
           }  
           $OutputArray = $OutputArray | select -Unique  
           $OutputArray = $OutputArray | Sort  
           foreach ($Item in $OutputArray) {  
                Write-Host $Item  
                If ($Item -ne $null) {  
                     Out-File -FilePath $OutputFile -InputObject $Item -Append -Force  
                }  
           }  
      } else {  
           $Output = "No User Input Properties Exist"  
           Write-Host $Output  
           Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name Entries -Scope Local -Force  
      Remove-Variable -Name Entry -Scope Local -Force  
      Remove-Variable -Name File -Scope Local -Force  
      Remove-Variable -Name FormattedEntry -Scope Local -Force  
      Remove-Variable -Name Line -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name OutputFile -Scope Local -Force  
      Remove-Variable -Name Position -Scope Local -Force  
      Remove-Variable -Name Property -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
      Remove-Variable -Name Value -Scope Local -Force  
 }  
   
 function Get-Features {  
      #Declare Local Variables  
      Set-Variable -Name Entries -Scope Local -Force  
      Set-Variable -Name File -Scope Local -Force  
      Set-Variable -Name Line -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name OutputFile -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
      Set-Variable -Name Value -Scope Local -Force  
      Set-Variable -Name Values -Scope Local -Force  
        
      $RelativePath = Get-RelativePath  
      $OutputFile = $RelativePath + "Report.txt"  
      $Entries = Get-Content -Path $RelativePath"UserInput.txt"  
      $Output = [char]13  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "Features"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "--------"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      If ($Entries -ne $null) {  
           $File = Get-Content -Path $global:RelativePath"Installer.log"  
           foreach ($Line in $File) {  
                If ($Line -like "*ADDLOCAL*") {  
                     $Value = $Line.split(' ')[-1]  
                     $Value = $Value -replace '''', ''  
                     $Value = $Value.SubString(0, $Value.Length - 1)  
                     $Values = $Value.Split(",")  
                     foreach ($Value in $Values) {  
                          Write-Host $Value  
                          Out-File -FilePath $OutputFile -InputObject $Value -Append -Force  
                     }  
                }  
           }  
      } else {  
           $Output = "No User Input Features Exist"  
           Write-Host $Output  
           Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name Entries -Scope Local -Force  
      Remove-Variable -Name File -Scope Local -Force  
      Remove-Variable -Name Line -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name OutputFile -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
      Remove-Variable -Name Value -Scope Local -Force  
      Remove-Variable -Name Values -Scope Local -Force  
 }  
   
 function Get-Buttons {  
      #Declare Local Variables  
      Set-Variable -Name Database -Scope Local -Force  
      Set-Variable -Name Entries -Scope Local -Force  
      Set-Variable -Name Entry -Scope Local -Force  
      Set-Variable -Name MSIFileName -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name OutputFile -Scope Local -Force  
      Set-Variable -Name PropertyName -Scope Local -Force  
      Set-Variable -Name PropertyValue -Scope Local -Force  
      Set-Variable -Name Record -Scope Local -Force  
      Set-Variable -Name RelativePath -Scope Local -Force  
      Set-Variable -Name View -Scope Local -Force  
      Set-Variable -Name WindowsInstaller -Scope Local -Force  
        
      $RelativePath = Get-RelativePath  
      $MSIFileName = $global:MSI  
      $Entries = Get-Content -Path $RelativePath"UserInput.txt"  
      $OutputFile = $RelativePath + "Report.txt"  
      $Output = [char]13  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "Buttons"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      $Output = "--------"  
      Write-Host $Output  
      Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
      foreach ($Entry in $Entries) {  
           $WindowsInstaller = New-Object -com WindowsInstaller.Installer  
           $Database = $WindowsInstaller.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $Null, $WindowsInstaller, @($MSIFileName, 0))  
           $View = $Database.GetType().InvokeMember("OpenView", "InvokeMethod", $Null, $Database, ("SELECT * FROM RadioButton"))  
           $View.GetType().InvokeMember("Execute", "InvokeMethod", $Null, $View, $Null)  
           $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)  
           $Entry = "*" + $Entry + "*"  
           while ($Record -ne $Null) {  
                $PropertyName = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 1)  
                if (-not ($PropertyName -cmatch "[a-z]")) {  
                     [string]$PropertyValue = $Record.GetType().InvokeMember("StringData", "GetProperty", $Null, $Record, 8)  
                     IF ($PropertyValue -like $Entry) {  
                          $Output = $PropertyName + " = " + $PropertyValue  
                          Write-Host $Output  
                          Out-File -FilePath $OutputFile -InputObject $Output -Append -Force  
                          #Write-Host ($PropertyName + " = " + $PropertyValue)  
                     }  
                }  
                $Record = $View.GetType().InvokeMember("Fetch", "InvokeMethod", $Null, $View, $Null)  
           }  
      }  
        
      #Cleanup Local Variables  
      Remove-Variable -Name Database -Scope Local -Force  
      Remove-Variable -Name Entries -Scope Local -Force  
      Remove-Variable -Name Entry -Scope Local -Force  
      Remove-Variable -Name MSIFileName -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name OutputFile -Scope Local -Force  
      Remove-Variable -Name PropertyName -Scope Local -Force  
      Remove-Variable -Name PropertyValue -Scope Local -Force  
      Remove-Variable -Name Record -Scope Local -Force  
      Remove-Variable -Name RelativePath -Scope Local -Force  
      Remove-Variable -Name View -Scope Local -Force  
      Remove-Variable -Name WindowsInstaller -Scope Local -Force  
 }  
   
 Clear-Host  
 ProcessTextFiles  
 Get-MSIFile  
 New-UserInputFile  
 Install-MSI  
 Uninstall-MSI  
 Get-ProductName  
 Get-ProductCode  
 Get-MSIFileName  
 Get-Properties  
 Get-Features  
 Get-Buttons  
   
 #Cleanup Global Variables  
 Remove-Variable -Name ApplicationName -Scope Global -Force  
 Remove-Variable -Name MSI -Scope Global -Force  
 Remove-Variable -Name ProductCode -Scope Global -Force  
