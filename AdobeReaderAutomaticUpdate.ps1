 #*******************************************************************************  
 #   Author: Mick Pletcher  
 #    Date: 27 March 2013  
 #  
 #   Program: Adobe Reader Automatic Update  
 #*******************************************************************************  
 Clear-Host  
 $Global:OS  
 Function GetOSArchitecture{  
      $Global:OS=Get-WMIObject win32_operatingsystem  
      $Global:OS.OSArchitecture  
 }  
 GetOSArchitecture  
 If($Global.OS.OSArchitecture -ne "32-bit"){  
      New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Adobe" -Name "Adobe ARM" –Force  
      New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Adobe\Adobe ARM" -Name 1.0 –Force  
      New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Adobe\Adobe ARM\1.0" -Name ARM –Force  
      New-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Adobe\Adobe ARM\1.0\ARM" -Name iCheck -Value 3 -PropertyType DWORD  
      New-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Adobe\Adobe ARM\1.0\ARM" -Name iCheckReader -Value 3 -PropertyType DWORD  
 } else{  
      New-Item -Path "HKLM:\SOFTWARE\Adobe" -Name "Adobe ARM" –Force  
      New-Item -Path "HKLM:\SOFTWARE\Adobe\Adobe ARM" -Name 1.0 –Force  
      New-Item -Path "HKLM:\SOFTWARE\Adobe\Adobe ARM\1.0" -Name ARM –Force  
      New-ItemProperty -Path "HKLM:\SOFTWARE\Adobe\Adobe ARM\1.0\ARM" -Name iCheck -Value 3 -PropertyType DWORD  
      New-ItemProperty -Path "HKLM:\SOFTWARE\Adobe\Adobe ARM\1.0\ARM" -Name iCheckReader -Value 3 -PropertyType DWORD  
 }  