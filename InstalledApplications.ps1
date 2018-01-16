<#  
 .SYNOPSIS  
   Installed Applications  
 .DESCRIPTION  
   This will retrieve the list of installed applications from   
   add/remove programs  
 .Author  
   Mick Pletcher  
 .Date  
   09 April 2015  
 .EXAMPLE  
   powershell.exe -executionpolicy bypass -file InstalledApplications.ps1  
 #>  
   
 #Declare Global Variables  
 Set-Variable -Name Architecture -Scope Global -Force  
 Set-Variable -Name Applications -Scope Global -Force  
 Set-Variable -Name LogFile -Value "c:\Applications.csv" -Scope Global -Force  
 Set-Variable -Name RelativePath -Scope Global -Force  
   
 function Get-RelativePath {  
      $Global:RelativePath = (split-path $SCRIPT:MyInvocation.MyCommand.Path -parent)+"\"  
 }  
   
 function Get-Architecture {  
      $Global:Architecture = Get-WmiObject -Class Win32_OperatingSystem | Select-Object OSArchitecture  
      $Global:Architecture = $Global:Architecture.OSArchitecture  
      #Returns 32-bit or 64-bit  
 }  
   
 function CreateLogFile {  
      #Define Local Variables  
      Set-Variable -Name Output -Scope Local -Force  
      Set-Variable -Name Temp -Scope Local -Force  
        
      if ((Test-Path $Global:LogFile) -eq $true) {  
           Remove-Item -Path $Global:LogFile -Force  
      }  
      if ((Test-Path $Global:LogFile) -eq $false) {  
           $Temp = New-Item -Path $Global:LogFile -ItemType file -Force  
      }  
      $Output = "Application Name"  
      Out-File -FilePath $Global:LogFile -InputObject $Output -Append -Force -Encoding UTF8  
                       
        
      #Cleanup Local Variables  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name Temp -Scope Local -Force  
 }  
   
 function GetAddRemovePrograms {  
      #Define Local Variables  
      Set-Variable -Name Applicationsx86 -Scope Local -Force  
      Set-Variable -Name Applicationsx64 -Scope Local -Force  
      Set-Variable -Name ARPx86 -Scope Local -Force  
      Set-Variable -Name ARPx64 -Scope Local -Force  
        
      $ARPx86 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\"  
      $ARPx64 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\"  
      if ($Global:Architecture -eq "32-bit") {  
           $Applicationsx86 = Get-ChildItem -Path $ARPx86 | ForEach-Object -Process {$_.GetValue("DisplayName")}  
      } else {  
           $Applicationsx86 = Get-ChildItem -Path $ARPx64 | ForEach-Object -Process {$_.GetValue("DisplayName")}  
           $Applicationsx64 = Get-ChildItem -Path $ARPx86 | ForEach-Object -Process {$_.GetValue("DisplayName")}  
      }  
      $Global:Applications = $Applicationsx86 + $Applicationsx64  
      $Global:Applications = $Global:Applications | Sort-Object  
      $Global:Applications = $Global:Applications | select -Unique  
        
      #Cleanup Local Memory  
      Remove-Variable -Name Applicationsx86 -Force  
      Remove-Variable -Name Applicationsx64 -Force  
      Remove-Variable -Name ARPx86 -Force  
      Remove-Variable -Name ARPx64 -Force  
 }  
   
 function GenerateReport {  
      #Define Local Variables  
      Set-Variable -Name Application -Scope Local -Force  
      Set-Variable -Name Exclusions -Scope Local -Force  
      Set-Variable -Name LogFile -Scope Local -Force  
      Set-Variable -Name Print -Value $true -Scope Local -Force  
        
      $Exclusions = Get-Content -Path $RelativePath"ExclusionList.txt"  
      foreach ($Application in $Global:Applications) {  
           if ($Application -ne $null) {  
                $Application = $Application.Trim()  
           }  
           if (($Application -ne "") -and ($Application -ne $null)) {  
                foreach ($Exclusion in $Exclusions) {  
                     $Exclusion = $Exclusion.Trim()  
                     if ($Application -like $Exclusion) {  
                          $Print = $false  
                     }  
                }  
                if ($Print -eq $true) {  
                     Write-Host $Application  
                     Out-File -FilePath $Global:LogFile -InputObject $Application -Append -Force -Encoding UTF8  
                }  
           }  
           $Print = $true  
      }  
   
      #Cleanup Local Variables  
      Remove-Variable -Name Application -Scope Local -Force  
      Remove-Variable -Name Exclusions -Scope Local -Force  
      Remove-Variable -Name LogFile -Scope Local -Force  
      Remove-Variable -Name Print -Scope Local -Force  
 }  
   
 cls  
 Get-RelativePath  
 Get-Architecture  
 CreateLogFile  
 GetAddRemovePrograms  
 GenerateReport  
   
 #Cleanup Global Variables  
 Remove-Variable -Name Architecture -Force  
 Remove-Variable -Name Applications -Force  
 Remove-Variable -Name LogFile -Force  
 Remove-Variable -Name RelativePath -Force  
   
