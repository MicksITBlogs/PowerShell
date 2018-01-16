 #*******************************************************************************  
 #   Author: Mick Pletcher  
 #    Date: 25 November 2013  
 #  
 #   Program: Add User to Local Administrator Group in Active Directory  
 #*******************************************************************************  

 #Define Global Memory  
 Set-Variable -Name Member -Scope Local -Force  
 Set-Variable -Name Results -Value $false -Scope Global -Force  

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

 Function CheckADForUser ($Member){  

      #Define Local Memory  
      Set-Variable -Name Computer -Scope Local -Force  
      Set-Variable -Name Group -Scope Local -Force  
      Set-Variable -Name LocalGroup -Scope Local -Force  
      Set-Variable -Name User -Scope Local -Force  
      Set-Variable -Name UserNames -Scope Local -Force  
      Set-Variable -Name Users -Scope Local -Force  

      $LocalGroup = "Administrators"  
      $UserNames = @()  
      $Computer = $env:computername  
           $Group= [ADSI]"WinNT://$Computer/$LocalGroup,group"  
           $Users = @($Group.psbase.Invoke("Members"))  
           $Users | ForEach-Object {  
                $UserNames += $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)  
                Foreach ( $User in $UserNames) {  
                     If ($User -eq $Member) {  
                          $Global:Results = $true  
                          Write-Host $User  
                     }  
                }  
           }  

      #Cleanup Local Memory  
      $UserNames.Clear()  
      Remove-Variable -Name Computer -Scope Local -Force  
      Remove-Variable -Name Group -Scope Local -Force  
      Remove-Variable -Name LocalGroup -Scope Local -Force  
      Remove-Variable -Name User -Scope Local -Force  
      Remove-Variable -Name UserNames -Scope Local -Force  
      Remove-Variable -Name Users -Scope Local -Force  

 }  

 Function AddUserToAD ($Member) {  

      $group = [ADSI]"WinNT://./Administrators,group"  
      $group.Add("WinNT://$Member,user")  

 }  

 cls  
 $Member = ""  
 CheckADForUser $Member  
 If ($Results -eq $true) {  
      AddRemovePrograms $Member $Member "Installed"  
      cls  
      Write-Host $Member" is already in the local administrators group"  
 } else {  
      AddUserToAD $Member  
      CheckADForUser $Member  
      If ($Results -eq $true) {  
           AddRemovePrograms $Member $Member "Installed"  
           cls  
           Write-Host $Member" has been added to the local administrators group"  
      }  
 }  

 #Cleanup Global Memory  
 Remove-Variable -Name Member -Scope Local -Force  
 Remove-Variable -Name Results -Scope Global -Force  