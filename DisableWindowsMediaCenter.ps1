 #*******************************************************************************  
 #   Author: Mick Pletcher  
 #    Date: 16 August 2013  
 #  
 #   Program: Windows Media Center  
 #*******************************************************************************  
 cls  

 #Declare Global Memory  
 Set-Variable -Name a -Scope Global -Force  
 Set-Variable -Name Output -Scope Global -Force  

 Function AddRemovePrograms($KeyName, $DisplayName, $Version){  

      #Define Local Memory  
      New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT  
      Set-Variable -Name AddRemKey -Scope Local -Force  
      Set-Variable -Name guid -Scope Local -Force  
      Set-Variable -Name ProductsKey -Scope Local -Force  

      If (!(Test-Path c:\windows\GSPBox_Icon.bmp)){  
           Copy-Item -Path \\global.gsp\data\clients\na_clients\Build\Add-ins\GSPBox_Icon.bmp -Destination c:\Windows -Force  
      }  
      $AddRemKey = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"  
      $ProductsKey = "HKCR:\Installer\Products\"  
      New-Item -Path $AddRemKey -Name $KeyName –Force  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayName -Value $DisplayName -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayVersion -Value $Version -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name UninstallString -Value " " -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name Publisher -Value "Gresham, Smith and Partners" -PropertyType String  
      New-ItemProperty -Path $AddRemKey"\"$KeyName -Name DisplayIcon -Value "c:\windows\GSPBox_Icon.bmp" -PropertyType String  
      $guid = [guid]::NewGuid().ToString("N")  
      $guid.ToString()  
      $guid = $guid.ToUpper()  
      New-Item -Path $ProductsKey -Name $guid –Force  
      New-ItemProperty -Path $ProductsKey"\"$guid -Name ProductName -Value $DisplayName -PropertyType String -Force  

      #Cleanup Local Memory  
      remove-psdrive -name HKCR  
      Remove-Variable -Name AddRemKey -Scope Local -Force  
      Remove-Variable -Name guid -Scope Local -Force  
      Remove-Variable -Name ProductsKey -Scope Local -Force  

 }  

 Invoke-Command {dism.exe /online /disable-feature /featurename:MediaCenter /norestart}  
 $a = Invoke-Command {dism.exe /online /get-featureinfo /featurename:MediaCenter}  
 $Output = $a | Select-String "State : Disabled"  
 Write-Host $Output  
 If ($Output -like "State : Disabled"){  
      AddRemovePrograms "MediaCenter" "MediaCenter" "Disabled"  
 }  

 #Cleanup Global Memory  
 Remove-Variable -Name a -Scope Global -Force  
 Remove-Variable -Name Output -Scope Global -Force  