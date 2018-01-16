 Function UninstallOldApplication($Description) {  
      #Declare Local Memory  
      Set-Variable -Name AppName -Scope Local -Force  
      Set-Variable -Name Arguments -Scope Local -Force  
      Set-Variable -Name Code -Scope Local -Force  
      Set-Variable -Name GUID -Scope Local -Force  
      Set-Variable -Name Output -Scope Local -Force  
      #Change '%application%' to whatever app you are calling  
      $Description = [char]34+"description like"+[char]32+[char]39+[char]37+$Description+[char]37+[char]39+[char]34  
      $Output = wmic product where $Description get IdentifyingNumber  
      $Output1 = wmic product where $Description get Description  
      $Output1 | ForEach-Object {  
           $_ = $_.Trim()  
        if(($_ -ne "Description")-and($_ -ne "")){  
          $AppName = $_  
        }  
      }  
      Write-Host "Uninstalling"$AppName"....." -NoNewline  
      $Output | ForEach-Object {  
           $_ = $_.Trim()  
        if(($_ -ne "IdentifyingNumber")-and($_ -ne "")){  
          $GUID = $_  
        }  
      }  
      $Arguments = "/X"+[char]32+$GUID+[char]32+"/qb- /norestart"  
      $Code = (Start-Process -FilePath "msiexec.exe" -ArgumentList $Arguments -Wait -Passthru).ExitCode  
      If ($Code -eq 0) {  
           Write-Host "Uninstalled" -ForegroundColor Yellow  
      } else {  
           Write-Host "Failed" -ForegroundColor Red  
      }  
      #Cleanup Local Memory  
      Remove-Variable -Name AppName -Scope Local -Force  
      Remove-Variable -Name Arguments -Scope Local -Force  
      Remove-Variable -Name Code -Scope Local -Force  
      Remove-Variable -Name GUID -Scope Local -Force  
      Remove-Variable -Name Output -Scope Local -Force  
      Remove-Variable -Name Output1 -Scope Local -Force  
 }  