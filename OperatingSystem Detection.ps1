<#  
 .SYNOPSIS  
   Operating System  
 .DESCRIPTION  
   This script will detect what operating system is installed  
   and write a file named for that OS to the windows directory.  
 .EXAMPLE  
   powershell.exe -executionpolicy bypass -file OperatingSytem.ps1  
 #>  
   
 cls  
 $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName .  
 Switch ($OS.Version) {  
      5.0.2195 {New-Item -Name "Windows 2000" -Path $env:windir -ItemType File}  
      5.1.2600 {New-Item -Name "Windows XP" -Path $env:windir -ItemType File}  
      5.2.3790 {New-Item -Name "Windows XP 64-Bit" -Path $env:windir -ItemType File}  
      6.0.6000 {New-Item -Name "Windows Vista" -Path $env:windir -ItemType File}  
      6.0.6001 {New-Item -Name "Windows Vista SP1" -Path $env:windir -ItemType File}  
      6.0.6002 {New-Item -Name "Windows Vista SP2" -Path $env:windir -ItemType File}  
      6.1.7600 {New-Item -Name "Windows 7" -Path $env:windir -ItemType File}  
      6.1.7601 {New-Item -Name "Windows 7 SP1" -Path $env:windir -ItemType File}  
      6.2.9200 {New-Item -Name "Windows 8" -Path $env:windir -ItemType File}  
      6.3.9600 {New-Item -Name "Windows 8.1" -Path $env:windir -ItemType File}  
 }  
